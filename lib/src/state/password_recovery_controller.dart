import 'package:flutter/foundation.dart';

import '../data/client_repository.dart';
import '../domain/models.dart';

enum PasswordRecoveryStep { request, code, newPassword, success }

@immutable
class PasswordRecoveryState {
  const PasswordRecoveryState({
    this.step = PasswordRecoveryStep.request,
    this.busy = false,
    this.message,
    this.error,
  });

  final PasswordRecoveryStep step;
  final bool busy;
  final String? message;
  final String? error;
}

class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController(this._repository);

  final ClientRepository _repository;
  PasswordRecoveryState state = const PasswordRecoveryState();
  String? _cpf;
  String? _resetToken;
  bool _disposed = false;
  int _operation = 0;

  Future<bool> requestCode(String cpf) async {
    if (state.busy) return false;
    final operation = ++_operation;
    state = const PasswordRecoveryState(
      step: PasswordRecoveryStep.request,
      busy: true,
    );
    _notify();
    try {
      await _repository.requestPasswordRecovery(cpf);
      if (!_isCurrent(operation)) return false;
      _cpf = cpf;
      _resetToken = null;
      state = const PasswordRecoveryState(
        step: PasswordRecoveryStep.code,
        message:
            'Se o CPF possuir uma conta, enviaremos um código para o e-mail cadastrado.',
      );
      _notify();
      return true;
    } on AppException catch (error) {
      if (!_isCurrent(operation)) return false;
      state = PasswordRecoveryState(
        step: PasswordRecoveryStep.request,
        error: error.message,
      );
      _notify();
      return false;
    } catch (_) {
      if (!_isCurrent(operation)) return false;
      state = const PasswordRecoveryState(
        step: PasswordRecoveryStep.request,
        error: 'Não foi possível solicitar a recuperação. Tente novamente.',
      );
      _notify();
      return false;
    }
  }

  Future<bool> validateCode(String code) async {
    final cpf = _cpf;
    if (state.busy || cpf == null) return false;
    final operation = ++_operation;
    state = PasswordRecoveryState(
      step: PasswordRecoveryStep.code,
      busy: true,
      message: state.message,
    );
    _notify();
    try {
      final token = await _repository.validatePasswordRecoveryCode(cpf, code);
      if (!_isCurrent(operation)) return false;
      _resetToken = token;
      state = const PasswordRecoveryState(
        step: PasswordRecoveryStep.newPassword,
      );
      _notify();
      return true;
    } on AppException catch (error) {
      if (!_isCurrent(operation)) return false;
      state = PasswordRecoveryState(
        step: PasswordRecoveryStep.code,
        message: state.message,
        error: error.message,
      );
      _notify();
      return false;
    } catch (_) {
      if (!_isCurrent(operation)) return false;
      state = const PasswordRecoveryState(
        step: PasswordRecoveryStep.code,
        error: 'Não foi possível validar o código. Tente novamente.',
      );
      _notify();
      return false;
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    final cpf = _cpf;
    final token = _resetToken;
    if (state.busy || cpf == null || token == null) return false;
    final operation = ++_operation;
    state = const PasswordRecoveryState(
      step: PasswordRecoveryStep.newPassword,
      busy: true,
    );
    _notify();
    try {
      await _repository.resetPassword(
        cpf: cpf,
        resetToken: token,
        newPassword: newPassword,
      );
      if (!_isCurrent(operation)) return false;
      _resetToken = null;
      state = const PasswordRecoveryState(step: PasswordRecoveryStep.success);
      _notify();
      return true;
    } on AppException catch (error) {
      if (!_isCurrent(operation)) return false;
      _resetToken = null;
      state = PasswordRecoveryState(
        step: PasswordRecoveryStep.code,
        error: error.message,
      );
      _notify();
      return false;
    } catch (_) {
      if (!_isCurrent(operation)) return false;
      state = const PasswordRecoveryState(
        step: PasswordRecoveryStep.newPassword,
        error: 'Não foi possível redefinir a senha. Tente novamente.',
      );
      _notify();
      return false;
    }
  }

  void restart() {
    if (state.busy) return;
    _operation++;
    _cpf = null;
    _resetToken = null;
    state = const PasswordRecoveryState();
    _notify();
  }

  void clearError() {
    if (state.error == null) return;
    state = PasswordRecoveryState(
      step: state.step,
      busy: state.busy,
      message: state.message,
    );
    _notify();
  }

  bool _isCurrent(int operation) => !_disposed && operation == _operation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    _resetToken = null;
    super.dispose();
  }
}
