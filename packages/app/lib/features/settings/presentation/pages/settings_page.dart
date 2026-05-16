import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:core_ui/utils/deep_link_generator.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/notifications_new/data/services/push_notification_service.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:wegig_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:wegig_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:wegig_app/features/settings/presentation/pages/blocked_users_page.dart';
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
  // Variável para rastrear posição inicial do swipe (Swipe to go back)
  double _swipeStartX = 0;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Carregar settings imediatamente, sem aguardar frame
    // Isso reduz a latência perceptível ao abrir a tela
    _loadSettingsEagerly();
  }
  
  void _loadSettingsEagerly() {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;
    if (activeProfile != null) {
      // Carregar diretamente sem addPostFrameCallback para reduzir latência
      ref
          .read(userSettingsProvider.notifier)
          .loadSettings(activeProfile.profileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;

    return GestureDetector(
      // Detecta início do swipe
      onHorizontalDragStart: (details) {
        _swipeStartX = details.globalPosition.dx;
      },
      // Detecta movimento do swipe
      onHorizontalDragUpdate: (details) {
        // Só permite swipe se começou da borda esquerda (primeiros 50px)
        // E movimento para a direita (delta.dx > 0)
        if (_swipeStartX < 50 && details.delta.dx > 10) {
          // Executa o pop (volta para ViewProfilePage)
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Configurações',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
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

            // Seção: Bloqueios
            const SettingsSection(title: 'Bloqueios', icon: Iconsax.shield_tick),
            const SizedBox(height: 12),
            SettingsTile(
              icon: Iconsax.user_remove,
              title: 'Perfis bloqueados',
              subtitle: 'Gerencie quem você bloqueou',
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const BlockedUsersPage(),
                  ),
                );
              },
            ),

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
          const SizedBox(height: 8),
          SettingsTile(
            icon: Iconsax.trash,
            title: 'Excluir Conta',
            subtitle: 'Remover permanentemente todos os dados',
            iconColor: AppColors.error,
            textColor: AppColors.error,
            onTap: _showDeleteAccountDialog,
          ),

          const SizedBox(height: 40),
        ],
      ),
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
                // ✅ FIX: Melhorar cores dos toggles para maior visibilidade
                activeColor: AppColors.primary,
                thumbColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white  // Thumb branco quando ativo
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                trackColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary  // Track colorido quando ativo
                      : AppColors.border,  // Track cinza quando inativo
                ),
                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : AppColors.border,
                ),
                thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                  (states) => null, // Thumb com sombra padrão
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
            child: AppRadioPulseLoader(size: 44, color: AppColors.primary),
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
            SettingsSwitchTile(
              icon: Iconsax.user_search,
              title: 'Aparecer em sugestões',
              subtitle: 'Permitir que seu perfil apareça em sugestões de conexão',
              value: settings.allowConnectionSuggestions,
              onChanged: (value) {
                ref
                    .read(userSettingsProvider.notifier)
                    .toggleAllowConnectionSuggestions(value);
                _showSnackBar('Preferência salva');
              },
            ),
            const SizedBox(height: 8),
            SettingsSwitchTile(
              icon: Iconsax.user_add,
              title: 'Receber convites de conexão',
              subtitle: 'Permitir que outros perfis enviem convites para você',
              value: settings.allowConnectionRequests,
              onChanged: (value) {
                ref
                    .read(userSettingsProvider.notifier)
                    .toggleAllowConnectionRequests(value);
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
            child: AppRadioPulseLoader(size: 44, color: AppColors.primary),
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
    final authService = ref.read(authServiceProvider);
    final profiles = ref.read(profileProvider).value?.profiles ?? [];
    final profileIds = profiles.map((p) => p.profileId).toList();

    try {
      debugPrint('🔓 SettingsPage: Iniciando processo de logout...');

      // 1. Remover tokens FCM de TODOS os perfis (antes do signOut)
      if (profileIds.isNotEmpty) {
        debugPrint('🔓 SettingsPage: Removendo tokens FCM de ${profileIds.length} perfis...');
        await PushNotificationService().removeTokenFromAllProfiles(profileIds);
      }

      // 2. Executar logout (Firebase + Google)
      debugPrint('🔓 SettingsPage: Executando signOut...');
      await authService.signOut();

      // ✅ FIX: Após signOut, o authStateProvider detectará a mudança
      // e o GoRouter redirecionará para /auth automaticamente.
      // NÃO invalidar providers aqui pois o widget pode já estar desmontado.
      // O router fará o cleanup ao navegar para /auth.
      
      debugPrint('✅ SettingsPage: Logout completo - aguardando redirect automático do router');
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro ao fazer logout: $e');

      // Tratar erro apenas se widget ainda estiver montado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: AppColors.error),
            SizedBox(width: 12),
            Text('Excluir Conta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tem certeza que deseja excluir sua conta? Esta ação é irreversível.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Serão excluídos permanentemente:',
                    style: AppTypography.captionLight.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Todos os seus perfis\n• Todos os seus posts\n• Todas as suas fotos\n• Todas as suas conversas\n• Todas as suas notificações',
                    style: AppTypography.captionLight.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              Navigator.pop(context);

              if (!mounted) return;
              final confirmed = await _showDeleteAccountFinalConfirmDialog();
              if (!confirmed) return;

              await _performDeleteAccount();
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteAccountFinalConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DeleteAccountFinalConfirmDialog(),
    );

    return result ?? false;
  }

  Future<void> _performDeleteAccount() async {
    if (!mounted) return;

    // Capturar referências ANTES de operações async
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final profiles = ref.read(profileProvider).value?.profiles ?? [];
    final profileIds = profiles.map((p) => p.profileId).toList();
    final user = ref.read(currentUserProvider);

    if (user == null) {
      debugPrint('❌ SettingsPage: Usuário não encontrado para deletar conta');
      return;
    }

    try {
      debugPrint('🗑️ SettingsPage: Iniciando processo de exclusão de conta...');
      
      // Mostrar loading
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const PopScope(
            canPop: false,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppRadioPulseLoader(size: 40),
                      SizedBox(height: 16),
                      Text('Excluindo conta...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      // 1. Remover tokens FCM de todos os perfis (antes de deletar)
      if (profileIds.isNotEmpty) {
        debugPrint('🗑️ SettingsPage: Removendo tokens FCM de ${profileIds.length} perfis...');
        await PushNotificationService().removeTokenFromAllProfiles(profileIds);
      }

      // 2. ✅ DELETAR USUÁRIO DO FIREBASE AUTH
      // A Cloud Function `onUserDelete` será acionada automaticamente e limpará:
      // - Documento users/{uid}
      // - Todos os perfis do usuário (que por sua vez acionam onProfileDelete)
      // - Conversas, interesses, rate limits órfãos
      debugPrint('🗑️ SettingsPage: Deletando usuário do Firebase Auth...');
      
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          debugPrint('⚠️ SettingsPage: Reautenticação necessária');
          
          // Fechar loading dialog
          if (mounted) navigator.pop();
          
          // Tentar reautenticar
          final reauthed = await _reauthenticateUser(user);
          if (!reauthed) {
            debugPrint('❌ SettingsPage: Reautenticação falhou ou cancelada');
            return;
          }
          
          // Mostrar loading novamente
          if (mounted) {
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const PopScope(
                canPop: false,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppRadioPulseLoader(size: 40),
                          SizedBox(height: 16),
                          Text('Excluindo conta...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          
          // Tentar deletar novamente após reautenticação
          await user.delete();
        } else {
          rethrow;
        }
      }
      
      debugPrint('✅ SettingsPage: Usuário deletado - Cloud Function onUserDelete cuidará da limpeza');
      
      debugPrint('✅ SettingsPage: Conta excluída com sucesso');

      // ✅ Fechar dialog de loading - o router detectará authState == null
      // e redirecionará automaticamente para /auth
      if (mounted) {
        navigator.pop();
      }

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ SettingsPage: FirebaseAuthException ao excluir conta: ${e.code} - ${e.message}');

      // Fechar loading dialog se ainda estiver aberto
      if (mounted) {
        navigator.pop();
      }

      String errorMessage;
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Para excluir sua conta, faça login novamente e tente de novo.';
      } else {
        errorMessage = 'Erro ao excluir conta: ${e.message ?? e.code}';
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.danger, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro ao excluir conta: $e');

      // Fechar loading dialog se ainda estiver aberto
      if (mounted) {
        navigator.pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Iconsax.danger, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Erro ao excluir conta: $e'),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Reautentica o usuário com base no provedor usado
  Future<bool> _reauthenticateUser(User user) async {
    final providerData = user.providerData;
    
    if (providerData.isEmpty) {
      debugPrint('❌ SettingsPage: Nenhum provedor de autenticação encontrado');
      _showReauthError('Não foi possível identificar o método de login.');
      return false;
    }
    
    final providerId = providerData.first.providerId;
    debugPrint('🔐 SettingsPage: Provedor de autenticação: $providerId');
    
    try {
      if (providerId == 'google.com') {
        return await _reauthenticateWithGoogle(user);
      } else if (providerId == 'apple.com') {
        return await _reauthenticateWithApple(user);
      } else if (providerId == 'password') {
        return await _reauthenticateWithPassword(user);
      } else {
        debugPrint('❌ SettingsPage: Provedor não suportado: $providerId');
        _showReauthError('Método de login não suportado para reautenticação.');
        return false;
      }
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro na reautenticação: $e');
      _showReauthError('Erro ao reautenticar: $e');
      return false;
    }
  }
  
  Future<bool> _reauthenticateWithGoogle(User user) async {
    try {
      debugPrint('🔐 SettingsPage: Reautenticando com Google...');
      
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        debugPrint('⚠️ SettingsPage: Usuário cancelou Google Sign-In');
        return false;
      }
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ SettingsPage: Reautenticação Google bem-sucedida');
      return true;
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro na reautenticação Google: $e');
      rethrow;
    }
  }
  
  Future<bool> _reauthenticateWithApple(User user) async {
    try {
      debugPrint('🔐 SettingsPage: Reautenticando com Apple...');
      
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      
      await user.reauthenticateWithCredential(oauthCredential);
      debugPrint('✅ SettingsPage: Reautenticação Apple bem-sucedida');
      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('⚠️ SettingsPage: Usuário cancelou Apple Sign-In');
        return false;
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro na reautenticação Apple: $e');
      rethrow;
    }
  }
  
  Future<bool> _reauthenticateWithPassword(User user) async {
    // Mostrar dialog para digitar a senha
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PasswordReauthDialog(email: user.email ?? ''),
    );
    
    if (password == null || password.isEmpty) {
      debugPrint('⚠️ SettingsPage: Usuário cancelou entrada de senha');
      return false;
    }
    
    try {
      debugPrint('🔐 SettingsPage: Reautenticando com senha...');
      
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ SettingsPage: Reautenticação com senha bem-sucedida');
      return true;
    } catch (e) {
      debugPrint('❌ SettingsPage: Erro na reautenticação com senha: $e');
      rethrow;
    }
  }
  
  void _showReauthError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.danger, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
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

/// Dialog para reautenticação com senha
class _PasswordReauthDialog extends StatefulWidget {
  const _PasswordReauthDialog({required this.email});
  
  final String email;

  @override
  State<_PasswordReauthDialog> createState() => _PasswordReauthDialogState();
}

class _PasswordReauthDialogState extends State<_PasswordReauthDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Iconsax.lock, color: AppColors.primary),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Confirme sua senha',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para excluir sua conta, confirme sua senha:',
            style: AppTypography.bodyLight.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: AppTypography.captionLight.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Senha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Iconsax.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: AppRadioPulseLoader(size: 20, color: Colors.white),
                )
              : const Text('Confirmar'),
        ),
      ],
    );
  }

  void _submit() {
    if (_passwordController.text.isEmpty) return;
    Navigator.pop(context, _passwordController.text);
  }
}

class _DeleteAccountFinalConfirmDialog extends StatefulWidget {
  const _DeleteAccountFinalConfirmDialog();

  @override
  State<_DeleteAccountFinalConfirmDialog> createState() =>
      _DeleteAccountFinalConfirmDialogState();
}

class _DeleteAccountFinalConfirmDialogState
    extends State<_DeleteAccountFinalConfirmDialog> {
  static const String _requiredText = 'EXCLUIR';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid => _controller.text.trim().toUpperCase() == _requiredText;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.7; // Máximo 70% da tela

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Iconsax.warning_2, color: AppColors.error),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              'Confirmação final',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxDialogHeight,
          minWidth: 280,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para confirmar a exclusão permanente da sua conta, digite "$_requiredText" abaixo.',
                style: AppTypography.bodyLight.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Digite $_requiredText',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_isValid) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isValid ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
          ),
          child: const Text('Excluir conta'),
        ),
      ],
    );
  }
}
