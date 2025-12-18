import 'package:flutter/material.dart';
import 'package:core_ui/theme/app_colors.dart';

class PostFormFields extends StatelessWidget {
  final TextEditingController? titleController;
  final TextEditingController descriptionController;
  final TextEditingController? videoUrlController;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? descriptionValidator;
  final String? Function(String?)? videoUrlValidator;

  const PostFormFields({
    super.key,
    this.titleController,
    required this.descriptionController,
    this.videoUrlController,
    this.titleValidator,
    this.descriptionValidator,
    this.videoUrlValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titleController != null) ...[
          TextFormField(
            controller: titleController,
            validator: titleValidator,
            decoration: InputDecoration(
              labelText: 'Título',
              hintText: 'Ex: Procuro guitarrista para banda de rock',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              floatingLabelStyle: TextStyle(color: AppColors.primary),
            ),
            maxLength: 50,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: descriptionController,
          validator: descriptionValidator,
          decoration: InputDecoration(
            labelText: 'Descrição',
            hintText: 'Conte mais sobre o projeto, influências, objetivos...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            floatingLabelStyle: TextStyle(color: AppColors.primary),
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          maxLength: 600,
          textInputAction: TextInputAction.newline,
        ),
        if (videoUrlController != null) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: videoUrlController,
            validator: videoUrlValidator,
            decoration: InputDecoration(
              labelText: 'Link de Vídeo (YouTube/Vimeo)',
              hintText: 'https://...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              floatingLabelStyle: TextStyle(color: AppColors.primary),
              prefixIcon: Icon(Icons.video_library, color: Colors.grey[600]),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
          ),
        ],
      ],
    );
  }
}
