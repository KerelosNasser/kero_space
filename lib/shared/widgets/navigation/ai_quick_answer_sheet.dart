import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../features/productivity/data/services/ai_service.dart';

class AiQuickAnswerSheet extends StatefulWidget {
  final String prompt;

  const AiQuickAnswerSheet({super.key, required this.prompt});

  static Future<void> show(BuildContext context, {required String prompt}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiQuickAnswerSheet(prompt: prompt),
    );
  }

  @override
  State<AiQuickAnswerSheet> createState() => _AiQuickAnswerSheetState();
}

class _AiQuickAnswerSheetState extends State<AiQuickAnswerSheet> {
  bool _isLoading = true;
  String _answer = '';

  @override
  void initState() {
    super.initState();
    _fetchAnswer();
  }

  Future<void> _fetchAnswer() async {
    setState(() {
      _isLoading = true;
      _answer = '';
    });

    try {
      final aiService = getIt<AIService>();
      final result = await aiService.askGeneralQuestion(widget.prompt);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _answer = result;
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _answer = 'Error querying AI assistant: $e';
        });
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    if (_answer.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _answer));
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _saveAsNote(BuildContext context) {
    Navigator.of(context).pop();
    HapticFeedback.mediumImpact();
    context.push('/note_editor', extra: {
      'initialContent': '# ${widget.prompt}\n\n$_answer',
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bgBase,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: colors.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              // Top drag bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, size: 18, color: colors.accentPrimary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trobio Assistant',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.prompt,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // Content Area
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colors.accentPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Synthesizing answer...',
                              style: TextStyle(fontSize: 13, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: SelectableText(
                          _answer,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: colors.textPrimary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
              ),

              // Action Toolbar
              if (!_isLoading)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      border: Border(top: BorderSide(color: colors.borderSubtle, width: 1)),
                    ),
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _copyToClipboard(context),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _saveAsNote(context),
                          icon: const Icon(Icons.note_add_rounded, size: 16),
                          label: const Text('Save as Note'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          tooltip: 'Regenerate',
                          onPressed: _fetchAnswer,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
