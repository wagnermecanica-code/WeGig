// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messages_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firestoreHash() => r'0e25e335c5657f593fc1baf3d9fd026e70bca7fa';

/// Provider para FirebaseFirestore instance
///
/// Copied from [firestore].
@ProviderFor(firestore)
final firestoreProvider = AutoDisposeProvider<FirebaseFirestore>.internal(
  firestore,
  name: r'firestoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$firestoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirestoreRef = AutoDisposeProviderRef<FirebaseFirestore>;
String _$messagesRemoteDataSourceHash() =>
    r'e174e14509da3e6a224b3506938ec74fa839a711';

/// Provider para MessagesRemoteDataSource
///
/// Copied from [messagesRemoteDataSource].
@ProviderFor(messagesRemoteDataSource)
final messagesRemoteDataSourceProvider =
    AutoDisposeProvider<IMessagesRemoteDataSource>.internal(
  messagesRemoteDataSource,
  name: r'messagesRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messagesRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessagesRemoteDataSourceRef
    = AutoDisposeProviderRef<IMessagesRemoteDataSource>;
String _$messagesRepositoryNewHash() =>
    r'cea8b4b2b4822d5f4279b4ee9b4a15e2aeceb19c';

/// Provider para MessagesRepository (nova implementação Clean Architecture)
///
/// Copied from [messagesRepositoryNew].
@ProviderFor(messagesRepositoryNew)
final messagesRepositoryNewProvider =
    AutoDisposeProvider<MessagesRepository>.internal(
  messagesRepositoryNew,
  name: r'messagesRepositoryNewProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messagesRepositoryNewHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessagesRepositoryNewRef = AutoDisposeProviderRef<MessagesRepository>;
String _$loadConversationsUseCaseHash() =>
    r'df8b29966d479a8de4805a0de14840f2814626f9';

/// See also [loadConversationsUseCase].
@ProviderFor(loadConversationsUseCase)
final loadConversationsUseCaseProvider =
    AutoDisposeProvider<LoadConversations>.internal(
  loadConversationsUseCase,
  name: r'loadConversationsUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadConversationsUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadConversationsUseCaseRef = AutoDisposeProviderRef<LoadConversations>;
String _$loadMessagesUseCaseHash() =>
    r'429b58cd1bca9a603f1881eb4266d529dc40d07b';

/// See also [loadMessagesUseCase].
@ProviderFor(loadMessagesUseCase)
final loadMessagesUseCaseProvider = AutoDisposeProvider<LoadMessages>.internal(
  loadMessagesUseCase,
  name: r'loadMessagesUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$loadMessagesUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LoadMessagesUseCaseRef = AutoDisposeProviderRef<LoadMessages>;
String _$sendMessageUseCaseHash() =>
    r'6b5c609feca234fcc58462801ea68592138639ce';

/// See also [sendMessageUseCase].
@ProviderFor(sendMessageUseCase)
final sendMessageUseCaseProvider = AutoDisposeProvider<SendMessage>.internal(
  sendMessageUseCase,
  name: r'sendMessageUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendMessageUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SendMessageUseCaseRef = AutoDisposeProviderRef<SendMessage>;
String _$sendImageUseCaseHash() => r'ca82319922166ea491899f776c13c24bd9815aa4';

/// See also [sendImageUseCase].
@ProviderFor(sendImageUseCase)
final sendImageUseCaseProvider = AutoDisposeProvider<SendImage>.internal(
  sendImageUseCase,
  name: r'sendImageUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$sendImageUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SendImageUseCaseRef = AutoDisposeProviderRef<SendImage>;
String _$markAsReadUseCaseHash() => r'fcaa6f4bb6b3e4430d1b6af556e2e43eed6bc225';

/// See also [markAsReadUseCase].
@ProviderFor(markAsReadUseCase)
final markAsReadUseCaseProvider = AutoDisposeProvider<MarkAsRead>.internal(
  markAsReadUseCase,
  name: r'markAsReadUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markAsReadUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkAsReadUseCaseRef = AutoDisposeProviderRef<MarkAsRead>;
String _$markAsUnreadUseCaseHash() =>
    r'40426050458c583578db5886d833e3de3b506721';

/// See also [markAsUnreadUseCase].
@ProviderFor(markAsUnreadUseCase)
final markAsUnreadUseCaseProvider = AutoDisposeProvider<MarkAsUnread>.internal(
  markAsUnreadUseCase,
  name: r'markAsUnreadUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$markAsUnreadUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MarkAsUnreadUseCaseRef = AutoDisposeProviderRef<MarkAsUnread>;
String _$deleteConversationUseCaseHash() =>
    r'5febffe04ac53b5ce2c243cf74385a21bcb05e36';

/// See also [deleteConversationUseCase].
@ProviderFor(deleteConversationUseCase)
final deleteConversationUseCaseProvider =
    AutoDisposeProvider<DeleteConversation>.internal(
  deleteConversationUseCase,
  name: r'deleteConversationUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deleteConversationUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeleteConversationUseCaseRef
    = AutoDisposeProviderRef<DeleteConversation>;
String _$conversationsStreamHash() =>
    r'8a0ddf8c5543771a553c319adf1df04c2d9e6bd7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Stream de conversas em tempo real
///
/// Copied from [conversationsStream].
@ProviderFor(conversationsStream)
const conversationsStreamProvider = ConversationsStreamFamily();

/// Stream de conversas em tempo real
///
/// Copied from [conversationsStream].
class ConversationsStreamFamily
    extends Family<AsyncValue<List<ConversationEntity>>> {
  /// Stream de conversas em tempo real
  ///
  /// Copied from [conversationsStream].
  const ConversationsStreamFamily();

  /// Stream de conversas em tempo real
  ///
  /// Copied from [conversationsStream].
  ConversationsStreamProvider call(
    String profileId,
  ) {
    return ConversationsStreamProvider(
      profileId,
    );
  }

  @override
  ConversationsStreamProvider getProviderOverride(
    covariant ConversationsStreamProvider provider,
  ) {
    return call(
      provider.profileId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationsStreamProvider';
}

/// Stream de conversas em tempo real
///
/// Copied from [conversationsStream].
class ConversationsStreamProvider
    extends AutoDisposeStreamProvider<List<ConversationEntity>> {
  /// Stream de conversas em tempo real
  ///
  /// Copied from [conversationsStream].
  ConversationsStreamProvider(
    String profileId,
  ) : this._internal(
          (ref) => conversationsStream(
            ref as ConversationsStreamRef,
            profileId,
          ),
          from: conversationsStreamProvider,
          name: r'conversationsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$conversationsStreamHash,
          dependencies: ConversationsStreamFamily._dependencies,
          allTransitiveDependencies:
              ConversationsStreamFamily._allTransitiveDependencies,
          profileId: profileId,
        );

  ConversationsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    Stream<List<ConversationEntity>> Function(ConversationsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationsStreamProvider._internal(
        (ref) => create(ref as ConversationsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ConversationEntity>> createElement() {
    return _ConversationsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationsStreamProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationsStreamRef
    on AutoDisposeStreamProviderRef<List<ConversationEntity>> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _ConversationsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<ConversationEntity>>
    with ConversationsStreamRef {
  _ConversationsStreamProviderElement(super.provider);

  @override
  String get profileId => (origin as ConversationsStreamProvider).profileId;
}

String _$messagesStreamHash() => r'53d85537f9bbb5befbab58fdcacb56a9fbafa182';

/// Stream de mensagens em tempo real
///
/// Copied from [messagesStream].
@ProviderFor(messagesStream)
const messagesStreamProvider = MessagesStreamFamily();

/// Stream de mensagens em tempo real
///
/// Copied from [messagesStream].
class MessagesStreamFamily extends Family<AsyncValue<List<MessageEntity>>> {
  /// Stream de mensagens em tempo real
  ///
  /// Copied from [messagesStream].
  const MessagesStreamFamily();

  /// Stream de mensagens em tempo real
  ///
  /// Copied from [messagesStream].
  MessagesStreamProvider call(
    String conversationId,
  ) {
    return MessagesStreamProvider(
      conversationId,
    );
  }

  @override
  MessagesStreamProvider getProviderOverride(
    covariant MessagesStreamProvider provider,
  ) {
    return call(
      provider.conversationId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'messagesStreamProvider';
}

/// Stream de mensagens em tempo real
///
/// Copied from [messagesStream].
class MessagesStreamProvider
    extends AutoDisposeStreamProvider<List<MessageEntity>> {
  /// Stream de mensagens em tempo real
  ///
  /// Copied from [messagesStream].
  MessagesStreamProvider(
    String conversationId,
  ) : this._internal(
          (ref) => messagesStream(
            ref as MessagesStreamRef,
            conversationId,
          ),
          from: messagesStreamProvider,
          name: r'messagesStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$messagesStreamHash,
          dependencies: MessagesStreamFamily._dependencies,
          allTransitiveDependencies:
              MessagesStreamFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  MessagesStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<List<MessageEntity>> Function(MessagesStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MessagesStreamProvider._internal(
        (ref) => create(ref as MessagesStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<MessageEntity>> createElement() {
    return _MessagesStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MessagesStreamProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MessagesStreamRef on AutoDisposeStreamProviderRef<List<MessageEntity>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _MessagesStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<MessageEntity>>
    with MessagesStreamRef {
  _MessagesStreamProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as MessagesStreamProvider).conversationId;
}

String _$unreadMessageCountForProfileHash() =>
    r'271e3bc160cfbf5c694121ab39ba49fe291c7fd1';

/// Stream de contador de não lidas para BottomNav badge
///
/// Copied from [unreadMessageCountForProfile].
@ProviderFor(unreadMessageCountForProfile)
const unreadMessageCountForProfileProvider =
    UnreadMessageCountForProfileFamily();

/// Stream de contador de não lidas para BottomNav badge
///
/// Copied from [unreadMessageCountForProfile].
class UnreadMessageCountForProfileFamily extends Family<AsyncValue<int>> {
  /// Stream de contador de não lidas para BottomNav badge
  ///
  /// Copied from [unreadMessageCountForProfile].
  const UnreadMessageCountForProfileFamily();

  /// Stream de contador de não lidas para BottomNav badge
  ///
  /// Copied from [unreadMessageCountForProfile].
  UnreadMessageCountForProfileProvider call(
    String profileId,
  ) {
    return UnreadMessageCountForProfileProvider(
      profileId,
    );
  }

  @override
  UnreadMessageCountForProfileProvider getProviderOverride(
    covariant UnreadMessageCountForProfileProvider provider,
  ) {
    return call(
      provider.profileId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'unreadMessageCountForProfileProvider';
}

/// Stream de contador de não lidas para BottomNav badge
///
/// Copied from [unreadMessageCountForProfile].
class UnreadMessageCountForProfileProvider
    extends AutoDisposeStreamProvider<int> {
  /// Stream de contador de não lidas para BottomNav badge
  ///
  /// Copied from [unreadMessageCountForProfile].
  UnreadMessageCountForProfileProvider(
    String profileId,
  ) : this._internal(
          (ref) => unreadMessageCountForProfile(
            ref as UnreadMessageCountForProfileRef,
            profileId,
          ),
          from: unreadMessageCountForProfileProvider,
          name: r'unreadMessageCountForProfileProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unreadMessageCountForProfileHash,
          dependencies: UnreadMessageCountForProfileFamily._dependencies,
          allTransitiveDependencies:
              UnreadMessageCountForProfileFamily._allTransitiveDependencies,
          profileId: profileId,
        );

  UnreadMessageCountForProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  Override overrideWith(
    Stream<int> Function(UnreadMessageCountForProfileRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnreadMessageCountForProfileProvider._internal(
        (ref) => create(ref as UnreadMessageCountForProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _UnreadMessageCountForProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadMessageCountForProfileProvider &&
        other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnreadMessageCountForProfileRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _UnreadMessageCountForProfileProviderElement
    extends AutoDisposeStreamProviderElement<int>
    with UnreadMessageCountForProfileRef {
  _UnreadMessageCountForProfileProviderElement(super.provider);

  @override
  String get profileId =>
      (origin as UnreadMessageCountForProfileProvider).profileId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
