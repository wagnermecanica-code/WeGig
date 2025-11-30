import 'package:cached_network_image/cached_network_image.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:wegig_app/app/router/app_router.dart';

/// Widget de tile para resultado de busca de perfil
/// Usado em search results para exibir perfis encontrados
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.profile,
    super.key,
  });
  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final primaryColor = profile.isBand ? AppColors.accent : AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        backgroundImage:
            profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(profile.photoUrl!)
                : null,
        child: profile.photoUrl == null || profile.photoUrl!.isEmpty
            ? Icon(
                profile.isBand ? Icons.groups_rounded : Icons.person_rounded,
                color: primaryColor,
                size: 28,
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              profile.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            profile.isBand ? Icons.groups_rounded : Icons.person_rounded,
            size: 16,
            color: primaryColor,
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.instruments?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: profile.instruments!.take(3).map((instrument) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    instrument,
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (profile.city.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    profile.city,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      onTap: () {
        context.pushProfile(profile.profileId);
      },
    );
  }
}
