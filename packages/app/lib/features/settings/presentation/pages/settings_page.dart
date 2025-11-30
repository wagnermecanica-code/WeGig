import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:wegig_app/features/settings/presentation/widgets/settings_tile.dart';

/// Tela de Configurações do perfil ativo
/// Design Airbnb 2025: Clean, minimalista, switches e botões bem organizados
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifyInterests = true;
  bool _notifyMessages = true;
  bool _notifyNearbyPosts = true;
  double _nearbyRadiusKm = 20;
  bool _isLoading = true;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(activeProfile.profileId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _notifyNearbyPosts =
              data?['notificationRadiusEnabled'] as bool? ?? true;
          _nearbyRadiusKm =
              ((data?['notificationRadius'] as num?) ?? 20.0).toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateNotificationSettings() async {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(activeProfile.profileId)
          .update({
        'notificationRadiusEnabled': _notifyNearbyPosts,
        'notificationRadius': _nearbyRadiusKm,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showError('Erro ao salvar configurações');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações',
            style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // Seção: Perfil
          const SettingsSection(title: 'Perfil', icon: Icons.person_outline),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Editar Perfil',
            subtitle: 'Atualize suas informações',
            onTap: () async {
              if (activeProfile == null) {
                _showError('Perfil ativo não encontrado');
                return;
              }

              // Capturar context antes de operação async
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final result = await navigator.push(
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );

              // Se o perfil foi atualizado (retornou profileId), atualiza providers
              if (result is String && result.isNotEmpty) {
                await ref.read(profileProvider.notifier).refresh();
                // Invalida posts para garantir que posts do perfil sejam atualizados
                ref.invalidate(postProvider);
              }

              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text('Perfil atualizado!'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          SettingsTile(
            icon: Icons.share_outlined,
            title: 'Compartilhar Perfil',
            subtitle: 'Compartilhe com amigos',
            onTap: () => _shareProfile(activeProfile),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Seção: Notificações
          const SettingsSection(
              title: 'Notificações', icon: Icons.notifications_outlined),
          const SizedBox(height: 12),
          SettingsSwitchTile(
            icon: Icons.favorite_outline,
            title: 'Interesses',
            subtitle: 'Notificação quando alguém demonstra interesse',
            value: _notifyInterests,
            onChanged: (value) {
              setState(() => _notifyInterests = value);
              _showSnackBar('Preferência salva');
            },
          ),
          const SizedBox(height: 8),
          SettingsSwitchTile(
            icon: Icons.message_outlined,
            title: 'Mensagens',
            subtitle: 'Notificação de novas mensagens',
            value: _notifyMessages,
            onChanged: (value) {
              setState(() => _notifyMessages = value);
              _showSnackBar('Preferência salva');
            },
          ),
          const SizedBox(height: 8),
          _buildNearbyPostsCard(),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Seção: Conta
          const SettingsSection(
              title: 'Conta', icon: Icons.account_circle_outlined),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.logout,
            title: 'Sair da Conta',
            subtitle: 'Desconectar do aplicativo',
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: _isLoggingOut ? null : _showLogoutDialog,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNearbyPostsCard() {
    if (_isLoading) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            title: Text(
              'Posts Próximos',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Notificação de novos posts perto de você',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            value: _notifyNearbyPosts,
            activeThumbColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _notifyNearbyPosts = value);
              _updateNotificationSettings();
              _showSnackBar(_notifyNearbyPosts
                  ? 'Você receberá notificações de posts próximos'
                  : 'Notificações de posts próximos desativadas');
            },
          ),

          // Slider animado (aparece quando toggle está ativo)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _notifyNearbyPosts
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.map_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Raio de Notificação',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_nearbyRadiusKm.toInt()} km',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Notificar quando houver novos posts até ${_nearbyRadiusKm.toInt()} km de você',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            thumbColor: AppColors.primary,
                            overlayColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 20),
                            trackHeight: 4,
                            valueIndicatorColor: AppColors.primary,
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Slider(
                            value: _nearbyRadiusKm,
                            min: 5,
                            max: 100,
                            divisions: 19, // 5, 10, 15, ..., 100
                            label: '${_nearbyRadiusKm.toInt()} km',
                            onChanged: (value) {
                              setState(() => _nearbyRadiusKm = value);
                            },
                            onChangeEnd: (value) {
                              _updateNotificationSettings();
                              _showSnackBar(
                                  'Raio atualizado para ${value.toInt()} km');
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '5 km',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '100 km',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _shareProfile(ProfileEntity? profile) {
    if (profile == null) {
      _showError('Perfil não encontrado');
      return;
    }

    final message = DeepLinkGenerator.generateProfileShareMessage(
      name: profile.name,
      isBand: profile.isBand,
      city: profile.city,
      userId: profile.uid,
      profileId: profile.profileId,
      instruments: profile.instruments ?? [],
      genres: profile.genres ?? [],
    );

    Share.share(message, subject: 'Perfil no WeGig');
  }

  void _showLogoutDialog() {
    // Prevenir múltiplos dialogs
    if (_isLoggingOut) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevenir fechar acidentalmente
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Sair da Conta'),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja sair? Você precisará fazer login novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context); // Fecha o dialog
              await _performLogout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    // Prevenir múltiplos logouts simultâneos
    if (_isLoggingOut) {
      debugPrint('⚠️ SettingsPage: Logout já em andamento, ignorando...');
      return;
    }

    if (!mounted) return;

    setState(() => _isLoggingOut = true);

    // Capturar navigator e messenger ANTES de operações async
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('🔓 SettingsPage: Iniciando processo de logout...');

      // CRÍTICO: Pop a tela de configurações imediatamente
      if (navigator.canPop()) {
        debugPrint('🔙 SettingsPage: Fechando tela de configurações...');
        navigator.pop();
      }

      // Aguardar frame para garantir que o pop foi processado
      await Future.delayed(const Duration(milliseconds: 150));

      // Invalidar todos os providers ANTES do logout para limpar cache
      debugPrint('🧹 SettingsPage: Invalidando providers...');
      ref.invalidate(profileProvider);
      ref.invalidate(postProvider);

      // Aguardar mais um frame para garantir que invalidação foi processada
      await Future.delayed(const Duration(milliseconds: 150));

      // Executar logout no AuthService (Firebase + cache cleanup)
      debugPrint('🔓 SettingsPage: Executando signOut...');
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      debugPrint('✅ SettingsPage: Logout completo com sucesso!');
      debugPrint(
          '🔄 SettingsPage: authStateProvider detectará mudança e mostrará AuthPage automaticamente');
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro ao fazer logout: $e');

      // Tratar erro apenas se widget ainda estiver montado
      if (mounted) {
        setState(() => _isLoggingOut = false);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao sair: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      // Garantir que flag é resetada mesmo se houver erro
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
