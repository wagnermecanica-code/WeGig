import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';

import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:core_ui/utils/deep_link_generator.dart';

import 'package:wegig_app/features/post/presentation/pages/post_page.dart';
import 'package:wegig_app/features/report/presentation/providers/report_providers.dart';
import 'package:wegig_app/features/report/presentation/widgets/report_dialog.dart';

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
            title: const Text('Reportar'),
            onTap: () {
              Navigator.pop(ctx);
              showReportDialog(
                context: context,
                targetType: ReportTargetType.profile,
                targetId: profileId,
                targetName: profileName,
              );
            },
          ),
          
          const SizedBox(height: 8),
        ],
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
}) {
  final isSalesPost = post.type == 'sales';

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
              title: const Text('Reportar'),
              onTap: () {
                Navigator.pop(ctx);
                showReportDialog(
                  context: context,
                  targetType: ReportTargetType.post,
                  targetId: post.id,
                  targetName: post.authorName ?? post.title ?? 'Post',
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
