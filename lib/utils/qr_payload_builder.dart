import '../models/user_model.dart';

class QrPayloadBuilder {
  const QrPayloadBuilder._();

  static const String _defaultHost = 'avahanaa.com';
  static const String _defaultPath = 'index.html';
  static const String _payloadVersion = '2';

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
      'payloadVersion': _payloadVersion,
      'qrCodeId': _toTrimmedString(user.qrCodeId),
      'userId': _toTrimmedString(user.id),
      'fcmToken': _toTrimmedString(user.fcmToken),
      'contact': {
        'email': _toTrimmedString(user.email),
        'phoneNumber': _toTrimmedString(user.phoneNumber),
      },
      'carDetails': {
        'color': _toTrimmedString(carDetails['color']),
        'carModel': _toTrimmedString(carDetails['carModel']),
        'licensePlate': _toTrimmedString(carDetails['licensePlate']),
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
    final queryParameters = <String, String>{
      // Keep the redirect page hint but otherwise minimise the query to shrink the QR payload.
      'page': 'notify',
    };

    final qrCodeId = _toTrimmedString(user.qrCodeId);
    if (qrCodeId.isNotEmpty) {
      queryParameters['qr'] = qrCodeId;
    }

    // Carry a lightweight version flag for future compatibility without the heavy encrypted payload.
    queryParameters['v'] = _payloadVersion;

    return Uri.https(
      _qrHost,
      _qrPath,
      queryParameters.isEmpty ? null : queryParameters,
    );
  }

  static String _toTrimmedString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }
}
