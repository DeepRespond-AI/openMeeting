import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/context_extensions.dart';

/// Shared switch appearance with a full-size thumb in both on and off states.
class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.secondary,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MergeSemantics(
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: secondary,
        enabled: onChanged != null,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailing: SizedBox(
          height: context.sizes.touchTarget,
          child: CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            applyTheme: false,
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.surface,
            thumbColor: colors.onPrimary,
            inactiveThumbColor: colors.onPrimary,
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? colors.primary : colors.input,
            ),
            trackOutlineWidth: WidgetStatePropertyAll(context.sizes.borderWidth),
          ),
        ),
      ),
    );
  }
}
