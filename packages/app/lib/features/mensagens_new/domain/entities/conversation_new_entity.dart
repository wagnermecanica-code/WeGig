import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'message_new_entity.dart';

part 'conversation_new_entity.freezed.dart';
part 'conversation_new_entity.g.dart';

/// Enum para status de digitação na conversa
enum TypingStatus {
  /// Ninguém está digitando
  idle,

  /// Usuário está digitando
  typing,
}

/// Domain entity para Conversas (chat 1:1) - Nova implementação
///
/// Suporta:
/// - Multi-perfil: cada perfil pode ter conversas independentes
/// - Contagem de não lidas por perfil
/// - Arquivamento por perfil
/// - Preview da última mensagem
/// - Indicador de digitação
/// - Dados completos dos participantes
@freezed
class ConversationNewEntity with _$ConversationNewEntity {
  const ConversationNewEntity._();

  const factory ConversationNewEntity({
    /// ID único da conversa no Firestore
    required String id,

    /// UIDs dos participantes (Firebase Auth UIDs)
    required List<String> participants,

    /// IDs dos perfis participantes
    required List<String> participantProfiles,

    /// Preview da última mensagem
    required String lastMessage,

    /// Status de entrega da última mensagem (para indicar leitura)
    @Default(MessageDeliveryStatus.sent)
    MessageDeliveryStatus lastMessageStatus,

    /// Timestamp da última mensagem
    required DateTime lastMessageTimestamp,

    /// ID do remetente da última mensagem
    String? lastMessageSenderId,

    /// Contagem de mensagens não lidas por profileId
    required Map<String, int> unreadCount,

    /// Data de criação da conversa
    required DateTime createdAt,

    /// Data da última atualização
    DateTime? updatedAt,

    /// Dados completos dos participantes (enriquecidos no read)
    @Default([])
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<ParticipantData> participantsData,

    /// Se a conversa foi arquivada (globalmente)
    @Default(false) bool archived,

    /// Lista de profileIds que arquivaram esta conversa
    @Default(<String>[]) List<String> archivedByProfiles,

    /// Lista de profileIds que silenciaram notificações
    @Default(<String>[]) List<String> mutedByProfiles,

    /// Lista de profileIds que fixaram esta conversa
    @Default(<String>[]) List<String> pinnedByProfiles,

    /// Lista de profileIds que deletaram esta conversa (soft delete)
    @Default(<String>[]) List<String> deletedByProfiles,

    /// Timestamp de "limpar histórico" por profileId
    /// Quando um perfil deleta a conversa, salva o timestamp atual.
    /// Mensagens anteriores a este timestamp não são exibidas quando a conversa reaparecer.
    @Default(<String, DateTime>{}) Map<String, DateTime> clearHistoryTimestamp,

    /// Quem está digitando atualmente (profileId -> timestamp)
    @Default({}) Map<String, DateTime> typingIndicators,

    /// Flag de grupo
    @Default(false) bool isGroup,

    /// Nome do grupo (se isGroup=true)
    String? groupName,

    /// Foto do grupo (se isGroup=true)
    String? groupPhotoUrl,
  }) = _ConversationNewEntity;

