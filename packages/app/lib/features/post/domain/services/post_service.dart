import 'dart:io';
import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Lightweight service that only handles storage + validation concerns.
///
/// All Firestore writes now live in the repository layer and are orchestrated
/// by [PostNotifier]. This service remains as a utility that uploads images
/// and validates post payloads before persistence.
class PostService {
  PostService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadPostImage(File file, String postId) async {
    try {
      final ref = _storage
          .ref()
          .child('posts/$postId/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final snapshot = await ref.putFile(file);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      debugPrint('Image deleted: $imageUrl');
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  void validatePostEntity(PostEntity post) {
    if (post.authorUid.isEmpty || post.authorProfileId.isEmpty) {
      throw ArgumentError('Autor inválido');
    }

    if (post.content.trim().isEmpty) {
      throw ArgumentError('Conteúdo é obrigatório');
    }

    if (post.content.length > 600) {
      throw ArgumentError('Conteúdo deve ter no máximo 600 caracteres');
    }

    if (post.city.trim().isEmpty) {
      throw ArgumentError('Cidade é obrigatória');
    }

    if (post.location.latitude == 0 && post.location.longitude == 0) {
      throw ArgumentError('Localização é obrigatória');
    }

    if (!['musician', 'band', 'sales'].contains(post.type)) {
      throw ArgumentError('Tipo inválido: ${post.type}');
    }

    if (post.expiresAt.isBefore(DateTime.now())) {
      throw ArgumentError('Post expirado');
    }

    if (post.type == 'musician' && post.instruments.isEmpty) {
      throw ArgumentError('Selecione pelo menos um instrumento');
    }

    if (post.type == 'band' && post.seekingMusicians.isEmpty) {
      throw ArgumentError('Informe os músicos buscados');
    }

    // Validações comuns para musician e band
    if (post.type != 'sales') {
      if (post.genres.isEmpty) {
        throw ArgumentError('Selecione pelo menos um gênero musical');
      }
      if (post.level.trim().isEmpty) {
        throw ArgumentError('Selecione o nível de experiência');
      }
    }

    // Validações específicas para sales
    if (post.type == 'sales') {
      if (post.title == null || post.title!.trim().isEmpty) {
        throw ArgumentError('Título é obrigatório para anúncios');
      }
      if (post.salesType == null || post.salesType!.trim().isEmpty) {
        throw ArgumentError('Tipo do anúncio é obrigatório');
      }
      if (post.price == null || post.price! <= 0) {
        throw ArgumentError('Preço deve ser maior que zero');
      }
    }
  }
}
