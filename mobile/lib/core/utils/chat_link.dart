/// Web invites use #k=, creator links use #p=, older app links use ?k=.
/// Parse parameters once so the parameter name never becomes part of the key.
String? passwordFromChatUri(Uri uri) {
  try {
    if (uri.fragment.isNotEmpty) {
      if (uri.fragment.contains('=')) {
        final params = Uri.splitQueryString(uri.fragment);
        final password = params['k'] ?? params['p'];
        if (password != null && password.isNotEmpty) return password;
      } else {
        return Uri.decodeComponent(uri.fragment);
      }
    }
    final password = uri.queryParameters['k'] ?? uri.queryParameters['p'];
    return password != null && password.isNotEmpty ? password : null;
  } on FormatException {
    return null;
  }
}

/// Keep the complete invitation while converting a localized web URL to an app route.
String withoutLocalePrefix(Uri uri) => Uri(
  path: '/${uri.pathSegments.skip(1).join('/')}',
  query: uri.hasQuery ? uri.query : null,
  fragment: uri.hasFragment ? uri.fragment : null,
).toString();

/// Authentication may resume only a local app route, including its invite fragment.
String safePostLoginPath(String? value) {
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority ||
      !uri.path.startsWith('/') || uri.path.startsWith('//') ||
      uri.path == '/login' || uri.path == '/splash') {
    return '/';
  }
  return uri.toString();
}
