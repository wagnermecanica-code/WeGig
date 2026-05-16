import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/entities.dart';
import '../providers/connections_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

part 'connections_list_controller.freezed.dart';
part 'connections_list_controller.g.dart';

@freezed
class ConnectionsListState with _$ConnectionsListState {
  const factory ConnectionsListState({
    @Default([]) List<ConnectionEntity> connections,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingMore,
    String? nextCursor,
    String? errorMessage,
  }) = _ConnectionsListState;
}

@riverpod
class ConnectionsListController extends _$ConnectionsListController {
  @override
  FutureOr<ConnectionsListState> build() async {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const ConnectionsListState(hasMore: false);
    }

    try {
      final useCase = ref.watch(loadConnectionsPageUseCaseProvider);
      final page = await useCase(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        limit: myConnectionsPageSize,
      );

      return ConnectionsListState(
        connections: page.connections,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      );
    } catch (error, stackTrace) {
      debugPrint('❌ ConnectionsListController: error loading - $error');
      debugPrintStack(stackTrace: stackTrace);
      return ConnectionsListState(
        hasMore: false,
        errorMessage: 'Erro ao carregar conexoes: $error',
      );
    }
  }

  Future<void> loadMore() async {
    final currentState = state.valueOrNull;
    final activeProfile = ref.read(activeProfileProvider);
    if (currentState == null ||
        activeProfile == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        currentState.nextCursor == null ||
        currentState.nextCursor!.isEmpty) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final useCase = ref.read(loadConnectionsPageUseCaseProvider);
      final page = await useCase(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        startAfterConnectionId: currentState.nextCursor,
        limit: myConnectionsPageSize,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          connections: [...currentState.connections, ...page.connections],
          hasMore: page.hasMore,
          isLoadingMore: false,
          nextCursor: page.nextCursor,
          errorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ ConnectionsListController: error loading more - $error');
      debugPrintStack(stackTrace: stackTrace);
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          errorMessage: 'Erro ao carregar mais conexoes: $error',
        ),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }
}
