import 'dart:convert';

import '../models/user_model.dart';

class QrPayloadBuilder {
  const QrPayloadBuilder._();

  static Map<String, dynamic> buildMetadata(UserModel user) {
    final carDetails = user.carDetails ?? {};

    return {
      'qrCodeId': user.qrCodeId,
      'userId': user.id,
      'contact': {
        'email': user.email,
        'phoneNumber': user.phoneNumber,
      },
      'carDetails': {
        'color': carDetails['color'] ?? '',
        'carModel': carDetails['carModel'] ?? '',
        'licensePlate': carDetails['licensePlate'] ?? '',
      },
    };
  }

  static String buildPayload(UserModel user) {
    final metadata = buildMetadata(user);
    return jsonEncode(metadata);
  }

  static String buildShareableLink(UserModel user) {
    final payload = buildPayload(user);
    final encoded = base64Url.encode(utf8.encode(payload));

    return Uri.https(
      'your-project.firebaseapp.com',
      '/notify.html',
      {
        'qr': user.qrCodeId,
        'payload': encoded,
      },
    ).toString();
  }
}
