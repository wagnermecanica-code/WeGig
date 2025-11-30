// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider para FirebaseFirestore instance

@ProviderFor(firestore)
const firestoreProvider = FirestoreProvider._();

/// Provider para FirebaseFirestore instance

final class FirestoreProvider extends $FunctionalProvider<FirebaseFirestore,
    FirebaseFirestore, FirebaseFirestore> with $Provider<FirebaseFirestore> {
  /// Provider para FirebaseFirestore instance
  const FirestoreProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'firestoreProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$firestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firestoreHash() => r'ef4a6b0737caace50a6d79dd3e4e2aa1bc3031d5';

/// Provider para MessagesRemoteDataSource

@ProviderFor(messagesRemoteDataSource)
const messagesRemoteDataSourceProvider = MessagesRemoteDataSourceProvider._();

/// Provider para MessagesRemoteDataSource

final class MessagesRemoteDataSourceProvider extends $FunctionalProvider<
    IMessagesRemoteDataSource,
    IMessagesRemoteDataSource,
    IMessagesRemoteDataSource> with $Provider<IMessagesRemoteDataSource> {
  /// Provider para MessagesRemoteDataSource
  const MessagesRemoteDataSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'messagesRemoteDataSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$messagesRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<IMessagesRemoteDataSource> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IMessagesRemoteDataSource create(Ref ref) {
    return messagesRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IMessagesRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IMessagesRemoteDataSource>(value),
    );
  }
}

String _$messagesRemoteDataSourceHash() =>
    r'ab88def8e1df67f885da5ac9008dbdcb955633e5';

/// Provider para MessagesRepository (nova implementação Clean Architecture)

@ProviderFor(messagesRepositoryNew)
const messagesRepositoryNewProvider = MessagesRepositoryNewProvider._();

/// Provider para MessagesRepository (nova implementação Clean Architecture)

final class MessagesRepositoryNewProvider extends $FunctionalProvider<
    MessagesRepository,
    MessagesRepository,
    MessagesRepository> with $Provider<MessagesRepository> {
  /// Provider para MessagesRepository (nova implementação Clean Architecture)
  const MessagesRepositoryNewProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'messagesRepositoryNewProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$messagesRepositoryNewHash();

  @$internal
  @override
  $ProviderElement<MessagesRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessagesRepository create(Ref ref) {
    return messagesRepositoryNew(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessagesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessagesRepository>(value),
    );
  }
}

String _$messagesRepositoryNewHash() =>
    r'457f1aaaa67efc70314525bce0489f4bc48fc699';

@ProviderFor(loadConversationsUseCase)
const loadConversationsUseCaseProvider = LoadConversationsUseCaseProvider._();

final class LoadConversationsUseCaseProvider extends $FunctionalProvider<
    LoadConversations,
    LoadConversations,
    LoadConversations> with $Provider<LoadConversations> {
  const LoadConversationsUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadConversationsUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadConversationsUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadConversations> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadConversations create(Ref ref) {
    return loadConversationsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadConversations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadConversations>(value),
    );
  }
}

String _$loadConversationsUseCaseHash() =>
    r'320c0542dd32291d0b0b9f98013d80b4ba2e94d1';

@ProviderFor(loadMessagesUseCase)
const loadMessagesUseCaseProvider = LoadMessagesUseCaseProvider._();

final class LoadMessagesUseCaseProvider
    extends $FunctionalProvider<LoadMessages, LoadMessages, LoadMessages>
    with $Provider<LoadMessages> {
  const LoadMessagesUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'loadMessagesUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$loadMessagesUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadMessages> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadMessages create(Ref ref) {
    return loadMessagesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadMessages value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadMessages>(value),
    );
  }
}

String _$loadMessagesUseCaseHash() =>
    r'8bc7fc7bb06d292871893e3fcd33ac0786d60538';

@ProviderFor(sendMessageUseCase)
const sendMessageUseCaseProvider = SendMessageUseCaseProvider._();

final class SendMessageUseCaseProvider
    extends $FunctionalProvider<SendMessage, SendMessage, SendMessage>
    with $Provider<SendMessage> {
  const SendMessageUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sendMessageUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sendMessageUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendMessage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendMessage create(Ref ref) {
    return sendMessageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendMessage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendMessage>(value),
    );
  }
}

String _$sendMessageUseCaseHash() =>
    r'bbfb194e6540a4e84906a464e3fee019e57f1081';

@ProviderFor(sendImageUseCase)
const sendImageUseCaseProvider = SendImageUseCaseProvider._();

final class SendImageUseCaseProvider
    extends $FunctionalProvider<SendImage, SendImage, SendImage>
    with $Provider<SendImage> {
  const SendImageUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'sendImageUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$sendImageUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendImage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendImage create(Ref ref) {
    return sendImageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendImage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendImage>(value),
    );
  }
}

String _$sendImageUseCaseHash() => r'781d2e1bd06a66439da3a5e1da360d28d77ad37c';

@ProviderFor(markAsReadUseCase)
const markAsReadUseCaseProvider = MarkAsReadUseCaseProvider._();

final class MarkAsReadUseCaseProvider
    extends $FunctionalProvider<MarkAsRead, MarkAsRead, MarkAsRead>
    with $Provider<MarkAsRead> {
  const MarkAsReadUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'markAsReadUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$markAsReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkAsRead> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkAsRead create(Ref ref) {
    return markAsReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkAsRead value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkAsRead>(value),
    );
  }
}

