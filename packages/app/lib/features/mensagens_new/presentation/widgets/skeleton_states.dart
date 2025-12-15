import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Skeleton loading para lista de conversas
class ConversationsNewSkeleton extends StatefulWidget {
  const ConversationsNewSkeleton({
    this.itemCount = 8,
    super.key,
  });

  final int itemCount;

  @override
  State<ConversationsNewSkeleton> createState() =>
      _ConversationsNewSkeletonState();
}

class _ConversationsNewSkeletonState extends State<ConversationsNewSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            return _SkeletonItem(opacity: _animation.value);
          },
        );
      },
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AppColors.surfaceVariant,
      AppColors.surfaceContainerHighest,
      opacity,
    )!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar skeleton
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name skeleton
                Row(
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Message preview skeleton
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading para mensagens do chat
class MessagesNewSkeleton extends StatefulWidget {
  const MessagesNewSkeleton({
    this.itemCount = 10,
    super.key,
  });

  final int itemCount;

  @override
  State<MessagesNewSkeleton> createState() => _MessagesNewSkeletonState();
}

class _MessagesNewSkeletonState extends State<MessagesNewSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          reverse: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) {
            final isMine = index % 3 != 0;
            final isLong = index % 4 == 0;

            return _MessageSkeletonItem(
              opacity: _animation.value,
              isMine: isMine,
              isLong: isLong,
            );
          },
        );
      },
    );
  }
}

class _MessageSkeletonItem extends StatelessWidget {
  const _MessageSkeletonItem({
    required this.opacity,
    required this.isMine,
    required this.isLong,
  });

  final double opacity;
  final bool isMine;
  final bool isLong;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      AppColors.surfaceVariant,
      AppColors.surfaceContainerHighest,
      opacity,
    )!;

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 80 : 16,
        right: isMine ? 16 : 80,
        top: 4,
        bottom: 4,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: isLong ? double.infinity : 200,
          height: isLong ? 100 : 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado vazio para lista de conversas
class EmptyConversationsNewState extends StatelessWidget {
  const EmptyConversationsNewState({
    this.onActionTap,
    this.showArchived = false,
    this.onToggleArchived,
    super.key,
  });

  final VoidCallback? onActionTap;
  final bool showArchived;
  final VoidCallback? onToggleArchived;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                showArchived ? Iconsax.archive_1 : Icons.chat_bubble_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              showArchived ? 'Nenhuma conversa arquivada' : 'Nenhuma conversa ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              showArchived
                  ? 'Suas conversas arquivadas aparecerão aqui'
                  : 'Comece uma conversa enviando uma mensagem\npara outro músico ou banda',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (!showArchived && onToggleArchived != null) ...[
              const SizedBox(height: 24),

              TextButton(
                onPressed: onToggleArchived,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Ver conversas arquivadas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            if (onActionTap != null) ...[
              SizedBox(height: showArchived ? 24 : 8),

              TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Explorar perfis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de erro com retry
class ErrorNewState extends StatelessWidget {
  const ErrorNewState({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),

            const SizedBox(height: 16),

            Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Tentar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
