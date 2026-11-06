import 'package:flutter/services.dart';

/// Keep platform clipboard access out of feature widgets.
Future<void> copyText(String text) => Clipboard.setData(ClipboardData(text: text));
