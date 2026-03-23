import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/utils/deep_link_generator.dart';

import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/report/presentation/providers/report_providers.dart';
import 'package:wegig_app/features/report/presentation/widgets/report_dialog.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';

/// Exibe um modal bottom sheet com opções para um perfil (apenas Compartilhar e Reportar).
/// 
/// [context] - BuildContext para exibir o modal
/// [profileId] - ID do perfil
/// [userId] - UID do usuário dono do perfil
/// [profileName] - Nome do perfil para compartilhamento
/// [isBand] - Se é um perfil de banda
/// [city] - Cidade do perfil
/// [neighborhood] - Bairro do perfil (opcional)
/// [state] - Estado do perfil (opcional)
/// [instruments] - Lista de instrumentos (opcional)
/// [genres] - Lista de gêneros (opcional)
void showProfileOptionsDialog({
  required BuildContext context,
  required String profileId,
  required String userId,
  required String profileName,
  required bool isBand,
  required String city,
  String? username,
  String? photoUrl,
  String? neighborhood,
  String? state,
  List<String> instruments = const [],
  List<String> genres = const [],
}) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Consumer(
      builder: (consumerContext, ref, _) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          const SizedBox(height: 8),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Compartilhar
          ListTile(
            leading: const Icon(Iconsax.share, color: AppColors.primary),
            title: const Text('Compartilhar'),
            onTap: () {
              Navigator.pop(ctx);
              _shareProfile(
                profileId: profileId,
                userId: userId,
                profileName: profileName,
                isBand: isBand,
                city: city,
                neighborhood: neighborhood,
                state: state,
                instruments: instruments,
                genres: genres,
              );
            },
          ),
          
          // Reportar
          ListTile(
            leading: Icon(Iconsax.flag, color: Colors.orange.shade700),
            title: const Text('Denunciar'),
            onTap: () {
              Navigator.pop(ctx);
              showReportDialog(
                context: context,
                targetType: ReportTargetType.profile,
                targetId: profileId,
                targetName: profileName,
                ownerUid: userId,
                ownerProfileId: profileId,
                ownerName: profileName,
                ownerUsername: username,
                ownerPhotoUrl: photoUrl,
                ownerCity: city,
                ownerNeighborhood: neighborhood,
                ownerState: state,
                ownerIsBand: isBand,
              );
            },
          ),

          // Bloquear
          ListTile(
            leading: const Icon(Iconsax.user_remove, color: Colors.red),
            title: const Text('Bloquear'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Bloquear perfil?'),
                  content: Text(
                    'Você não verá mais conteúdo de "$profileName" no feed e busca.\n\nDeseja continuar?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text('Bloquear'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              if (!ctx.mounted) return;
              Navigator.pop(ctx);

              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Você precisa estar logado.')),
                  );
                }
                return;
              }

              final blockerProfile = ref.read(activeProfileProvider);
              if (blockerProfile == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nenhum perfil ativo.')),
                  );
                }
                return;
              }

              if (profileId == blockerProfile.profileId) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Não é possível bloquear a si mesmo.')),
                  );
                }
                return;
              }

              try {
                final firestore = FirebaseFirestore.instance;
                final reportNotifier = ref.read(reportNotifierProvider.notifier);

                // Add to profiles/{profileId}.blockedProfileIds
                await BlockedProfiles.add(
                  firestore: firestore,
                  blockerProfileId: blockerProfile.profileId,
                  blockedProfileId: profileId,
                );

                // Edge compartilhável para reverse visibility.
                try {
                  await BlockedRelations.create(
                    firestore: firestore,
                    blockedByProfileId: blockerProfile.profileId,
                    blockedProfileId: profileId,
                    blockedByUid: currentUser.uid,
                    blockedUid: userId,
                  );
                } catch (e) {
                  debugPrint('⚠️ blocks edge write failed (non-critical): $e');
                }

                // Report automático para auditoria/moderação (best-effort)
                try {
                  await reportNotifier.submitReport(
                        ReportData(
                          targetType: ReportTargetType.profile,
                          targetId: profileId,
                          reason: 'Blocked abusive user',
                          description: 'Auto-report ao bloquear. blockedProfileId=$profileId',
                        ),
                      );
                } catch (e) {
                  debugPrint('⚠️ Auto-report on block failed (non-critical): $e');
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$profileName" foi bloqueado.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao bloquear: $e')),
                  );
                }
              }
            },
          ),
          
          const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

