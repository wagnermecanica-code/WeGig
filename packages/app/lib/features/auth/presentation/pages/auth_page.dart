import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wegig_app/features/auth/domain/entities/auth_result.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/auth/presentation/widgets/age_verification_dialog.dart';
import 'package:wegig_app/features/auth/presentation/widgets/google_sign_in_button.dart';

/// Mensagem padrão exibida quando o usuário tenta logar/recuperar senha
/// com um e-mail que não possui conta cadastrada no app.
const String _kNoAccountForEmailMessage =
    'Não existe conta para esse endereço de e-mail. Use outro e-mail ou crie uma conta.';

/// Tela única de autenticação (Login/Cadastro) com design Airbnb 2025
/// - Email/senha como método principal
/// - Google Sign-In opcional
/// - Cria usuário no primeiro acesso
/// - Usa AuthService para lógica de negócio
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with SingleTickerProviderStateMixin {
  final _secureStorage = const FlutterSecureStorage();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = false; // true = Login, false = Cadastro
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;
  double _passwordStrength = 0.0; // 0.0 a 1.0

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    _loadSavedEmail();
    _checkPendingAuthError();
  }

  /// Verifica se há mensagem de erro pendente (de login social que falhou)
  void _checkPendingAuthError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pendingError = ref.read(pendingAuthErrorProvider);
      if (pendingError != null && pendingError.isNotEmpty) {
        // Consumir a mensagem
        ref.read(pendingAuthErrorProvider.notifier).state = null;
        setState(() {
          _errorMessage = pendingError;
        });
        debugPrint('📛 AuthPage: Exibindo erro pendente: $pendingError');
      }
    });
  }

  Future<void> _loadSavedEmail() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'last_used_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
        debugPrint('E-mail restaurado: $savedEmail');

        // Opcional: já deixa o foco na senha
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            FocusScope.of(context).nextFocus(); // pula pro campo senha
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar e-mail salvo: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Informe o e-mail';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'E-mail inválido. Verifique o formato.';
    }
    return null;
  }

  bool _hasInvalidEmailFormat() {
    final emailError = _validateEmail(_emailController.text);
    return emailError != null && emailError.startsWith('E-mail inválido');
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  Future<void> _saveEmailToSecureStorage(String email) async {
    try {
      await _secureStorage.write(
          key: 'last_used_email', value: email.trim().toLowerCase());
      debugPrint('E-mail salvo com segurança: $email');
    } catch (e) {
      debugPrint('Erro ao salvar e-mail: $e');
    }
  }

  /// Calcula força da senha (0.0 a 1.0)
  double _calculatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 6) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score / 4.0;
  }

  /// Retorna cor baseada na força da senha
  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.5) return AppColors.error;
    if (strength < 0.75) return Colors.orange;
    return Colors.green;
  }

  /// Retorna label baseado na força da senha
  String _getPasswordStrengthLabel(double strength) {
    if (strength < 0.5) return '❌ Fraca';
    if (strength < 0.75) return '⚠️ Média';
    return '✅ Forte';
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a senha';
    }
    if (value != _passwordController.text) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    setState(() {
      _errorMessage = null;
      _formKey = GlobalKey<FormState>();
    });

    final success = await showDialog<bool>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        validateEmail: _validateEmail,
        emailHasRegisteredAccount: _emailHasRegisteredAccount,
        sendPasswordResetEmail: (email) =>
            ref.read(sendPasswordResetEmailUseCaseProvider).call(email),
        resolveFailureMessage: _resolvePasswordResetFailureMessage,
      ),
    );

    if (!mounted || success != true) return;

    AppSnackBar.showSuccess(
      context,
      'E-mail de recuperação enviado! Verifique sua caixa de entrada.',
    );
  }

  String _resolvePasswordResetFailureMessage({
    required String message,
    required String? code,
    required String email,
  }) {
    switch (code) {
      case 'user-not-found':
        return _kNoAccountForEmailMessage;
      case 'invalid-email':
        return 'E-mail inválido. Verifique o formato.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      default:
        if (email.trim().isNotEmpty &&
            message.toLowerCase().contains('não está cadastrado')) {
          return _kNoAccountForEmailMessage;
        }
        return message.isNotEmpty
            ? message
            : 'Erro ao enviar e-mail de recuperação. Verifique o endereço.';
    }
  }

  Future<void> _submitEmailPassword() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('🔐 AuthPage: Validação do formulário falhou');
      if (_hasInvalidEmailFormat()) {
        setState(() {
          _errorMessage = 'E-mail inválido. Verifique o formato.';
        });
      }
      return;
    }

    debugPrint('🔐 AuthPage: Iniciando ${_isLogin ? "login" : "cadastro"}...');
    debugPrint('🔐 AuthPage: Email: ${_emailController.text.trim()}');

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Limpar erro anterior
    });

    try {
      if (_isLogin) {
        // Login com email/senha
        debugPrint('🔐 AuthPage: Tentando login com Firebase Auth...');
        try {
          final userCredential =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          await _saveEmailToSecureStorage(_emailController.text);

          debugPrint(
              '✅ AuthPage: Login bem-sucedido! UID: ${userCredential.user?.uid}');
          debugPrint('🔄 AuthPage: Aguardando navegação automática...');
          // Manter loading ativo - widget será desmontado quando authState mudar
          return; // Sair do método sem desligar loading
        } on FirebaseAuthException catch (e) {
          debugPrint('❌ AuthPage: Erro Firebase Auth: ${e.code}');
          final errorMsg = await _resolveEmailLoginErrorMessage(e);
          if (mounted) {
            setState(() {
              _errorMessage = errorMsg;
              _isLoading = false;
            });
          }
          return;
        }
      } else {
        // Cadastro
        if (!_agreedToTerms) {
          debugPrint('⚠️ AuthPage: Usuário não aceitou os termos');
          setState(() {
            _errorMessage = 'Você deve aceitar os termos para criar uma conta.';
            _isLoading = false;
          });
          return;
        }

        // ✅ Verificação de idade obrigatória para cadastro
        setState(
            () => _isLoading = false); // Desliga loading para mostrar dialog
        final ageResult = await AgeVerificationDialog.show(context, ref: ref);
        if (!ageResult.isAdult) {
          debugPrint('⚠️ AuthPage: Usuário não passou na verificação de idade');
          if (mounted) {
            setState(() {
              _errorMessage = null;
              _isLoading = false;
            });
          }
          return;
        }
        setState(() => _isLoading = true); // Religa loading após verificação

        debugPrint(
            '🔐 AuthPage: Delegando cadastro para SignUpWithEmailUseCase...');
        final useCase = ref.read(signUpWithEmailUseCaseProvider);
        final result = await useCase(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Pattern matching com AuthResult
        await result.when(
          success:
              (user, requiresEmailVerification, requiresProfileCreation) async {
            debugPrint('✅ AuthPage: Cadastro bem-sucedido! UID: ${user.uid}');

            await _saveEmailToSecureStorage(_emailController.text);

            if (!mounted) return;

            // Mostrar mensagem de verificação de email se necessário
            if (requiresEmailVerification) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.email, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                            'Verifique seu e-mail para confirmar a conta!'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
            // Manter loading ativo - será desmontado automaticamente quando authState mudar
            debugPrint('🔄 AuthPage: Aguardando navegação automática...');
          },
          failure: (message, code) {
            debugPrint('❌ AuthPage: Falha no cadastro: $message');
            if (mounted) {
              setState(() {
                _errorMessage = message;
                _isLoading = false;
              });
            }
          },
          cancelled: () {
            debugPrint('⚠️ AuthPage: Login cancelado');
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        );
        return;
      }
    } catch (e) {
      debugPrint('❌ AuthPage: Erro inesperado no submit');
      debugPrint('❌ AuthPage: Tipo: ${e.runtimeType}');
      debugPrint('❌ AuthPage: Erro: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Erro inesperado. Tente novamente.';
          _isLoading = false;
        });
      }
    }
    // Não desliga loading aqui - só em caso de erro
    // Em caso de sucesso, o widget será desmontado quando authState mudar
  }

  Future<String> _resolveEmailLoginErrorMessage(
    FirebaseAuthException exception,
  ) async {
    switch (exception.code) {
      case 'user-not-found':
        return _kNoAccountForEmailMessage;
      case 'wrong-password':
        final hasRegisteredAccount = await _emailHasRegisteredAccount(
          _emailController.text.trim(),
        );
        if (hasRegisteredAccount == false) {
          return _kNoAccountForEmailMessage;
        }
        if (hasRegisteredAccount == null) {
          return 'Nao foi possivel validar o e-mail. Confira o e-mail e a senha e tente novamente.';
        }
        return 'Senha incorreta. Tente novamente ou recupere a senha.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        final hasRegisteredAccount = await _emailHasRegisteredAccount(
          _emailController.text.trim(),
        );
        if (hasRegisteredAccount == false) {
          return _kNoAccountForEmailMessage;
        }
        if (hasRegisteredAccount == null) {
          return 'E-mail ou senha invalidos. Verifique os dados e tente novamente.';
        }
        return 'Senha incorreta. Tente novamente ou recupere a senha.';
      case 'invalid-email':
        return 'E-mail inválido. Verifique o formato.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Entre em contato com o suporte.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Erro ao fazer login (${exception.code}). Tente novamente.';
    }
  }

  Future<bool?> _emailHasRegisteredAccount(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return false;
    }

    final registrationStatus = await _lookupEmailRegistration(trimmedEmail);
    if (registrationStatus != null) {
      return registrationStatus;
    }

    debugPrint(
      '⚠️ AuthPage: Nao foi possivel verificar se o e-mail possui conta cadastrada.',
    );
    return null;
  }

  Future<bool?> _lookupEmailRegistration(String email) async {
    final apiKey = Firebase.app().options.apiKey;
    if (apiKey.isEmpty) {
      debugPrint('⚠️ AuthPage: Firebase API key ausente para lookup de e-mail.');
      return null;
    }

    final uri = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:createAuthUri',
      {'key': apiKey},
    );

    try {
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': email.toLowerCase(),
          'continueUri': 'https://wegig.com.br/login',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '⚠️ AuthPage: createAuthUri retornou ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final responseBody = jsonDecode(response.body);
      if (responseBody is! Map<String, dynamic>) {
        return null;
      }

      final registered = responseBody['registered'];
      if (registered is bool) {
        return registered;
      }

      final signInMethods = responseBody['signinMethods'];
      if (signInMethods is List) {
        return signInMethods.isNotEmpty;
      }

      final allProviders = responseBody['allProviders'];
      if (allProviders is List) {
        return allProviders.isNotEmpty;
      }

      return false;
    } on FirebaseException catch (lookupError) {
      debugPrint(
        '⚠️ AuthPage: lookup de e-mail falhou (${lookupError.code}).',
      );
    } catch (lookupError) {
      debugPrint(
        '⚠️ AuthPage: lookup de e-mail erro inesperado: $lookupError',
      );
    }

    return null;
  }

  Future<void> _signInWithGoogle() async {
    debugPrint('🔐 AuthPage: Iniciando Google Sign-In...');
    debugPrint('🔐 AuthPage: Modo atual: ${_isLogin ? "LOGIN" : "CADASTRO"}');

    // ✅ NO MODO CADASTRO: Exigir aceite de termos ANTES de autenticar
    if (!_isLogin && !_agreedToTerms) {
      debugPrint('⚠️ AuthPage: Termos não aceitos para cadastro Google');
      setState(() {
        _errorMessage = 'Você deve aceitar os termos para criar uma conta.';
      });
      return;
    }

    // ✅ NO MODO CADASTRO: Verificar idade ANTES de autenticar
    AgeVerificationResult? ageResult;
    if (!_isLogin) {
      ageResult = await AgeVerificationDialog.show(context, ref: ref);
      if (!ageResult.isAdult) {
        debugPrint(
            '⚠️ AuthPage: Usuário não passou na verificação de idade (Google pré-auth)');
        return;
      }
      debugPrint('✅ AuthPage: Idade verificada antes do Google Sign-In');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ✅ CAPTURAR dependências do Riverpod ANTES de qualquer await
    // AuthPage pode ser desmontada/reconstruída quando authState/profileState mudam.
    // Usar ref após dispose lança: "Cannot use ref after the widget was disposed".
    final authOperationNotifier =
        ref.read(authOperationInProgressProvider.notifier);
    final pendingAuthErrorNotifier =
        ref.read(pendingAuthErrorProvider.notifier);
    final socialLoginNotifier = ref.read(socialLoginDataProvider.notifier);
    final verifiedBirthYearNotifier =
        ref.read(verifiedBirthYearProvider.notifier);
    final authService = ref.read(authServiceProvider);

    // ✅ CRÍTICO: Bloquear redirect do router durante operação
    authOperationNotifier.state = true;
    debugPrint('🔐 AuthPage: authOperationInProgress = TRUE');

    try {
      final result = await authService.signInWithGoogle();

      await result.when(
        success:
            (user, requiresEmailVerification, requiresProfileCreation) async {
          debugPrint('✅ AuthPage: Login Google SUCESSO! UID: ${user.uid}');
          debugPrint('✅ AuthPage: Email: ${user.email}');
          debugPrint('✅ AuthPage: DisplayName: ${user.displayName}');
          debugPrint('✅ AuthPage: PhotoURL: ${user.photoURL}');

          // ✅ DETECÇÃO DE USUÁRIO NOVO via documento Firestore (100% confiável)
          // Firebase Auth para providers sociais SEMPRE cria conta se não existir
          // Verificamos se o documento users/{uid} existe no Firestore
          // ⚠️ IMPORTANTE: Forçar leitura do servidor para evitar cache stale após reinstalar
          DocumentSnapshot<Map<String, dynamic>> userDoc;
          try {
            userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(const GetOptions(source: Source.server));
            debugPrint('✅ AuthPage: users/${user.uid} obtido do SERVIDOR');
          } catch (e) {
            debugPrint(
                '⚠️ AuthPage: Falha ao obter do servidor, tentando default: $e');
            userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
          }
          final bool isNewUser = !userDoc.exists;
          debugPrint(
              '✅ AuthPage: Documento users/${user.uid} existe? ${userDoc.exists}');
          debugPrint('✅ AuthPage: É novo usuário (Firestore)? $isNewUser');
          debugPrint(
              '✅ AuthPage: Modo atual: ${_isLogin ? "LOGIN" : "CADASTRO"}');

          // ✅ BLOQUEAR: Se estamos no modo LOGIN e o usuário é novo, significa que
          // a conta não existe - devemos bloquear e mostrar erro IMEDIATAMENTE
          if (_isLogin && isNewUser) {
            debugPrint(
                '⚠️ AuthPage: Usuário tentou LOGIN mas conta não existe (Google)');
            debugPrint(
                '⚠️ AuthPage: Executando signOut e deletando usuário Auth...');

            // Deletar conta IMEDIATAMENTE antes que ProfileNotifier carregue
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              try {
                await currentUser.delete();
                debugPrint('🗑️ AuthPage: Usuário Auth deletado');
              } catch (e) {
                debugPrint('⚠️ AuthPage: Erro ao deletar usuário: $e');
              }
            }
            // Usar authService.signOut() para limpeza completa
            await authService.signOut();
            debugPrint('🔓 AuthPage: SignOut completo via authService');

            // ✅ Liberar bloqueio APÓS signOut completar
            authOperationNotifier.state = false;
            debugPrint(
                '🔐 AuthPage: authOperationInProgress = FALSE (após signOut)');

            // Mostrar apenas erro na UI (sem snackbar/overlay)
            const errorMsg =
                'Conta não encontrada. Use "Criar conta" para se cadastrar.';
            if (mounted) {
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = false;
              });
            }
            return;
          }

          // ✅ NOVO USUÁRIO (CADASTRO): Primeiro setar socialLoginData, DEPOIS criar documento
          // A ordem é importante para que o dado esteja disponível quando EditProfilePage carregar
          if (isNewUser) {
            // 1. PRIMEIRO: Armazenar dados do login social ANTES de qualquer navegação
            final socialData = SocialLoginData(
              displayName: user.displayName,
              email: user.email,
              photoUrl: user.photoURL,
              provider: 'google',
            );
            socialLoginNotifier.state = socialData;
            debugPrint('✅ AuthPage: Dados do login Google armazenados:');
            debugPrint('   - displayName: ${socialData.displayName}');
            debugPrint('   - email: ${socialData.email}');
            debugPrint('   - photoUrl: ${socialData.photoUrl}');
            debugPrint('   - provider: ${socialData.provider}');

            // Também armazenar ano de nascimento verificado
            if (ageResult != null && ageResult.birthYear != null) {
              verifiedBirthYearNotifier.state = ageResult.birthYear;
              debugPrint(
                  '✅ AuthPage: Ano de nascimento armazenado: ${ageResult.birthYear}');
            }

            // 2. DEPOIS: Criar o documento do usuário
            debugPrint(
                '✅ AuthPage: Criando documento users/${user.uid} após verificação de idade (Google)');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'email': user.email ?? '',
              'activeProfileId': null,
              'createdAt': FieldValue.serverTimestamp(),
              'provider': 'google',
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              // ✅ AUDITORIA: Registro de aceite de termos
              'termsAcceptedAt': FieldValue.serverTimestamp(),
              'termsVersion': '1.0', // Incrementar quando os termos mudarem
              'ageVerifiedAt': FieldValue.serverTimestamp(),
            });
            debugPrint(
                '✅ AuthPage: Documento users/${user.uid} criado com sucesso');

            // 3. ✅ CRÍTICO: Liberar bloqueio ANTES de navegação automática
            authOperationNotifier.state = false;
            debugPrint(
                '🔐 AuthPage: authOperationInProgress = FALSE (cadastro Google OK)');

            // 4. Navegação será automática via router quando profileState atualizar
            // Não precisamos chamar context.go() manualmente
            debugPrint(
                '🚀 AuthPage: Aguardando navegação automática para /profiles/new (Google)');
            return; // Sair do método - router vai redirecionar automaticamente
          }

          // ✅ USUÁRIO EXISTENTE (LOGIN): Liberar bloqueio
          authOperationNotifier.state = false;
          debugPrint(
              '🔐 AuthPage: authOperationInProgress = FALSE (login existente Google)');

          if (user.email != null && user.email!.isNotEmpty) {
            await _saveEmailToSecureStorage(user.email!);
          }
        },
        failure: (message, code) {
          debugPrint('❌ AuthPage: Login Google FALHOU: $message');
          debugPrint('❌ AuthPage: Código de erro: $code');
          // ✅ Liberar bloqueio em caso de erro
          authOperationNotifier.state = false;
          debugPrint(
              '🔐 AuthPage: authOperationInProgress = FALSE (erro Google)');

          final msg = message.isNotEmpty
              ? message
              : 'Erro ao fazer login com Google. Tente novamente.';
          pendingAuthErrorNotifier.state = msg;
          if (mounted) {
            setState(() {
              _errorMessage = msg;
            });
          }
        },
        cancelled: () {
          debugPrint('⚠️ AuthPage: Usuário CANCELOU login com Google');
          // ✅ Liberar bloqueio quando cancelado
          authOperationNotifier.state = false;
          debugPrint(
              '🔐 AuthPage: authOperationInProgress = FALSE (cancelado Google)');
        },
      );
    } catch (e) {
      debugPrint('❌ AuthPage: ERRO INESPERADO no Google Sign-In: $e');
      // ✅ Liberar bloqueio em caso de exceção
      authOperationNotifier.state = false;
      debugPrint(
          '🔐 AuthPage: authOperationInProgress = FALSE (exceção Google)');

      const msg = 'Erro ao fazer login com Google. Tente novamente.';
      pendingAuthErrorNotifier.state = msg;
      if (mounted) {
        setState(() {
          _errorMessage = msg;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    debugPrint('🍎 AuthPage: Delegando login Apple para AuthService...');
    debugPrint('🍎 AuthPage: Modo atual: ${_isLogin ? "LOGIN" : "CADASTRO"}');

    // ✅ NO MODO CADASTRO: Exigir aceite de termos ANTES de autenticar
    if (!_isLogin && !_agreedToTerms) {
      debugPrint('⚠️ AuthPage: Termos não aceitos para cadastro Apple');
      setState(() {
        _errorMessage = 'Você deve aceitar os termos para criar uma conta.';
      });
      return;
    }

    // ✅ NO MODO CADASTRO: Verificar idade ANTES de autenticar
    AgeVerificationResult? ageResult;
    if (!_isLogin) {
      ageResult = await AgeVerificationDialog.show(context, ref: ref);
      if (!ageResult.isAdult) {
        debugPrint(
            '⚠️ AuthPage: Usuário não passou na verificação de idade (Apple pré-auth)');
        return;
      }
      debugPrint('✅ AuthPage: Idade verificada antes do Apple Sign-In');
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ✅ CAPTURAR dependências do Riverpod ANTES de qualquer await
    final authOperationNotifier =
        ref.read(authOperationInProgressProvider.notifier);
    final pendingAuthErrorNotifier =
        ref.read(pendingAuthErrorProvider.notifier);
    final socialLoginNotifier = ref.read(socialLoginDataProvider.notifier);
    final verifiedBirthYearNotifier =
        ref.read(verifiedBirthYearProvider.notifier);
    final authService = ref.read(authServiceProvider);

    // ✅ CRÍTICO: Bloquear redirect do router durante operação
    authOperationNotifier.state = true;
    debugPrint('🍎 AuthPage: authOperationInProgress = TRUE');

    try {
      final result = await authService.signInWithApple();

      // Pattern matching com AuthResult
      await result.when(
        success:
            (user, requiresEmailVerification, requiresProfileCreation) async {
          debugPrint('✅ AuthPage: Login Apple bem-sucedido! UID: ${user.uid}');
          debugPrint('✅ AuthPage: Email: ${user.email}');
          debugPrint('✅ AuthPage: DisplayName: ${user.displayName}');
          debugPrint('✅ AuthPage: PhotoURL: ${user.photoURL}');

          // ✅ DETECÇÃO DE USUÁRIO NOVO via documento Firestore (100% confiável)
          // Firebase Auth para providers sociais SEMPRE cria conta se não existir
          // Verificamos se o documento users/{uid} existe no Firestore
          // ⚠️ IMPORTANTE: Forçar leitura do servidor para evitar cache stale após reinstalar
          DocumentSnapshot<Map<String, dynamic>> userDoc;
          try {
            userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(const GetOptions(source: Source.server));
            debugPrint('✅ AuthPage: users/${user.uid} obtido do SERVIDOR');
          } catch (e) {
            debugPrint(
                '⚠️ AuthPage: Falha ao obter do servidor, tentando default: $e');
            userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
          }
          final bool isNewUser = !userDoc.exists;
          debugPrint(
              '✅ AuthPage: Documento users/${user.uid} existe? ${userDoc.exists}');
          debugPrint('✅ AuthPage: É novo usuário (Firestore)? $isNewUser');
          debugPrint(
              '✅ AuthPage: Modo atual: ${_isLogin ? "LOGIN" : "CADASTRO"}');

          // ✅ BLOQUEAR: Se estamos no modo LOGIN e o usuário é novo, significa que
          // a conta não existe - devemos bloquear e mostrar erro IMEDIATAMENTE
          if (_isLogin && isNewUser) {
            debugPrint(
                '⚠️ AuthPage: Usuário tentou LOGIN mas conta não existe (Apple)');
            debugPrint(
                '⚠️ AuthPage: Executando signOut e deletando usuário Auth...');

            // Deletar conta IMEDIATAMENTE antes que ProfileNotifier carregue
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              try {
                await currentUser.delete();
                debugPrint('🗑️ AuthPage: Usuário Auth deletado (Apple)');
              } catch (e) {
                debugPrint('⚠️ AuthPage: Erro ao deletar usuário: $e');
              }
            }
            // Usar authService.signOut() para limpeza completa
            await authService.signOut();
            debugPrint('🔓 AuthPage: SignOut completo via authService (Apple)');

            // ✅ Liberar bloqueio APÓS signOut completar
            authOperationNotifier.state = false;
            debugPrint(
                '🍎 AuthPage: authOperationInProgress = FALSE (após signOut Apple)');

            // Mostrar apenas erro na UI (sem snackbar/overlay)
            const errorMsg =
                'Conta não encontrada. Use "Criar conta" para se cadastrar.';
            if (mounted) {
              setState(() {
                _errorMessage = errorMsg;
                _isLoading = false;
              });
            }

            return;
          }

          // ✅ NOVO USUÁRIO (CADASTRO): Primeiro setar socialLoginData, DEPOIS criar documento
          // A ordem é importante para que o dado esteja disponível quando EditProfilePage carregar
          if (isNewUser) {
            // 1. PRIMEIRO: Armazenar dados do login social ANTES de qualquer navegação
            final socialData = SocialLoginData(
              displayName: user.displayName,
              email: user.email,
              photoUrl: user.photoURL,
              provider: 'apple',
            );
            socialLoginNotifier.state = socialData;
            debugPrint('✅ AuthPage: Dados do login Apple armazenados:');
            debugPrint('   - displayName: ${socialData.displayName}');
            debugPrint('   - email: ${socialData.email}');
            debugPrint('   - photoUrl: ${socialData.photoUrl}');
            debugPrint('   - provider: ${socialData.provider}');

            // Também armazenar ano de nascimento verificado
            if (ageResult != null && ageResult.birthYear != null) {
              verifiedBirthYearNotifier.state = ageResult.birthYear;
              debugPrint(
                  '✅ AuthPage: Ano de nascimento armazenado: ${ageResult.birthYear}');
            }

            // 2. DEPOIS: Criar o documento do usuário
            debugPrint(
                '✅ AuthPage: Criando documento users/${user.uid} após verificação de idade (Apple)');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'email': user.email ?? '',
              'activeProfileId': null,
              'createdAt': FieldValue.serverTimestamp(),
              'provider': 'apple',
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              // ✅ AUDITORIA: Registro de aceite de termos
              'termsAcceptedAt': FieldValue.serverTimestamp(),
              'termsVersion': '1.0', // Incrementar quando os termos mudarem
              'ageVerifiedAt': FieldValue.serverTimestamp(),
            });
            debugPrint(
                '✅ AuthPage: Documento users/${user.uid} criado com sucesso');

            // 3. ✅ CRÍTICO: Liberar bloqueio ANTES de navegação automática
            authOperationNotifier.state = false;
            debugPrint(
                '🍎 AuthPage: authOperationInProgress = FALSE (cadastro Apple OK)');

            // 4. Navegação será automática via router quando profileState atualizar
            // Não precisamos chamar context.go() manualmente
            debugPrint(
                '🚀 AuthPage: Aguardando navegação automática para /profiles/new (Apple)');
            return; // Sair do método - router vai redirecionar automaticamente
          }

          // ✅ USUÁRIO EXISTENTE (LOGIN): Liberar bloqueio
          authOperationNotifier.state = false;
          debugPrint(
              '🍎 AuthPage: authOperationInProgress = FALSE (login existente Apple)');

          debugPrint('🔄 AuthPage: Aguardando navegação automática...');

          if (user.email != null && user.email!.isNotEmpty) {
            await _saveEmailToSecureStorage(user.email!);
          }
          // Manter loading ativo - widget será desmontado quando authState mudar
        },
        failure: (message, code) {
          debugPrint('❌ AuthPage: Falha no login Apple: $message');
          // ✅ Liberar bloqueio em caso de erro
          authOperationNotifier.state = false;
          debugPrint(
              '🍎 AuthPage: authOperationInProgress = FALSE (erro Apple)');

          final msg = message.isNotEmpty
              ? message
              : 'Erro ao fazer login com Apple. Tente novamente.';
          pendingAuthErrorNotifier.state = msg;
          if (mounted) {
            setState(() {
              _errorMessage = msg;
              _isLoading = false;
            });
          }
        },
        cancelled: () {
          debugPrint('⚠️ AuthPage: Usuário cancelou login com Apple');
          // ✅ Liberar bloqueio quando cancelado
          authOperationNotifier.state = false;
          debugPrint(
              '🍎 AuthPage: authOperationInProgress = FALSE (cancelado Apple)');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      debugPrint('❌ AuthPage: Erro inesperado no Apple Sign-In: $e');
      // ✅ Liberar bloqueio em caso de exceção
      authOperationNotifier.state = false;
      debugPrint(
          '🍎 AuthPage: authOperationInProgress = FALSE (exceção Apple)');

      const msg = 'Erro ao fazer login com Apple. Tente novamente.';
      pendingAuthErrorNotifier.state = msg;
      if (mounted) {
        setState(() {
          _errorMessage = msg;
          _isLoading = false;
        });
      }
    } finally {
      // ✅ Garantia extra: nunca deixar o router travado nesse estado
      // (safe: não depende de mounted/ref)
      if (authOperationNotifier.state) {
        authOperationNotifier.state = false;
        debugPrint(
            '🍎 AuthPage: authOperationInProgress = FALSE (finally safety)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AppLoadingOverlay(
            isLoading: _isLoading,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 16),
                      child: Image.asset(
                        'assets/Logo/LogoAuth.png',
                        height: 158,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (context, error, stackTrace) {
                          return Column(
                            children: [
                              const Icon(
                                Icons.music_note_rounded,
                                size: 96,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tô Sem Banda',
                                style: AppTypography.displayLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isLogin ? 'Entrar' : 'Criar Conta',
                              style: AppTypography.headlineLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'E-mail',
                                hintText: 'seu@email.com',
                                prefixIcon: const Icon(Icons.email_outlined,
                                    color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: _isLogin
                                    ? 'Sua senha'
                                    : 'Mínimo 6 caracteres, 1 maiúscula, 1 número, 1 símbolo',
                                prefixIcon: const Icon(Icons.lock_outline,
                                    color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.error, width: 2),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              enabled: !_isLoading,
                              onChanged: !_isLogin
                                  ? (value) {
                                      setState(() {
                                        _passwordStrength =
                                            _calculatePasswordStrength(value);
                                      });
                                    }
                                  : null,
                            ),
                            // ✅ Medidor de força de senha (apenas no cadastro)
                            if (!_isLogin &&
                                _passwordController.text.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _passwordStrength,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getPasswordStrengthColor(
                                        _passwordStrength),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    _passwordStrength < 0.5
                                        ? Icons.shield_outlined
                                        : _passwordStrength < 0.75
                                            ? Icons.shield
                                            : Icons.verified_user,
                                    size: 16,
                                    color: _getPasswordStrengthColor(
                                        _passwordStrength),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getPasswordStrengthLabel(
                                        _passwordStrength),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getPasswordStrengthColor(
                                          _passwordStrength),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Força da senha',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirmar Senha',
                                  hintText: 'Digite a senha novamente',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {
                                      setState(() => _obscureConfirmPassword =
                                          !_obscureConfirmPassword);
                                    },
                                  ),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.error, width: 2),
                                  ),
                                ),
                                obscureText: _obscureConfirmPassword,
                                validator: _validateConfirmPassword,
                                enabled: !_isLoading,
                              ),
                            ],
                            if (_isLogin) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _showForgotPasswordDialog,
                                  child: const Text(
                                    'Esqueci minha senha',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (!_isLogin) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _agreedToTerms,
                                    onChanged: _isLoading
                                        ? null
                                        : (value) {
                                            setState(
                                                () => _agreedToTerms = value!);
                                          },
                                    activeColor: AppColors.primary,
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        text: 'Aceito os ',
                                        style:
                                            AppTypography.captionLight.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'termos de uso',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                const url =
                                                    'https://wegig.com.br/termos.html';
                                                final uri = Uri.parse(url);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(
                                                    uri,
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                }
                                              },
                                          ),
                                          const TextSpan(text: ' e '),
                                          TextSpan(
                                            text: 'política de privacidade',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () async {
                                                const url =
                                                    'https://wegig.com.br/privacidade.html';
                                                final uri = Uri.parse(url);
                                                if (await canLaunchUrl(uri)) {
                                                  await launchUrl(
                                                    uri,
                                                    mode: LaunchMode
                                                        .externalApplication,
                                                  );
                                                }
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.error),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: AppColors.error, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    WidgetStateProperty.all(AppColors.primary),
                                foregroundColor:
                                    WidgetStateProperty.all(Colors.white),
                                padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(vertical: 18)),
                                shape: WidgetStateProperty.all(
                                    const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
                                )),
                                textStyle:
                                    WidgetStateProperty.all(const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                )),
                              ),
                              onPressed:
                                  _isLoading ? null : _submitEmailPassword,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: AppRadioPulseLoader(
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_isLogin ? 'Entrar' : 'Criar Conta'),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(color: AppColors.border)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'ou',
                                    style: AppTypography.captionLight.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                    child: Divider(color: AppColors.border)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ✅ Botão oficial do Google com logo SVG
                            GoogleSignInButton(
                              onPressed: _signInWithGoogle,
                              isLoading: _isLoading,
                            ),

                            // ✅ Botão oficial do Apple (apenas iOS)
                            if (Platform.isIOS) ...<Widget>[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: SignInWithAppleButton(
                                  onPressed:
                                      _isLoading ? () {} : _signInWithApple,
                                  text: 'Continuar com Apple',
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin
                                      ? 'Não tem uma conta? '
                                      : 'Já tem uma conta? ',
                                  style: AppTypography.bodyLight,
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  child: Text(
                                    _isLogin ? 'Criar conta' : 'Entrar',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo de recuperação de senha.
///
/// Encapsulado num `StatefulWidget` próprio para que o `TextEditingController`
/// viva no ciclo de vida do State e seja descartado pelo Flutter no momento
/// correto, evitando erros de "controller used after dispose" e
/// `_dependents.isEmpty` no Overlay quando o diálogo está animando a saída.
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.validateEmail,
    required this.emailHasRegisteredAccount,
    required this.sendPasswordResetEmail,
    required this.resolveFailureMessage,
  });

  final String? Function(String?) validateEmail;
  final Future<bool?> Function(String email) emailHasRegisteredAccount;
  final Future<AuthResult> Function(String email) sendPasswordResetEmail;
  final String Function({
    required String message,
    required String? code,
    required String email,
  }) resolveFailureMessage;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      final emailError = widget.validateEmail(_emailController.text);
      if (emailError != null && emailError.startsWith('E-mail inválido')) {
        setState(() {
          _inlineError = 'E-mail inválido. Verifique o formato.';
        });
      }
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final email = _emailController.text.trim();
    final hasRegisteredAccount = await widget.emailHasRegisteredAccount(email);

    if (hasRegisteredAccount == false) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = _kNoAccountForEmailMessage;
      });
      return;
    }

    final result = await widget.sendPasswordResetEmail(email);
    if (!mounted) return;

    result.when(
      success: (_, __, ___) {
        Navigator.of(context).pop(true);
      },
      failure: (message, code) {
        setState(() {
          _isSubmitting = false;
          _inlineError = widget.resolveFailureMessage(
            message: message,
            code: code,
            email: email,
          );
        });
      },
      cancelled: () {
        // No fluxo de recuperação, não há usuário autenticado: o repositório
        // retorna AuthCancelled quando a operação foi concluída com sucesso
        // mas não há `User` a anexar. Tratamos como sucesso.
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      scrollable: true,
      title: const Text('Recuperar Senha'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite seu e-mail para receber um link de recuperação:',
              style: AppTypography.bodyLight,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: widget.validateEmail,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: (_) {
                if (_inlineError != null) {
                  setState(() => _inlineError = null);
                }
              },
            ),
            if (_inlineError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _inlineError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSubmitting ? null : () => Navigator.of(context).maybePop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}
