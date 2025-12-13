import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Bottom sheet que mostra quem reagiu a uma mensagem (Instagram-style)
///
/// Exibe:
/// - Lista de emojis como tabs
/// - Perfis que reagiram com cada emoji
/// - Nome e foto de cada pessoa
class ReactorsBottomSheet extends StatefulWidget {
  const ReactorsBottomSheet({
    required this.reactions,
    required this.conversationId,
    super.key,
  });

  /// Map de profileId -> emoji
  final Map<String, String> reactions;

  /// ID da conversa (para contexto)
  final String conversationId;

  @override
  State<ReactorsBottomSheet> createState() => _ReactorsBottomSheetState();
}

class _ReactorsBottomSheetState extends State<ReactorsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, _ProfileData> _profilesData = {};
  bool _isLoading = true;

  // Reações únicas para as tabs
  late List<String> _uniqueReactions;

  @override
  void initState() {
    super.initState();
    _uniqueReactions = widget.reactions.values.toSet().toList();
    _tabController = TabController(
      length: _uniqueReactions.length + 1, // +1 para "Todos"
      vsync: this,
    );
    _loadProfilesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfilesData() async {
    final profileIds = widget.reactions.keys.toList();

    for (final profileId in profileIds) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(profileId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          _profilesData[profileId] = _ProfileData(
            name: data['name'] as String? ?? 'Usuário',
            username: data['username'] as String?,
            photoUrl: data['photoUrl'] as String?,
          );
        } else {
          _profilesData[profileId] = _ProfileData(name: 'Usuário');
        }
      } catch (e) {
        _profilesData[profileId] = _ProfileData(name: 'Usuário');
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Reações',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.reactions.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tabs de reações
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Todos ${widget.reactions.length}'),
              ..._uniqueReactions.map((emoji) {
                final count =
                    widget.reactions.values.where((e) => e == emoji).length;
                return Tab(text: '$emoji $count');
              }),
            ],
          ),

          // Lista de perfis
          SizedBox(
            height: 300,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab "Todos"
                      _buildProfilesList(widget.reactions.keys.toList()),
                      // Tabs por emoji
                      ..._uniqueReactions.map((emoji) {
                        final profileIds = widget.reactions.entries
                            .where((e) => e.value == emoji)
                            .map((e) => e.key)
                            .toList();
                        return _buildProfilesList(profileIds, emoji: emoji);
                      }),
                    ],
                  ),
          ),

          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildProfilesList(List<String> profileIds, {String? emoji}) {
    if (profileIds.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma reação',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: profileIds.length,
      itemBuilder: (context, index) {
        final profileId = profileIds[index];
        final profile = _profilesData[profileId];
        final reactionEmoji = emoji ?? widget.reactions[profileId];

        return ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: profile?.photoUrl != null
                ? CachedNetworkImageProvider(profile!.photoUrl!)
                : null,
            child: profile?.photoUrl == null
                ? Icon(Iconsax.user, size: 22, color: AppColors.textSecondary)
                : null,
          ),
          title: Text(
            profile?.name ?? 'Usuário',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          subtitle: profile?.username != null
              ? Text(
                  '@${profile!.username}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: Text(
            reactionEmoji ?? '',
            style: const TextStyle(fontSize: 24),
          ),
        );
      },
    );
  }
}

class _ProfileData {
  final String name;
  final String? username;
  final String? photoUrl;

  _ProfileData({required this.name, this.username, this.photoUrl});
}
