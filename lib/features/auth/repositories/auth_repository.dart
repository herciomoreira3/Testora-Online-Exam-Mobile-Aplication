import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user uid
  String? get currentUid => _auth.currentUser?.uid;

  // Login
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _ensureActiveEmailProfile(credential.user);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'Akontese sala. Favor koko fali.';
    }
  }

  Future<void> _ensureActiveEmailProfile(User? user) async {
    if (user == null) throw 'auth_failed';

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (!doc.exists || data == null) {
      await signOut();
      throw 'account_not_approved';
    }

    final profile = UserModel.fromMap(data, doc.id);
    if (!profile.isActive || profile.role.isEmpty) {
      await signOut();
      throw 'account_not_approved';
    }
  }

  Future<UserCredential> signInWithGoogle({
    required Future<bool> Function(String email) confirmAgreement,
  }) async {
    try {
      if (!_googleInitialized) {
        await _googleSignIn.initialize();
        _googleInitialized = true;
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        throw 'google_sign_in_unavailable';
      }

      final googleUser = await _googleSignIn.authenticate();
      final accepted = await confirmAgreement(googleUser.email);
      if (!accepted) {
        await _googleSignIn.signOut();
        throw 'agreement_declined';
      }

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _ensureApprovedProfile(userCredential.user);
      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw 'google_sign_in_cancelled';
      }
      throw 'google_sign_in_failed';
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is String) rethrow;
      throw 'error_occurred';
    }
  }

  Future<void> _ensureApprovedProfile(User? user) async {
    if (user == null) throw 'auth_failed';

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      await signOut();
      throw 'account_not_approved';
    }

    final uidDoc = await _firestore.collection('users').doc(user.uid).get();
    if (uidDoc.exists && uidDoc.data() != null) {
      final profile = UserModel.fromMap(uidDoc.data()!, uidDoc.id);
      if (!profile.isActive) {
        await signOut();
        throw 'account_not_approved';
      }
      if (profile.isActive && profile.role.isNotEmpty) {
        await _refreshGoogleProfile(user, uidDoc.data()!, email);
        return;
      }

      final approvedDoc = await _findApprovedProfileByEmail(
        email: email,
        rawEmail: user.email,
        currentUid: user.uid,
      );
      if (approvedDoc != null) {
        await _activateApprovedProfile(user, approvedDoc, email);
        return;
      }

      await _createPendingGoogleUser(user, email);
      await signOut();
      throw 'account_not_approved';
    }

    final approvedDoc = await _findApprovedProfileByEmail(
      email: email,
      rawEmail: user.email,
      currentUid: user.uid,
    );

    if (approvedDoc == null) {
      await _createPendingGoogleUser(user, email);
      await signOut();
      throw 'account_not_approved';
    }

    await _activateApprovedProfile(user, approvedDoc, email);
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
  _findApprovedProfileByEmail({
    required String email,
    required String? rawEmail,
    required String currentUid,
  }) async {
    final candidates = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final byEmailLower = await _firestore
        .collection('users')
        .where('emailLower', isEqualTo: email)
        .get();
    candidates.addAll(byEmailLower.docs);

    for (final value in {rawEmail, email}) {
      if (value == null || value.trim().isEmpty) continue;
      final byEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: value.trim())
          .get();
      candidates.addAll(byEmail.docs);
    }

    final unique = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final candidate in candidates) {
      unique[candidate.id] = candidate;
    }

    for (final candidate in unique.values) {
      final profile = UserModel.fromMap(candidate.data(), candidate.id);
      if (profile.isActive && profile.role.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  Future<void> _activateApprovedProfile(
    User user,
    QueryDocumentSnapshot<Map<String, dynamic>> approvedDoc,
    String email,
  ) async {
    final approvedData = approvedDoc.data();
    final profile = UserModel.fromMap(approvedData, approvedDoc.id);
    if (!profile.isActive || profile.role.isEmpty) {
      await signOut();
      throw 'account_not_approved';
    }

    await _firestore.collection('users').doc(user.uid).set({
      ...approvedData,
      'uid': user.uid,
      'email': user.email ?? approvedData['email'],
      'emailLower': email,
      'name': approvedData['name'] ?? user.displayName ?? user.email ?? 'User',
      'role': profile.role,
      'photoUrl': (approvedData['photoUrl']?.toString().isNotEmpty ?? false)
          ? approvedData['photoUrl']
          : user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (approvedDoc.id != user.uid) {
      await _moveSubjectAssignments(
        oldUserId: approvedDoc.id,
        newUserId: user.uid,
        role: profile.role,
      );
    }
  }

  Future<void> _refreshGoogleProfile(
    User user,
    Map<String, dynamic> currentData,
    String email,
  ) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? currentData['email'] ?? email,
      'emailLower': email,
      if ((currentData['photoUrl']?.toString().isNotEmpty ?? false) == false)
        'photoUrl': user.photoURL ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _createPendingGoogleUser(User user, String emailLower) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? user.email ?? 'User',
      'email': user.email ?? emailLower,
      'emailLower': emailLower,
      'school': '',
      'role': '',
      'language': 'tet',
      'photoUrl': user.photoURL ?? '',
      'darkMode': false,
      'selectedSubjectId': '',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _moveSubjectAssignments({
    required String oldUserId,
    required String newUserId,
    required String role,
  }) async {
    final field = role == 'teacher' ? 'teacherIds' : 'studentIds';
    final subjects = await _firestore
        .collection('subjects')
        .where(field, arrayContains: oldUserId)
        .get();

    for (final subject in subjects.docs) {
      final ids = List<String>.from(
        (subject.data()[field] as List? ?? []).map((item) => item.toString()),
      );
      final updatedIds = ids
          .map((id) => id == oldUserId ? newUserId : id)
          .toSet()
          .toList();
      await subject.reference.update({field: updatedIds});
    }
  }

  // Register + Profile creation in Firestore
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String school,
    required String role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Save user to Firestore
      final userModel = UserModel(
        uid: uid,
        name: name,
        email: email.trim(),
        school: school,
        role: '',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set({
        ...userModel.toMap(),
        'emailLower': email.trim().toLowerCase(),
        'requestedRole': UserModel.normalizeRole(role),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await signOut();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Akontese sala. Favor koko fali.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitialized) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // FirebaseAuth is the source of truth for the app session.
      }
    }
  }

  // Fetch specific user profile details from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      return UserModel.fromMap(data, doc.id);
    });
  }

  Future<void> updateUserPreferences(
    String uid,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateOneSignalSubscription({
    required String uid,
    String? subscriptionId,
    String? token,
    bool? optedIn,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'oneSignalSubscriptionId': subscriptionId ?? '',
      'oneSignalPushToken': token ?? '',
      'oneSignalOptedIn': optedIn == true,
      'oneSignalUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Helper mapping Firebase Exception messages to Tetun
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'auth_failed'; // Maps to "Email ka password sala." in tetun.json
      case 'email-already-in-use':
        return 'email_in_use'; // Maps to "Email ne'e uza ona."
      case 'weak-password':
        return 'weak_password'; // Maps to "Password fraku liu."
      case 'invalid-email':
        return 'invalid_email'; // Maps to "Email la válidu."
      default:
        return 'error_occurred'; // Maps to "Akontese sala. Favor koko fali."
    }
  }
}
