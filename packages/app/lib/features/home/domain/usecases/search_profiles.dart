import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:wegig_app/features/home/domain/repositories/home_repository.dart';

/// UseCase para buscar perfis
/// Encapsula lógica de busca por nome, instrumento e cidade
class SearchProfilesUseCase {
  SearchProfilesUseCase(this._repository);
  final HomeRepository _repository;

  /// Executa busca de perfis
  Future<List<ProfileEntity>> call({
    String? name,
    String? instrument,
    String? city,
    int limit = 20,
  }) async {
    return _repository.searchProfiles(
      name: name,
      instrument: instrument,
      city: city,
      limit: limit,
    );
  }
}
