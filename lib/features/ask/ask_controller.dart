import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../ai/copilot_service.dart';
import '../../ai/gemini_client.dart';
import '../../ai/ocr_client.dart';
import '../../ai/whisper_client.dart';
import '../../app/providers.dart';
import '../../cloud/supabase_config.dart';
import '../../core/money/currency.dart';
import '../../data/chat_repository.dart';
import '../../data/database.dart';
import 'chat_codec.dart';

final geminiClientProvider = Provider<GeminiClient>((ref) {
  // With Supabase, the Gemini key stays on the server (Edge Function).
  final client = GeminiClient(
    proxy: supabaseReady
        ? GeminiProxy(
            url: Uri.parse('$supabaseUrl/functions/v1/gemini'),
            publishableKey: supabasePublishableKey,
            accessToken: () =>
                Supabase.instance.client.auth.currentSession?.accessToken,
          )
        : null,
  );
  ref.onDispose(client.close);
  return client;
});

final whisperClientProvider = Provider<WhisperClient>((ref) {
  final client = WhisperClient();
  ref.onDispose(client.close);
  return client;
});

final ocrClientProvider = Provider<OcrClient>((ref) {
  final client = OcrClient();
  ref.onDispose(client.close);
  return client;
});

final copilotServiceProvider = Provider<CopilotService>(
  (ref) => CopilotService(
    ref.watch(geminiClientProvider),
    ref.watch(ledgerRepositoryProvider),
    whisper: ref.watch(whisperClientProvider),
    ocr: ref.watch(ocrClientProvider),
  ),
);

/// Rebuilt for each signed-in user, like the ledger.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  ref.watch(currentUserIdProvider);
  final repo = ChatRepository(ref.watch(cloudStoreProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Saved conversations, most recently active first.
final chatsProvider = StreamProvider<List<ChatRow>>(
  (ref) => ref.watch(chatRepositoryProvider).watchChats(),
);

sealed class ChatMessage {
  const ChatMessage();
}

class UserMessage extends ChatMessage {
  const UserMessage({this.text, this.image, this.isVoice = false});

  final String? text;
  final Uint8List? image;
  final bool isVoice;
}

class AssistantMessage extends ChatMessage {
  const AssistantMessage(this.reply, {this.saved = false});

  final CopilotReply reply;

  /// True once the user saved the proposed entry.
  final bool saved;
}

class PendingMessage extends ChatMessage {
  const PendingMessage();
}

enum AskFailure { notConfigured, quota, other }

class FailureMessage extends ChatMessage {
  const FailureMessage(this.failure);
  final AskFailure failure;
}

/// The conversation on the Ask screen. Saved after every reply so it can be
/// reopened from the history.
class AskController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    // A new account starts with an empty chat.
    ref.watch(currentUserIdProvider);
    _chatId = null;
    return const [];
  }

  /// The saved chat being shown; null until the first reply is saved.
  String? get chatId => _chatId;
  String? _chatId;

  /// Saves run one after another so a chat is never created twice.
  Future<void> _saving = Future.value();

  bool get isBusy => state.lastOrNull is PendingMessage;

  Future<void> send(
    CopilotInput input,
    UserMessage shown, {
    required String languageCode,
  }) async {
    if (isBusy) return;
    state = [...state, shown, const PendingMessage()];

    final service = ref.read(copilotServiceProvider);
    final watch = Stopwatch()..start();
    debugPrint('[ai] send ${input.runtimeType}');
    final results = <ChatMessage>[];
    if (!service.isConfigured) {
      results.add(const FailureMessage(AskFailure.notConfigured));
    } else {
      try {
        // Read straight from the database: categoriesProvider's stream is
        // paused when no screen watches it, so its future would never land.
        final categories = await ref
            .read(ledgerRepositoryProvider)
            .watchCategories()
            .first;
        final settings = ref.read(settingsStoreProvider);
        final currencyCode = await settings.get(lastCurrencySettingKey);
        final reply = await service.handle(
          input,
          categories: categories,
          languageCode: languageCode,
          businessName: await settings.get(businessNameSettingKey) ?? '',
          defaultCurrency: Currency.values
              .where((c) => c.code == currencyCode)
              .firstOrNull,
        );
        results.add(AssistantMessage(reply));
        if (reply.declined case final declined?) {
          results.add(AssistantMessage(MessageReply(declined)));
        }
      } on AiException catch (e) {
        debugPrint('[ai] failed: $e');
        results.add(
          FailureMessage(e.isQuota ? AskFailure.quota : AskFailure.other),
        );
      } catch (e, stack) {
        debugPrint('[ai] failed: $e\n$stack');
        results.add(const FailureMessage(AskFailure.other));
      }
    }
    debugPrint('[ai] done in ${watch.elapsedMilliseconds} ms: $results');
    state = [...state.where((m) => m is! PendingMessage), ...results];
    await _save();
  }

  void markSaved(AssistantMessage message) {
    state = [
      for (final m in state)
        identical(m, message)
            ? AssistantMessage(message.reply, saved: true)
            : m,
    ];
    _save();
  }

  /// Starts a new, empty chat.
  void clear() {
    if (isBusy) return;
    _chatId = null;
    state = const [];
  }

  /// Shows a saved chat.
  Future<void> open(String chatId) async {
    if (isBusy || chatId == _chatId) return;
    final data = await ref.read(chatRepositoryProvider).loadMessages(chatId);
    _chatId = chatId;
    state = [for (final d in data) ?decodeMessage(d)];
  }

  Future<void> delete(String chatId) async {
    if (chatId == _chatId) clear();
    await ref.read(chatRepositoryProvider).delete(chatId);
  }

  Future<void> _save() => _saving = _saving.then((_) async {
        final messages = state;
        final data = [for (final m in messages) ?encodeMessage(m)];
        if (data.isEmpty) return;
        final repo = ref.read(chatRepositoryProvider);
        try {
          if (_chatId == null) {
            final first = messages.whereType<UserMessage>().firstOrNull;
            final title = (first?.text ?? '').trim();
            _chatId = await repo.create(
              title.length > 80 ? '${title.substring(0, 80)}…' : title,
              data,
            );
          } else {
            await repo.update(_chatId!, data);
          }
        } catch (e) {
          debugPrint('[ai] saving chat failed: $e');
        }
      });
}

final askControllerProvider =
    NotifierProvider<AskController, List<ChatMessage>>(AskController.new);
