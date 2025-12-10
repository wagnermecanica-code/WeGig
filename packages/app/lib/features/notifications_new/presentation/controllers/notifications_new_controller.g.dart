// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_new_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsNewControllerHash() =>
    r'4abf99bcde969ea49b49b18c3096c7f8c860e27f';

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

abstract class _$NotificationsNewController
    extends BuildlessAutoDisposeAsyncNotifier<NotificationsNewState> {
  late final String profileId;
  late final NotificationType? type;

  FutureOr<NotificationsNewState> build(
    String profileId, {
    NotificationType? type,
  });
}

/// Controller para lista de notificações com paginação
///
/// Parâmetros do build():
/// - [profileId] - ID do perfil ativo (obrigatório)
/// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
///
/// Exemplo:
/// ```dart
/// // Todas as notificações
/// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
///
/// // Apenas interesses
/// final interests = ref.watch(
///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
/// );
/// ```
///
/// Copied from [NotificationsNewController].
@ProviderFor(NotificationsNewController)
const notificationsNewControllerProvider = NotificationsNewControllerFamily();

/// Controller para lista de notificações com paginação
///
/// Parâmetros do build():
/// - [profileId] - ID do perfil ativo (obrigatório)
/// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
///
/// Exemplo:
/// ```dart
/// // Todas as notificações
/// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
///
/// // Apenas interesses
/// final interests = ref.watch(
///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
/// );
/// ```
///
/// Copied from [NotificationsNewController].
class NotificationsNewControllerFamily
    extends Family<AsyncValue<NotificationsNewState>> {
  /// Controller para lista de notificações com paginação
  ///
  /// Parâmetros do build():
  /// - [profileId] - ID do perfil ativo (obrigatório)
  /// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
  ///
  /// Exemplo:
  /// ```dart
  /// // Todas as notificações
  /// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
  ///
  /// // Apenas interesses
  /// final interests = ref.watch(
  ///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
  /// );
  /// ```
  ///
  /// Copied from [NotificationsNewController].
  const NotificationsNewControllerFamily();

  /// Controller para lista de notificações com paginação
  ///
  /// Parâmetros do build():
  /// - [profileId] - ID do perfil ativo (obrigatório)
  /// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
  ///
  /// Exemplo:
  /// ```dart
  /// // Todas as notificações
  /// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
  ///
  /// // Apenas interesses
  /// final interests = ref.watch(
  ///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
  /// );
  /// ```
  ///
  /// Copied from [NotificationsNewController].
  NotificationsNewControllerProvider call(
    String profileId, {
    NotificationType? type,
  }) {
    return NotificationsNewControllerProvider(
      profileId,
      type: type,
    );
  }

  @override
  NotificationsNewControllerProvider getProviderOverride(
    covariant NotificationsNewControllerProvider provider,
  ) {
    return call(
      provider.profileId,
      type: provider.type,
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
  String? get name => r'notificationsNewControllerProvider';
}

/// Controller para lista de notificações com paginação
///
/// Parâmetros do build():
/// - [profileId] - ID do perfil ativo (obrigatório)
/// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
///
/// Exemplo:
/// ```dart
/// // Todas as notificações
/// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
///
/// // Apenas interesses
/// final interests = ref.watch(
///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
/// );
/// ```
///
/// Copied from [NotificationsNewController].
class NotificationsNewControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<NotificationsNewController,
        NotificationsNewState> {
  /// Controller para lista de notificações com paginação
  ///
  /// Parâmetros do build():
  /// - [profileId] - ID do perfil ativo (obrigatório)
  /// - [type] - Filtro por tipo (null = todas, interest = apenas interesses)
  ///
  /// Exemplo:
  /// ```dart
  /// // Todas as notificações
  /// final allNotifs = ref.watch(notificationsNewControllerProvider(profileId));
  ///
  /// // Apenas interesses
  /// final interests = ref.watch(
  ///   notificationsNewControllerProvider(profileId, type: NotificationType.interest),
  /// );
  /// ```
  ///
  /// Copied from [NotificationsNewController].
  NotificationsNewControllerProvider(
    String profileId, {
    NotificationType? type,
  }) : this._internal(
          () => NotificationsNewController()
            ..profileId = profileId
            ..type = type,
          from: notificationsNewControllerProvider,
          name: r'notificationsNewControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationsNewControllerHash,
          dependencies: NotificationsNewControllerFamily._dependencies,
          allTransitiveDependencies:
              NotificationsNewControllerFamily._allTransitiveDependencies,
          profileId: profileId,
          type: type,
        );

  NotificationsNewControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
    required this.type,
  }) : super.internal();

  final String profileId;
  final NotificationType? type;

  @override
  FutureOr<NotificationsNewState> runNotifierBuild(
    covariant NotificationsNewController notifier,
  ) {
    return notifier.build(
      profileId,
      type: type,
    );
  }

  @override
  Override overrideWith(NotificationsNewController Function() create) {
    return ProviderOverride(
      origin: this,
      override: NotificationsNewControllerProvider._internal(
        () => create()
          ..profileId = profileId
          ..type = type,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<NotificationsNewController,
      NotificationsNewState> createElement() {
    return _NotificationsNewControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsNewControllerProvider &&
        other.profileId == profileId &&
        other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NotificationsNewControllerRef
    on AutoDisposeAsyncNotifierProviderRef<NotificationsNewState> {
  /// The parameter `profileId` of this provider.
  String get profileId;

  /// The parameter `type` of this provider.
  NotificationType? get type;
}

class _NotificationsNewControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<NotificationsNewController,
        NotificationsNewState> with NotificationsNewControllerRef {
  _NotificationsNewControllerProviderElement(super.provider);

  @override
  String get profileId =>
      (origin as NotificationsNewControllerProvider).profileId;
  @override
  NotificationType? get type =>
      (origin as NotificationsNewControllerProvider).type;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
