import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
// import 'package:wegig_app/models/user_profile.dart'; // Removido: use apenas Profile
import 'package:core_ui/core_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_switcher_provider.dart';
import 'package:wegig_app/features/profile/presentation/widgets/profile_transition_overlay.dart';
import 'package:wegig_app/features/notifications_new/presentation/providers/notifications_new_providers.dart';
import 'package:wegig_app/features/mensagens_new/presentation/providers/mensagens_new_providers.dart';

/// BottomSheet para alternar entre perfis do usuário
/// Agora com animações melhoradas e componentes do Design System
class ProfileSwitcherBottomSheet extends ConsumerWidget {
  const ProfileSwitcherBottomSheet({
    required this.activeProfileId,
    required this.onProfileSelected,
    super.key,
  });
  final String? activeProfileId;
  final void Function(String profileId) onProfileSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar com semântica para acessibilidade
          Semantics(
            label: 'Arraste para fechar',
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título com melhor tipografia
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Iconsax.repeat, color: AppColors.primary, size: 24),
                SizedBox(width: 12),
                Text(
                  'Alternar Perfil',
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de perfis - Busca da collection 'profiles'
          Flexible(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('profiles')
                  .where('uid', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.info_circle,
                            color: AppColors.error, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Erro ao carregar perfis',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  );
                }

                // Converter documentos para lista de Profiles
                final profiles = snapshot.data?.docs
                        .map((QueryDocumentSnapshot<Object?> doc) {
                          try {
                            return ProfileEntity.fromFirestore(
                                doc as DocumentSnapshot<Map<String, dynamic>>);
                          } catch (e) {
                            debugPrint(
                                'Erro ao converter perfil ${doc.id}: $e');
                            return null;
                          }
                        })
                        .where((ProfileEntity? p) => p != null)
                        .cast<ProfileEntity>()
                        .toList() ??
                    <ProfileEntity>[];

                // Se não há perfis, mostrar opção para criar primeiro perfil
                if (profiles.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.user_add,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum perfil encontrado',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crie seu primeiro perfil para começar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final result = await Navigator.push<bool?>(
                              context,
                              MaterialPageRoute<bool?>(
                                builder: (context) =>
                                    const EditProfilePage(isNewProfile: true),
                              ),
                            );
                            if (result == true && context.mounted) {
                              AppSnackBar.showSuccess(context, 'Perfil criado com sucesso!');
                            }
                          },
                          icon: const Icon(Iconsax.add),
                          label: const Text('Criar Primeiro Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: profiles.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final profile = profiles[index];
                    // ✅ FIX: Comparação correta do perfil ativo
                    final isActive = profile.profileId == activeProfileId;
                    
                    // Debug para verificar se comparação está correta
                    if (isActive) {
                      debugPrint('✅ ProfileSwitcher: Perfil ATIVO - ${profile.name} (${profile.profileId})');
                    }

                    // Card com animação FadeIn
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      opacity: 1,
                      child: Semantics(
                        label:
                            '${profile.name}, ${_getProfileTypeLabel(profile.profileType)}${isActive ? ', perfil ativo' : ''}',
                        button: true,
                        enabled: !isActive,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          // Avatar com indicador de perfil ativo
                          leading: Hero(
                            tag: 'profile-avatar-${profile.profileId}',
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: profile.photoUrl != null &&
                                      profile.photoUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                      profile.photoUrl!) as ImageProvider
                                  : null,
                              child: profile.photoUrl == null ||
                                      profile.photoUrl!.isEmpty
                                  ? const Icon(Iconsax.user, size: 30)
                                  : null,
                            ),
                          ),
                          title: Text(
                            profile.name,
                            style: AppTypography.subtitleLight.copyWith(
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w600,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(
                                _getProfileTypeIcon(profile.profileType),
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getProfileTypeLabel(profile.profileType),
                                style: AppTypography.captionLight,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Badge counter unificado para perfis não ativos
                              if (!isActive) ...[
                                _UnifiedBadgeCounter(
                                  profileId: profile.profileId,
                                  uid: profile.uid,
                                ),
                                const SizedBox(width: 12),
                              ],
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Iconsax.tick_circle,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('Ativo',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12)),
                                    ],
                                  ),
                                )
                              else
                                const Icon(
                                  Iconsax.arrow_right_3,
                                  color: AppColors.textSecondary,
                                ),
                              // Menu de opções (editar/excluir)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Iconsax.more,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _editProfile(context, profile);
                                  } else if (value == 'delete') {
                                    _deleteProfile(context, ref, profile);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Iconsax.edit,
                                            size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    enabled: !isActive, // ✅ Não permite excluir perfil ativo
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.trash,
                                          size: 18,
                                          color: !isActive
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Excluir',
                                          style: TextStyle(
                                            color: !isActive
                                                ? AppColors.error
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: isActive
                              ? null
                              : () async {
                                  // Fecha o modal primeiro
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }

                                  // Aguarda um frame para garantir que o modal foi fechado
                                  await Future<void>.delayed(
                                    const Duration(milliseconds: 100),
                                  );

                                  if (!context.mounted) return;

                                  try {
                                    // Mostra overlay e aguarda
                                    final overlayFuture =
                                        ProfileTransitionOverlay.show(
                                      context,
                                      profileName: profile.name,
                                      profileType: profile.profileType.name,
                                      photoUrl: profile.photoUrl,
                                      onComplete: () {
                                        // Chama o callback para recarregar os dados
                                        onProfileSelected(profile.profileId);
                                      },
                                    );

                                    // ✅ NOVO: Usar ProfileSwitcherNotifier centralizado
                                    // Troca perfil + invalida TODOS os caches automaticamente
                                    await Future.wait(<Future<dynamic>>[
                                      ref.read(profileSwitcherNotifierProvider.notifier)
                                          .switchToProfile(profile.profileId),
                                      Future<void>.delayed(const Duration(
                                        milliseconds: 1300,
                                      )), // Duração mínima do overlay
                                    ]);

                                    // Aguarda o overlay fechar completamente
                                    await overlayFuture;
                                  } catch (e) {
                                    // Fecha overlay se houver erro
                                    if (context.mounted) {
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                    }

                                    // Mostra mensagem de erro
                                    // Error already shown by AppSnackBar above
                                  }
                                },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Botão adicionar novo perfil com gradiente (esconde quando há 5 perfis)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('profiles')
                .where('uid', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final profileCount = snapshot.data?.docs.length ?? 0;
              
              // Esconder botão se já tem 5 perfis
              if (profileCount >= 5) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Você atingiu o limite de 5 perfis',
                    style: AppTypography.captionLight.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(
                  label: 'Adicionar novo perfil',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute<String?>(
                          builder: (context) =>
                              const EditProfilePage(isNewProfile: true),
                        ),
                      );

                      if (result is String && result.isNotEmpty) {
                        onProfileSelected(result);

                        if (context.mounted) {
                          AppSnackBar.showSuccess(
                            context,
                            'Novo perfil ativado!',
                          );
                        }
                      }
                    },
                    icon: const Icon(Iconsax.user_add),
                    label: const Text('Adicionar Novo Perfil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// ✅ Obtém o ícone baseado no tipo de perfil
  IconData _getProfileTypeIcon(ProfileType profileType) {
    switch (profileType) {
      case ProfileType.band:
        return Iconsax.people;
      case ProfileType.space:
        return Iconsax.building;
      case ProfileType.musician:
        return Iconsax.user;
    }
  }

  /// ✅ Obtém o label baseado no tipo de perfil
  String _getProfileTypeLabel(ProfileType profileType) {
    switch (profileType) {
      case ProfileType.band:
        return 'Banda';
      case ProfileType.space:
        return 'Espaço';
      case ProfileType.musician:
        return 'Músico';
    }
  }

  /// Edita um perfil existente
  Future<void> _editProfile(BuildContext context, ProfileEntity profile) async {
    Navigator.pop(context); // Fecha o bottom sheet

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute<String?>(
        builder: (context) =>
            EditProfilePage(profileIdToEdit: profile.profileId),
      ),
    );

    // Se retornou um profileId (String), perfil foi editado
    if (result is String && result.isNotEmpty && context.mounted) {
      // Recarrega dados através do callback
      onProfileSelected(result);

      AppSnackBar.showSuccess(context, 'Perfil atualizado!');
    }
  }

  /// Exclui um perfil com confirmação
  Future<void> _deleteProfile(
      BuildContext context, WidgetRef ref, ProfileEntity profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ✅ Obter todos os perfis do provider
    final profileState = ref.read(profileProvider);
    final allProfiles = profileState.value?.profiles ?? <ProfileEntity>[];
    final activeProfile = profileState.value?.activeProfile;

    // ✅ Verifica se tem mais de um perfil
    if (allProfiles.length <= 1) {
      AppSnackBar.showWarning(context, 'Você deve ter pelo menos um perfil');
      return;
    }

    // ✅ Não permite excluir o perfil ativo
    if (profile.profileId == activeProfile?.profileId) {
      AppSnackBar.showWarning(
        context,
        'Para excluir este perfil, primeiro troque para outro perfil',
      );
      return;
    }

    // Diálogo de confirmação com animação
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Iconsax.warning_2, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tem certeza que deseja excluir o perfil "${profile.name}"?',
              style: AppTypography.bodyLight,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle,
                      size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita.',
                      style: AppTypography.captionLight.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // ✅ CORREÇÃO: Capturar TODAS as referências ANTES de fechar o bottom sheet
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final profileNotifier = ref.read(profileProvider.notifier);
    final profileIdToDelete = profile.profileId;

    try {
      debugPrint('🗑️ ProfileSwitcher: Iniciando deleção do perfil $profileIdToDelete');
      
      // ✅ CORREÇÃO: Executar deleção ANTES de fechar o bottom sheet
      await profileNotifier.deleteProfile(profileIdToDelete);

      debugPrint('✅ ProfileSwitcher: Perfil deletado com sucesso');

      // ✅ CORREÇÃO: Fechar o bottom sheet DEPOIS da deleção bem-sucedida
      navigator.pop();

      // ✅ CORREÇÃO: Usar scaffoldMessenger salvo anteriormente
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Perfil excluído com sucesso'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('❌ ProfileSwitcher: Erro ao deletar perfil - $e');
      
      // ✅ CORREÇÃO: Usar scaffoldMessenger salvo anteriormente
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao excluir perfil: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Mostra o BottomSheet de alternância de perfis
  static void show(
    BuildContext context, {
    required String? activeProfileId,
    required void Function(String) onProfileSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProfileSwitcherBottomSheet(
        activeProfileId: activeProfileId,
        onProfileSelected: onProfileSelected,
      ),
    );
  }
}

/// Widget: Badge counter unificado para notificações + mensagens de um perfil
/// Padrão: Circular/oblongo com cor #FF2828
class _UnifiedBadgeCounter extends ConsumerWidget {
  const _UnifiedBadgeCounter({
    required this.profileId,
    required this.uid,
  });
  final String profileId;
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Soma de notificações + mensagens
    // ✅ FIX: Passar uid para match com Security Rules
    final notificationsAsync = ref.watch(unreadNotificationCountNewStreamProvider(profileId, uid));
    final messagesAsync = ref.watch(unreadMessagesNewCountProvider(profileId: profileId, profileUid: uid));
    
    // Aguardar ambos os providers carregarem
    if (notificationsAsync.isLoading || messagesAsync.isLoading) {
      return const SizedBox.shrink();
    }
    
    final notificationCount = notificationsAsync.value ?? 0;
    final messageCount = messagesAsync.value ?? 0;
    final totalCount = notificationCount + messageCount;
    
    if (totalCount <= 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.badgeRed,
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
      ),
      child: Text(
        totalCount > 99 ? '99+' : totalCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
