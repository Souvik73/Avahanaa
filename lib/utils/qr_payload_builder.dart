import '../models/user_model.dart';
import 'qr_encryption.dart';

class QrPayloadBuilder {
  const QrPayloadBuilder._();

  static const String _defaultHost = 'congestion-free.firebaseapp.com';
  static const String _defaultPath = 'notify.html';

  static final String _qrHost = const String.fromEnvironment(
    'QR_REDIRECT_HOST',
    defaultValue: _defaultHost,
  );
  static final String _qrPath = const String.fromEnvironment(
    'QR_REDIRECT_PATH',
    defaultValue: _defaultPath,
  );

  static Map<String, dynamic> buildMetadata(UserModel user) {
    final carDetails = user.carDetails ?? {};

    return {
      'qrCodeId': user.qrCodeId,
      'userId': user.id,
      'contact': {'email': user.email, 'phoneNumber': user.phoneNumber},
      'carDetails': {
        'color': carDetails['color'] ?? '',
        'carModel': carDetails['carModel'] ?? '',
        'licensePlate': carDetails['licensePlate'] ?? '',
      },
    };
  }

  static String buildPayload(UserModel user) {
    return _buildQrUri(user).toString();
  }

  static String buildShareableLink(UserModel user) {
    return buildPayload(user);
  }

  static Uri _buildQrUri(UserModel user) {
    final carDetails = user.carDetails ?? {};
    final queryParameters = <String, String>{};

    if (user.qrCodeId.isNotEmpty) {
      queryParameters['qr'] = user.qrCodeId;
    }

    final sanitizedCarDetails = <String, String>{};

    void addCarDetail(String key, dynamic value) {
      final valueString = value?.toString().trim() ?? '';
      if (valueString.isNotEmpty) {
        sanitizedCarDetails[key] = valueString;
      }
    }

    addCarDetail('color', carDetails['color']);
    addCarDetail('carModel', carDetails['carModel']);
    addCarDetail('licensePlate', carDetails['licensePlate']);

    if (sanitizedCarDetails.isNotEmpty) {
      queryParameters['v'] = '1';
      queryParameters['payload'] = QrEncryption.encryptCarDetails(
        sanitizedCarDetails,
      );
    }

    return Uri.https(
      _qrHost,
      _qrPath,
      queryParameters.isEmpty ? null : queryParameters,
    );
  }
}
