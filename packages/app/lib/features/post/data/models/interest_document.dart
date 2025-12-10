import 'package:cloud_firestore/cloud_firestore.dart';

/// Factory para criar documentos de interesse padronizados
/// Garante consistência entre HomePage e PostDetailPage
class InterestDocumentFactory {
  /// Cria documento de interesse padronizado
  /// 
  /// Estrutura garantida:
  /// - Post info (quem RECEBE): postId, postAuthorUid, postAuthorProfileId
  /// - Interested user info (quem ENVIA): profileUid, interestedUid, interestedProfileId, interestedProfileName, interestedProfileUsername, interestedProfilePhotoUrl
  /// - Metadata: createdAt, read
  static Map<String, dynamic> create({
    required String postId,
    required String postAuthorUid,
    required String postAuthorProfileId,
    required String currentUserUid,
    required String activeProfileUid,
    required String activeProfileId,
    required String activeProfileName,
    String? activeProfileUsername,
    String? activeProfilePhotoUrl,
  }) {
    // Validações
    if (postId.isEmpty) throw ArgumentError('postId não pode estar vazio');
    if (postAuthorUid.isEmpty) throw ArgumentError('postAuthorUid não pode estar vazio');
    if (postAuthorProfileId.isEmpty) throw ArgumentError('postAuthorProfileId não pode estar vazio');
    if (currentUserUid.isEmpty) throw ArgumentError('currentUserUid não pode estar vazio');
    if (activeProfileUid.isEmpty) throw ArgumentError('activeProfileUid não pode estar vazio');
    if (activeProfileId.isEmpty) throw ArgumentError('activeProfileId não pode estar vazio');
    if (activeProfileName.isEmpty) throw ArgumentError('activeProfileName não pode estar vazio');

    return {
      // Post info (quem RECEBE o interesse)
      'postId': postId,
      'postAuthorUid': postAuthorUid,
      'postAuthorProfileId': postAuthorProfileId,
      
      // Interested user info (quem ENVIA o interesse)
      'profileUid': activeProfileUid,            // UID para Security Rules
      'interestedUid': currentUserUid,           // UID do usuário (compatibilidade/redundância)
      'interestedProfileId': activeProfileId,    // ID do perfil ativo
      'interestedProfileName': activeProfileName, // Nome do perfil
      'interestedProfileUsername': activeProfileUsername ?? '', // Username do perfil
      'interestedProfilePhotoUrl': activeProfilePhotoUrl ?? '', // Foto (default vazio)
      
      // Metadata
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    };
  }
}
