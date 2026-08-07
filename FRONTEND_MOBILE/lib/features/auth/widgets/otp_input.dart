import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// A fixed-length, single-digit-per-box OTP entry field.
///
/// Handles auto-advance on input, backspace to the previous box, and pasting a
/// full code into any box. Reports the assembled value via [onChanged] and
/// fires [onCompleted] when every box is filled.
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List<TextEditingController>.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List<FocusNode>.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void _notify() {
    final String value = _value;
    widget.onChanged(value);
    if (value.length == widget.length && !value.contains(RegExp(r'\s'))) {
      widget.onCompleted?.call(value);
    }
  }

  void _onChanged(int index, String raw) {
    // Support pasting a multi-character code into a single box.
    if (raw.length > 1) {
      _distribute(raw, startIndex: index);
      return;
    }

    if (raw.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (raw.isNotEmpty && index == widget.length - 1) {
      _focusNodes[index].unfocus();
    }
    _notify();
  }

  void _distribute(String text, {required int startIndex}) {
    final String digits = text.replaceAll(RegExp(r'\D'), '');
    for (int i = 0; i < widget.length; i++) {
      if (i < startIndex) continue;
      final int sourceIndex = i - startIndex;
      _controllers[i].text = sourceIndex < digits.length
          ? digits[sourceIndex]
          : '';
    }
    final int next = (startIndex + digits.length).clamp(0, widget.length - 1);
    _focusNodes[next].requestFocus();
    _notify();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _notify();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(widget.length, (int index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 5,
              right: index == widget.length - 1 ? 0 : 5,
            ),
            child: AspectRatio(
              aspectRatio: 0.86,
              child: Focus(
                onKeyEvent: (_, KeyEvent event) => _onKey(index, event),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.fieldFill,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: _border(AppColors.border),
                    focusedBorder: _border(AppColors.navy, width: 1.6),
                  ),
                  onChanged: (String value) => _onChanged(index, value),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
