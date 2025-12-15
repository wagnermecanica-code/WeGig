// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_switcher_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileSwitcherNotifierHash() =>
    r'43bba2d547253c9e20de08a3b949dfca3c937c66';

/// Gerenciador centralizado de troca de perfil
///
/// Responsável por:
/// - Executar troca de perfil via ProfileNotifier
/// - Invalidar TODOS os caches relacionados (posts, notificações, mensagens)
/// - Atualizar Analytics com perfil ativo
/// - Garantir consistência de dados entre perfis
///
/// Benefícios:
/// - Um único ponto de controle para troca de perfil
/// - Impossível esquecer de invalidar algum cache
/// - Fácil adicionar novos providers no futuro
/// - Logs centralizados para debugging
///
/// Copied from [ProfileSwitcherNotifier].
@ProviderFor(ProfileSwitcherNotifier)
final profileSwitcherNotifierProvider =
    AutoDisposeNotifierProvider<ProfileSwitcherNotifier, void>.internal(
  ProfileSwitcherNotifier.new,
  name: r'profileSwitcherNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileSwitcherNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileSwitcherNotifier = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
