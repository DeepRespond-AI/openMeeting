import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/session_controller.dart';
import '../../theme/context_extensions.dart';
import '../user_profile.dart';

String? _fallback(WidgetRef ref, String username, String? fallback) {
  final me = ref.watch(currentUserProvider);
  final name = me?.id.toLowerCase() == username.toLowerCase() ? me?.name : fallback;
  return name?.trim().toLowerCase() == username.toLowerCase() ? null : name;
}

class ImUserAvatar extends ConsumerWidget {
  const ImUserAvatar({required this.username, this.fallbackName, this.size, super.key});
  final String username;
  final String? fallbackName;
  final double? size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(imUserProfileProvider(username));
    final profile = snapshot.isLoading ? null : snapshot.value;
    final name = identityName(
      profile,
      _fallback(ref, username, fallbackName),
      context.l10n.imUnknownUser,
    );
    final url = Uri.tryParse(profile?.avatarUrl.trim() ?? '');
    final extent = size ?? context.sizes.touchTarget;
    final placeholder = ColoredBox(
      color: context.colors.accent,
      child: Center(
        child: Text(name.characters.first, style: TextStyle(color: context.colors.primary)),
      ),
    );
    return Semantics(
      label: name,
      image: true,
      child: SizedBox.square(
        dimension: extent,
        child: ClipOval(
          child: url != null && ['http', 'https'].contains(url.scheme) && url.host.isNotEmpty
              ? Image.network(
                  url.toString(),
                  key: ValueKey(url.toString()),
                  fit: BoxFit.cover,
                  frameBuilder: (_, child, frame, synchronous) =>
                      synchronous || frame != null ? child : placeholder,
                  loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
                  errorBuilder: (_, _, _) => placeholder,
                )
              : placeholder,
        ),
      ),
    );
  }
}

class ImMessageSender extends ConsumerWidget {
  const ImMessageSender({required this.username, this.fallbackName, super.key});
  final String username;
  final String? fallbackName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(imUserProfileProvider(username));
    final profile = snapshot.isLoading ? null : snapshot.value;
    final name = identityName(
      profile,
      _fallback(ref, username, fallbackName),
      context.l10n.imUnknownUser,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImUserAvatar(username: username, fallbackName: fallbackName, size: context.sizes.iconXl),
          context.spacing.gapXs,
          Flexible(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}
