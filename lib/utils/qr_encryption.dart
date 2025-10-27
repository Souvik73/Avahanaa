import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;

class QrEncryption {
  const QrEncryption._();

  static const String _defaultKey =
      '0123456789abcdef0123456789abcdef'; // 32 chars
  static const String _defaultIv = 'abcdef9876543210'; // 16 chars

  static final encrypt.Key _key = _buildKey(
    const String.fromEnvironment(
      'QR_ENCRYPTION_KEY',
      defaultValue: _defaultKey,
    ),
  );

  static final encrypt.IV _iv = _buildIv(
    const String.fromEnvironment('QR_ENCRYPTION_IV', defaultValue: _defaultIv),
  );

  static final encrypt.Encrypter _encrypter = encrypt.Encrypter(
    encrypt.AES(_key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
  );

  static String encryptCarDetails(Map<String, dynamic> carDetails) {
    final payload = jsonEncode(carDetails);
    final result = _encrypter.encrypt(payload, iv: _iv);
    return result.base64;
  }

  static encrypt.Key _buildKey(String rawKey) {
    final key = rawKey.trim();
    if (key.length == 32 || key.length == 24 || key.length == 16) {
      return encrypt.Key.fromUtf8(key);
    }
    throw ArgumentError(
      'QR_ENCRYPTION_KEY must be 16, 24, or 32 characters long.',
    );
  }

  static encrypt.IV _buildIv(String rawIv) {
    final iv = rawIv.trim();
    if (iv.length == 16) {
      return encrypt.IV.fromUtf8(iv);
    }
    throw ArgumentError('QR_ENCRYPTION_IV must be 16 characters long.');
  }
}
