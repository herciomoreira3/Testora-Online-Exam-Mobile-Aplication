import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/alert_model.dart';
import '../../../shared/services/onesignal_push_service.dart';
import '../../auth/providers/auth_provider.dart';

class AlertRepository {
  AlertRepository(this._firestore);

  final FirebaseFirestore _firestore;
  final OneSignalPushService _pushService = const OneSignalPushService();

  Stream<List<AlertModel>> watchAlerts(String uid) {
    return _firestore
        .collection('alerts')
        .where('recipientIds', arrayContains: uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final now = DateTime.now();
          final alerts = <AlertModel>[];
          for (final doc in snapshot.docs) {
            final alert = AlertModel.fromMap(doc.data(), doc.id);
            if (alert.isExpired) {
              await doc.reference.delete();
              continue;
            }
            if (!alert.scheduledAt.isAfter(now)) {
              alerts.add(alert);
            }
          }
          alerts.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
          return alerts;
        });
  }

  Future<void> markAlertsRead(String uid, List<AlertModel> alerts) async {
    final unreadAlerts = alerts.where((alert) => !alert.isReadBy(uid)).toList();
    if (unreadAlerts.isEmpty) return;

    final batch = _firestore.batch();
    for (final alert in unreadAlerts) {
      batch.update(_firestore.collection('alerts').doc(alert.id), {
        'readBy': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> pushUnreadAlerts(String uid) async {
    final snapshot = await _firestore
        .collection('alerts')
        .where('recipientIds', arrayContains: uid)
        .get();
    final now = DateTime.now();
    final pushJobs = <Future<void>>[];
    for (final doc in snapshot.docs) {
      final alert = AlertModel.fromMap(doc.data(), doc.id);
      if (alert.isExpired ||
          alert.scheduledAt.isAfter(now) ||
          alert.isReadBy(uid)) {
        continue;
      }
      pushJobs.add(pushSingleAlert(uid, alert));
    }

    for (final job in pushJobs) {
      try {
        await job;
      } catch (_) {
        // Push on login is a best-effort reminder. Firestore alert remains.
      }
    }
  }

  Future<void> pushSingleAlert(String uid, AlertModel alert) async {
    await _pushService.sendToExternalIds(
      externalIds: [uid],
      title: alert.title,
      message: alert.message,
      type: alert.type,
      examId: alert.examId,
    );
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(FirebaseFirestore.instance);
});

final alertClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 15), (_) => DateTime.now());
});

final myAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  ref.watch(alertClockProvider);
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(alertRepositoryProvider).watchAlerts(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final unreadAlertsProvider = Provider<int>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  final alerts = ref.watch(myAlertsProvider).value ?? const <AlertModel>[];
  if (uid == null) return 0;
  return alerts.where((alert) => !alert.isReadBy(uid)).length;
});
