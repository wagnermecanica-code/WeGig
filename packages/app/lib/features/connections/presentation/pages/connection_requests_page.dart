import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_router.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/connection_request_entity.dart';
import '../providers/connections_providers.dart';

enum ConnectionRequestsPageMode { received, sent }

class ConnectionRequestsPage extends ConsumerWidget {
  const ConnectionRequestsPage.received({super.key})
      : mode = ConnectionRequestsPageMode.received;

  const ConnectionRequestsPage.sent({super.key})
      : mode = ConnectionRequestsPageMode.sent;

  final ConnectionRequestsPageMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final actionState = ref.watch(connectionsActionsProvider);

    if (activeProfile == null) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Selecione um perfil.'),
          ),
        ),
      );
    }

    final stream = mode == ConnectionRequestsPageMode.received
        ? ref.watch(
            pendingReceivedRequestsStreamProvider(
              profileId: activeProfile.profileId,
              profileUid: activeProfile.uid,
            ),
          )
        : ref.watch(
            pendingSentRequestsStreamProvider(
              profileId: activeProfile.profileId,
              profileUid: activeProfile.uid,
            ),
          );

    final pageTitle = mode == ConnectionRequestsPageMode.received
        ? 'Convites recebidos'
        : 'Convites enviados';

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle)),
      body: stream.when(
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  mode == ConnectionRequestsPageMode.received
                      ? 'Nenhum convite pendente para aceitar.'
                      : 'Nenhum convite enviado aguardando resposta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final isReceived = mode == ConnectionRequestsPageMode.received;
              final title = isReceived
                  ? request.requesterName
                  : request.recipientName;
              final subtitle = isReceived
                  ? _receivedRequestSubtitle(request)
                  : _sentRequestSubtitle(request);
              final photoUrl = isReceived
                  ? request.requesterPhotoUrl
                  : request.recipientPhotoUrl;
              final targetProfileId = isReceived
                  ? request.requesterProfileId
                  : request.recipientProfileId;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.pushProfile(targetProfileId),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _RequestAvatar(photoUrl: photoUrl, label: title),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isReceived) ...[
                            IconButton.outlined(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => ref
                                      .read(connectionsActionsProvider.notifier)
                                      .declineRequest(
                                        requestId: request.id,
                                        otherProfileId:
                                            request.requesterProfileId,
                                      ),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Recusar',
                              iconSize: 20,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(36, 36),
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.5),
                                ),
                                foregroundColor: AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton.filledTonal(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => ref
                                      .read(connectionsActionsProvider.notifier)
                                      .acceptRequest(
                                        requestId: request.id,
                                        otherProfileId:
                                            request.requesterProfileId,
                                      ),
                              icon: const Icon(Icons.check_rounded),
                              tooltip: 'Aceitar',
                              iconSize: 20,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(36, 36),
                                backgroundColor:
                                    AppColors.salesBlue.withValues(alpha: 0.18),
                                foregroundColor: AppColors.salesBlue,
                              ),
                            ),
                          ] else
                            IconButton.outlined(
                              onPressed: actionState.isLoading
                                  ? null
                                  : () => ref
                                      .read(connectionsActionsProvider.notifier)
                                      .cancelRequest(
                                        requestId: request.id,
                                        otherProfileId:
                                            request.recipientProfileId,
                                      ),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Cancelar',
                              iconSize: 20,
                              style: IconButton.styleFrom(
                                minimumSize: const Size(36, 36),
                                side: BorderSide(
                                  color: AppColors.error.withValues(alpha: 0.5),
                                ),
                                foregroundColor: AppColors.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              mode == ConnectionRequestsPageMode.received
                  ? 'Não foi possível carregar os convites recebidos.'
                  : 'Não foi possível carregar os convites enviados.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestAvatar extends StatelessWidget {
  const _RequestAvatar({required this.label, this.photoUrl, this.radius = 22});

  final String label;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = photoUrl?.trim() ?? '';
    final initial = _initialForName(label);
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    if (trimmedUrl.isEmpty) return fallback;

    return CachedNetworkImage(
      imageUrl: trimmedUrl,
      imageBuilder: (_, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

String _receivedRequestSubtitle(ConnectionRequestEntity request) {
  final sentAt = _formatRelativeDate(request.createdAt);
  return 'Enviado em $sentAt';
}

String _sentRequestSubtitle(ConnectionRequestEntity request) {
  final sentAt = _formatRelativeDate(request.createdAt);
  return 'Aguardando resposta desde $sentAt';
}

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inMinutes < 1) return 'agora';
  if (difference.inHours < 1) return '${difference.inMinutes} min';
  if (difference.inDays < 1) return '${difference.inHours} h';
  if (difference.inDays < 30) return '${difference.inDays} d';

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String _initialForName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '?';
  }

  return trimmed[0].toUpperCase();
}
