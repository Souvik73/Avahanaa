import '../models/user_model.dart';
import 'qr_encryption.dart';

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
    final carDetails = user.carDetails ?? {};
    final queryParameters = <String, String>{
      'page': 'notify',
    };

    if (user.qrCodeId.isNotEmpty) {
      queryParameters['qr'] = user.qrCodeId;
    }

    final payloadData = <String, dynamic>{
      'version': _payloadVersion,
    };

    final sanitizedCarDetails = <String, String>{};
    void addCarDetail(String key, dynamic value) {
      final valueString = _toTrimmedString(value);
      if (valueString.isNotEmpty) {
        sanitizedCarDetails[key] = valueString;
      }
    }

    addCarDetail('color', carDetails['color']);
    addCarDetail('carModel', carDetails['carModel']);
    addCarDetail('licensePlate', carDetails['licensePlate']);

    if (sanitizedCarDetails.isNotEmpty) {
      payloadData['carDetails'] = sanitizedCarDetails;
    }

    final contact = <String, String>{};
    final email = _toTrimmedString(user.email);
    if (email.isNotEmpty) {
      contact['email'] = email;
    }
    final phoneNumber = _toTrimmedString(user.phoneNumber);
    if (phoneNumber.isNotEmpty) {
      contact['phoneNumber'] = phoneNumber;
    }
    if (contact.isNotEmpty) {
      payloadData['contact'] = contact;
    }

    final userId = _toTrimmedString(user.id);
    if (userId.isNotEmpty) {
      payloadData['userId'] = userId;
    }

    final qrCodeId = _toTrimmedString(user.qrCodeId);
    if (qrCodeId.isNotEmpty) {
      payloadData['qrCodeId'] = qrCodeId;
    }

    final fcmToken = _toTrimmedString(user.fcmToken);
    if (fcmToken.isNotEmpty) {
      payloadData['fcmToken'] = fcmToken;
    }

    payloadData.removeWhere(
      (key, value) => value == null || (value is String && value.isEmpty),
    );

    if (payloadData.length > 1) {
      queryParameters['v'] = _payloadVersion;
      queryParameters['payload'] = QrEncryption.encryptPayload(payloadData);
    }

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