String _$markAsReadUseCaseHash() => r'e2bbd46ecdc3a2a37c1f1f7d6a6be1b16e211885';

@ProviderFor(markAsUnreadUseCase)
const markAsUnreadUseCaseProvider = MarkAsUnreadUseCaseProvider._();

final class MarkAsUnreadUseCaseProvider
    extends $FunctionalProvider<MarkAsUnread, MarkAsUnread, MarkAsUnread>
    with $Provider<MarkAsUnread> {
  const MarkAsUnreadUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'markAsUnreadUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$markAsUnreadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkAsUnread> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MarkAsUnread create(Ref ref) {
    return markAsUnreadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkAsUnread value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkAsUnread>(value),
    );
  }
}

String _$markAsUnreadUseCaseHash() =>
    r'110087caf2ba23b9e913a4295899e41d64fa5ecf';

@ProviderFor(deleteConversationUseCase)
const deleteConversationUseCaseProvider = DeleteConversationUseCaseProvider._();

final class DeleteConversationUseCaseProvider extends $FunctionalProvider<
    DeleteConversation,
    DeleteConversation,
    DeleteConversation> with $Provider<DeleteConversation> {
  const DeleteConversationUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'deleteConversationUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$deleteConversationUseCaseHash();

  @$internal
  @override
  $ProviderElement<DeleteConversation> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeleteConversation create(Ref ref) {
    return deleteConversationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeleteConversation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeleteConversation>(value),
    );
  }
}

String _$deleteConversationUseCaseHash() =>
    r'b9df445874801ad2caf9c30ea45d012a3b9bcd4b';

/// Stream de conversas em tempo real

@ProviderFor(conversationsStream)
const conversationsStreamProvider = ConversationsStreamFamily._();

/// Stream de conversas em tempo real

final class ConversationsStreamProvider extends $FunctionalProvider<
        AsyncValue<List<ConversationEntity>>,
        List<ConversationEntity>,
        Stream<List<ConversationEntity>>>
    with
        $FutureModifier<List<ConversationEntity>>,
        $StreamProvider<List<ConversationEntity>> {
  /// Stream de conversas em tempo real
  const ConversationsStreamProvider._(
      {required ConversationsStreamFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'conversationsStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$conversationsStreamHash();

  @override
  String toString() {
    return r'conversationsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ConversationEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ConversationEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return conversationsStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationsStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationsStreamHash() =>
    r'6ea8e9b45b816fc4b078fcb352bc84017915b2fe';

/// Stream de conversas em tempo real

final class ConversationsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ConversationEntity>>, String> {
  const ConversationsStreamFamily._()
      : super(
          retry: null,
          name: r'conversationsStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Stream de conversas em tempo real

  ConversationsStreamProvider call(
    String profileId,
  ) =>
      ConversationsStreamProvider._(argument: profileId, from: this);

  @override
  String toString() => r'conversationsStreamProvider';
}

/// Stream de mensagens em tempo real

@ProviderFor(messagesStream)
const messagesStreamProvider = MessagesStreamFamily._();

/// Stream de mensagens em tempo real

final class MessagesStreamProvider extends $FunctionalProvider<
        AsyncValue<List<MessageEntity>>,
        List<MessageEntity>,
        Stream<List<MessageEntity>>>
    with
        $FutureModifier<List<MessageEntity>>,
        $StreamProvider<List<MessageEntity>> {
  /// Stream de mensagens em tempo real
  const MessagesStreamProvider._(
      {required MessagesStreamFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'messagesStreamProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$messagesStreamHash();

  @override
  String toString() {
    return r'messagesStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<MessageEntity>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<MessageEntity>> create(Ref ref) {
    final argument = this.argument as String;
    return messagesStream(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesStreamProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$messagesStreamHash() => r'7fb46bada6568e40afb919dc87f16289219a251a';

/// Stream de mensagens em tempo real

final class MessagesStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<MessageEntity>>, String> {
  const MessagesStreamFamily._()
      : super(
          retry: null,
          name: r'messagesStreamProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Stream de mensagens em tempo real

  MessagesStreamProvider call(
    String conversationId,
  ) =>
      MessagesStreamProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'messagesStreamProvider';
}

/// Stream de contador de não lidas para BottomNav badge

@ProviderFor(unreadMessageCountForProfile)
const unreadMessageCountForProfileProvider =
    UnreadMessageCountForProfileFamily._();

/// Stream de contador de não lidas para BottomNav badge

final class UnreadMessageCountForProfileProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Stream de contador de não lidas para BottomNav badge
  const UnreadMessageCountForProfileProvider._(
      {required UnreadMessageCountForProfileFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'unreadMessageCountForProfileProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$unreadMessageCountForProfileHash();

  @override
  String toString() {
    return r'unreadMessageCountForProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return unreadMessageCountForProfile(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadMessageCountForProfileProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$unreadMessageCountForProfileHash() =>
    r'db1b340c88290265166e7971b2a3656fc2517b71';

/// Stream de contador de não lidas para BottomNav badge

final class UnreadMessageCountForProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<int>, String> {
  const UnreadMessageCountForProfileFamily._()
      : super(
          retry: null,
          name: r'unreadMessageCountForProfileProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Stream de contador de não lidas para BottomNav badge

  UnreadMessageCountForProfileProvider call(
    String profileId,
  ) =>
      UnreadMessageCountForProfileProvider._(argument: profileId, from: this);

  @override
  String toString() => r'unreadMessageCountForProfileProvider';
}
