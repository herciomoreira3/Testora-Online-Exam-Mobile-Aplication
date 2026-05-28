import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/alert_model.dart';
import '../../auth/providers/auth_provider.dart';

class AlertRepository {
  AlertRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository(FirebaseFirestore.instance);
});

final myAlertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUid;
  if (uid == null) return const Stream.empty();
  return ref.watch(alertRepositoryProvider).watchAlerts(uid);
});

final unreadAlertsProvider = Provider<int>((ref) {
  final alerts = ref.watch(myAlertsProvider).value ?? const <AlertModel>[];
  return alerts.length;
});
