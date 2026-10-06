import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_input_formatter.dart';

/// Date typed as DD/MM/YYYY, or picked from the calendar through the trailing icon.
class DateOfBirthField extends StatefulWidget {
  final String text;
  final String hint;
  final String pickTooltip;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickDate;

  const DateOfBirthField({
    super.key,
    required this.text,
    required this.hint,
    required this.pickTooltip,
    required this.onChanged,
    required this.onPickDate,
    this.errorText,
  });

  @override
  State<DateOfBirthField> createState() => _DateOfBirthFieldState();
}

class _DateOfBirthFieldState extends State<DateOfBirthField> {
  late final TextEditingController _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(DateOfBirthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [DateInputFormatter()],
      onChanged: widget.onChanged,
      style: AppTextStyles.input,
      cursorColor: AppColors.brandPrimary,
      decoration: InputDecoration(
        hintText: widget.hint,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: widget.pickTooltip,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: widget.onPickDate,
          icon: const Icon(Icons.calendar_today_outlined, color: AppColors.brandMutedText),
        ),
      ),
    );
  }
}
