import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Remote DataSource para autenticação
///
/// Responsabilidades:
/// - Comunicação direta com Firebase Auth
/// - Comunicação com Google Sign-In SDK
/// - Comunicação com Sign-In with Apple SDK
/// - Operações CRUD no Firestore (users/{uid})
/// - Retorna objetos Firebase (User, UserCredential) ou lança exceções
abstract class AuthRemoteDataSource {
  /// Stream de mudanças no estado de autenticação
  Stream<User?> get authStateChanges;

  /// Usuário atualmente autenticado (nullable)
  User? get currentUser;

  /// Login com email e senha
  ///
  /// Throws:
  /// - FirebaseAuthException se credenciais inválidas
  Future<User> signInWithEmail(String email, String password);

  /// Cadastro com email e senha
  ///
  /// Username será definido posteriormente na criação do perfil (EditProfilePage)
  ///
  /// Throws:
  /// - FirebaseAuthException se email já existe ou senha fraca
  Future<User> signUpWithEmail(
    String email,
    String password,
  );

  /// Login com Google
  ///
  /// Returns:
  /// - User se sucesso
  /// - null se usuário cancelou
  ///
  /// Throws:
  /// - FirebaseAuthException se erro no Firebase
  Future<User?> signInWithGoogle();

  /// Login com Apple
  ///
  /// Returns:
  /// - User se sucesso
  /// - null se usuário cancelou
  ///
  /// Throws:
  /// - FirebaseAuthException se erro no Firebase
  /// - SignInWithAppleAuthorizationException se erro Apple
  Future<User?> signInWithApple();

  /// Logout (Firebase + Google + Apple)
  Future<void> signOut();

  /// Enviar email de recuperação de senha
  Future<void> sendPasswordResetEmail(String email);

  /// Enviar email de verificação
  Future<void> sendEmailVerification();

  /// Criar documento users/{uid} no Firestore
  ///
  /// Chamado automaticamente após signUp ou login social (se novo usuário)
  Future<void> createUserDocument(
    User user,
    String provider, {
    String? username,
  });

  /// Verificar se documento users/{uid} existe
  Future<bool> userDocumentExists(String uid);
}

