import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PkceHelper {
  static const int _codeVerifierLength = 128;
  static const String _charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  static String generateCodeVerifier() {
    final random = Random.secure();
    return List.generate(
      _codeVerifierLength,
      (_) => _charset[random.nextInt(_charset.length)],
    ).join();
  }

  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}
