import 'dart:math';

String getRandomString({required final int length}) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final rnd = Random();

  return String.fromCharCodes(
    Iterable.generate(
      length,
      (final _) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ),
  );
}
