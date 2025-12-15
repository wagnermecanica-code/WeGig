// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_new_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatNewControllerHash() => r'0ac2672f8dd32a226593714ae79bfdc9cfc4326b';

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

abstract class _$ChatNewController
    extends BuildlessAutoDisposeNotifier<ChatNewState> {
  late final String conversationId;

  ChatNewState build(
    String conversationId,
  );
}

/// Controller para o Chat individual
///
/// Gerencia:
/// - Stream de mensagens em tempo real
/// - Envio de mensagens (texto e imagem)
/// - Reações e edições
/// - Indicador de digitação
/// - Paginação (load more)
/// - Filtro de histórico (clearHistoryTimestamp)
///
/// Copied from [ChatNewController].
@ProviderFor(ChatNewController)
const chatNewControllerProvider = ChatNewControllerFamily();

/// Controller para o Chat individual
///
/// Gerencia:
/// - Stream de mensagens em tempo real
/// - Envio de mensagens (texto e imagem)
/// - Reações e edições
/// - Indicador de digitação
/// - Paginação (load more)
/// - Filtro de histórico (clearHistoryTimestamp)
///
/// Copied from [ChatNewController].
class ChatNewControllerFamily extends Family<ChatNewState> {
  /// Controller para o Chat individual
  ///
  /// Gerencia:
  /// - Stream de mensagens em tempo real
  /// - Envio de mensagens (texto e imagem)
  /// - Reações e edições
  /// - Indicador de digitação
  /// - Paginação (load more)
  /// - Filtro de histórico (clearHistoryTimestamp)
  ///
  /// Copied from [ChatNewController].
  const ChatNewControllerFamily();

  /// Controller para o Chat individual
  ///
  /// Gerencia:
  /// - Stream de mensagens em tempo real
  /// - Envio de mensagens (texto e imagem)
  /// - Reações e edições
  /// - Indicador de digitação
  /// - Paginação (load more)
  /// - Filtro de histórico (clearHistoryTimestamp)
  ///
  /// Copied from [ChatNewController].
  ChatNewControllerProvider call(
    String conversationId,
  ) {
    return ChatNewControllerProvider(
      conversationId,
    );
  }

  @override
  ChatNewControllerProvider getProviderOverride(
    covariant ChatNewControllerProvider provider,
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
  String? get name => r'chatNewControllerProvider';
}

/// Controller para o Chat individual
///
/// Gerencia:
/// - Stream de mensagens em tempo real
/// - Envio de mensagens (texto e imagem)
/// - Reações e edições
/// - Indicador de digitação
/// - Paginação (load more)
/// - Filtro de histórico (clearHistoryTimestamp)
///
/// Copied from [ChatNewController].
class ChatNewControllerProvider
    extends AutoDisposeNotifierProviderImpl<ChatNewController, ChatNewState> {
  /// Controller para o Chat individual
  ///
  /// Gerencia:
  /// - Stream de mensagens em tempo real
  /// - Envio de mensagens (texto e imagem)
  /// - Reações e edições
  /// - Indicador de digitação
  /// - Paginação (load more)
  /// - Filtro de histórico (clearHistoryTimestamp)
  ///
  /// Copied from [ChatNewController].
  ChatNewControllerProvider(
    String conversationId,
  ) : this._internal(
          () => ChatNewController()..conversationId = conversationId,
          from: chatNewControllerProvider,
          name: r'chatNewControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chatNewControllerHash,
          dependencies: ChatNewControllerFamily._dependencies,
          allTransitiveDependencies:
              ChatNewControllerFamily._allTransitiveDependencies,
          conversationId: conversationId,
        );

  ChatNewControllerProvider._internal(
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
  ChatNewState runNotifierBuild(
    covariant ChatNewController notifier,
  ) {
    return notifier.build(
      conversationId,
    );
  }

  @override
  Override overrideWith(ChatNewController Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChatNewControllerProvider._internal(
        () => create()..conversationId = conversationId,
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
  AutoDisposeNotifierProviderElement<ChatNewController, ChatNewState>
      createElement() {
    return _ChatNewControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatNewControllerProvider &&
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
mixin ChatNewControllerRef on AutoDisposeNotifierProviderRef<ChatNewState> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ChatNewControllerProviderElement
    extends AutoDisposeNotifierProviderElement<ChatNewController, ChatNewState>
    with ChatNewControllerRef {
  _ChatNewControllerProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ChatNewControllerProvider).conversationId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
