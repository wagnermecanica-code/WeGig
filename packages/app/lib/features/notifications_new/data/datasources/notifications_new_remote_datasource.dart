/// WeGig - NotificationsNew Remote DataSource
///
/// DataSource para operações Firestore de notificações seguindo Clean Architecture.
/// Implementa queries otimizadas com paginação cursor-based e filtros multi-perfil.
///
/// CRÍTICO: Todas as queries usam recipientUid para match com Security Rules Firestore.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wegig_app/core/firebase/blocked_relations.dart';
import 'package:wegig_app/core/firebase/blocked_profiles.dart';
import 'package:wegig_app/features/notifications_new/domain/entities/notification_new_entity.dart';

/// Interface do DataSource de notificações
///
/// Define contrato para operações Firestore isolando a implementação.
abstract class INotificationsNewRemoteDataSource {
  /// Busca notificações paginadas
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  });

  /// Busca notificação por ID
  Future<NotificationEntity?> getNotificationById(String notificationId);

  /// Marca como lida
  Future<void> markAsRead(String notificationId);

  /// Marca todas como lidas
  Future<void> markAllAsRead(String profileId, String recipientUid);

  /// Deleta notificação
  Future<void> deleteNotification(String notificationId);

  /// Conta não lidas
  Future<int> getUnreadCount(String profileId, String recipientUid);

  /// Stream de notificações
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    required String recipientUid,
    int limit = 50,
  });

  /// Stream de contador de não lidas
  Stream<int> watchUnreadCount({
    required String profileId,
    required String recipientUid,
  });
}

