import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Provider para lista de profileIds bloqueados pelo perfil ativo
final _blockedProfileIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final activeProfile = ref.watch(activeProfileProvider);
  final profileId = activeProfile?.profileId;
  if (profileId == null || profileId.isEmpty) {
    return const Stream<List<String>>.empty();
  }
  return BlockedProfiles.watch(
    firestore: FirebaseFirestore.instance,
    profileId: profileId,
  );
});

/// Provider para buscar dados do perfil bloqueado
final _blockedProfileDataProvider = FutureProvider.autoDispose.family<ProfileEntity?, String>((ref, blockedProfileId) async {
  final firestore = FirebaseFirestore.instance;
  
  final doc = await firestore.collection('profiles').doc(blockedProfileId).get();
  if (!doc.exists) return null;
  return ProfileEntity.fromFirestore(doc);
});

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeProfile = ref.watch(activeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfis bloqueados'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: currentUser == null || activeProfile == null
          ? const _EmptyState(
              title: 'Você precisa estar logado',
              subtitle: 'Entre na sua conta para gerenciar bloqueios.',
            )
          : _BlockedProfilesBody(
              currentProfileId: activeProfile.profileId,
              currentUid: currentUser.uid,
            ),
    );
  }
}

class _BlockedProfilesBody extends ConsumerWidget {
  const _BlockedProfilesBody({
    required this.currentProfileId,
    required this.currentUid,
  });

  final String currentProfileId;
  final String currentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedProfileIdsAsync = ref.watch(_blockedProfileIdsProvider);

    return blockedProfileIdsAsync.when(
      loading: () => const Center(
        child: AppRadioPulseLoader(
          size: 44,
          color: AppColors.primary,
        ),
      ),
      error: (err, _) => _ErrorState(
        onRetry: () => ref.invalidate(_blockedProfileIdsProvider),
      ),
      data: (blockedProfileIds) {
        if (blockedProfileIds.isEmpty) {
          return const _EmptyState(
            title: 'Nenhum perfil bloqueado',
            subtitle: 'Você não bloqueou ninguém ainda.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: blockedProfileIds.length,
          itemBuilder: (context, index) {
            final blockedProfileId = blockedProfileIds[index];
            return _BlockedProfileCard(
              blockedProfileId: blockedProfileId,
              onUnblock: () => _confirmAndUnblock(
                context: context,
                ref: ref,
                blockedProfileId: blockedProfileId,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndUnblock({
    required BuildContext context,
    required WidgetRef ref,
    required String blockedProfileId,
  }) async {
    final shouldUnblock = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desbloquear perfil?'),
        content: const Text('Este perfil será removido da sua lista de bloqueados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (shouldUnblock != true) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // Remove from profiles/{profileId}.blockedProfileIds
      await BlockedProfiles.remove(
        firestore: firestore,
        blockerProfileId: currentProfileId,
        blockedProfileId: blockedProfileId,
      );

      // Remove edge from blocks collection (reverse visibility)
      try {
        await BlockedRelations.delete(
          firestore: firestore,
          blockedByProfileId: currentProfileId,
          blockedProfileId: blockedProfileId,
        );
      } catch (e) {
        debugPrint('⚠️ blocks edge delete failed (non-critical): $e');
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil desbloqueado'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível desbloquear. Tente novamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _BlockedProfileCard extends ConsumerWidget {
  const _BlockedProfileCard({
    required this.blockedProfileId,
    required this.onUnblock,
  });

  final String blockedProfileId;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_blockedProfileDataProvider(blockedProfileId));

    return profileAsync.when(
      loading: () => Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: CircleAvatar(backgroundColor: AppColors.border),
          title: Text('Carregando…'),
        ),
      ),
      error: (err, _) => _buildFallbackCard(),
      data: (profile) {
        if (profile == null) {
          return _buildFallbackCard();
        }

        final username = (profile.username ?? '').trim();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: _Avatar(photoUrl: profile.photoUrl),
            title: Text(
              profile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                username.isNotEmpty ? '@$username' : _formatProfileId(blockedProfileId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Desbloquear',
              icon: const Icon(Iconsax.user_tick, color: AppColors.primary),
              onPressed: onUnblock,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const CircleAvatar(
          backgroundColor: AppColors.border,
          child: Icon(Iconsax.user, color: AppColors.textSecondary, size: 18),
        ),
        title: const Text('Perfil bloqueado'),
        subtitle: Text(
          _formatProfileId(blockedProfileId),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
        ),
        trailing: IconButton(
          tooltip: 'Desbloquear',
          icon: const Icon(Iconsax.user_tick, color: AppColors.primary),
          onPressed: onUnblock,
        ),
      ),
    );
  }

  static String _formatProfileId(String profileId) {
    final value = profileId.trim();
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = (photoUrl ?? '').trim();
    if (url.isEmpty || !url.startsWith('http')) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.border,
        child: Icon(Iconsax.user, color: AppColors.textSecondary, size: 18),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.border,
      foregroundImage: CachedNetworkImageProvider(url),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.shield_tick, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 42, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text('Erro ao carregar bloqueios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Toque para tentar novamente.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
