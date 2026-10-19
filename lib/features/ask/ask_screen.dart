import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import '../../ai/copilot_service.dart';
import '../../ai/gemini_client.dart';
import '../../ai/wav.dart';
import '../../app/labels.dart';
import '../../app/providers.dart';
import '../../cloud/auth.dart';
import '../../core/date_only.dart';
import '../../core/money/money.dart';
import '../../core/money/money_format.dart';
import '../../core/money/money_parser.dart';
import '../../domain/entry_draft.dart';
import '../../domain/entry_proposal.dart';
import '../../domain/enums.dart';
import 'ask_controller.dart';
import 'chat_history_drawer.dart';

/// The landing screen: say, type or photograph what happened, or ask a
/// question about the ledger.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();

  final _focus = FocusNode();

  static const _bytesPerSecond = 16000 * 2; // 16 kHz, 16-bit mono

  final _pcm = BytesBuilder();
  StreamSubscription<Uint8List>? _audioSub;

  /// What the text box held before recording started.
  String _prefix = '';

  bool _recording = false;
  bool _transcribing = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  /// True while the text box holds a voice transcript, so the entry is
  /// recorded as coming from voice.
  bool _fromVoice = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(
      () => setState(() {
        if (_text.text.trim().isEmpty) _fromVoice = false;
      }),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioSub?.cancel();
    _recorder.dispose();
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _languageCode => Localizations.localeOf(context).languageCode;

  Future<void> _send(CopilotInput input, UserMessage shown) async {
    final languageCode = _languageCode;
    final future = ref
        .read(askControllerProvider.notifier)
        .send(input, shown, languageCode: languageCode);
    _scrollToEnd();
    await future;
    _scrollToEnd();
  }

  void _sendText() {
    final text = _text.text.trim();
    if (text.isEmpty || ref.read(askControllerProvider.notifier).isBusy) return;
    final fromVoice = _fromVoice;
    _text.clear();
    _send(
      TextInput(text, source: fromVoice ? EntrySource.voice : EntrySource.text),
      UserMessage(text: text, isVoice: fromVoice),
    );
  }

  Future<void> _startRecording() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!await _recorder.hasPermission()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.askMicDenied)));
      return;
    }
    if (!mounted) return;
    // 16 kHz mono 16-bit PCM, wrapped as WAV when recording stops.
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );
    _pcm.clear();
    _prefix = _text.text.trim();
    _audioSub = stream.listen(_pcm.add);
    setState(() {
      _recording = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
      // Keep requests small for the free tier.
      if (_elapsed.inSeconds >= 60) _stopRecording();
    });
  }

  void _showInTextBox(String transcript) {
    _text.text = _prefix.isEmpty ? transcript : '$_prefix $transcript';
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
  }

  Future<void> _stopRecording({bool discard = false}) async {
    // The 60-second auto-stop and a tap can both arrive.
    if (!_recording) return;
    _timer?.cancel();
    await _recorder.stop();
    await _audioSub?.cancel();
    _audioSub = null;
    final pcm = _pcm.takeBytes();
    setState(() => _recording = false);
    if (discard || pcm.length < _bytesPerSecond ~/ 2) {
      _text.text = _prefix;
      return;
    }
    await _transcribeIntoTextBox(pcm16ToWav(pcm), 'audio/wav');
  }

  /// Puts the transcript in the text box so the user can check or fix it
  /// before sending.
  Future<void> _transcribeIntoTextBox(Uint8List audio, String mimeType) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final languageCode = _languageCode;
    setState(() => _transcribing = true);
    String transcript = '';
    try {
      transcript = await ref
          .read(copilotServiceProvider)
          .transcribe(audio, mimeType, languageCode: languageCode);
    } on AiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.isQuota
                ? l10n.askQuota
                : e.isBusy
                ? l10n.askBusy
                : l10n.askTranscribeFailed,
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.askTranscribeFailed)));
    } finally {
      if (mounted) setState(() => _transcribing = false);
    }
    if (!mounted) return;
    if (transcript.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.askNothingHeard)));
      return;
    }
    _showInTextBox(transcript);
    _fromVoice = true;
    _focus.requestFocus();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
    } catch (_) {
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final caption = _text.text.trim();
    _text.clear();
    await _send(
      PhotoInput(
        bytes,
        picked.mimeType ?? _imageMime(picked.name),
        caption: caption,
      ),
      UserMessage(image: bytes, text: caption.isEmpty ? null : caption),
    );
  }

  Future<void> _choosePhotoSource() async {
    // In a browser the picker must open within the tap itself: after our
    // sheet closes, Safari no longer counts it as the user's action and
    // ignores it. The browser's own picker offers the camera anyway.
    final canUseCamera =
        !kIsWeb && _picker.supportsImageSource(ImageSource.camera);
    if (!canUseCamera) return _pickPhoto(ImageSource.gallery);
    final l10n = context.l10n;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.askTakePhoto),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.askChoosePhoto),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final messages = ref.watch(askControllerProvider);
    final busy = messages.lastOrNull is PendingMessage;
    final configured = ref.watch(copilotServiceProvider).isConfigured;

    return Scaffold(
      drawer: const ChatHistoryDrawer(),
      appBar: AppBar(
        title: Text(l10n.askTitle),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: l10n.chatHistory,
            icon: const Icon(Icons.history),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              tooltip: l10n.askNewChat,
              icon: const Icon(Icons.edit_note),
              onPressed: busy
                  ? null
                  : () => ref.read(askControllerProvider.notifier).clear(),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!configured)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.askNotConfigured,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: messages.isEmpty
                ? const _Welcome()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) =>
                        _MessageView(messages[index]),
                  ),
          ),
          _Composer(
            controller: _text,
            focusNode: _focus,
            busy: busy,
            recording: _recording,
            transcribing: _transcribing,
            elapsed: _elapsed,
            onSend: _sendText,
            onPhoto: _choosePhotoSource,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
            onCancelRecording: () => _stopRecording(discard: true),
          ),
        ],
      ),
    );
  }
}