/// Compartilha o perfil usando deep link
void _shareProfile({
  required String profileId,
  required String userId,
  required String profileName,
  required bool isBand,
  required String city,
  String? neighborhood,
  String? state,
  List<String> instruments = const [],
  List<String> genres = const [],
}) {
  final message = DeepLinkGenerator.generateProfileShareMessage(
    name: profileName,
    isBand: isBand,
    city: city,
    neighborhood: neighborhood,
    state: state,
    userId: userId,
    profileId: profileId,
    instruments: instruments,
    genres: genres,
  );
  
  SharePlus.instance.share(ShareParams(text: message));
}

/// Exibe um modal bottom sheet com opções para um post.
/// 
/// [context] - BuildContext para exibir o modal
/// [post] - PostEntity do post em questão
/// [isInterestSent] - Se o usuário atual já demonstrou interesse
/// [isOwner] - Se o usuário atual é dono do post
/// [onSendInterest] - Callback para enviar interesse
/// [onRemoveInterest] - Callback para remover interesse
/// [onDeletePost] - Callback para deletar o post (apenas owner)
/// [onViewProfile] - Callback para ver perfil do autor
/// [onPostEdited] - Callback quando o post é editado com sucesso
/// [onRepost] - Callback para renovar/repostar o post (apenas owner, expirado ou expirando)
void showInterestOptionsDialog({
  required BuildContext context,
  required PostEntity post,
  required bool isInterestSent,
  required bool isOwner,
  required VoidCallback onSendInterest,
  required VoidCallback onRemoveInterest,
  required VoidCallback onDeletePost,
  required VoidCallback onViewProfile,
  VoidCallback? onPostEdited,
  VoidCallback? onRepost,
}) {
  final isSalesPost = post.type == 'sales';
  final isExpired = post.expiresAt.isBefore(DateTime.now());
  final isExpiringSoon = !isExpired && post.expiresAt.difference(DateTime.now()).inDays <= 1;

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          
          // Opções para o dono do post
          if (isOwner) ...[
            // Renovar/Repostar (para posts expirados ou expirando em breve)
            if ((isExpired || isExpiringSoon) && onRepost != null)
              ListTile(
                leading: Icon(
                  Iconsax.refresh,
                  color: isExpired ? Colors.red.shade700 : Colors.orange.shade700,
                ),
                title: Text(isExpired ? 'Repostar (+30 dias)' : 'Renovar (+30 dias)'),
                subtitle: Text(
                  isExpired
                      ? 'Post expirado — renove para torná-lo visível novamente'
                      : 'Post expira em breve — renove agora',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onRepost!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Editar Post'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.of(context).push<bool?>(
                  MaterialPageRoute<bool?>(
                    builder: (_) => PostPage(
                      postType: post.type,
                      existingPostData: _buildExistingPostData(post),
                    ),
                  ),
                );
                if (result == true) {
                  onPostEdited?.call();
                }
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.trash, color: Colors.red),
              title: const Text('Deletar Post'),
              onTap: () {
                Navigator.pop(ctx);
                onDeletePost();
              },
            ),
          ]
          // Opções para outros usuários (não donos)
          else ...[
            // Interesse / Salvar
            if (isInterestSent)
              ListTile(
                leading: Icon(
                  isSalesPost ? Iconsax.tag5 : Iconsax.heart5,
                  color: isSalesPost ? AppColors.primary : Colors.pink,
                  size: 24,
                ),
                title: Text(isSalesPost ? 'Remover dos Salvos' : 'Remover Interesse'),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemoveInterest();
                },
              )
            else
              ListTile(
                leading: Icon(
                  isSalesPost ? Iconsax.tag : Iconsax.heart5,
                  color: isSalesPost ? AppColors.primary : Colors.pink,
                  size: 24,
                ),
                title: Text(isSalesPost ? 'Salvar Anúncio' : 'Demonstrar Interesse'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSendInterest();
                },
              ),
            
            // Ver Perfil
            ListTile(
              leading: const Icon(Iconsax.user, color: AppColors.primary),
              title: const Text('Ver Perfil'),
              onTap: () {
                Navigator.pop(ctx);
                onViewProfile();
              },
            ),
            
            // Compartilhar
            ListTile(
              leading: const Icon(Iconsax.share, color: AppColors.primary),
              title: const Text('Compartilhar'),
              onTap: () {
                Navigator.pop(ctx);
                _sharePost(post);
              },
            ),
            
            // Reportar
            ListTile(
              leading: Icon(Iconsax.flag, color: Colors.orange.shade700),
              title: const Text('Denunciar'),
              onTap: () {
                Navigator.pop(ctx);
                showReportDialog(
                  context: context,
                  targetType: ReportTargetType.post,
                  targetId: post.id,
                  targetName: post.authorName ?? post.title ?? 'Post',
                   ownerUid: post.authorUid,
                   ownerProfileId: post.authorProfileId,
                   ownerName: post.authorName,
                   ownerPhotoUrl: post.authorPhotoUrl,
                   ownerCity: post.city,
                   ownerNeighborhood: post.neighborhood,
                   ownerState: post.state,
                );
              },
            ),
          ],
          
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Compartilha o post usando deep link
void _sharePost(PostEntity post) {
  final text = DeepLinkGenerator.generatePostShareMessage(
    postId: post.id,
    authorName: post.authorName ?? 'Anônimo',
    postType: post.type,
    city: post.city,
    neighborhood: post.neighborhood,
    state: post.state,
    content: post.content,
    instruments: post.instruments,
    genres: post.genres,
    title: post.title,
    salesType: post.salesType,
    price: post.price,
    discountMode: post.discountMode,
    discountValue: post.discountValue,
  );
  
  SharePlus.instance.share(ShareParams(text: text));
}

