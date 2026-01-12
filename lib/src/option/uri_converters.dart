// Copyright (c) 2023, the coap project authors.
//
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'integer_option.dart';
import 'option.dart';
import 'string_option.dart';

// TODO(JKRhb): Consider turning this into an enhanced enum.
int? _defaultPortFromScheme(final String? scheme) {
  switch (scheme) {
    case 'coap':
      return 5683;
    case 'coaps':
      return 5684;
    case 'coap+tcp':
      return 5683;
    case 'coaps+tcp':
      return 5684;
    case 'coap+ws':
      return 80;
    case 'coaps+ws':
      return 443;
  }

  return null;
}

bool _isSupportedUriScheme(final String scheme) => const [
  'coap',
  'coaps',
  'coap+tcp',
  'coaps+tcp',
  'coap+ws',
  'coaps+ws',
].contains(scheme);

/// Converts a list of [Option]s to a [Uri] of a provided [scheme] as specified
/// in [RFC 7252, section 6.5].
///
/// If no [UriHostOption] is included in the [Option]s, the [destinationAddress]
/// will be used for the host component.
///
/// [RFC 7252, section 6.5]: https://www.rfc-editor.org/rfc/rfc7252.html#section-6.5
Uri optionsToUri(
  final List<Option<Object?>> options, {
  final String? scheme,
  final InternetAddress? destinationAddress,
}) {
  var host = destinationAddress?.address;
  int? port;
  var path = '';
  var query = '';

  for (final option in options) {
    if (option is UriHostOption) {
      host = option.value;
      continue;
    }

    if (option is UriPortOption) {
      final optionValue = option.value;
      if (_defaultPortFromScheme(scheme) != optionValue) {
        port = optionValue;
      }

      continue;
    }

    if (option is PathOption) {
      // TODO(JKRhb): Refactor?
      final pathSegment = option.value.replaceAll('/', '%2F');
      path = '$path/$pathSegment';
      continue;
    }

    if (option is QueryOption) {
      // TODO(JKRhb): Refactor?
      final queryParameter = option.value.replaceAll('&', '%26');

      if (query.isEmpty) {
        query = queryParameter;
        continue;
      }

      query = '$query&$queryParameter';
    }
  }

  // Step 7 of the algorithm
  if (path.isEmpty) {
    path = '/';
  }

  return Uri(scheme: scheme, host: host, port: port, path: path, query: query);
}

/// Converts a [uri] into a list of [Option]s as specified
/// in [RFC 7252, section 6.4].
///
/// If the [uri]'s host component should equal the [destinationAddress], no
/// [UriHostOption] will be included in the returned [List] of [Option]s.
/// Similarly, if the default port for the provided URI scheme should be used,
/// it will be omitted as an [Option].
///
/// [RFC 7252, section 6.4]: https://www.rfc-editor.org/rfc/rfc7252.html#section-6.4
List<Option<Object?>> uriToOptions(
  final Uri uri,
  final InternetAddress? destinationAddress,
) {
  final options = <Option<Object?>>[];

  if (!uri.isAbsolute) {
    throw FormatException('Provided request URI $uri is not absolute.');
  }

  final scheme = uri.scheme;
  if (!_isSupportedUriScheme(scheme)) {
    throw FormatException(
      'Provided request URI scheme $scheme is not allowed.',
    );
  }

  if (uri.hasFragment) {
    throw FormatException('$uri contains a URI fragment, which is not allowed');
  }

  final host = uri.host;
  if (host != destinationAddress?.address) {
    options.add(UriHostOption(host));
  }

  final port = uri.port;
  final defaultPorts = [0, _defaultPortFromScheme(scheme)];
  if (!defaultPorts.contains(port)) {
    options.add(UriPortOption(port));
  }

  options
    ..addAll(_uriPathsToOptions<UriPathOption>(uri))
    ..addAll(_uriQueriesToOptions<UriQueryOption>(uri));

  return options;
}

/// Converts a relative [location] URI into a list of [Option]s.
List<Option<Object?>> locationToOptions(final Uri location) => [
  ..._uriPathsToOptions<LocationPathOption>(location),
  ..._uriQueriesToOptions<LocationQueryOption>(location),
];

/// Converts a [uri]'s path components into a list of [PathOption]s as specified
/// in [RFC 7252, section 6.4].
///
/// [RFC 7252, section 6.4]: https://www.rfc-editor.org/rfc/rfc7252.html#section-6.4
List<Option<Object?>> _uriPathsToOptions<T extends PathOption>(final Uri uri) {
  final options = <Option<Object?>>[];

  final path = uri.path;
  if (path.isNotEmpty && path != '/') {
    final optionValues = path.split('/').map(Uri.decodeFull);

    for (final optionValue in optionValues.skip(1)) {
      switch (T) {
        case const (UriPathOption):
          options.add(UriPathOption(optionValue));
          continue;
        case const (LocationPathOption):
          options.add(LocationPathOption(optionValue));
          continue;
      }

      throw ArgumentError('Specified invalid option type $T');
    }
  }

  return options;
}

/// Converts a [uri]'s query parameters into a list of [QueryOption]s as
/// specified in [RFC 7252, section 6.4].
///
/// [RFC 7252, section 6.4]: https://www.rfc-editor.org/rfc/rfc7252.html#section-6.4
List<Option<Object?>> _uriQueriesToOptions<T extends QueryOption>(
  final Uri uri,
) {
  final options = <Option<Object?>>[];

  for (final queryParameter in uri.queryParameters.entries) {
    final components = [queryParameter.key];
    final value = queryParameter.value;

    if (value.isNotEmpty) {
      components.add(value);
    }

    final optionValue = components.map(Uri.decodeFull).join('=');

    switch (T) {
      case const (UriQueryOption):
        options.add(UriQueryOption(optionValue));
        continue;
      case const (LocationQueryOption):
        options.add(LocationQueryOption(optionValue));
        continue;
    }

    throw ArgumentError('Specified invalid option type $T');
  }

  return options;
}
