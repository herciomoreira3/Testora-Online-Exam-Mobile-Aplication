import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserModel?>((ref) async* {
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) {
    yield null;
    return;
  }
  yield* ref.read(authRepositoryProvider).watchUserProfile(authState.uid);
});

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      // Force refreshing the userProfileProvider
      ref.invalidate(userProfileProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return false;
    }
  }

  Future<bool> loginWithGoogle({
    required Future<bool> Function(String email) confirmAgreement,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(confirmAgreement: confirmAgreement);
      ref.invalidate(userProfileProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String school,
    required String role,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .signUpWithEmail(
            email: email,
            password: password,
            name: name,
            school: school,
            role: role,
          );
      // Force refreshing the userProfileProvider
      ref.invalidate(userProfileProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return false;
    }
  }

  Future<bool> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      ref.invalidate(userProfileProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return false;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(() {
      return AuthController();
    });
