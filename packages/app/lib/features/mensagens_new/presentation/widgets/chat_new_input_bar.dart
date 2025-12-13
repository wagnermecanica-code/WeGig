import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../domain/entities/entities.dart';

/// Barra de input para o chat
///
/// Inclui:
/// - Campo de texto com suporte a emojis
/// - Botão de enviar
/// - Botão de anexar imagem
/// - Preview de reply/edit
/// - Indicador de "digitando"
class ChatNewInputBar extends StatefulWidget {
  const ChatNewInputBar({
    required this.onSend,
    required this.onTyping,
    this.onImageTap,
    this.replyingTo,
    this.editingMessage,
    this.onCancelReplyOrEdit,
    this.isSending = false,
    this.enabled = true,
    super.key,
  });

  /// Callback ao enviar mensagem
  final void Function(String text) onSend;

  /// Callback quando usuário está digitando
  final VoidCallback onTyping;

  /// Callback ao tocar no botão de imagem
  final VoidCallback? onImageTap;

  /// Mensagem sendo respondida
  final MessageNewEntity? replyingTo;

  /// Mensagem sendo editada
  final MessageNewEntity? editingMessage;

  /// Callback para cancelar reply/edit
  final VoidCallback? onCancelReplyOrEdit;

  /// Se está enviando mensagem
  final bool isSending;

  /// Se o input está habilitado
  final bool enabled;

  @override
  State<ChatNewInputBar> createState() => _ChatNewInputBarState();
}

class _ChatNewInputBarState extends State<ChatNewInputBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Se está editando, preencher com o texto original
    if (widget.editingMessage != null) {
      _controller.text = widget.editingMessage!.text;
      _hasText = _controller.text.isNotEmpty;
    }

    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatNewInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se começou a editar, preencher o campo
    if (widget.editingMessage != null &&
        oldWidget.editingMessage?.id != widget.editingMessage?.id) {
      _controller.text = widget.editingMessage!.text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _focusNode.requestFocus();
    }

    // Se cancelou edição, limpar campo
    if (widget.editingMessage == null && oldWidget.editingMessage != null) {
      _controller.clear();
    }

    // Se começou a responder, focar no campo
    if (widget.replyingTo != null && oldWidget.replyingTo == null) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Notificar typing
    if (hasText) {
      widget.onTyping();
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview de reply ou edit
            if (widget.replyingTo != null || widget.editingMessage != null)
              _buildReplyEditPreview(),

            // Input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Botão de imagem
                  if (widget.onImageTap != null && widget.editingMessage == null)
                    _buildIconButton(
                      icon: Iconsax.image,
                      onTap: widget.enabled ? widget.onImageTap : null,
                    ),

                  const SizedBox(width: 8),

                  // Campo de texto
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.editingMessage != null
                              ? 'Editar mensagem...'
                              : 'Mensagem...',
                          hintStyle: TextStyle(
                            color: AppColors.textHint,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                        onTap: () {
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Botão enviar
                  _buildSendButton(),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildReplyEditPreview() {
    final isEditing = widget.editingMessage != null;
    final message = isEditing ? widget.editingMessage! : widget.replyingTo!;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Indicador de cor
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isEditing ? AppColors.warning : AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(width: 8),

          // Conteúdo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Editando' : 'Respondendo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isEditing ? AppColors.warning : AppColors.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (message.hasImage) ...[
                      Icon(
                        Iconsax.image,
                        size: 12,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        message.preview,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botão cancelar
          IconButton(
            onPressed: widget.onCancelReplyOrEdit,
            icon: Icon(
              Iconsax.close_circle,
              size: 20,
              color: AppColors.textHint,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: onTap != null ? AppColors.textSecondary : AppColors.textHint,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    final canSend = _hasText && widget.enabled && !widget.isSending;

    return GestureDetector(
      onTap: canSend ? _handleSend : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: canSend ? AppColors.accent : AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        child: widget.isSending
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              )
            : Icon(
                widget.editingMessage != null ? Iconsax.tick_circle : Iconsax.send_1,
                size: 20,
                color: canSend ? Colors.white : AppColors.textHint,
              ),
      ),
    );
  }
}