String _imageMime(String name) {
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'image/jpeg',
  };
}

class _Welcome extends ConsumerWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lines = context.l10n.askWelcomeTitle.split('\n');
    // Greet the signed-in user by the name they signed up with.
    final user = ref.watch(currentUserProvider).value;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim() ?? '';
    if (name.isNotEmpty) lines[0] = context.l10n.askHelloName(name);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 28,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              lines.first,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
                letterSpacing: -0.5,
              ),
            ),
            if (lines.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                lines.skip(1).join('\n'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.recording,
    required this.transcribing,
    required this.elapsed,
    required this.onSend,
    required this.onPhoto,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onCancelRecording,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final bool recording;

  /// True while a recording is being turned into text.
  final bool transcribing;
  final Duration elapsed;
  final VoidCallback onSend;
  final VoidCallback onPhoto;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onCancelRecording;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasText = controller.text.trim().isNotEmpty;
    // The field sits borderless inside the bar; the bar draws the outline.
    const bare = InputDecoration(
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    );

    final List<Widget> children;
    if (recording) {
      final time =
          '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      children = [
        IconButton(
          tooltip: l10n.cancel,
          icon: const Icon(Icons.delete_outline),
          onPressed: onCancelRecording,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14, right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fiber_manual_record, color: scheme.error, size: 12),
              const SizedBox(width: 4),
              Text(
                time,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            minLines: 1,
            maxLines: 4,
            decoration: bare.copyWith(hintText: l10n.askListening),
          ),
        ),
        IconButton.filled(
          tooltip: l10n.askDoneTalking,
          icon: const Icon(Icons.check_rounded),
          onPressed: onStopRecording,
        ),
      ];
    } else {
      children = [
        IconButton(
          tooltip: l10n.askPhotoTooltip,
          icon: const Icon(Icons.photo_camera_outlined),
          onPressed: busy || transcribing ? null : onPhoto,
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: !transcribing,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            decoration: bare.copyWith(
              hintText: transcribing ? l10n.askTranscribing : l10n.askHint,
              hintMaxLines: 1,
            ),
          ),
        ),
        if (transcribing)
          const SizedBox.square(
            dimension: 40,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else if (hasText)
          IconButton.filled(
            tooltip: l10n.askSend,
            icon: const Icon(Icons.arrow_upward_rounded),
            onPressed: busy ? null : onSend,
          )
        else
          IconButton.filled(
            tooltip: l10n.askMicTooltip,
            icon: const Icon(Icons.mic_none_rounded),
            onPressed: busy ? null : onStartRecording,
          ),
      ];
    }

    return ColoredBox(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: recording ? scheme.error : scheme.outlineVariant,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageView extends ConsumerWidget {
  const _MessageView(this.message);

  final ChatMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return switch (message) {
      UserMessage m => _UserBubble(m),
      PendingMessage() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(l10n.askThinking),
          ],
        ),
      ),
      FailureMessage(:final failure) => _AssistantCard(
        child: Text(switch (failure) {
          AskFailure.notConfigured => l10n.askNotConfigured,
          AskFailure.quota => l10n.askQuota,
          AskFailure.busy => l10n.askBusy,
          AskFailure.other => l10n.askError,
        }),
      ),
      AssistantMessage m => _AssistantCard(
        transcript: m.reply.transcript,
        fromPhoto: switch (m.reply) {
          ProposalReply(:final proposal) =>
            proposal.source == EntrySource.receipt,
          _ => false,
        },
        child: switch (m.reply) {
          ProposalReply() => _ProposalView(m),
          AnswerReply reply => _AnswerView(reply),
          MessageReply(:final message) => Text(message),
        },
      ),
    };
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.message);

  final UserMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(message.image!, height: 160),
              ),
            if (message.text != null) ...[
              if (message.image != null) const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isVoice) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.mic, size: 16, color: scheme.onPrimary),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      message.text!,
                      style: TextStyle(color: scheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.child,
    this.transcript,
    this.fromPhoto = false,
  });

  final Widget child;
  final String? transcript;

  /// The transcript is text read from a photo, not speech.
  final bool fromPhoto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 24, bottom: 8),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transcript != null && fromPhoto) ...[
                  Text(
                    context.l10n.askRead(transcript!),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProposalView extends ConsumerStatefulWidget {
  const _ProposalView(this.message);

  final AssistantMessage message;

  @override
  ConsumerState<_ProposalView> createState() => _ProposalViewState();
}

class _ProposalViewState extends ConsumerState<_ProposalView> {
  bool _saving = false;

  AssistantMessage get message => widget.message;
  EntryProposal get _proposal => (message.reply as ProposalReply).proposal;

  Future<void> _edit() async {
    final saved = await context.push<bool>('/entry/new', extra: _proposal);
    if (saved == true) {
      ref.read(askControllerProvider.notifier).markSaved(message);
    }
  }

  /// Saves the proposal as it is, with the same checks as the entry form.
  /// Anything the form would flag (bad amount, missing category, future
  /// date) opens the form instead, so the user can fix it there.
  Future<void> _save() async {
    if (_saving) return;
    final proposal = _proposal;
    final currency = proposal.currency;
    if (currency == null) return _edit();
    final parsed = parseAmount(proposal.amountText ?? '', currency);
    final categories = ref.read(categoriesByIdProvider);
    final draft = EntryDraft(
      type: proposal.type,
      amountMinor: parsed.minor ?? 0,
      currency: currency,
      occurredOn: proposal.occurredOn ?? dateOnly(DateTime.now()),
      categoryId: proposal.categoryId,
      categoryKind: categories[proposal.categoryId]?.kind,
      description: proposal.description,
      note: proposal.rawInput ?? '',
      paymentMethod: proposal.paymentMethod,
      source: proposal.source,
    );
    if (!parsed.isOk ||
        validateDraft(draft, today: DateTime.now()).isNotEmpty) {
      return _edit();
    }

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(ledgerRepositoryProvider);
    setState(() => _saving = true);
    try {
      final duplicates = await repo.findPossibleDuplicates(draft);
      if (duplicates.isNotEmpty && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.duplicateTitle),
            content: Text(l10n.duplicateBody(duplicates.length)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.saveAnyway),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
      await repo.create(draft);
      await ref
          .read(settingsStoreProvider)
          .set(lastCurrencySettingKey, currency.code);
      ref.read(askControllerProvider.notifier).markSaved(message);
      messenger.showSnackBar(SnackBar(content: Text(l10n.savedMessage)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final proposal = (message.reply as ProposalReply).proposal;
    final category = ref.watch(categoriesByIdProvider)[proposal.categoryId];
    final color = proposal.type.isMoneyIn
        ? MoneyColors.moneyIn(context)
        : MoneyColors.moneyOut(context);

    final parsed = proposal.amountText == null || proposal.currency == null
        ? null
        : parseAmount(proposal.amountText!, proposal.currency!);
    final amount = proposal.amountText == null
        ? null
        : parsed?.minor != null
        ? formatMoney(
            Money(parsed!.minor!, proposal.currency!),
            locale: context.localeTag,
          )
        : proposal.currency == null
        ? proposal.amountText!
        : '${proposal.amountText} ${proposal.currency!.code}';

    Widget row(IconData icon, String text, {Color? textColor}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(entryTypeIcon(proposal.type), color: color),
            const SizedBox(width: 8),
            Text(
              l10n.entryType(proposal.type),
              style: textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount ?? l10n.askAmountMissing,
          style: amount == null
              ? textTheme.bodyLarge?.copyWith(color: scheme.error)
              : textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (proposal.amountText != null && proposal.currency == null)
          Text(
            l10n.askCurrencyUnknown,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        const SizedBox(height: 6),
        if (proposal.description.isNotEmpty)
          row(Icons.notes, proposal.description),
        if (proposal.type.categoryKind != null)
          row(Icons.sell_outlined, context.categoryName(category)),
        row(
          Icons.calendar_today_outlined,
          proposal.occurredOn == null
              ? l10n.today
              : DateFormat.yMMMd(context.localeTag)
                    .format(proposal.occurredOn!),
        ),
        if (proposal.paymentMethod != null)
          row(
            Icons.payments_outlined,
            l10n.paymentMethodLabel(proposal.paymentMethod!),
          ),
        const SizedBox(height: 12),
        if (message.saved)
          Row(
            children: [
              Icon(Icons.check_circle, color: MoneyColors.moneyIn(context)),
              const SizedBox(width: 8),
              Text(l10n.savedMessage),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(l10n.edit),
                  onPressed: _saving ? null : _edit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.save),
                  // Without an amount and currency there is nothing to save
                  // yet; Edit fills them in.
                  onPressed:
                      _saving ||
                          proposal.amountText == null ||
                          proposal.currency == null
                      ? null
                      : _save,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _AnswerView extends StatelessWidget {
  const _AnswerView(this.reply);

  final AnswerReply reply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final facts = reply.facts;
    final locale = context.localeTag;
    String fmt(Money m, {bool signed = false}) =>
        formatMoney(m, locale: locale, signed: signed);

    final lines = <Widget>[];
    if (facts.topic == QuestionTopic.cashBalance) {
      if (facts.cashBalances.isEmpty) {
        lines.add(Text(l10n.askCashUnknown));
      }
      for (final money in facts.cashBalances.values) {
        lines.add(_FactLine(l10n.cashOnHand, fmt(money), emphasize: true));
      }
    } else if (facts.summary.isEmpty) {
      lines.add(Text(l10n.askNoRecords));
    } else if (facts.topic == QuestionTopic.expenseCategories) {
      if (facts.topExpenses.isEmpty) lines.add(Text(l10n.noExpenses));
      for (final list in facts.topExpenses.values) {
        for (final e in list) {
          lines.add(_CategoryFactLine(e.key, fmt(e.value)));
        }
      }
    } else {
      for (final t in facts.summary.byCurrency.values) {
        lines.addAll([
          if (lines.isNotEmpty) const Divider(height: 16),
          _FactLine(
            l10n.moneyIn,
            fmt(t.income),
            color: MoneyColors.moneyIn(context),
          ),
          _FactLine(
            l10n.moneyOut,
            fmt(t.expense),
            color: MoneyColors.moneyOut(context),
          ),
          _FactLine(
            l10n.profitCash,
            fmt(t.profit, signed: true),
            emphasize: true,
          ),
        ]);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.periodLabel(facts.period), style: textTheme.titleSmall),
        const SizedBox(height: 6),
        ...lines,
        if (reply.explanation != null) ...[
          const SizedBox(height: 10),
          Text(reply.explanation!, style: textTheme.bodyLarge),
        ],
        const SizedBox(height: 10),
        Text(
          facts.topic == QuestionTopic.cashBalance
              ? l10n.summaryFootnote
              : l10n.askCalculatedFrom(facts.entryCount),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine(this.label, this.value, {this.color, this.emphasize = false});

  final String label;
  final String value;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: (emphasize ? textTheme.titleMedium : textTheme.bodyLarge)
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CategoryFactLine extends ConsumerWidget {
  const _CategoryFactLine(this.categoryId, this.value);

  final String? categoryId;
  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoriesByIdProvider)[categoryId];
    return _FactLine(
      context.categoryName(category),
      value,
      color: MoneyColors.moneyOut(context),
    );
  }
}
