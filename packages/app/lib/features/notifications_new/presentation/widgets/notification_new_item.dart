/// WeGig - NotificationNew Item Widget
///
/// Widget para exibir item individual de notificação.
/// Implementa swipe para deletar, indicador de não lido e navegação.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/core/cache/image_cache_manager.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';
import 'package:wegig_app/features/notifications_new/presentation/controllers/notifications_new_controller.dart';
import 'package:wegig_app/features/notifications_new/presentation/utils/notification_new_action_handler.dart';

/// Widget para item de notificação individual
///
/// Features:
/// - Swipe para deletar com confirmação
/// - Indicador de não lido (ponto azul)
/// - Avatar do remetente com cache
/// - Ícone por tipo de notificação
/// - Localização do post (se aplicável)
/// - Deep link ao tocar
class NotificationNewItem extends ConsumerWidget {
  /// Cria item de notificação
  const NotificationNewItem({
    required this.notification,
    required this.profileId,
    this.type,
    super.key,
  });

  /// Notificação a exibir
  final NotificationEntity notification;

  /// ID do perfil ativo (para controller)
  final String profileId;

  /// Tipo de filtro atual (para controller)
  final NotificationType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.notificationId),
      background: _buildDismissBackground(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteConfirmation(context),
      onDismissed: (_) => _handleDelete(context, ref),
      child: _buildContent(context, ref),
    );
  }

  /// Background do swipe (vermelho com ícone de lixeira)
  Widget _buildDismissBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Iconsax.trash, color: Colors.white),
    );
  }

  /// Diálogo de confirmação de exclusão
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remover notificação'),
            content: const Text('Deseja remover esta notificação?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remover'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Executa deleção via controller
  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(notificationsNewControllerProvider(profileId, type: type)
              .notifier)
          .deleteNotification(notification.notificationId);

      if (context.mounted) {
        AppSnackBar.showSuccess(context, 'Notificação removida');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, 'Erro ao remover: $e');
      }
    }
  }

  /// Conteúdo principal do item
  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: notification.read
          ? Colors.white
          : AppColors.primary.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(),
              const SizedBox(width: 12),
              Expanded(child: _buildTextContent(context)),
              if (!notification.read) ...[
                const SizedBox(width: 8),
                _buildUnreadIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Ícone/avatar da notificação
  Widget _buildNotificationIcon() {
    // Se tem foto do remetente, usa avatar
    if (notification.senderPhoto != null &&
        notification.senderPhoto!.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: CachedNetworkImageProvider(
          notification.senderPhoto!,
          cacheManager: WeGigImageCacheManager.instance,
        ),
      );
    }

    // Senão, usa ícone baseado no tipo
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getTypeColor().withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 24,
      ),
    );
  }

  /// Ícone baseado no tipo de notificação
  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.interest:
        return Iconsax.heart5;
      case NotificationType.newMessage:
        return Iconsax.message;
      case NotificationType.postExpiring:
        return Iconsax.clock;
      case NotificationType.nearbyPost:
        return Iconsax.location;
      case NotificationType.profileMatch:
        return Iconsax.people;
      case NotificationType.interestResponse:
        return Iconsax.arrow_left_2;
      case NotificationType.postUpdated:
        return Iconsax.edit;
      case NotificationType.profileView:
        return Iconsax.eye;
      case NotificationType.savedPost:
        return Iconsax.archive_add;
      case NotificationType.system:
        return Iconsax.info_circle;
    }
  }

  /// Cor baseada no tipo de notificação
  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.interest:
        return Colors.pink;
      case NotificationType.newMessage:
        return AppColors.primary;
      case NotificationType.postExpiring:
        return Colors.orange;
      case NotificationType.nearbyPost:
        return Colors.green;
      case NotificationType.profileMatch:
        return AppColors.accent;
      case NotificationType.interestResponse:
        return Colors.blue;
      case NotificationType.postUpdated:
        return Colors.grey;
      case NotificationType.profileView:
        return Colors.purple;
      case NotificationType.savedPost:
        return Colors.amber;
      case NotificationType.system:
        return Colors.teal;
    }
  }

  /// Conteúdo textual - Formato único em linha:
  /// @username • ação • localização • tempo
  Widget _buildTextContent(BuildContext context) {
    return NotificationInlineContent(
      notification: notification,
      onMentionTap: (username) => context.pushProfileByUsername(username),
    );
  }

  /// Formata data como "há X minutos/horas/dias"
  String _formatTimeAgo(DateTime dateTime) {
    return timeago.format(dateTime, locale: 'pt_BR');
  }

  /// Indicador de não lido (ponto azul)
  Widget _buildUnreadIndicator() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  /// Trata tap na notificação
  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
    // Marca como lida via controller
    if (!notification.read) {
      ref
          .read(notificationsNewControllerProvider(profileId, type: type)
              .notifier)
          .markAsRead(notification.notificationId);
    }

    // Navega via action handler
    final handler = NotificationNewActionHandler(ref: ref, context: context);
    await handler.handle(notification);
  }
}

