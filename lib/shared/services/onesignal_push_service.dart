import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OneSignalPushService {
  const OneSignalPushService();

  static const _appId = '51778ec8-c5ff-4661-85f9-cca8f1b5b105';
  static const _apiKey =
      'os_v2_app_kf3y5sgf75dgdbpzzsupdnnraw2c47pn33ae3znqfkad7eqdukr3xu4xgeasovloe6zy5z2gwrh33se7bm3e7wb3yome3ozh4vk57ni';
  static final _endpoint = Uri.parse('https://api.onesignal.com/notifications');
  static final _legacyEndpoint = Uri.parse(
    'https://onesignal.com/api/v1/notifications',
  );

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

    final subscriptionIds = await _subscriptionIdsForUsers(recipients);
    if (subscriptionIds.isNotEmpty) {
      final directPayload = _basePayload(
        title: title,
        message: message,
        type: type,
        examId: examId,
        sendAfter: sendAfter,
      )..['include_subscription_ids'] = subscriptionIds;
      final sentDirect = await _post(
        endpoint: _endpoint,
        payload: directPayload,
        authorization: 'key $_apiKey',
        label: 'subscription',
        allowThrow: false,
      );
      if (sentDirect) return;
    }

    final aliasPayload = _basePayload(
      title: title,
      message: message,
      type: type,
      examId: examId,
      sendAfter: sendAfter,
    )..['include_aliases'] = {'external_id': recipients};
    final sentAlias = await _post(
      endpoint: _endpoint,
      payload: aliasPayload,
      authorization: 'key $_apiKey',
      label: 'external_id',
      allowThrow: false,
    );
    if (sentAlias) return;

    final legacyPayload = <String, dynamic>{
      'app_id': _appId,
      'include_external_user_ids': recipients,
      'channel_for_external_user_ids': 'push',
      'headings': {'en': title},
      'contents': {'en': message},
      'data': {'type': type, 'examId': examId},
    };
    if (sendAfter != null &&
        sendAfter.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      legacyPayload['send_after'] = sendAfter.toUtc().toIso8601String();
    }
    await _post(
      endpoint: _legacyEndpoint,
      payload: legacyPayload,
      authorization: 'key $_apiKey',
      label: 'legacy_external_id',
      allowThrow: true,
    );
  }

  Map<String, dynamic> _basePayload({
    required String title,
    required String message,
    required String type,
    required String examId,
    DateTime? sendAfter,
  }) {
    final payload = <String, dynamic>{
      'app_id': _appId,
      'target_channel': 'push',
      'headings': {'en': title},
      'contents': {'en': message},
      'data': {'type': type, 'examId': examId},
    };

    if (sendAfter != null &&
        sendAfter.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      payload['send_after'] = sendAfter.toUtc().toIso8601String();
    }
    return payload;
  }

  Future<bool> _post({
    required Uri endpoint,
    required Map<String, dynamic> payload,
    required String authorization,
    required String label,
    required bool allowThrow,
  }) async {
    final response = await http.post(
      endpoint,
      headers: {
        'Authorization': authorization,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final body = _decodeBody(response.body);
    final hasErrors = body['errors'] != null;
    final recipients = int.tryParse(body['recipients']?.toString() ?? '');
    final delivered =
        ok && !hasErrors && (recipients == null || recipients > 0);
    debugPrint(
      'OneSignal $label ${response.statusCode}: ${response.body}',
      wrapWidth: 1024,
    );
    await _logPushAttempt(
      label: label,
      statusCode: response.statusCode,
      ok: delivered,
      payload: payload,
      body: response.body,
    );
    if (!delivered && allowThrow) {
      throw Exception(
        'OneSignal $label ${response.statusCode}: ${response.body}',
      );
    }
    return delivered;
  }

  Future<List<String>> _subscriptionIdsForUsers(List<String> userIds) async {
    final firestore = FirebaseFirestore.instance;
    final ids = <String>{};
    for (final userId in userIds) {
      try {
        final doc = await firestore.collection('users').doc(userId).get();
        final data = doc.data();
        final subscriptionId = data?['oneSignalSubscriptionId']?.toString();
        if (subscriptionId != null && subscriptionId.isNotEmpty) {
          ids.add(subscriptionId);
        }
      } catch (_) {
        // Fall back to external_id if reading the subscription fails.
      }
    }
    return ids.toList();
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return const {};
  }

  Future<void> _logPushAttempt({
    required String label,
    required int statusCode,
    required bool ok,
    required Map<String, dynamic> payload,
    required String body,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('push_logs').add({
        'label': label,
        'statusCode': statusCode,
        'ok': ok,
        'payload': payload,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
