import 'package:core_ui/core_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/notifications/presentation/providers/push_notification_provider.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:iconsax/iconsax.dart';

/// Página de configurações de notificações
///
/// Permite o usuário:
/// - Habilitar/desabilitar push notifications
/// - Configurar raio de notificações de posts próximos
/// - Ver status de permissões
/// - Testar notificações
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(activeProfileProvider);

    if (activeProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificações')),
        body: const Center(child: Text('Nenhum perfil ativo')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status de permissão
          _buildPermissionCard(),
          const SizedBox(height: 16),

          // Configurações de notificações de posts próximos
          _buildProximityNotificationsCard(activeProfile),
          const SizedBox(height: 16),

          // Configurações de tipos de notificação
          _buildNotificationTypesCard(),
          const SizedBox(height: 16),

          // Botão de teste
          _buildTestButton(),
        ],
      ),
    );
  }

  /// Card com status de permissão
  Widget _buildPermissionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.notification_bing, color: AppColors.accent),
                SizedBox(width: 12),
                Text(
                  'Status das Notificações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<NotificationSettings>(
              future: FirebaseMessaging.instance.getNotificationSettings(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                }
                final status = snapshot.data!.authorizationStatus;
                final isAuthorized = status == AuthorizationStatus.authorized;
                return Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAuthorized ? Iconsax.tick_circle : Iconsax.danger,
                          color: isAuthorized
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isAuthorized
                                ? 'Notificações habilitadas'
                                : 'Notificações desabilitadas',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    if (!isAuthorized) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _requestPermission,
                          icon: const Icon(Iconsax.notification),
                          label: const Text('Solicitar Permissão'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Card de configurações de posts próximos
  Widget _buildProximityNotificationsCard(ProfileEntity activeProfile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.location, color: AppColors.accent),
                SizedBox(width: 12),
                Text(
                  'Posts Próximos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Receba notificações quando novos posts forem criados próximos a você',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value:
                  (activeProfile.notificationRadiusEnabled as bool?) ?? false,
              onChanged: _toggleProximityNotifications,
              title: const Text('Ativar notificações de proximidade'),
              thumbColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => states.contains(MaterialState.selected)
                    ? AppColors.accent
                    : AppColors.border,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if ((activeProfile.notificationRadiusEnabled as bool?) ??
                false) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Raio: ${((activeProfile.notificationRadius as num?) ?? 20).toInt()} km',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Slider(
                value: ((activeProfile.notificationRadius as num?) ?? 20)
                    .toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                label: '${activeProfile.notificationRadius.toInt()} km',
                activeColor: AppColors.accent,
                onChanged: _updateNotificationRadius,
              ),
              const Text(
                'Você será notificado quando posts forem criados dentro deste raio',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card de tipos de notificação
  Widget _buildNotificationTypesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Iconsax.setting_2, color: AppColors.accent),
                SizedBox(width: 12),
                Text(
                  'Tipos de Notificação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationTypeItem(
              icon: Iconsax.location,
              title: 'Posts próximos',
              description: 'Novos posts na sua região',
              enabled: true,
            ),
            const Divider(),
            _buildNotificationTypeItem(
              icon: Iconsax.heart5,
              title: 'Interesses',
              description: 'Quando alguém demonstra interesse no seu post',
              enabled: true,
            ),
            const Divider(),
            _buildNotificationTypeItem(
              icon: Iconsax.message,
              title: 'Mensagens',
              description: 'Novas mensagens no chat',
              enabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeItem({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: enabled ? AppColors.accent : AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Iconsax.tick_circle : Iconsax.close_circle,
            color: enabled ? AppColors.success : AppColors.textHint,
          ),
        ],
      ),
    );
  }

  /// Botão para testar notificações
  Widget _buildTestButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Testar Notificações',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Envie uma notificação de teste para verificar se está funcionando',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendTestNotification,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.send_2),
                label: Text(_isLoading ? 'Enviando...' : 'Enviar Teste'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Solicita permissão de notificações
  Future<void> _requestPermission() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Usar PushNotificationService
      final pushService = ref.read(pushNotificationServiceProvider);
      final settings = await pushService.requestPermission();

      if (!mounted) return;

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Salvar token para perfil ativo
        final activeProfile = ref.read(activeProfileProvider);
        if (activeProfile != null) {
          await pushService.saveTokenForProfile(activeProfile.profileId);
        }

        AppSnackBar.showSuccess(context, '✅ Permissão concedida!');

        // Rebuild UI
        if (!mounted) return;
        setState(() {});
      } else {
        AppSnackBar.showError(context, '❌ Permissão negada');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Alterna notificações de proximidade
  Future<void> _toggleProximityNotifications(bool enabled) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final updatedProfile = activeProfile.copyWith(
        notificationRadiusEnabled: enabled,
      );
      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

      // Invalidar provider para atualizar UI
      ref.invalidate(profileProvider);

      if (!mounted) return;
      AppSnackBar.showSuccess(
        context,
        enabled
            ? '✅ Notificações de proximidade ativadas'
            : '🔕 Notificações de proximidade desativadas',
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Erro: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Atualiza raio de notificações
  Future<void> _updateNotificationRadius(double radius) async {
    final activeProfile = ref.read(activeProfileProvider);
    if (activeProfile == null) return;

    try {
      final updatedProfile = activeProfile.copyWith(
        notificationRadius: radius,
      );
      await ref.read(profileProvider.notifier).updateProfile(updatedProfile);

      // Invalidar provider para atualizar UI
      ref.invalidate(profileProvider);
    } catch (e) {
      debugPrint('Erro ao atualizar raio: $e');
    }
  }

  /// Envia notificação de teste
  Future<void> _sendTestNotification() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final activeProfile = ref.read(activeProfileProvider);

      if (activeProfile == null) {
        throw Exception('Nenhum perfil ativo');
      }

      // Criar notificação in-app de teste usando NotificationService
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.create(
        recipientProfileId: activeProfile.profileId,
        type: 'system',
        title: '🧪 Notificação de Teste',
        body: 'Push notifications estão funcionando perfeitamente!',
        data: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (!mounted) return;

      AppSnackBar.showSuccess(
        context,
        '✅ Notificação de teste enviada! Verifique a aba de notificações.',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Erro ao enviar teste: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
