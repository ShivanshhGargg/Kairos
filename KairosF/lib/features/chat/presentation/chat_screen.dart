import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/config/brand_config.dart';
import '../../../shared/data/kairos_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  late final AnimationController _recordingController;
  bool _hasText = false;
  bool _isSending = false;
  bool _isRecording = false;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleTextChanged);
    _recordingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingController.dispose();
    _messageController
      ..removeListener(_handleTextChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final horizontalPadding = size.width < 600
        ? KairosSpacing.md
        : size.width < 900
            ? KairosSpacing.lg
            : KairosSpacing.xl;
    final bottomPadding =
        size.width < 760 ? 96.0 + bottomInset : KairosSpacing.lg;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          KairosSpacing.sm,
          horizontalPadding,
          bottomPadding,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                _ChatTopBar(
                  onHistory: _showHistoryReady,
                ),
                const SizedBox(height: KairosSpacing.sm),
                Expanded(
                  child: _MessageList(
                    messages: _messages,
                    scrollController: _scrollController,
                  ),
                ),
                const SizedBox(height: KairosSpacing.sm),
                _RecordingIndicator(
                  animation: _recordingController,
                  visible: _isRecording,
                ),
                const SizedBox(height: KairosSpacing.sm),
                _MessageComposer(
                  controller: _messageController,
                  hasText: _hasText,
                  isSending: _isSending,
                  isRecording: _isRecording,
                  recordingAnimation: _recordingController,
                  onAttach: _pickFiles,
                  onSend: _sendMessage,
                  onVoice: _toggleRecording,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTextChanged() {
    final nextHasText = _messageController.text.trim().isNotEmpty;
    if (nextHasText == _hasText) return;
    setState(() => _hasText = nextHasText);
    if (nextHasText && _isRecording) _stopRecording(addTranscript: false);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final timeLabel = DateFormat('h:mm a').format(DateTime.now());
    setState(() {
      _messages.add(
        _ChatMessage(
          author: 'You',
          body: text,
          timeLabel: timeLabel,
          isUser: true,
        ),
      );
      _isSending = true;
    });
    _messageController.clear();
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final reply =
        await ref.read(kairosRepositoryProvider.notifier).sendChatMessage(text);
    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (reply != null && reply.trim().isNotEmpty) {
        _messages.add(
          _ChatMessage(
            author: BrandConfig.assistantName,
            body: reply.trim(),
            timeLabel: DateFormat('h:mm a').format(DateTime.now()),
            isUser: false,
          ),
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'txt',
        'mp3',
        'wav',
        'm4a',
      ],
    );

    if (!mounted || result == null || _isSending) return;
    final fileNames = result.files.map((file) => file.name).join(', ');
    final files = result.files
        .where((file) => file.bytes != null)
        .map(
          (file) => MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        )
        .toList();

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected files are not available.')),
      );
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          author: 'You',
          body: 'Attached $fileNames',
          timeLabel: DateFormat('h:mm a').format(DateTime.now()),
          isUser: true,
        ),
      );
      _isSending = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final reply = await ref
        .read(kairosRepositoryProvider.notifier)
        .uploadChatAttachments(FormData.fromMap({'files': files}));
    if (!mounted) return;
    setState(() {
      _isSending = false;
      if (reply != null && reply.trim().isNotEmpty) {
        _messages.add(
          _ChatMessage(
            author: BrandConfig.assistantName,
            body: reply.trim(),
            timeLabel: DateFormat('h:mm a').format(DateTime.now()),
            isUser: false,
          ),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent ${result.files.length} file(s).')),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _toggleRecording() {
    if (_hasText) {
      _sendMessage();
      return;
    }
    if (_isRecording) {
      _stopRecording(addTranscript: true);
      return;
    }
    setState(() => _isRecording = true);
    _recordingController.repeat(reverse: true);
    _recordingTimer?.cancel();
    _recordingTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || !_isRecording) return;
      _stopRecording(addTranscript: true);
    });
  }

  void _stopRecording({required bool addTranscript}) {
    _recordingTimer?.cancel();
    _recordingController.stop();
    _recordingController.reset();
    setState(() => _isRecording = false);
    if (!addTranscript) return;

    _messageController.text = 'Voice note recorded';
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
  }

  void _showHistoryReady() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat history is ready for API wiring.')),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({
    required this.onHistory,
  });

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/brand/kairos-mark.png',
                width: 36,
                height: 36,
              ),
              const SizedBox(width: KairosSpacing.sm),
              Text(BrandConfig.assistantName,
                  style: theme.textTheme.titleLarge),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Tooltip(
              message: 'History',
              child: IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: onHistory,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
  });

  final List<_ChatMessage> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        0,
        KairosSpacing.sm,
        0,
        KairosSpacing.md,
      ),
      itemCount: messages.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: KairosSpacing.sm),
      itemBuilder: (context, index) {
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = message.isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.3 : 0.7,
          );

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KairosRadius.md),
            color: color.withValues(alpha: message.isUser ? 0.74 : 0.92),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: message.isUser ? 0.18 : 0.1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(KairosSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!message.isUser) ...[
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      message.author,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: message.isUser
                            ? Colors.white.withValues(alpha: 0.86)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KairosSpacing.xs),
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: message.isUser ? Colors.white : null,
                  ),
                ),
                const SizedBox(height: KairosSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    message.timeLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: message.isUser
                          ? Colors.white.withValues(alpha: 0.68)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  const _RecordingIndicator({
    required this.animation,
    required this.visible,
  });

  final Animation<double> animation;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < 5; index++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 4,
                height: 12 + (value * 18 * ((index % 2) + 1) / 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.56 + (value * 0.34)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              if (index != 4) const SizedBox(width: 5),
            ],
            const SizedBox(width: KairosSpacing.sm),
            Text(
              'Recording',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        );
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.hasText,
    required this.isSending,
    required this.isRecording,
    required this.recordingAnimation,
    required this.onAttach,
    required this.onSend,
    required this.onVoice,
  });

  final TextEditingController controller;
  final bool hasText;
  final bool isSending;
  final bool isRecording;
  final Animation<double> recordingAnimation;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final VoidCallback onVoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surface.withValues(alpha: isDark ? 0.26 : 0.62),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.74),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 30,
            spreadRadius: -14,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Attach files',
            child: IconButton(
              style: IconButton.styleFrom(
                fixedSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: isSending ? null : onAttach,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Message ${BrandConfig.assistantName}...',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: KairosSpacing.xs,
                  vertical: 12,
                ),
              ),
            ),
          ),
          _ComposerActionButton(
            hasText: hasText,
            isSending: isSending,
            isRecording: isRecording,
            animation: recordingAnimation,
            onPressed: isSending
                ? null
                : hasText
                    ? onSend
                    : onVoice,
          ),
        ],
      ),
    );
  }
}

class _ComposerActionButton extends StatelessWidget {
  const _ComposerActionButton({
    required this.hasText,
    required this.isSending,
    required this.isRecording,
    required this.animation,
    required this.onPressed,
  });

  final bool hasText;
  final bool isSending;
  final bool isRecording;
  final Animation<double> animation;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = hasText || isRecording || isSending
        ? theme.colorScheme.primary
        : theme.colorScheme.surface.withValues(alpha: 0.26);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final scale = isRecording ? 1 + (animation.value * 0.14) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Tooltip(
            message: isSending
                ? 'Sending'
                : hasText
                    ? 'Send'
                    : isRecording
                        ? 'Stop recording'
                        : 'Record voice',
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                fixedSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isSending
                    ? const SizedBox(
                        key: ValueKey('sending'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        hasText
                            ? Icons.arrow_upward_rounded
                            : isRecording
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                        key: ValueKey('$hasText-$isRecording'),
                      ),
              ),
              onPressed: onPressed,
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.author,
    required this.body,
    required this.timeLabel,
    required this.isUser,
  });

  final String author;
  final String body;
  final String timeLabel;
  final bool isUser;
}
