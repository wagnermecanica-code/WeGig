import 'dart:async';

import 'package:core_ui/features/post/domain/entities/post_entity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/entities.dart';
import '../providers/connections_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

part 'network_activity_list_controller.freezed.dart';
part 'network_activity_list_controller.g.dart';

@freezed
class NetworkActivityListState with _$NetworkActivityListState {
  const factory NetworkActivityListState({
    @Default([]) List<PostEntity> posts,
    @Default(true) bool hasMore,
    @Default(false) bool isLoadingMore,
    NetworkActivityCursorEntity? nextCursor,
    String? errorMessage,
  }) = _NetworkActivityListState;
}

@riverpod
class NetworkActivityListController extends _$NetworkActivityListController {
  @override
  FutureOr<NetworkActivityListState> build() async {
    final activeProfile = ref.watch(activeProfileProvider);
    if (activeProfile == null) {
      return const NetworkActivityListState(hasMore: false);
    }

    try {
      final useCase = ref.watch(loadNetworkActivityPageUseCaseProvider);
      final page = await useCase(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        limit: networkActivityPageSize,
      );

      return NetworkActivityListState(
        posts: page.posts,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      );
    } catch (error) {
      return NetworkActivityListState(
        hasMore: false,
        errorMessage: 'Erro ao carregar atividade da rede: $error',
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
        currentState.nextCursor == null) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final useCase = ref.read(loadNetworkActivityPageUseCaseProvider);
      final page = await useCase(
        profileId: activeProfile.profileId,
        profileUid: activeProfile.uid,
        startAfter: currentState.nextCursor,
        limit: networkActivityPageSize,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          posts: [...currentState.posts, ...page.posts],
          hasMore: page.hasMore,
          isLoadingMore: false,
          nextCursor: page.nextCursor,
          errorMessage: null,
        ),
      );
    } catch (error) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          errorMessage: 'Erro ao carregar mais atividade da rede: $error',
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