/// Widget que exibe conteúdo da notificação em formato inline
/// 
/// Formato: @username • ação • localização • tempo
/// Busca localização do actionData ou do Firestore (com cache)
class NotificationInlineContent extends StatefulWidget {
  const NotificationInlineContent({
    required this.notification,
    required this.onMentionTap,
    super.key,
  });

  final NotificationEntity notification;
  final void Function(String username) onMentionTap;

  @override
  State<NotificationInlineContent> createState() =>
      _NotificationInlineContentState();
}

class _NotificationInlineContentState extends State<NotificationInlineContent> {
  String? _locationText;
  bool _isLoading = true;

  /// Cache estático para localização
  static final Map<String, String?> _locationCache = {};

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final notification = widget.notification;
    final actionData = notification.actionData;

    // 1. Tenta obter do actionData (enviado pelo Cloud Function)
    if (actionData != null && actionData['city'] != null) {
      final city = actionData['city'] as String?;
      if (city != null && city.isNotEmpty) {
        if (mounted) {
          setState(() {
            _locationText = city;
            _isLoading = false;
          });
        }
        return;
      }
    }

    // 2. Tenta obter do cache ou Firestore
    final postId = notification.targetId ??
        notification.data['postId'] as String? ??
        actionData?['postId'] as String?;

    if (postId == null || postId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Verifica cache
    if (_locationCache.containsKey(postId)) {
      if (mounted) {
        setState(() {
          _locationText = _locationCache[postId];
          _isLoading = false;
        });
      }
      return;
    }

    // Busca no Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!doc.exists) {
        _locationCache[postId] = null;
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final data = doc.data();
      final city = data?['city'] as String? ?? '';
      final neighborhood = data?['neighborhood'] as String? ?? '';

      String? location;
      if (neighborhood.isNotEmpty && city.isNotEmpty) {
        location = '$neighborhood, $city';
      } else if (city.isNotEmpty) {
        location = city;
      } else if (neighborhood.isNotEmpty) {
        location = neighborhood;
      }

      _locationCache[postId] = location;
      if (mounted) {
        setState(() {
          _locationText = location;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ NotificationInlineContent: Error loading location - $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    
    // Usa senderUsername se disponível, senão usa senderName como fallback
    final senderUsername = notification.senderUsername;
    final senderName = notification.senderName ?? 'Alguém';
    
    // Username para exibição (prefere username, fallback para nome)
    final displayUsername = (senderUsername != null && senderUsername.isNotEmpty)
        ? senderUsername
        : senderName;
    final usernameDisplay = displayUsername.startsWith('@') 
        ? displayUsername 
        : '@$displayUsername';
    
    // Username limpo para navegação (sem @)
    final cleanUsernameForNav = (senderUsername != null && senderUsername.isNotEmpty)
        ? senderUsername.replaceAll('@', '')
        : ''; // Vazio se não tem username real
    
    // A ação já vem formatada no body do Cloud Function
    // Ex: "@anitta • anunciou perto de você"
    // Precisamos extrair apenas a parte da ação
    String actionText = _extractAction(notification.message);
    
    // Monta o texto formatado
    final timeAgo = timeago.format(notification.createdAt, locale: 'pt_BR');
    
    // Constrói partes do texto (sem o username)
    final restParts = <String>[];
    
    if (actionText.isNotEmpty) {
      restParts.add(actionText);
    }
    
    if (_locationText != null && _locationText!.isNotEmpty) {
      restParts.add(_locationText!);
    }
    
    restParts.add(timeAgo);
    
    final restText = restParts.join(' • ');

    // Constrói RichText com @username clicável separadamente
    return Text.rich(
      TextSpan(
        children: [
          // @username clicável - navega para perfil (só se tiver username real)
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: cleanUsernameForNav.isNotEmpty
                  ? () => widget.onMentionTap(cleanUsernameForNav)
                  : null,
              child: Text(
                usernameDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          // Resto do texto (não clicável - o InkWell pai cuida)
          TextSpan(
            text: ' • $restText',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Extrai a ação do body da notificação
  /// Body pode ser: "@username • ação" ou apenas "ação"
  String _extractAction(String message) {
    // Se a mensagem já contém @, extrai a parte após o •
    if (message.contains('•')) {
      final parts = message.split('•');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    
    // Se começa com @, remove o username
    if (message.startsWith('@')) {
      final spaceIndex = message.indexOf(' ');
      if (spaceIndex > 0) {
        return message.substring(spaceIndex + 1).trim();
      }
      return '';
    }
    
    // Retorna a mensagem como está
    return message;
  }
}

/// Limpa o cache de localização inline
void clearNotificationInlineCache() {
  _NotificationInlineContentState._locationCache.clear();
}
