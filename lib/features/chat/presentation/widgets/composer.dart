import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/gradients.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/chat.dart';

/// Keeps a text within [max] characters counted as the server counts them: code points, so Hindi
/// text and emoji are not penalised and a long message can never be refused for its length.
class CodePointLimit extends TextInputFormatter {
  final int max;

  const CodePointLimit(this.max);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.runes.length <= max) return newValue;
    return oldValue;
  }
}

/// The message field of a conversation (US-013): a rounded multi-line field with an attach icon
/// inside, a counter near the limit, and a gradient Send that looks disabled while the field is
/// empty. [controller] belongs to the screen so a refused message can be put back.
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;
  final int maxChars;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    this.maxChars = chatMessageMaxChars,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  static const double _counterFrom = 0.8;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  void _send() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final length = widget.controller.text.runes.length;
    final canSend = widget.controller.text.trim().isNotEmpty;
    final showCounter = length >= widget.maxChars * _counterFrom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.brandSurface,
        border: Border(top: BorderSide(color: AppColors.brandBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showCounter)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.chatCounter(length, widget.maxChars),
                      textAlign: TextAlign.end,
                      style: AppTextStyles.caption.copyWith(
                        color: length >= widget.maxChars
                            ? AppColors.brandError
                            : AppColors.brandMutedText,
                      ),
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [CodePointLimit(widget.maxChars)],
                      style: AppTextStyles.input,
                      decoration: InputDecoration(
                        hintText: l10n.chatComposerHint,
                        hintStyle: AppTextStyles.hint,
                        semanticCounterText: '',
                        filled: true,
                        fillColor: AppColors.brandBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl + 8),
                          borderSide: const BorderSide(color: AppColors.brandBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl + 8),
                          borderSide: const BorderSide(color: AppColors.brandBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl + 8),
                          borderSide:
                              const BorderSide(color: AppColors.brandBorderFocused, width: 2),
                        ),
                        suffixIcon: IconButton(
                          tooltip: l10n.chatAttach,
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: const Icon(Icons.attach_file_rounded,
                              color: AppColors.brandMutedText),
                          onPressed: widget.onAttach,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Semantics(
                    button: true,
                    enabled: canSend,
                    label: l10n.chatSend,
                    excludeSemantics: true,
                    onTap: canSend ? _send : null,
                    child: Opacity(
                      opacity: canSend ? 1 : 0.45,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          onTap: canSend ? _send : null,
                          child: Ink(
                            width: AppSizes.buttonMedium,
                            height: AppSizes.buttonMedium,
                            decoration: BoxDecoration(
                              gradient: AppGradients.brand,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                            child: const Icon(Icons.send_rounded, color: AppColors.brandOnPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
