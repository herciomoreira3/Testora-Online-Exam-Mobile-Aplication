import 'dart:convert';

import 'package:http/http.dart' as http;

class OneSignalPushService {
  const OneSignalPushService();

  static const _appId = '51778ec8-c5ff-4661-85f9-cca8f1b5b105';
  static const _apiKey =
      'os_v2_app_kf3y5sgf75dgdbpzzsupdnnraxwphopyug4ulmmekokq5engstmuszmpfvwhpuctgy6rxsocamgsbhuof2pv6xyqnm3wdetppqimmfi';
  static final _endpoint = Uri.parse('https://api.onesignal.com/notifications');

  Future<void> sendToExternalIds({
    required List<String> externalIds,
    required String title,
    required String message,
    String type = 'alert',
    String examId = '',
    DateTime? sendAfter,
  }) async {
    final recipients = externalIds
        .where((id) => id.trim().isNotEmpty)
        .map((id) => id.trim())
        .toSet()
        .toList();
    if (recipients.isEmpty) return;

    final payload = <String, dynamic>{
      'app_id': _appId,
      'target_channel': 'push',
      'include_aliases': {'external_id': recipients},
      'headings': {'en': title},
      'contents': {'en': message},
      'data': {'type': type, 'examId': examId},
    };

    if (sendAfter != null &&
        sendAfter.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      payload['send_after'] = sendAfter.toUtc().toIso8601String();
    }

    final response = await http.post(
      _endpoint,
      headers: const {
        'Authorization': 'Key $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('OneSignal ${response.statusCode}: ${response.body}');
    }
  }
}
