import 'package:firebase_auth/firebase_auth.dart';
import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';
import 'package:wegig_app/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  String? lastEmail;
  String? lastPassword;
    String? lastUsername;
  AuthResult? _mockedResponse;

  void setupSuccessResponse() {
    _mockedResponse = AuthSuccess(
      user: _MockUser(),
    );
  }

  void setupFailureResponse(String message, String code) {
    _mockedResponse = AuthFailure(message: message, code: code);
  }

  @override
  Future<AuthResult> signInWithEmail(String email, String password) async {
    lastEmail = email;
    lastPassword = password;
    return _mockedResponse ??
        const AuthFailure(
            message: 'No response configured', code: 'test-error');
  }

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  bool get isEmailVerified => false;

  @override
  Future<AuthResult> sendEmailVerification() async =>
      const AuthFailure(message: 'Not implemented', code: 'test-error');

  @override
  Future<AuthResult> sendPasswordResetEmail(String email) async =>
      const AuthFailure(message: 'Not implemented', code: 'test-error');

  @override
  Future<AuthResult> signInWithApple() async =>
      const AuthFailure(message: 'Not implemented', code: 'test-error');

  @override
  Future<AuthResult> signInWithGoogle() async =>
      const AuthFailure(message: 'Not implemented', code: 'test-error');

  @override
  Future<void> signOut() async {}

    @override
    Future<AuthResult> signUpWithEmail(
        String email,
        String password,
        String username,
    ) async {
        lastEmail = email;
        lastPassword = password;
        lastUsername = username;
        return _mockedResponse ??
                const AuthFailure(message: 'Not implemented', code: 'test-error');
    }
}

class _MockUser implements User {
  @override
  String get uid => 'test-uid-123';

  @override
  String? get email => 'test@wegig.app';

  @override
  bool get emailVerified => false;

  @override
  String? get displayName => 'Test User';

  @override
  String? get photoURL => null;

  @override
  bool get isAnonymous => false;

  @override
  UserMetadata get metadata => throw UnimplementedError();

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get phoneNumber => null;

  @override
  String? get refreshToken => null;

  @override
  String? get tenantId => null;

  @override
  Future<void> delete() => throw UnimplementedError();

  @override
  Future<String> getIdToken([bool forceRefresh = false]) =>
      throw UnimplementedError();

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) =>
      throw UnimplementedError();

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber,
          [RecaptchaVerifier? verifier]) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<void> linkWithRedirect(AuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithCredential(
          AuthCredential credential) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<void> reload() => throw UnimplementedError();

  @override
  Future<void> sendEmailVerification(
          [ActionCodeSettings? actionCodeSettings]) =>
      throw UnimplementedError();

  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();

  @override
  Future<void> updateDisplayName(String? displayName) =>
      throw UnimplementedError();

  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();

  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) =>
      throw UnimplementedError();

  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) =>
      throw UnimplementedError();

  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail,
          [ActionCodeSettings? actionCodeSettings]) =>
      throw UnimplementedError();

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) =>
      throw UnimplementedError();

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) =>
      throw UnimplementedError();
}
