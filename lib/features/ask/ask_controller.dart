import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/copilot_service.dart';
import '../../ai/gemini_client.dart';
import '../../ai/ocr_client.dart';
import '../../ai/whisper_client.dart';
import '../../app/providers.dart';

final geminiClientProvider = Provider<GeminiClient>((ref) {
  final client = GeminiClient();
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

/// Set once the user agrees that AI input is sent to Gemini.
const aiConsentSettingKey = 'ai_consent';

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

/// The conversation on the Ask screen. Kept in memory for the session.
class AskController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() => const [];

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
    ChatMessage result;
    if (!service.isConfigured) {
      result = const FailureMessage(AskFailure.notConfigured);
    } else {
      try {
        // Read straight from the database: categoriesProvider's stream is
        // paused when no screen watches it, so its future would never land.
        final categories = await ref
            .read(ledgerRepositoryProvider)
            .watchCategories()
            .first;
        final reply = await service.handle(
          input,
          categories: categories,
          languageCode: languageCode,
        );
        result = AssistantMessage(reply);
      } on AiException catch (e) {
        debugPrint('[ai] failed: $e');
        result = FailureMessage(
          e.isQuota ? AskFailure.quota : AskFailure.other,
        );
      } catch (e, stack) {
        debugPrint('[ai] failed: $e\n$stack');
        result = const FailureMessage(AskFailure.other);
      }
    }
    debugPrint('[ai] done in ${watch.elapsedMilliseconds} ms: $result');
    state = [...state.where((m) => m is! PendingMessage), result];
  }

  void markSaved(AssistantMessage message) {
    state = [
      for (final m in state)
        identical(m, message)
            ? AssistantMessage(message.reply, saved: true)
            : m,
    ];
  }

  void clear() => state = const [];
}

final askControllerProvider =
    NotifierProvider<AskController, List<ChatMessage>>(AskController.new);
