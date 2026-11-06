// Merges per-feature ARB fragments (l10n/fragments/<feature>_<locale>.arb) into the
// gen-l10n inputs lib/core/l10n/app_<locale>.arb, then runs `flutter gen-l10n`.
//
// Each feature owns its own fragment pair so parallel work never edits the same file.
// Usage: dart run tool/l10n.dart
import 'dart:convert';
import 'dart:io';

const locales = ['zh', 'en'];
const fragmentsDir = 'l10n/fragments';
const outputDir = 'lib/core/l10n';

void main() {
  final merged = <String, Map<String, Object?>>{};
  final owners = <String, String>{};
  for (final locale in locales) {
    final out = <String, Object?>{'@@locale': locale};
    final files =
        Directory(fragmentsDir)
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('_$locale.arb'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final fragment = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      for (final entry in fragment.entries) {
        final owner = owners['$locale:${entry.key}'];
        if (owner != null) {
          stderr.writeln('Duplicate key "${entry.key}" in ${file.path} (already in $owner)');
          exit(1);
        }
        owners['$locale:${entry.key}'] = file.path;
        out[entry.key] = entry.value;
      }
    }
    merged[locale] = out;
  }

  // Both locales must expose the same message keys.
  Set<String> keys(Map<String, Object?> m) => m.keys.where((k) => !k.startsWith('@')).toSet();
  final zh = keys(merged['zh']!), en = keys(merged['en']!);
  if (zh.difference(en).isNotEmpty || en.difference(zh).isNotEmpty) {
    stderr.writeln('Missing in en: ${zh.difference(en)}\nMissing in zh: ${en.difference(zh)}');
    exit(1);
  }

  const encoder = JsonEncoder.withIndent('  ');
  for (final locale in locales) {
    File('$outputDir/app_$locale.arb').writeAsStringSync('${encoder.convert(merged[locale])}\n');
  }
  final result = Process.runSync('flutter', ['gen-l10n'], runInShell: true);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exit(result.exitCode);
}
