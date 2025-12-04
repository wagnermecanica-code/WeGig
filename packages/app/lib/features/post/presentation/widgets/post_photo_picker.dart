import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Displays the photo preview + actions used in the post form.
class PostPhotoPicker extends StatelessWidget {
  const PostPhotoPicker({
    super.key,
    this.localPhotoPath,
    this.remotePhotoUrl,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final String? localPhotoPath;
  final String? remotePhotoUrl;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  bool get _hasPhoto =>
      (localPhotoPath != null && localPhotoPath!.isNotEmpty) ||
      (remotePhotoUrl != null && remotePhotoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Foto do post',
                  style: theme.textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: onPickPhoto,
                  icon: const Icon(Iconsax.image),
                  label: Text(_hasPhoto ? 'Trocar' : 'Adicionar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: _buildPreview(context),
            ),
            if (_hasPhoto) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onRemovePhoto,
                  child: const Text('Remover foto'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (localPhotoPath != null && localPhotoPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(localPhotoPath!),
          fit: BoxFit.cover,
        ),
      );
    }

    if (remotePhotoUrl != null && remotePhotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: remotePhotoUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Text(
          'Adicione uma foto quadrada (1:1)',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }
}
