import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';

/// The home dashboard's fourth entry groups the two existing audio workflows.
class RecordingToolsPage extends StatelessWidget {
  const RecordingToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.liveRecordingTools)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
          child: ListView(
            padding: context.spacing.page,
            children: [
              Text(
                l.liveRecordingToolsHint,
                style: TextStyle(color: context.colors.mutedForeground),
              ),
              context.spacing.gapLg,
              Card(
                child: ListTile(
                  key: const ValueKey('recording-tools-start'),
                  leading: Icon(Icons.mic_none, color: context.colors.primary),
                  title: Text(l.meetingsStartRecording),
                  subtitle: Text(l.liveRecordingHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.recording),
                ),
              ),
              Card(
                child: ListTile(
                  key: const ValueKey('recording-tools-import'),
                  leading: Icon(Icons.upload_file_outlined, color: context.colors.primary),
                  title: Text(l.meetingsImportAudio),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.import),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
