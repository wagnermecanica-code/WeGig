import 'package:core_ui/features/settings/domain/entities/user_settings_entity.dart';
import 'package:wegig_app/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:wegig_app/features/settings/domain/repositories/settings_repository.dart';

/// Implementation of SettingsRepository
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required this.remoteDataSource});

  final ISettingsRemoteDataSource remoteDataSource;

  @override
  Future<UserSettingsEntity> getSettings(String profileId) async {
    return remoteDataSource.getSettings(profileId);
  }

  @override
  Future<void> updateSettings(UserSettingsEntity settings) async {
    await remoteDataSource.updateSettings(settings);
  }
}
