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
import 'package:wegig_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:wegig_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:wegig_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:iconsax/iconsax.dart';

/// Tela de Configurações do perfil ativo
/// Design Airbnb 2025: Clean, minimalista, switches e botões bem organizados
/// Migrated to Riverpod AsyncNotifier (no setState!)
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load settings when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(profileProvider);
      final activeProfile = profileState.value?.activeProfile;
      if (activeProfile != null) {
        ref
            .read(userSettingsProvider.notifier)
            .loadSettings(activeProfile.profileId);
      }
    });
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
          const SettingsSection(title: 'Perfil', icon: Iconsax.user),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Iconsax.edit,
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

              final result = await navigator.push<String?>(
                MaterialPageRoute<String?>(
                  builder: (context) => EditProfilePage(
                    profileIdToEdit: activeProfile.profileId,
                  ),
                ),
              );

              final didUpdateProfile = result is String && result.isNotEmpty;
              if (!didUpdateProfile) {
                return;
              }

              await ref.read(profileProvider.notifier).refresh();
              // Invalida posts para garantir que posts do perfil sejam atualizados
              ref.invalidate(postNotifierProvider);

              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Iconsax.tick_circle, color: Colors.white),
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
            icon: Iconsax.share,
            title: 'Compartilhar Perfil',
            subtitle: 'Compartilhe com amigos',
            onTap: () => _shareProfile(activeProfile),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Seção: Notificações
          const SettingsSection(
              title: 'Notificações', icon: Iconsax.notification),
          const SizedBox(height: 12),
          _buildNotificationSettings(),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),

          // Seção: Conta
          const SettingsSection(
              title: 'Conta', icon: Iconsax.profile_circle),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Iconsax.logout,
            title: 'Sair da Conta',
            subtitle: 'Desconectar do aplicativo',
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: _showLogoutDialog,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNearbyPostsCard() {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (settings == null) {
          return const SizedBox.shrink();
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
                    Iconsax.location,
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
                value: settings.notifyNearbyPosts,
                thumbColor: MaterialStateProperty.resolveWith<Color?>(
                  (states) => states.contains(MaterialState.selected)
                      ? AppColors.primary
                      : AppColors.border,
                ),
                onChanged: (value) {
                  ref
                      .read(userSettingsProvider.notifier)
                      .toggleNotifyNearbyPosts(value);
                  _showSnackBar(value
                      ? 'Você receberá notificações de posts próximos'
                      : 'Notificações de posts próximos desativadas');
                },
              ),

              // Slider animado (aparece quando toggle está ativo)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: settings.notifyNearbyPosts
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
                                  Iconsax.map,
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
                                    color:
                                        AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${settings.nearbyRadiusKm.toInt()} km',
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
                              'Notificar quando houver novos posts até ${settings.nearbyRadiusKm.toInt()} km de você',
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
                                value: settings.nearbyRadiusKm,
                                min: 5,
                                max: 100,
                                divisions: 19, // 5, 10, 15, ..., 100
                                label: '${settings.nearbyRadiusKm.toInt()} km',
                                onChanged: (value) {
                                  // Optimistic UI update via provider
                                  ref
                                      .read(userSettingsProvider.notifier)
                                      .updateNearbyRadius(value);
                                },
                                onChangeEnd: (value) {
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
      },
      loading: () => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
      ),
      error: (error, stack) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.error),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Erro ao carregar configurações',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (settings == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SettingsSwitchTile(
              icon: Iconsax.heart,
              title: 'Interesses',
              subtitle: 'Notificação quando alguém demonstra interesse',
              value: settings.notifyInterests,
              onChanged: (value) {
                ref
                    .read(userSettingsProvider.notifier)
                    .toggleNotifyInterests(value);
                _showSnackBar('Preferência salva');
              },
            ),
            const SizedBox(height: 8),
            SettingsSwitchTile(
              icon: Iconsax.message,
              title: 'Mensagens',
              subtitle: 'Notificação de novas mensagens',
              value: settings.notifyMessages,
              onChanged: (value) {
                ref
                    .read(userSettingsProvider.notifier)
                    .toggleNotifyMessages(value);
                _showSnackBar('Preferência salva');
              },
            ),
            const SizedBox(height: 8),
            _buildNearbyPostsCard(),
          ],
        );
      },
      loading: () => const Column(
        children: [
          SizedBox(height: 40),
          Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Erro ao carregar preferências de notificação',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Compartilha o deep link do perfil via WhatsApp, Instagram, etc
  void _shareProfile(ProfileEntity? profile) {
    if (profile == null) {
      _showError('Perfil não encontrado');
      return;
    }

    final message = DeepLinkGenerator.generateProfileShareMessage(
      name: profile.name,
      isBand: profile.isBand,
      city: profile.city,
      neighborhood: profile.neighborhood,
      state: profile.state,
      userId: profile.uid,
      profileId: profile.profileId,
      instruments: profile.instruments ?? [],
      genres: profile.genres ?? [],
    );

    SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: 'Perfil no WeGig',
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevenir fechar acidentalmente
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Iconsax.logout, color: AppColors.error),
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
    if (!mounted) return;

    // Capturar TUDO ANTES de operações async (crítico!)
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authService = ref.read(authServiceProvider);  // ✅ Capturar ANTES!

    try {
      debugPrint('🔓 SettingsPage: Iniciando processo de logout...');

      // Invalidar providers ANTES de qualquer navegação
      debugPrint('🧹 SettingsPage: Invalidando providers...');
      ref.invalidate(profileProvider);
      ref.invalidate(postNotifierProvider);

      // Executar logout
      debugPrint('🔓 SettingsPage: Executando signOut...');
      await authService.signOut();

      // Pop apenas DEPOIS do signOut (se widget ainda montado)
      if (navigator.canPop() && mounted) {
        debugPrint('🔙 SettingsPage: Fechando tela...');
        navigator.pop();
      }

      debugPrint('✅ SettingsPage: Logout completo com sucesso!');
      debugPrint(
          '🔄 SettingsPage: authStateProvider detectará mudança e mostrará AuthPage automaticamente');
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro ao fazer logout: $e');

      // Tratar erro apenas se widget ainda estiver montado
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.danger, color: Colors.white),
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
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 22),
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
