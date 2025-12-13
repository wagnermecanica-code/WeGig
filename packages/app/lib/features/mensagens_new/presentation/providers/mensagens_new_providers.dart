import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/mensagens_new_remote_datasource.dart';
import '../../data/repositories/mensagens_new_repository_impl.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/mensagens_new_repository.dart';
import '../../domain/usecases/usecases.dart';

part 'mensagens_new_providers.g.dart';

// ============================================================================
// DATA LAYER PROVIDERS
// ============================================================================

/// Provider para FirebaseFirestore instance
@riverpod
FirebaseFirestore mensagensNewFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// Provider para MensagensNewRemoteDataSource
@riverpod
IMensagensNewRemoteDataSource mensagensNewRemoteDataSource(Ref ref) {
  final firestore = ref.watch(mensagensNewFirestoreProvider);
  return MensagensNewRemoteDataSource(firestore: firestore);
}

/// Provider para MensagensNewRepository
@riverpod
MensagensNewRepository mensagensNewRepository(Ref ref) {
  final dataSource = ref.watch(mensagensNewRemoteDataSourceProvider);
  return MensagensNewRepositoryImpl(remoteDataSource: dataSource);
}

// ============================================================================
// USE CASE PROVIDERS - CONVERSAS
// ============================================================================

@riverpod
LoadConversationsNewUseCase loadConversationsNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return LoadConversationsNewUseCase(repository);
}

@riverpod
GetOrCreateConversationNewUseCase getOrCreateConversationNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return GetOrCreateConversationNewUseCase(repository);
}

@riverpod
ArchiveConversationNewUseCase archiveConversationNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return ArchiveConversationNewUseCase(repository);
}

@riverpod
UnarchiveConversationNewUseCase unarchiveConversationNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return UnarchiveConversationNewUseCase(repository);
}

@riverpod
DeleteConversationNewUseCase deleteConversationNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return DeleteConversationNewUseCase(repository);
}

@riverpod
TogglePinConversationNewUseCase togglePinConversationNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return TogglePinConversationNewUseCase(repository);
}

@riverpod
ToggleMuteConversationNewUseCase toggleMuteConversationNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return ToggleMuteConversationNewUseCase(repository);
}

@riverpod
MarkAsReadNewUseCase markAsReadNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return MarkAsReadNewUseCase(repository);
}

@riverpod
MarkAsUnreadNewUseCase markAsUnreadNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return MarkAsUnreadNewUseCase(repository);
}

@riverpod
UpdateTypingIndicatorNewUseCase updateTypingIndicatorNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return UpdateTypingIndicatorNewUseCase(repository);
}

@riverpod
WatchConversationsNewUseCase watchConversationsNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return WatchConversationsNewUseCase(repository);
}

@riverpod
WatchUnreadCountNewUseCase watchUnreadCountNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return WatchUnreadCountNewUseCase(repository);
}

@riverpod
WatchTypingIndicatorsNewUseCase watchTypingIndicatorsNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return WatchTypingIndicatorsNewUseCase(repository);
}

// ============================================================================
// USE CASE PROVIDERS - MENSAGENS
// ============================================================================

@riverpod
SendMessageNewUseCase sendMessageNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return SendMessageNewUseCase(repository);
}

@riverpod
SendImageMessageNewUseCase sendImageMessageNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return SendImageMessageNewUseCase(repository);
}

@riverpod
EditMessageNewUseCase editMessageNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return EditMessageNewUseCase(repository);
}

@riverpod
DeleteMessageForMeNewUseCase deleteMessageForMeNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return DeleteMessageForMeNewUseCase(repository);
}

@riverpod
DeleteMessageForEveryoneNewUseCase deleteMessageForEveryoneNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return DeleteMessageForEveryoneNewUseCase(repository);
}

@riverpod
AddReactionNewUseCase addReactionNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return AddReactionNewUseCase(repository);
}

@riverpod
RemoveReactionNewUseCase removeReactionNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return RemoveReactionNewUseCase(repository);
}

@riverpod
LoadMessagesNewUseCase loadMessagesNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return LoadMessagesNewUseCase(repository);
}

@riverpod
WatchMessagesNewUseCase watchMessagesNewUseCase(Ref ref) {
  final repository = ref.watch(mensagensNewRepositoryProvider);
  return WatchMessagesNewUseCase(repository);
}

// ============================================================================
// STREAM PROVIDERS - TEMPO REAL
// ============================================================================

/// Stream de conversas em tempo real para o perfil ativo
///
/// Uso:
/// ```dart
/// final conversations = ref.watch(conversationsNewStreamProvider(
///   profileId: activeProfile.profileId,
///   profileUid: activeProfile.uid,
/// ));
/// ```
@riverpod
Stream<List<ConversationNewEntity>> conversationsNewStream(
  Ref ref, {
  required String profileId,
  required String profileUid,
  int limit = 20,
  bool includeArchived = false,
}) {
  final useCase = ref.watch(watchConversationsNewUseCaseProvider);
  return useCase(
    profileId: profileId,
    profileUid: profileUid,
    limit: limit,
    includeArchived: includeArchived,
  );
}

/// Stream de mensagens em tempo real para uma conversa
///
/// Uso:
/// ```dart
/// final messages = ref.watch(messagesNewStreamProvider(conversationId));
/// ```
@riverpod
Stream<List<MessageNewEntity>> messagesNewStream(
  Ref ref,
  String conversationId, {
  int limit = 50,
}) {
  final useCase = ref.watch(watchMessagesNewUseCaseProvider);
  return useCase(conversationId: conversationId, limit: limit);
}

/// Stream de contagem de não lidas para badge no BottomNav
///
/// Uso:
/// ```dart
/// final unreadCount = ref.watch(unreadMessagesNewCountProvider(
///   profileId: activeProfile.profileId,
///   profileUid: activeProfile.uid,
/// ));
/// ```
@riverpod
Stream<int> unreadMessagesNewCount(
  Ref ref, {
  required String profileId,
  required String profileUid,
}) {
  final useCase = ref.watch(watchUnreadCountNewUseCaseProvider);
  return useCase(profileId: profileId, profileUid: profileUid);
}

/// Stream de indicadores de digitação
@riverpod
Stream<Map<String, DateTime>> typingIndicatorsNewStream(
  Ref ref,
  String conversationId,
) {
  final useCase = ref.watch(watchTypingIndicatorsNewUseCaseProvider);
  return useCase(conversationId: conversationId);
}
