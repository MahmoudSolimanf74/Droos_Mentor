import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/exceptions.dart';
import '../data/auth_repository.dart';
import '../domain/user_profile.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserProfile user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthRoleUnauthorized extends AuthState {
  final String message;

  const AuthRoleUnauthorized(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserProfile?>? _authSubscription;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        if (user.isTeacher) {
          emit(Authenticated(user));
        } else {
          emit(const AuthRoleUnauthorized('الحساب المسجل ليس حساب معلم مصرح له بالدخول لتطبيق الإدارة.'));
        }
      } else {
        if (state is! AuthInitial && state is! AuthLoading) {
          emit(Unauthenticated());
        }
      }
    }, onError: (e) {
      if (e is RoleUnauthorizedException) {
        emit(AuthRoleUnauthorized(e.message));
      }
    });
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null && user.isTeacher) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } on RoleUnauthorizedException catch (e) {
      emit(AuthRoleUnauthorized(e.message));
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithGoogle();
    } on RoleUnauthorizedException catch (e) {
      emit(AuthRoleUnauthorized(e.message));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('AuthException: ', '')));
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithEmailPassword(email, password);
      emit(Authenticated(user));
    } on RoleUnauthorizedException catch (e) {
      emit(AuthRoleUnauthorized(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signUpWithEmailPassword(String email, String password, String name) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUpWithEmailPassword(email, password, name);
      emit(Authenticated(user));
    } on RoleUnauthorizedException catch (e) {
      emit(AuthRoleUnauthorized(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> updateProfileName(String newName) async {
    final previousState = state;
    emit(AuthLoading());
    try {
      final updatedUser = await _authRepository.updateProfileName(newName);
      emit(Authenticated(updatedUser));
    } catch (e) {
      emit(AuthError(e.toString()));
      if (previousState is Authenticated) {
        emit(previousState);
      }
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    await _authRepository.signOut();
    emit(Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
