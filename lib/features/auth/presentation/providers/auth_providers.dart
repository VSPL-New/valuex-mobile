import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/otp/otp_provider.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/native_google_id_token_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/google_id_token_source.dart';
import '../../domain/usecases/restore_session.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider), ref.watch(otpProviderProvider));
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  );
}

@Riverpod(keepAlive: true)
RestoreSession restoreSession(Ref ref) {
  return RestoreSession(ref.watch(authRepositoryProvider));
}

@Riverpod(keepAlive: true)
GoogleIdTokenSource googleIdTokenSource(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return NativeGoogleIdTokenSource(
    serverClientId: config.googleServerClientId,
    iosClientId: config.googleIosClientId,
  );
}
