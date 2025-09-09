import 'package:flutter/foundation.dart';
import 'models/auth_state.dart';
import 'services/auth_service.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthService _authService;
  AuthState _state = const AuthState();

  AuthNotifier(this._authService);

  AuthState get state => _state;

  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  bool get isLoading => _state.isLoading;
  String? get errorMessage => _state.errorMessage;

  /// 初始化认证状态
  Future<void> initialize() async {
    _updateState(_state.copyWith(status: AuthStatus.unknown));
    
    try {
      final isAuth = await _authService.isAuthenticated();
      _updateState(_state.copyWith(
        status: isAuth ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to check authentication status',
      ));
    }
  }

  /// 登录
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _updateState(_state.copyWith(
      status: AuthStatus.authenticating,
      isLoading: true,
      errorMessage: null,
    ));

    try {
      final response = await _authService.login(
        username: username,
        password: password,
      );

      if (response.success) {
        _updateState(_state.copyWith(
          status: AuthStatus.authenticated,
          isLoading: false,
          errorMessage: null,
        ));
        return true;
      } else {
        _updateState(_state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: response.message ?? 'Login failed',
        ));
        return false;
      }
    } catch (e) {
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: 'Login error: $e',
      ));
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    _updateState(_state.copyWith(isLoading: true));

    try {
      await _authService.logout();
    } catch (e) {
      // 即使登出失败也要清除本地状态
    } finally {
      _updateState(_state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        errorMessage: null,
      ));
    }
  }

  /// 清除错误信息
  void clearError() {
    if (_state.errorMessage != null) {
      _updateState(_state.copyWith(errorMessage: null));
    }
  }

  void _updateState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}