/// Constrói o mapa de dados existentes do post para edição
Map<String, dynamic> _buildExistingPostData(PostEntity post) {
  return {
    // CAMPOS COMUNS A TODOS OS TIPOS
    'postId': post.id,
    'content': post.content,
    'photoUrls': post.photoUrls,
    'youtubeLink': post.youtubeLink,
    'spotifyLink': post.spotifyLink,
    'deezerLink': post.deezerLink,
    'location': GeoPoint(post.location.latitude, post.location.longitude),
    'city': post.city,
    'neighborhood': post.neighborhood,
    'state': post.state,
    'createdAt': post.createdAt,
    'expiresAt': post.expiresAt,
    
    // CAMPOS ESPECÍFICOS DE MUSICIAN/BAND
    'instruments': post.instruments,
    'genres': post.genres,
    'seekingMusicians': post.seekingMusicians,
    'level': post.level,
    'availableFor': post.availableFor,

    // CAMPOS ESPECÍFICOS DE HIRING
    'eventDate': post.eventDate,
    'eventType': post.eventType,
    'gigFormat': post.gigFormat,
    'venueSetup': post.venueSetup,
    'budgetRange': post.budgetRange,
    'eventStartTime': post.eventStartTime,
    'eventEndTime': post.eventEndTime,
    'eventDurationMinutes': post.eventDurationMinutes,
    'guestCount': post.guestCount,
    
    // CAMPOS ESPECÍFICOS DE SALES
    'title': post.title,
    'salesType': post.salesType,
    'price': post.price,
    'discountMode': post.discountMode,
    'discountValue': post.discountValue,
    'promoStartDate': post.promoStartDate,
    'promoEndDate': post.promoEndDate,
    'whatsappNumber': post.whatsappNumber,
  };
}