  /// From Firestore Document
  factory ConversationNewEntity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, {
    List<ParticipantData>? enrichedParticipants,
  }) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception('ConversationNewEntity: data is null for ${snapshot.id}');
    }

    return ConversationNewEntity(
      id: snapshot.id,
      participants:
          (data['participants'] as List<dynamic>?)?.cast<String>() ?? [],
      participantProfiles:
          (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [],
      lastMessage: data['lastMessage'] as String? ?? '',
        lastMessageStatus: _parseLastMessageStatus(data['lastMessageStatus']),
      lastMessageTimestamp:
          (data['lastMessageTimestamp'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCount: _parseUnreadCount(data['unreadCount']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      participantsData: enrichedParticipants ?? const [],
      archived: data['archived'] as bool? ?? false,
      archivedByProfiles:
          (data['archivedByProfiles'] as List<dynamic>?)?.cast<String>() ??
              const [],
      mutedByProfiles:
          (data['mutedByProfiles'] as List<dynamic>?)?.cast<String>() ??
              const [],
      pinnedByProfiles:
          (data['pinnedByProfiles'] as List<dynamic>?)?.cast<String>() ??
              const [],
      deletedByProfiles:
          (data['deletedByProfiles'] as List<dynamic>?)?.cast<String>() ??
              const [],
      clearHistoryTimestamp: _parseClearHistoryTimestamp(data['clearHistoryTimestamp']),
      typingIndicators: _parseTypingIndicators(data['typingIndicators']),
      // Inferir isGroup com lógica clara:
      // 1. Se isGroup está explícito no Firestore, usar esse valor
      // 2. Se não estiver, inferir baseado em:
      //    - Mais de 2 participantes = grupo
      //    - OU tem groupName preenchido = grupo
      //    - OU conversationType == 'group' = grupo
      isGroup: _inferIsGroup(data),
      groupName: data['groupName'] as String?,
      groupPhotoUrl: data['groupPhotoUrl'] as String?,
    );
  }

  /// From JSON - generated by freezed
  factory ConversationNewEntity.fromJson(Map<String, dynamic> json) =>
      _$ConversationNewEntityFromJson(json);

  /// Parse unreadCount map safely
  static Map<String, int> _parseUnreadCount(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {};
    return Map<String, int>.from(
      data.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
    );
  }

  /// Parse lastMessageStatus safely with sensible default
  static MessageDeliveryStatus _parseLastMessageStatus(dynamic data) {
    if (data == null) return MessageDeliveryStatus.sent;
    if (data is String) {
      return MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == data,
        orElse: () => MessageDeliveryStatus.sent,
      );
    }
    return MessageDeliveryStatus.sent;
  }

  /// Parse typingIndicators map safely
  static Map<String, DateTime> _parseTypingIndicators(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {};
    return Map<String, DateTime>.from(
      data.map((k, v) {
        final timestamp = v is Timestamp ? v.toDate() : DateTime.now();
        return MapEntry(k.toString(), timestamp);
      }),
    );
  }

  /// Parse clearHistoryTimestamp map safely
  static Map<String, DateTime> _parseClearHistoryTimestamp(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {};
    return Map<String, DateTime>.from(
      data.map((k, v) {
        final timestamp = v is Timestamp ? v.toDate() : DateTime.now();
        return MapEntry(k.toString(), timestamp);
      }),
    );
  }

  /// Inferir isGroup com lógica clara e sem ambiguidade
  static bool _inferIsGroup(Map<String, dynamic> data) {
    // 1. Campo canônico: conversationType (novo, mais confiável)
    final conversationType = data['conversationType'] as String?;
    if (conversationType == 'group') return true;
    if (conversationType == 'direct') return false;

    // 2. Campo explícito isGroup
    final explicitIsGroup = data['isGroup'] as bool?;
    if (explicitIsGroup != null) return explicitIsGroup;

    // 3. Inferência por características (para dados legados)
    final participantProfiles =
        (data['participantProfiles'] as List<dynamic>?)?.cast<String>() ?? [];
    final groupName = data['groupName'] as String?;

    // Mais de 2 participantes = definitivamente grupo
    if (participantProfiles.length > 2) return true;

    // Tem nome de grupo preenchido = provavelmente grupo
    if (groupName != null && groupName.trim().isNotEmpty) return true;

    // 2 ou menos participantes e sem nome de grupo = 1:1
    return false;
  }

  // ============================================
  // GETTERS ÚTEIS
  // ============================================

  /// Retorna contagem de não lidas para um profileId específico
  int getUnreadCountForProfile(String profileId) {
    return unreadCount[profileId] ?? 0;
  }

  /// Verifica se tem mensagens não lidas para o perfil
  bool hasUnreadMessages(String profileId) {
    return getUnreadCountForProfile(profileId) > 0;
  }

  /// Retorna o profileId do outro participante
  String? getOtherProfileId(String currentProfileId) {
    try {
      return participantProfiles.firstWhere((id) => id != currentProfileId);
    } catch (e) {
      return null;
    }
  }

  /// Retorna o UID do outro participante
  String? getOtherUid(String currentUid) {
    try {
      return participants.firstWhere((id) => id != currentUid);
    } catch (e) {
      return null;
    }
  }

  /// Retorna dados do outro participante
  ParticipantData? getOtherParticipantData(String currentProfileId) {
    try {
      return participantsData.firstWhere(
        (p) => p.profileId != currentProfileId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Verifica se a conversa está arquivada para o perfil
  bool isArchivedForProfile(String profileId) {
    return archivedByProfiles.contains(profileId);
  }

  /// Verifica se notificações estão silenciadas para o perfil
  bool isMutedForProfile(String profileId) {
    return mutedByProfiles.contains(profileId);
  }

  /// Verifica se a conversa está fixada para o perfil
  bool isPinnedForProfile(String profileId) {
    return pinnedByProfiles.contains(profileId);
  }

  /// Verifica se a conversa foi deletada para o perfil (soft delete)
  bool isDeletedForProfile(String profileId) {
    return deletedByProfiles.contains(profileId);
  }

  /// Retorna o timestamp de "limpar histórico" para um perfil
  /// Mensagens anteriores a este timestamp não devem ser exibidas
  DateTime? getClearHistoryTimestampForProfile(String profileId) {
    return clearHistoryTimestamp[profileId];
  }

  /// Verifica se alguém está digitando (exceto o próprio usuário)
  bool isOtherTyping(String currentProfileId) {
    final now = DateTime.now();
    return typingIndicators.entries.any((entry) {
      if (entry.key == currentProfileId) return false;
      // Typing é válido por 5 segundos
      return now.difference(entry.value).inSeconds < 5;
    });
  }

  /// Retorna quem está digitando (profileId)
  String? getTypingProfileId(String currentProfileId) {
    final now = DateTime.now();
    for (final entry in typingIndicators.entries) {
      if (entry.key == currentProfileId) continue;
      if (now.difference(entry.value).inSeconds < 5) {
        return entry.key;
      }
    }
    return null;
  }

  // ============================================
  // TO FIRESTORE
  // ============================================

  /// To Firestore Document
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'participantProfiles': participantProfiles,
      'lastMessage': lastMessage,
      'lastMessageStatus': lastMessageStatus.name,
      'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp),
      if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'archived': archived,
      'archivedByProfiles': archivedByProfiles,
      'mutedByProfiles': mutedByProfiles,
      'pinnedByProfiles': pinnedByProfiles,
      'deletedByProfiles': deletedByProfiles,
      'clearHistoryTimestamp': clearHistoryTimestamp.map(
        (k, v) => MapEntry(k, Timestamp.fromDate(v)),
      ),
      'typingIndicators': typingIndicators.map(
        (k, v) => MapEntry(k, Timestamp.fromDate(v)),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      // CRÍTICO: Campos canônicos para distinguir tipo de conversa
      'isGroup': isGroup,
      'conversationType': isGroup ? 'group' : 'direct', // Campo canônico imutável
      if (groupName != null) 'groupName': groupName,
      if (groupPhotoUrl != null) 'groupPhotoUrl': groupPhotoUrl,
    };
  }
}

/// Dados enriquecidos de um participante da conversa
@freezed
class ParticipantData with _$ParticipantData {
  const ParticipantData._();

  const factory ParticipantData({
    /// ID do perfil
    required String profileId,

    /// UID (Firebase Auth)
    required String uid,

    /// Nome do perfil
    required String name,

    /// URL da foto do perfil
    String? photoUrl,

    /// Tipo do perfil (musician/band)
    String? profileType,

    /// Se o perfil está online
    @Default(false) bool isOnline,

    /// Última vez online
    DateTime? lastSeen,
  }) = _ParticipantData;

  /// From Firestore map
  factory ParticipantData.fromMap(Map<String, dynamic> map) {
    return ParticipantData(
      profileId: map['profileId'] as String? ?? '',
      uid: map['uid'] as String? ?? '',
      name: map['name'] as String? ?? 'Usuário',
      photoUrl: map['photoUrl'] as String?,
      profileType: map['profileType'] as String?,
      isOnline: map['isOnline'] as bool? ?? false,
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  factory ParticipantData.fromJson(Map<String, dynamic> json) =>
      _$ParticipantDataFromJson(json);

  /// To Firestore map
  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'uid': uid,
      'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (profileType != null) 'profileType': profileType,
      'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
    };
  }
}
