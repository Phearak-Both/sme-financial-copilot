import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/labels.dart';
import '../../core/date_only.dart';
import '../../data/database.dart';
import 'ask_controller.dart';

/// Date filters for the history list.
enum _When { all, today, last7Days, last30Days, custom }

/// Saved conversations, opened from the top-left button on the Ask screen.
class ChatHistoryDrawer extends ConsumerStatefulWidget {
  const ChatHistoryDrawer({super.key});

  @override
  ConsumerState<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends ConsumerState<ChatHistoryDrawer> {
  _When _when = _When.all;

  /// Set when [_when] is [_When.custom]; end exclusive.
  DateRange? _custom;

  DateRange? get _range {
    final tomorrow = addDays(dateOnly(DateTime.now()), 1);
    return switch (_when) {
      _When.all => null,
      _When.today => DateRange(addDays(tomorrow, -1), tomorrow),
      _When.last7Days => DateRange(addDays(tomorrow, -7), tomorrow),
      _When.last30Days => DateRange(addDays(tomorrow, -30), tomorrow),
      _When.custom => _custom,
    };
  }

  Future<void> _pickDates() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: _custom == null
          ? null
          : DateTimeRange(
              start: _custom!.start,
              end: addDays(_custom!.end, -1),
            ),
    );
    if (picked == null) return;
    setState(() {
      _when = _When.custom;
      _custom = DateRange(picked.start, addDays(picked.end, 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final all = ref.watch(chatsProvider).value ?? const <ChatRow>[];
    final range = _range;
    final chats = range == null
        ? all
        : all
            .where((c) => range.containsKey(toDateKey(c.updatedAt.toLocal())))
            .toList();
    final controller = ref.read(askControllerProvider.notifier);
    final busy = ref.watch(askControllerProvider).lastOrNull is PendingMessage;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(l10n.chatHistory, style: theme.textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.tonalIcon(
                onPressed: busy
                    ? null
                    : () {
                        controller.clear();
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.edit_note),
                label: Text(l10n.askNewChat),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final (option, label) in [
                    (_When.all, l10n.filterAll),
                    (_When.today, l10n.today),
                    (_When.last7Days, l10n.last7Days),
                    (_When.last30Days, l10n.last30Days),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _when == option,
                        onSelected: (_) => setState(() => _when = option),
                      ),
                    ),
                  ChoiceChip(
                    avatar: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      _when == _When.custom && _custom != null
                          ? context.rangeLabel(_custom!)
                          : l10n.pickDates,
                    ),
                    selected: _when == _When.custom,
                    onSelected: (_) => _pickDates(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        all.isEmpty ? l10n.noChats : l10n.noChatsInRange,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: chats.length,
                      itemBuilder: (context, i) => _ChatTile(
                        chat: chats[i],
                        selected: chats[i].id == controller.chatId,
                        enabled: !busy,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  const _ChatTile({
    required this.chat,
    required this.selected,
    required this.enabled,
  });

  final ChatRow chat;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(askControllerProvider.notifier);
    final when = chat.updatedAt.toLocal();
    final subtitle = '${context.dayLabel(toDateKey(when))} · '
        '${DateFormat.Hm(context.localeTag).format(when)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        enabled: enabled,
        selected: selected,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.only(left: 12),
        title: Text(
          chat.title.isEmpty ? l10n.photoChat : chat.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle),
        onTap: () async {
          await controller.open(chat.id);
          if (context.mounted) Navigator.of(context).pop();
        },
        trailing: PopupMenuButton<void>(
          enabled: enabled,
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: () => _confirmDelete(context, ref),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, size: 20),
                  const SizedBox(width: 12),
                  Text(l10n.delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteChatTitle),
        content: Text(l10n.deleteChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(askControllerProvider.notifier).delete(chat.id);
    }
  }
}
