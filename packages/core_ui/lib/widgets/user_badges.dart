import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:iconsax/iconsax.dart';

/// Widget para exibir badges de conquistas do usuário
/// Exemplo: "Top Músico da Semana", "Ativo", "Verificado"
class UserBadges extends StatelessWidget {
  final String userId;
  final bool isBand;

  const UserBadges({
    super.key,
    required this.userId,
    this.isBand = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        // Calcula badges baseados em dados do usuário
        final badges = _calculateBadges(data);
        
        if (badges.isEmpty) return const SizedBox.shrink();

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: badges.map((badge) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badge['color'],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badge['icon'], size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    badge['text'],
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Calcula badges baseados nos dados do usuário
  List<Map<String, dynamic>> _calculateBadges(Map<String, dynamic> data) {
    final badges = <Map<String, dynamic>>[];

    // Badge de usuário ativo (postou recentemente)
    final lastPostDate = data['lastPostDate'] as Timestamp?;
    if (lastPostDate != null) {
      final daysSincePost = DateTime.now().difference(lastPostDate.toDate()).inDays;
      if (daysSincePost <= 7) {
        badges.add({
          'text': 'Ativo',
          'color': AppColors.success,
          'icon': Iconsax.tick_circle,
        });
      }
    }

    // Badge de usuário verificado
    final isVerified = data['isVerified'] as bool? ?? false;
    if (isVerified) {
      badges.add({
        'text': 'Verificado',
        'color': AppColors.primary,
        'icon': Iconsax.verify,
      });
    }

    // Badge de Top Músico/Banda da Semana
    final topOfWeek = data['topOfWeek'] as bool? ?? false;
    if (topOfWeek) {
      badges.add({
        'text': isBand ? 'Top Banda' : 'Top Músico',
        'color': AppColors.accent,
        'icon': Iconsax.star,
      });
    }

    // Badge de novo usuário (menos de 7 dias)
    final createdAt = data['createdAt'] as Timestamp?;
    if (createdAt != null) {
      final daysSinceCreation = DateTime.now().difference(createdAt.toDate()).inDays;
      if (daysSinceCreation <= 7) {
        badges.add({
          'text': 'Novo',
          'color': AppColors.primary,
          'icon': Iconsax.medal_star,
        });
      }
    }

    // Badge de usuário premium (exemplo)
    final isPremium = data['isPremium'] as bool? ?? false;
    if (isPremium) {
      badges.add({
        'text': 'Premium',
        'color': const Color(0xFFFFD700), // Dourado
        'icon': Iconsax.crown,
      });
    }

    return badges;
  }
}

/// Sistema de gamificação para engajamento
class GamificationService {
  /// Atualiza o status de "Top da Semana" baseado em atividade
  static Future<void> updateTopOfWeek(String userId) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final userData = await userDoc.get();
      
      if (!userData.exists) return;
      
      final data = userData.data()!;
      final postsCount = data['postsCount'] as int? ?? 0;
      final likesReceived = data['likesReceived'] as int? ?? 0;
      
      // Critério: pelo menos 3 posts e 10 likes na última semana
      final isTopOfWeek = postsCount >= 3 && likesReceived >= 10;
      
      await userDoc.update({'topOfWeek': isTopOfWeek});
    } catch (e) {
      debugPrint('Erro ao atualizar Top of Week: $e');
    }
  }

  /// Incrementa contador de posts do usuário
  static Future<void> incrementPostsCount(String userId) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      await userDoc.update({
        'postsCount': FieldValue.increment(1),
        'lastPostDate': FieldValue.serverTimestamp(),
      });
      
      // Verifica se merece badge de Top da Semana
      await updateTopOfWeek(userId);
    } catch (e) {
      debugPrint('Erro ao incrementar posts count: $e');
    }
  }

  /// Incrementa contador de likes recebidos
  static Future<void> incrementLikesReceived(String userId) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      await userDoc.update({
        'likesReceived': FieldValue.increment(1),
      });
      
      // Verifica se merece badge de Top da Semana
      await updateTopOfWeek(userId);
    } catch (e) {
      debugPrint('Erro ao incrementar likes: $e');
    }
  }
}
