import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

/// Picker de reações para mensagens
///
/// Exibe uma lista horizontal de emojis populares para reagir a mensagens.
/// Long press em uma reação abre um picker completo.
class ReactionNewPicker extends StatelessWidget {
  const ReactionNewPicker({
    required this.onReactionSelected,
    this.currentReaction,
    this.onMorePressed,
    super.key,
  });

  /// Callback quando uma reação é selecionada
  final void Function(String emoji) onReactionSelected;

  /// Reação atual do usuário (para destacar)
  final String? currentReaction;

  /// Callback para abrir picker de emojis completo
  final VoidCallback? onMorePressed;

  /// Emojis padrão para reações rápidas
  static const List<String> defaultReactions = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '👍',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reações rápidas
          ...defaultReactions.map((emoji) {
            final isSelected = currentReaction == emoji;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onReactionSelected(emoji);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: isSelected
                    ? BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: isSelected ? 26 : 24,
                  ),
                ),
              ),
            );
          }),

          // Botão "mais"
          if (onMorePressed != null) ...[
            const SizedBox(width: 4),
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onMorePressed?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.add,
                  size: 24,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal de reações com animação e menu de ações
class ReactionNewPickerModal extends StatefulWidget {
  const ReactionNewPickerModal({
    required this.onReactionSelected,
    required this.onDismiss,
    this.currentReaction,
    this.anchorPosition,
    this.isMine = false,
    this.canEdit = false,
    this.onReply,
    this.onEdit,
    this.onCopy,
    this.onDelete,
    super.key,
  });

  final void Function(String emoji) onReactionSelected;
  final VoidCallback onDismiss;
  final String? currentReaction;
  final Offset? anchorPosition;
  
  /// Se a mensagem é do usuário atual
  final bool isMine;
  
  /// ✅ Se pode editar a mensagem (mensagem própria + dentro de 15 min)
  final bool canEdit;
  
  /// Callback para responder mensagem
  final VoidCallback? onReply;
  
  /// Callback para editar mensagem (apenas se isMine && canEdit)
  final VoidCallback? onEdit;
  
  /// Callback para copiar texto
  final VoidCallback? onCopy;
  
  /// Callback para deletar mensagem
  final VoidCallback? onDelete;

  @override
  State<ReactionNewPickerModal> createState() => _ReactionNewPickerModalState();
}

class _ReactionNewPickerModalState extends State<ReactionNewPickerModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    // Calcula a posição do menu (acima ou abaixo da mensagem)
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final visibleHeight = screenHeight - keyboardHeight;
    
    final anchorY = widget.anchorPosition?.dy ?? screenHeight / 2;
    
    // ✅ FIX: Considerar teclado aberto para decidir posição
    // Se o teclado está aberto, sempre mostrar acima para evitar ficar escondido
    final showAbove = keyboardHeight > 0 || anchorY > visibleHeight / 2;
    
    // ✅ FIX: Calcular margens considerando teclado
    final safeTopMargin = MediaQuery.of(context).padding.top + 60; // AppBar + padding
    final safeBottomMargin = keyboardHeight + 80; // Teclado + input bar
    
    return GestureDetector(
      onTap: _handleDismiss,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                // ✅ FIX: Usar margens seguras para posicionamento
                top: showAbove ? safeTopMargin : null,
                bottom: showAbove ? null : safeBottomMargin,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: showAbove ? Alignment.topCenter : Alignment.bottomCenter,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Picker de reações
                        ReactionNewPicker(
                          onReactionSelected: (emoji) {
                            widget.onReactionSelected(emoji);
                            _handleDismiss();
                          },
                          currentReaction: widget.currentReaction,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Menu de ações
                        _buildActionsMenu(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionsMenu() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Responder
          if (widget.onReply != null)
            _buildActionItem(
              icon: Iconsax.message,
              label: 'Responder',
              onTap: () {
                _handleDismiss();
                widget.onReply?.call();
              },
            ),
          
          // Copiar
          if (widget.onCopy != null)
            _buildActionItem(
              icon: Iconsax.copy,
              label: 'Copiar',
              onTap: () {
                _handleDismiss();
                widget.onCopy?.call();
              },
            ),
          
          // Editar (apenas mensagens próprias dentro de 15 min)
          if (widget.isMine && widget.canEdit && widget.onEdit != null)
            _buildActionItem(
              icon: Iconsax.edit,
              label: 'Editar',
              onTap: () {
                _handleDismiss();
                widget.onEdit?.call();
              },
            ),
          
          // Deletar
          if (widget.onDelete != null)
            _buildActionItem(
              icon: Iconsax.trash,
              label: 'Apagar',
              onTap: () {
                _handleDismiss();
                widget.onDelete?.call();
              },
              isDestructive: true,
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;
    
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
