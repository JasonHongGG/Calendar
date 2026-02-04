import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/ai_command_provider.dart';
import '../theme/app_colors.dart';

class AiCommandSheet extends StatefulWidget {
  const AiCommandSheet({super.key, required this.baseUrl, this.onJumpToMonth});

  final String baseUrl;
  final VoidCallback? onJumpToMonth;

  static Future<void> open(BuildContext context, {VoidCallback? onJumpToMonth}) {
    final baseUrl = context.read<SettingsProvider>().aiBaseUrl;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiCommandSheet(baseUrl: baseUrl, onJumpToMonth: onJumpToMonth),
    );
  }

  @override
  State<AiCommandSheet> createState() => _AiCommandSheetState();
}

class _AiCommandSheetState extends State<AiCommandSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  AiCommandProvider? _draftProvider;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncDraftText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDraftText);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiProvider = context.watch<AiCommandProvider>();
    _draftProvider ??= aiProvider;
    if (_controller.text != aiProvider.draftText) {
      _controller.text = aiProvider.draftText;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.16), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [_buildProgressList(aiProvider), _buildInputRow(aiProvider)]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressList(AiCommandProvider aiProvider) {
    final steps = aiProvider.steps;
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final step = steps[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStepStatusIcon(step.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(color: step.status == AiStepStatus.done ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13, fontWeight: step.status == AiStepStatus.running ? FontWeight.w600 : FontWeight.w500),
                  ),
                ),
                if (step.status == AiStepStatus.done)
                  Text(
                    '完成',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepStatusIcon(AiStepStatus status) {
    switch (status) {
      case AiStepStatus.running:
        return const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gradientStart));
      case AiStepStatus.done:
        return const Icon(Icons.check_circle_rounded, color: AppColors.gradientStart, size: 16);
      case AiStepStatus.error:
        return const Icon(Icons.error_rounded, color: Colors.redAccent, size: 16);
      case AiStepStatus.pending:
        return Icon(Icons.circle_outlined, color: AppColors.textTertiary.withValues(alpha: 0.6), size: 14);
    }
  }

  Widget _buildInputRow(AiCommandProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(aiProvider),
              decoration: const InputDecoration(hintText: '輸入指令：新增、刪除、修改、提醒…', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 10),
          _buildSendButton(aiProvider),
        ],
      ),
    );
  }

  Widget _buildSendButton(AiCommandProvider aiProvider) {
    final child = aiProvider.sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Icon(Icons.send_rounded, size: 18, color: Colors.white);

    return IgnorePointer(
      ignoring: aiProvider.sending,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: aiProvider.sending ? 0.6 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _submit(aiProvider),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.gradientStart.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AiCommandProvider aiProvider) async {
    final text = _controller.text.trim();
    if (text.isEmpty || aiProvider.sending) return;

    final eventProvider = context.read<EventProvider>();
    await aiProvider.submit(text: text, baseUrl: widget.baseUrl, eventProvider: eventProvider, onJumpToMonth: widget.onJumpToMonth);
    if (!mounted) return;
    _controller.clear();
    aiProvider.setDraftText('');
    _focusNode.requestFocus();
  }

  void _syncDraftText() {
    final provider = _draftProvider;
    if (provider == null) return;
    provider.setDraftText(_controller.text);
  }
}
