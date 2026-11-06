import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 与 Pydantic 的字符串长度一致：按 Unicode 码点计数，emoji 不按 UTF-16 拆开。
class CodePointLengthFormatter extends TextInputFormatter {
  const CodePointLengthFormatter(this.maxLength);

  final int maxLength;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // 输入法组字期间不裁剪；提交时统一限制，避免破坏中文候选词。
    if (!newValue.composing.isCollapsed || newValue.text.runes.length <= maxLength) return newValue;
    final text = String.fromCharCodes(newValue.text.runes.take(maxLength));
    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(
        offset: math.min(math.max(newValue.selection.extentOffset, 0), text.length),
      ),
      composing: TextRange.empty,
    );
  }
}

InputCounterWidgetBuilder codePointCounter(TextEditingController controller, int limit) =>
    (context, {required currentLength, required isFocused, required maxLength}) => Text(
      '${controller.text.runes.length}/$limit',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: controller.text.runes.length > limit ? Theme.of(context).colorScheme.error : null,
      ),
    );
