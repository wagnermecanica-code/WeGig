import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:wegig_app/models/user_profile.dart'; // Removido: use apenas Profile
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/theme/app_typography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wegig_app/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/profile/presentation/widgets/profile_transition_overlay.dart';

/// BottomSheet para alternar entre perfis do usuário
/// Agora com animações melhoradas e componentes do Design System
class ProfileSwitcherBottomSheet extends ConsumerWidget {
  const ProfileSwitcherBottomSheet({
    required this.activeProfileId,
    required this.onProfileSelected,
    super.key,
  });
  final String? activeProfileId;
  final Function(String profileId) onProfileSelected;

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
                Icon(Icons.swap_horiz, color: AppColors.primary, size: 24),
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
                        Icon(Icons.error_outline,
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
                          Icons.person_add_outlined,
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
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EditProfilePage(isNewProfile: true),
                              ),
                            );
                            if (result == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Perfil criado com sucesso!'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
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
                    final isActive = profile.profileId == activeProfileId;

                    // Card com animação FadeIn
                    return AnimatedOpacity(
                      duration: Duration(milliseconds: 200 + (index * 50)),
                      opacity: 1,
                      child: Semantics(
                        label:
                            '${profile.name}, ${profile.isBand ? 'Banda' : 'Músico'}${isActive ? ', perfil ativo' : ''}',
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
                                  ? const Icon(Icons.person, size: 28)
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
                                profile.isBand ? Icons.groups : Icons.person,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.isBand ? 'Banda' : 'Músico',
                                style: AppTypography.captionLight,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Badge counters para perfis não ativos
                              if (!isActive) ...[
                                _ProfileBadgeCounter(
                                  profileId: profile.profileId,
                                  icon: Icons.notifications,
                                  isNotification: true,
                                ),
                                const SizedBox(width: 4),
                                _ProfileBadgeCounter(
                                  profileId: profile.profileId,
                                  icon: Icons.message,
                                  isNotification: false,
                                ),
                                const SizedBox(width: 8),
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
                                      Icon(Icons.check_circle,
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
                                  Icons.chevron_right,
                                  color: AppColors.textSecondary,
                                ),
                              // Menu de opções (editar/excluir)
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
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
                                        Icon(Icons.edit,
                                            size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    enabled: profile.profileId !=
                                        user.uid, // Não permite excluir perfil principal
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: profile.profileId != user.uid
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Excluir',
                                          style: TextStyle(
                                            color: profile.profileId != user.uid
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
                                  await Future.delayed(
                                      const Duration(milliseconds: 100));

                                  if (!context.mounted) return;

                                  try {
                                    // Mostra overlay e aguarda
                                    final overlayFuture =
                                        ProfileTransitionOverlay.show(
                                      context,
                                      profileName: profile.name,
                                      isBand: profile.isBand,
                                      photoUrl: profile.photoUrl,
                                      onComplete: () {
                                        // Chama o callback para recarregar os dados
                                        onProfileSelected(profile.profileId);
                                      },
                                    );

                                    // Atualiza o perfil ativo usando ProfileRepository
                                    // Faz isso em paralelo com a animação do overlay
                                    // TODO: Implementar switchActiveProfile via profileProvider
                                    await Future.wait(<Future<dynamic>>[
                                      Future.delayed(const Duration(
                                          milliseconds: 100)), // Placeholder
                                      Future.delayed(const Duration(
                                          milliseconds:
                                              1300)), // Duração mínima do overlay
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
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.error,
                                                  color: Colors.white),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: Text(
                                                      'Erro ao trocar perfil: $e')),
                                            ],
                                          ),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
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

          // Botão adicionar novo perfil com gradiente
          Padding(
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: 'Adicionar novo perfil',
              button: true,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const EditProfilePage(isNewProfile: true),
                    ),
                  );
                  // Se retornou um profileId (String), perfil foi criado com sucesso
                  if (result is String && result.isNotEmpty) {
                    try {
                      // Atualiza activeProfileId para o novo perfil
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({'activeProfileId': result});

                      // Chama callback para recarregar dados
                      onProfileSelected(result);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Perfil alterado'),
                              ],
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(
                                    child:
                                        Text('Erro ao ativar novo perfil: $e')),
                              ],
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Adicionar Novo Perfil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Edita um perfil existente
  Future<void> _editProfile(BuildContext context, ProfileEntity profile) async {
    Navigator.pop(context); // Fecha o bottom sheet

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfilePage(profileIdToEdit: profile.profileId),
      ),
    );

    // Se retornou um profileId (String), perfil foi editado
    if (result is String && result.isNotEmpty && context.mounted) {
      // Recarrega dados através do callback
      onProfileSelected(result);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Perfil atualizado!'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Exclui um perfil com confirmação
  Future<void> _deleteProfile(
      BuildContext context, WidgetRef ref, ProfileEntity profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Não permite excluir perfil principal
    if (profile.profileId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                  child: Text('Não é possível excluir o perfil principal')),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
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
            Icon(Icons.warning_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 12),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja excluir o perfil "${profile.name}"?',
              style: AppTypography.bodyLight,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
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

    try {
      // TODO: Implementar getAllProfiles via profileProvider
      final profileState = ref.read(profileProvider);
      final allProfiles = profileState.value?.profiles ?? <ProfileEntity>[];

      // Verifica se tem mais de um perfil
      if (allProfiles.length <= 1) {
        if (context.mounted) {
          // Não fecha o bottom sheet, apenas mostra o erro.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text('Você precisa ter pelo menos um perfil')),
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Fecha o bottom sheet antes de excluir
      if (context.mounted) {
        Navigator.pop(context);
      }

      // TODO: Implementar deleteProfile via profileProvider
      await ref.read(profileProvider.notifier).deleteProfile(profile.profileId);

      if (context.mounted) {
        // Se excluiu o perfil ativo, recarrega com o novo perfil ativo
        final newActiveProfile =
            ref.read(profileProvider).value?.activeProfile;
        if (newActiveProfile != null) {
          onProfileSelected(newActiveProfile.profileId);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Perfil excluído com sucesso'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao excluir perfil: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Mostra o BottomSheet de alternância de perfis
  static void show(
    BuildContext context, {
    required String? activeProfileId,
    required Function(String) onProfileSelected,
  }) {
    showModalBottomSheet(
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

/// Widget: Badge counter para notificações/mensagens de um perfil específico
class _ProfileBadgeCounter extends ConsumerWidget {
  const _ProfileBadgeCounter({
    required this.profileId,
    required this.icon,
    required this.isNotification,
  });
  final String profileId;
  final IconData icon;
  final bool isNotification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implementar unread count providers para notificações e mensagens
    // Temporariamente desabilitado
    return const SizedBox.shrink();

    /* CÓDIGO ORIGINAL COMENTADO - REQUER IMPLEMENTAÇÃO DOS PROVIDERS
    // Obter o AsyncValue do provider correto baseado no tipo
    final countAsync = isNotification
        ? ref.watch(unreadNotificationCountForProfileProvider(profileId))
        : ref.watch(unreadMessageCountForProfileProvider(profileId));
    
    return countAsync.when(
      data: (int count) {
        if (count <= 0) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: Colors.white),
              const SizedBox(width: 2),
              Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
    */
  }
}
