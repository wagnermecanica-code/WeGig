// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsControllerHash() =>
    r'b540d60c1c2d1249a4af09fc865498345c913686';

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

abstract class _$NotificationsController
    extends BuildlessAutoDisposeAsyncNotifier<NotificationsState> {
  late final String profileId;
  late final NotificationType? type;

  FutureOr<NotificationsState> build(
    String profileId, {
    NotificationType? type,
  });
}

/// Controller para gerenciar lista de notificações e paginação
///
/// Copied from [NotificationsController].
@ProviderFor(NotificationsController)
const notificationsControllerProvider = NotificationsControllerFamily();

/// Controller para gerenciar lista de notificações e paginação
///
/// Copied from [NotificationsController].
class NotificationsControllerFamily
    extends Family<AsyncValue<NotificationsState>> {
  /// Controller para gerenciar lista de notificações e paginação
  ///
  /// Copied from [NotificationsController].
  const NotificationsControllerFamily();

  /// Controller para gerenciar lista de notificações e paginação
  ///
  /// Copied from [NotificationsController].
  NotificationsControllerProvider call(
    String profileId, {
    NotificationType? type,
  }) {
    return NotificationsControllerProvider(
      profileId,
      type: type,
    );
  }

  @override
  NotificationsControllerProvider getProviderOverride(
    covariant NotificationsControllerProvider provider,
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
  String? get name => r'notificationsControllerProvider';
}

/// Controller para gerenciar lista de notificações e paginação
///
/// Copied from [NotificationsController].
class NotificationsControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<NotificationsController,
        NotificationsState> {
  /// Controller para gerenciar lista de notificações e paginação
  ///
  /// Copied from [NotificationsController].
  NotificationsControllerProvider(
    String profileId, {
    NotificationType? type,
  }) : this._internal(
          () => NotificationsController()
            ..profileId = profileId
            ..type = type,
          from: notificationsControllerProvider,
          name: r'notificationsControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notificationsControllerHash,
          dependencies: NotificationsControllerFamily._dependencies,
          allTransitiveDependencies:
              NotificationsControllerFamily._allTransitiveDependencies,
          profileId: profileId,
          type: type,
        );

  NotificationsControllerProvider._internal(
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
  FutureOr<NotificationsState> runNotifierBuild(
    covariant NotificationsController notifier,
  ) {
    return notifier.build(
      profileId,
      type: type,
    );
  }

  @override
  Override overrideWith(NotificationsController Function() create) {
    return ProviderOverride(
      origin: this,
      override: NotificationsControllerProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<NotificationsController,
      NotificationsState> createElement() {
    return _NotificationsControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotificationsControllerProvider &&
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
mixin NotificationsControllerRef
    on AutoDisposeAsyncNotifierProviderRef<NotificationsState> {
  /// The parameter `profileId` of this provider.
  String get profileId;

  /// The parameter `type` of this provider.
  NotificationType? get type;
}

class _NotificationsControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<NotificationsController,
        NotificationsState> with NotificationsControllerRef {
  _NotificationsControllerProviderElement(super.provider);

  @override
  String get profileId => (origin as NotificationsControllerProvider).profileId;
  @override
  NotificationType? get type =>
      (origin as NotificationsControllerProvider).type;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
