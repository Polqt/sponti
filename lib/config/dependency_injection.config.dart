// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../core/network/network_info.dart' as _i6;
import '../features/auth/data/datasources/auth_remote_datasource.dart' as _i100;
import '../features/auth/data/repositories/auth_repository_impl.dart' as _i101;
import '../features/auth/domain/repositories/auth_repository.dart' as _i102;
import '../features/auth/domain/usecases/auth_usecases.dart' as _i103;
import 'dependency_injection.dart' as _i9;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i454.SupabaseClient>(() => registerModule.supabaseClient);
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i6.NetworkInfo>(
      () => _i6.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i100.AuthRemoteDataSource>(
      () => _i100.AuthRemoteDataSourceImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i102.AuthRepository>(
      () => _i101.AuthRepositoryImpl(gh<_i100.AuthRemoteDataSource>()),
    );
    gh.lazySingleton<_i103.SignInWithGoogleUseCase>(
      () => _i103.SignInWithGoogleUseCase(gh<_i102.AuthRepository>()),
    );
    gh.lazySingleton<_i103.SignInWithFacebookUseCase>(
      () => _i103.SignInWithFacebookUseCase(gh<_i102.AuthRepository>()),
    );
    gh.lazySingleton<_i103.SignOutUseCase>(
      () => _i103.SignOutUseCase(gh<_i102.AuthRepository>()),
    );
    gh.lazySingleton<_i103.GetCurrentUserUseCase>(
      () => _i103.GetCurrentUserUseCase(gh<_i102.AuthRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i9.RegisterModule {}
