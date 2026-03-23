import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/core_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Tipos de feedback disponíveis para seleção via chips.
enum FeedbackType {
  problem('Reportar um problema', Icons.bug_report_outlined),
  review('Enviar uma avaliação', Icons.star_outline_rounded),
  suggestion('Sugestão de melhoria', Icons.lightbulb_outline),
  other('Outro', Icons.chat_bubble_outline);

  const FeedbackType(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Bottom sheet para envio de feedback do usuário.
///
/// Abre com [show] e grava o feedback na coleção `feedbacks` do Firestore.
class FeedbackBottomSheet extends StatefulWidget {
  const FeedbackBottomSheet({super.key});

  /// Abre o bottom sheet de feedback.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FeedbackBottomSheet(),
    );
  }

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  final _messageController = TextEditingController();
  FeedbackType? _selectedType;
  bool _isSending = false;

  String get _userEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selectedType == null) {
      AppSnackBar.showError(context, 'Selecione o tipo de feedback.');
      return;
    }
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      AppSnackBar.showError(context, 'Escreva sua mensagem.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'type': _selectedType!.name,
        'typeLabel': _selectedType!.label,
        'message': message,
        'userEmail': _userEmail,
        'userId': user?.uid ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.showSuccess(
          context,
          'Feedback enviado com sucesso! Obrigado.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Erro ao enviar feedback.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Quando o teclado está aberto, ele já cobre a safe area inferior,
    // então usamos apenas bottomInset. Caso contrário, respeitamos o safe area.
    final effectiveBottom = bottomInset > 0 ? bottomInset : bottomPadding;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: effectiveBottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                const Text(
                  'Envie seu Feedback',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sua opinião é essencial para melhorarmos o WeGig. '
                  'Conte o que está funcionando bem ou o que podemos melhorar!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Email (read-only)
                TextField(
                  readOnly: true,
                  controller: TextEditingController(text: _userEmail),
                  decoration: InputDecoration(
                    labelText: 'Seu email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 16),

                // Feedback type chips
                const Text(
                  'Tipo de feedback',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackType.values.map((type) {
                    final selected = _selectedType == type;
                    return ChoiceChip(
                      label: Text(type.label),
                      avatar: Icon(
                        type.icon,
                        size: 18,
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 13,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Free text field
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Descreva seu feedback',
                    hintText: 'Escreva aqui...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Send button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: AppColors.primary.withAlpha(150),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enviar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