/// Implementação do AuthRemoteDataSource usando Firebase
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
            ),
        _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User> signInWithEmail(String email, String password) async {
    debugPrint('🔐 AuthRemoteDataSource: signInWithEmail');

    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (credential.user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'User is null after signIn',
      );
    }

    debugPrint(
        '✅ AuthRemoteDataSource: signInWithEmail success - ${credential.user!.uid}');
    return credential.user!;
  }

  @override
  Future<User> signUpWithEmail(
    String email,
    String password,
  ) async {
    debugPrint('🔐 AuthRemoteDataSource: signUpWithEmail');

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    if (credential.user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'User is null after signUp',
      );
    }

    try {
      await createUserDocument(
        credential.user!,
        'email',
      );
    } catch (e) {
      // Se falhar ao criar documento, remove usuário para evitar órfãos
      debugPrint('⚠️ Erro ao criar documento do usuário: $e');
      await _deleteUserOnConflict(credential.user);
      rethrow;
    }

    debugPrint(
        '✅ AuthRemoteDataSource: signUpWithEmail success - ${credential.user!.uid}');
    // Enviar email de verificação automaticamente
    await credential.user!.sendEmailVerification();
    debugPrint('📧 AuthRemoteDataSource: Email de verificação enviado');


    return credential.user!;
  }

  @override
  Future<User?> signInWithGoogle() async {
    debugPrint('🔐 AuthRemoteDataSource: signInWithGoogle - iniciando...');

    try {
      if (kIsWeb) {
        debugPrint('🌐 AuthRemoteDataSource: Executando fluxo Google para Web');
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});

        final userCredential = await _auth.signInWithPopup(provider);
        final user = userCredential.user;

        if (user == null) {
          throw FirebaseAuthException(
            code: 'null-user',
            message: 'User is null after Google Sign-In (web)',
          );
        }

        // ✅ NÃO criar documento automaticamente aqui (web)
        // A criação do documento será feita pela camada de apresentação
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          debugPrint(
              '🆕 AuthRemoteDataSource: Novo usuário Google (web) detectado (documento será criado após verificação)');
        }

        debugPrint('✅ AuthRemoteDataSource: Google Sign-In web concluído');
        return user;
      }

      // Mobile/Desktop flow
      try {
        await _googleSignIn.signOut();
        debugPrint('🔄 AuthRemoteDataSource: Google Sign-In resetado');
      } catch (e) {
        debugPrint(
            '⚠️ AuthRemoteDataSource: Erro ao resetar Google Sign-In: $e');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ AuthRemoteDataSource: Usuário cancelou Google Sign-In');
        return null;
      }

      debugPrint(
          '✅ AuthRemoteDataSource: GoogleSignInAccount obtida - ${googleUser.email}');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔐 AuthRemoteDataSource: Autenticando no Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'User is null after Google Sign-In',
        );
      }

      // ✅ Melhorar preenchimento: algumas vezes displayName/photoURL vêm nulos
      // no primeiro frame. Garantimos que o Firebase User receba os dados do
      // GoogleSignInAccount e recarregamos antes de retornar.
      try {
        final googleDisplayName = googleUser.displayName;
        final googlePhotoUrl = googleUser.photoUrl;
        if ((user.displayName ?? '').trim().isEmpty &&
            (googleDisplayName ?? '').trim().isNotEmpty) {
          await user.updateDisplayName(googleDisplayName);
        }
        if ((user.photoURL ?? '').trim().isEmpty &&
            (googlePhotoUrl ?? '').trim().isNotEmpty) {
          await user.updatePhotoURL(googlePhotoUrl);
        }
        await user.reload();
      } catch (e) {
        debugPrint('⚠️ AuthRemoteDataSource: Falha ao sincronizar dados Google: $e');
      }

      // ✅ NÃO criar documento automaticamente aqui
      // A criação do documento será feita pela camada de apresentação
      // após verificar se estamos em modo Login ou Cadastro
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        debugPrint(
            '🆕 AuthRemoteDataSource: Novo usuário Google detectado (documento será criado após verificação)');
      }

      debugPrint(
          '✅ AuthRemoteDataSource: Google Sign-In completo - ${user.uid}');
        return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthRemoteDataSource: FirebaseAuthException - ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint(
          '❌ AuthRemoteDataSource: Erro inesperado no Google Sign-In: $e');
      rethrow;
    }
  }

  @override
  Future<User?> signInWithApple() async {
    debugPrint('🔐 AuthRemoteDataSource: signInWithApple - iniciando...');

    try {
      // Solicitar credencial Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('✅ AuthRemoteDataSource: Credencial Apple obtida');

      // Criar OAuthCredential para Firebase
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('🔐 AuthRemoteDataSource: Autenticando no Firebase...');
      final userCredential = await _auth.signInWithCredential(oAuthCredential);

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'User is null after Apple Sign-In',
        );
      }

      // Se é primeira vez e temos nome, atualizar displayName
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;

        if (givenName != null || familyName != null) {
          final displayName = [givenName, familyName]
              .where((name) => name != null && name.isNotEmpty)
              .join(' ');

          if (displayName.isNotEmpty) {
            debugPrint(
                '🔐 AuthRemoteDataSource: Atualizando displayName: $displayName');
            await userCredential.user!.updateDisplayName(displayName);
          }
        }

        // ✅ NÃO criar documento automaticamente aqui
        // A criação do documento será feita pela camada de apresentação
        // após verificar se estamos em modo Login ou Cadastro
        debugPrint(
            '🆕 AuthRemoteDataSource: Novo usuário Apple detectado (documento será criado após verificação)');
      }

      debugPrint(
          '✅ AuthRemoteDataSource: Apple Sign-In completo - ${userCredential.user!.uid}');
      // ✅ Garantir que displayName/email do FirebaseAuth estejam atualizados
      try {
        await userCredential.user!.reload();
      } catch (e) {
        debugPrint('⚠️ AuthRemoteDataSource: Falha ao reload após Apple Sign-In: $e');
      }
      return _auth.currentUser;
    } on SignInWithAppleAuthorizationException catch (e) {
      // Usuário cancelou
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('⚠️ AuthRemoteDataSource: Usuário cancelou Apple Sign-In');
        return null;
      }
      rethrow; // Re-throw outros erros
    }
  }

  @override
  Future<void> signOut() async {
    debugPrint('🔓 AuthRemoteDataSource: signOut - iniciando...');

    // Sign out Google (se estiver logado)
    try {
      await _googleSignIn.signOut();
      debugPrint('✅ AuthRemoteDataSource: Google Sign-Out completo');
    } catch (e) {
      debugPrint('⚠️ AuthRemoteDataSource: Google não estava conectado: $e');
    }

    // Sign out Firebase (sempre por último)
    await _auth.signOut();
    debugPrint('✅ AuthRemoteDataSource: Firebase Sign-Out completo');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('🔐 AuthRemoteDataSource: sendPasswordResetEmail - $email');
    await _auth.sendPasswordResetEmail(email: email.trim());
    debugPrint('✅ AuthRemoteDataSource: Email de recuperação enviado');
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Nenhum usuário logado',
      );
    }

    debugPrint('🔐 AuthRemoteDataSource: sendEmailVerification');
    await user.sendEmailVerification();
    debugPrint('✅ AuthRemoteDataSource: Email de verificação enviado');
  }

  @override
  Future<void> createUserDocument(
    User user,
    String provider, {
    String? username,
  }) async {
    debugPrint('📝 AuthRemoteDataSource: createUserDocument - ${user.uid}');

    final userDoc = _firestore.collection('users').doc(user.uid);
    final alreadyExists = await userDocumentExists(user.uid);
    if (alreadyExists) {
      debugPrint(
          '📄 AuthRemoteDataSource: Documento já existe, pulando criação');
      return;
    }

    // Criar documento com campos de auditoria para compliance
    await userDoc.set({
      'email': user.email ?? '',
      'activeProfileId': null, // Será definido ao criar primeiro perfil
      'createdAt': FieldValue.serverTimestamp(),
      'provider': provider,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      if (username != null) 'username': username,
      if (username != null) 'usernameLowercase': username.toLowerCase(),
      // ✅ AUDITORIA: Registro de aceite de termos (cadastro via email)
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'termsVersion': '1.0', // Incrementar quando os termos mudarem
      'ageVerifiedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ AuthRemoteDataSource: Documento users/${user.uid} criado');
  }

  @override
  Future<bool> userDocumentExists(String uid) async {
    debugPrint('🔍 AuthRemoteDataSource: userDocumentExists - $uid');
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    final exists = docSnapshot.exists;
    debugPrint('📄 AuthRemoteDataSource: Documento existe: $exists');
    return exists;
  }

  Future<void> _deleteUserOnConflict(User? user) async {
    if (user == null) return;
    try {
      await user.delete();
      debugPrint(
          '🗑️ AuthRemoteDataSource: Usuário removido após conflito');
    } catch (e) {
      debugPrint(
          '⚠️ AuthRemoteDataSource: Falha ao remover usuário temporário: $e');
    }
  }
}