/// Implementação do DataSource de notificações usando Firestore
///
/// Otimizações:
/// - Paginação cursor-based com startAfter (mais eficiente que offset)
/// - Filtro client-side por profileId (isolamento multi-perfil)
/// - Batch writes para operações em massa (markAllAsRead)
/// - Streams com distinct para evitar rebuilds desnecessários
class NotificationsNewRemoteDataSource
    implements INotificationsNewRemoteDataSource {
  /// Cria o datasource, opcionalmente com instância Firestore customizada (testes)
  NotificationsNewRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Referência à collection de notificações
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  Future<({Set<String> blocked, Set<String> blockedBy})> _getBlockSets({
    required String profileId,
    String? uid,
  }) async {
    final trimmed = profileId.trim();
    if (trimmed.isEmpty) return (blocked: <String>{}, blockedBy: <String>{});

    try {
      final blocked = await BlockedProfiles.get(firestore: _firestore, profileId: trimmed);
      final blockedBy = await BlockedRelations.getBlockedByProfileIds(
        firestore: _firestore,
        profileId: trimmed,
        uid: uid,
      );
      debugPrint('🔒 [BLOCK_SETS] profileId=$trimmed | blocked=${blocked.length} profiles: $blocked | blockedBy=${blockedBy.length} profiles: $blockedBy');
      return (blocked: blocked.toSet(), blockedBy: blockedBy.toSet());
    } catch (e) {
      debugPrint('⚠️ NotificationsNewDataSource: Falha ao carregar block sets (non-critical): $e');
      return (blocked: <String>{}, blockedBy: <String>{});
    }
  }

  Stream<({Set<String> blocked, Set<String> blockedBy})> _watchBlockSets({
    required String profileId,
    String? uid,
  }) {
    final trimmed = profileId.trim();
    if (trimmed.isEmpty) {
      return Stream.value((blocked: <String>{}, blockedBy: <String>{}));
    }

    final blocked$ = BlockedProfiles.watch(firestore: _firestore, profileId: trimmed)
        .map((l) => l.toSet())
        .onErrorReturn(<String>{});

    final blockedBy$ = BlockedRelations.watchBlockedByProfileIds(
      firestore: _firestore,
      profileId: trimmed,
      uid: uid,
    ).map((l) => l.toSet()).onErrorReturn(<String>{});

    return Rx.combineLatest2<Set<String>, Set<String>, ({Set<String> blocked, Set<String> blockedBy})>(
      blocked$,
      blockedBy$,
      (a, b) => (blocked: a, blockedBy: b),
    );
  }

  /// Extrai todos os profileIds candidatos de uma notificação para verificar bloqueio.
  /// 
  /// Verifica múltiplas fontes pois diferentes tipos de notificação usam campos diferentes:
  /// - nearbyPost: actionData.authorProfileId
  /// - interest: actionData.interestedProfileId  
  /// - newMessage: data.senderProfileId ou senderProfileId direto
  Iterable<String> _candidateProfileIds(NotificationEntity n) sync* {
    // 1. Campo direto senderProfileId (todas as notificações)
    final senderProfileId = (n.senderProfileId ?? '').trim();
    if (senderProfileId.isNotEmpty) yield senderProfileId;

    // 2. Verificar em actionData (nearbyPost, interest, etc.)
    final actionData = n.actionData ?? {};
    
    // actionData.authorProfileId (nearbyPost)
    final actionAuthorProfileId = (actionData['authorProfileId'] is String) 
        ? (actionData['authorProfileId'] as String).trim() 
        : '';
    if (actionAuthorProfileId.isNotEmpty) yield actionAuthorProfileId;
    
    // actionData.interestedProfileId (interest)
    final actionInterestedProfileId = (actionData['interestedProfileId'] is String) 
        ? (actionData['interestedProfileId'] as String).trim() 
        : '';
    if (actionInterestedProfileId.isNotEmpty) yield actionInterestedProfileId;
    
    // actionData.senderProfileId (newMessage)
    final actionSenderProfileId = (actionData['senderProfileId'] is String) 
        ? (actionData['senderProfileId'] as String).trim() 
        : '';
    if (actionSenderProfileId.isNotEmpty) yield actionSenderProfileId;

    // actionData.commenterProfileId (comment)
    final actionCommenterProfileId = (actionData['commenterProfileId'] is String) 
        ? (actionData['commenterProfileId'] as String).trim() 
        : '';
    if (actionCommenterProfileId.isNotEmpty) yield actionCommenterProfileId;

    // 3. Verificar em data (fallback para compatibilidade)
    final data = n.data;
    
    final dataActionProfileId = (data['actionProfileId'] is String) 
        ? (data['actionProfileId'] as String).trim() 
        : '';
    if (dataActionProfileId.isNotEmpty) yield dataActionProfileId;

    final dataAuthorProfileId = (data['authorProfileId'] is String) 
        ? (data['authorProfileId'] as String).trim() 
        : '';
    if (dataAuthorProfileId.isNotEmpty) yield dataAuthorProfileId;

    final dataInterestedProfileId = (data['interestedProfileId'] is String) 
        ? (data['interestedProfileId'] as String).trim() 
        : '';
    if (dataInterestedProfileId.isNotEmpty) yield dataInterestedProfileId;
    
    final dataSenderProfileId = (data['senderProfileId'] is String) 
        ? (data['senderProfileId'] as String).trim() 
        : '';
    if (dataSenderProfileId.isNotEmpty) yield dataSenderProfileId;
  }

  bool _matchesProfileSet(NotificationEntity n, Set<String> profileSet) {
    if (profileSet.isEmpty) return false;
    final candidates = _candidateProfileIds(n).toList();
    final matches = candidates.any(profileSet.contains);
    if (matches) {
      debugPrint('🚫 [BLOCK_FILTER] Notificação ${n.notificationId} (type=${n.type.name}) '
          'filtrada. candidates=$candidates, blockedSet=$profileSet');
    }
    return matches;
  }

  NotificationEntity _asEmptyProfile(NotificationEntity n) {
    // Mantemos a notificação (ex.: viewPost), mas removemos identidade do remetente
    // para respeitar bloqueio aplicado pelo autor sobre o viewer.
    return n.copyWith(
      senderUid: null,
      senderProfileId: null,
      senderUsername: null,
      senderPhoto: null,
      senderName: 'Perfil indisponível',
    );
  }

  @override
  Future<List<NotificationEntity>> getNotifications({
    required String profileId,
    required String recipientUid,
    NotificationType? type,
    int limit = 20,
    NotificationEntity? startAfter,
  }) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: getNotifications for profile=$profileId, uid=$recipientUid, type=${type?.name ?? 'all'}');

      // Validação de parâmetros obrigatórios
      if (recipientUid.isEmpty) {
        debugPrint('⚠️ NotificationsNewDataSource: recipientUid vazio');
        return [];
      }

      // Query base: recipientUid (CRÍTICO para Security Rules)
      // IMPORTANTE: Ordem dos filtros deve seguir índices em firestore.indexes.json
      var query = _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid);

      // Filtro opcional por tipo de notificação
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      // Ordenação: createdAt DESC (mais recentes primeiro)
      // Usa índice: recipientUid + type + createdAt OU recipientUid + createdAt
      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit * 3); // Margem maior para filtros client-side

      // Paginação cursor-based
      if (startAfter != null) {
        query = query.startAfter([
          Timestamp.fromDate(startAfter.createdAt),
        ]);
      }

      final snapshot = await query.get();
      debugPrint(
          '📝 NotificationsNewDataSource: ${snapshot.docs.length} docs retornados do Firestore');

      // Log dos documentos para debug
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint(
            '📋 Doc ${doc.id}: recipientProfileId=${data['recipientProfileId']}, type=${data['type']}, title=${data['title']}');
      }

      final now = DateTime.now();
      final blockSets = await _getBlockSets(profileId: profileId, uid: recipientUid);
      
      // Filtros client-side:
      // 1. Por profileId (isolamento multi-perfil)
      // 2. Por expiração (remove notificações expiradas)
      // 3. Exclui newMessage (já notificado na MessagesNewPage)
      final notifications = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .map((n) {
            // Se o autor me bloqueou, manter a notificação mas renderizar como "perfil vazio".
            if (_matchesProfileSet(n, blockSets.blockedBy)) {
              return _asEmptyProfile(n);
            }
            return n;
          })
          .where((n) {
            // Filtro por profileId
            if (n.recipientProfileId != profileId) {
              debugPrint(
                  '🚫 Filtrado por profileId: doc.recipientProfileId=${n.recipientProfileId} != profileId=$profileId');
              return false;
            }
            
            // Filtro por expiração
            if (n.expiresAt != null && n.expiresAt!.isBefore(now)) {
              debugPrint(
                  '🚫 Filtrado por expiração: expiresAt=${n.expiresAt} < now=$now');
              return false;
            }
            
            // Filtro: Excluir notificações de mensagem (já aparecem no chat)
            if (n.type == NotificationType.newMessage) {
              debugPrint(
                  '🚫 Filtrado tipo newMessage: já notificado na MessagesNewPage');
              return false;
            }

            // Filtro: se EU bloqueei, remover completamente.
            if (_matchesProfileSet(n, blockSets.blocked)) {
              return false;
            }
            
            return true;
          })
          .take(limit)
          .toList();

      debugPrint(
          '✅ NotificationsNewDataSource: ${notifications.length} notificações após filtro');

      return notifications;
    } catch (e, stack) {
      debugPrint('❌ NotificationsNewDataSource: Erro em getNotifications - $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  @override
  Future<NotificationEntity?> getNotificationById(
      String notificationId) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: getNotificationById $notificationId');

      final doc = await _notificationsRef.doc(notificationId).get();

      if (!doc.exists) {
        debugPrint('⚠️ NotificationsNewDataSource: Notificação não encontrada');
        return null;
      }

      return NotificationEntity.fromFirestore(doc);
    } catch (e) {
      debugPrint(
          '❌ NotificationsNewDataSource: Erro em getNotificationById - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      debugPrint('📝 NotificationsNewDataSource: markAsRead $notificationId');

      await _notificationsRef.doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ NotificationsNewDataSource: Marcada como lida');
    } catch (e) {
      debugPrint('❌ NotificationsNewDataSource: Erro em markAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead(String profileId, String recipientUid) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: markAllAsRead for profile $profileId');

      if (recipientUid.isEmpty) {
        debugPrint('⚠️ NotificationsNewDataSource: recipientUid vazio');
        return;
      }

      // Busca todas não lidas do usuário
      final snapshot = await _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .get();

      // Filtro client-side por profileId
      final docsToUpdate = snapshot.docs
          .where((doc) => doc.data()['recipientProfileId'] == profileId)
          .toList();

      debugPrint(
          '📝 NotificationsNewDataSource: ${docsToUpdate.length} para marcar');

      if (docsToUpdate.isEmpty) return;

      // Batch write (limite 500 por batch)
      const int batchSize = 500;
      for (var i = 0; i < docsToUpdate.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < docsToUpdate.length)
            ? i + batchSize
            : docsToUpdate.length;
        final chunk = docsToUpdate.sublist(i, end);

        for (final doc in chunk) {
          batch.update(doc.reference, {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
        debugPrint(
            '✅ NotificationsNewDataSource: Batch ${i ~/ batchSize + 1} commitado');
      }

      debugPrint('✅ NotificationsNewDataSource: Todas marcadas como lidas');
    } catch (e) {
      debugPrint('❌ NotificationsNewDataSource: Erro em markAllAsRead - $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: deleteNotification $notificationId');

      await _notificationsRef.doc(notificationId).delete();

      debugPrint('✅ NotificationsNewDataSource: Notificação deletada');
    } catch (e) {
      debugPrint(
          '❌ NotificationsNewDataSource: Erro em deleteNotification - $e');
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String profileId, String recipientUid) async {
    try {
      debugPrint(
          '📝 NotificationsNewDataSource: getUnreadCount for profile $profileId');

      if (recipientUid.isEmpty) return 0;

      final snapshot = await _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .get();

        final blockSets = await _getBlockSets(profileId: profileId, uid: recipientUid);
        final now = DateTime.now();

      // Filtros client-side: profileId + expiração + tipo + bloqueios
      final count = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .where((n) {
            if (n.recipientProfileId != profileId) return false;
            if (n.expiresAt != null && n.expiresAt!.isBefore(now)) return false;
            if (n.type == NotificationType.newMessage) return false;
            if (_matchesProfileSet(n, blockSets.blocked)) return false;
            return true;
          })
          .length;

      debugPrint('✅ NotificationsNewDataSource: $count não lidas');
      return count;
    } catch (e) {
      debugPrint('❌ NotificationsNewDataSource: Erro em getUnreadCount - $e');
      return 0;
    }
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications({
    required String profileId,
    required String recipientUid,
    int limit = 50,
  }) {
    debugPrint(
        '📝 NotificationsNewDataSource: watchNotifications for profile=$profileId, uid=$recipientUid');

    if (recipientUid.isEmpty) {
      debugPrint('⚠️ NotificationsNewDataSource: recipientUid vazio no stream');
      return Stream.value([]);
    }

    return _watchBlockSets(profileId: profileId, uid: recipientUid).switchMap((blockSets) {
      return _notificationsRef
        .where('recipientUid', isEqualTo: recipientUid)
        .orderBy('createdAt', descending: true)
        .limit(limit * 2)
        .snapshots()
        .map((snapshot) {
      debugPrint(
          '📡 Stream: ${snapshot.docs.length} docs do Firestore');
      
      final now = DateTime.now();
      
      // Filtros client-side: profileId + expiração + tipo
      final notifications = snapshot.docs
          .map(NotificationEntity.fromFirestore)
          .map((n) {
            if (_matchesProfileSet(n, blockSets.blockedBy)) {
              return _asEmptyProfile(n);
            }
            return n;
          })
          .where((n) {
            // Filtro por profileId
            if (n.recipientProfileId != profileId) {
              debugPrint(
                  '🚫 Stream filtrado: doc.recipientProfileId=${n.recipientProfileId} != profileId=$profileId');
              return false;
            }
            
            // Filtro por expiração
            if (n.expiresAt != null && n.expiresAt!.isBefore(now)) {
              return false;
            }
            
            // Filtro: Excluir notificações de mensagem (já aparecem no chat)
            if (n.type == NotificationType.newMessage) {
              return false;
            }

            // Filtro: se EU bloqueei, remover completamente.
            if (_matchesProfileSet(n, blockSets.blocked)) {
              return false;
            }
            
            return true;
          })
          .take(limit)
          .toList();

      debugPrint(
          '📡 Stream emitiu ${notifications.length} notificações após filtro');
      return notifications;
      });
    });
  }

  @override
  Stream<int> watchUnreadCount({
    required String profileId,
    required String recipientUid,
  }) {
    debugPrint(
        '📝 NotificationsNewDataSource: watchUnreadCount for profile $profileId');

    if (recipientUid.isEmpty) {
      return Stream.value(0);
    }

    return _watchBlockSets(profileId: profileId, uid: recipientUid).switchMap((blockSets) {
      return _notificationsRef
          .where('recipientUid', isEqualTo: recipientUid)
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
        final now = DateTime.now();

        // Filtro: exclui newMessage do contador (já contamos em MessagesNewPage)
        final count = snapshot.docs
            .map(NotificationEntity.fromFirestore)
            .where((n) {
              if (n.recipientProfileId != profileId) return false;
              if (n.type == NotificationType.newMessage) return false;
              if (n.expiresAt != null && n.expiresAt!.isBefore(now)) return false;
              if (_matchesProfileSet(n, blockSets.blocked)) return false;
              return true;
            })
            .length;

        debugPrint(
            '📝 NotificationsNewDataSource: Stream unread count = $count (excluindo newMessage + bloqueios)');
        return count;
      });
    }).distinct();
  }
}
