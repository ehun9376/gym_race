import "package:get_it/get_it.dart";

import "../../feature/auth/data/services/auth_service.dart";
import "../../feature/training/data/repositories/training_repository_impl.dart";
import "../../feature/training/data/services/voice_api_service.dart";
import "../../feature/training/domain/repositories/training_repository.dart";
import "../../feature/training/domain/usecases/log_voice_usecase.dart";
import "../../feature/training/present/view_models/voice_record_view_model.dart";

final getIt = GetIt.instance;

/// 依賴注入設定（依 CLAUDE.md）：
/// - Service / APIService：singleton
/// - Repository / UseCase / ViewModel：factory
class GetItService {
  const GetItService._();

  static void init() {
    // ── Services（singleton）──
    getIt.registerLazySingleton<AuthService>(() => AuthService());
    getIt.registerLazySingleton<VoiceApiService>(() => VoiceApiService());

    // ── Repository（factory）──
    getIt.registerFactory<TrainingRepository>(
      () => TrainingRepositoryImpl(
        authService: getIt<AuthService>(),
        apiService: getIt<VoiceApiService>(),
      ),
    );

    // ── UseCase（factory）──
    getIt.registerFactory<LogVoiceUseCase>(
      () => LogVoiceUseCase(getIt<TrainingRepository>()),
    );

    // ── ViewModel（factory）──
    getIt.registerFactory<VoiceRecordViewModel>(
      () => VoiceRecordViewModel(getIt<LogVoiceUseCase>()),
    );
  }
}
