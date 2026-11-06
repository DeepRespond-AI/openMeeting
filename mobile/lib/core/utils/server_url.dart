/// Server URL helpers.
library;

/// Trims whitespace and trailing slashes. Returns `null` for blank input.
String? normalizeServerUrl(String? input) {
  final trimmed = input?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  var end = trimmed.length;
  while (end > 0 && trimmed[end - 1] == '/') {
    end--;
  }
  final result = trimmed.substring(0, end);
  return result.isEmpty ? null : result;
}

/// True for an absolute `http`/`https` URL with a host.
bool isValidServerUrl(String? input) {
  final normalized = normalizeServerUrl(input);
  if (normalized == null) return false;
  final uri = Uri.tryParse(normalized);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}
