import 'package:flutter/foundation.dart';

import '../data/client_repository.dart';
import '../domain/client_registration.dart';

enum RegistrationPhase { idle, validating, submitting, success, error }

@immutable
class RegistrationState {
  const RegistrationState({
    this.phase = RegistrationPhase.idle,
    this.message,
    this.failureKind,
    this.fieldErrors = const {},
    this.legalConfig = const RegistrationLegalConfig.none(),
    this.loadingLegalConfig = true,
    this.legalConfigError,
  });

  final RegistrationPhase phase;
  final String? message;
  final RegistrationFailureKind? failureKind;
  final Map<String, String> fieldErrors;
  final RegistrationLegalConfig legalConfig;
  final bool loadingLegalConfig;
  final String? legalConfigError;

  bool get isBusy =>
      phase == RegistrationPhase.validating ||
      phase == RegistrationPhase.submitting;
}

class RegistrationController extends ChangeNotifier {
  RegistrationController(this._repository);

  final ClientRepository _repository;
  RegistrationState state = const RegistrationState();
  bool _configurationRequestInProgress = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> loadLegalConfig() async {
    if (_configurationRequestInProgress) return;
    _configurationRequestInProgress = true;
    state = RegistrationState(
      phase: state.phase,
      fieldErrors: state.fieldErrors,
      loadingLegalConfig: true,
    );
    _notify();
    try {
      final config = await _repository.loadRegistrationLegalConfig();
      if (_disposed) return;
      state = RegistrationState(
        phase: state.phase,
        fieldErrors: state.fieldErrors,
        legalConfig: config,
        loadingLegalConfig: false,
      );
    } catch (_) {
      if (_disposed) return;
      state = RegistrationState(
        phase: state.phase,
        fieldErrors: state.fieldErrors,
        loadingLegalConfig: false,
        legalConfigError:
            'Não foi possível carregar os Termos de Uso e a Política de Privacidade.',
      );
    } finally {
      _configurationRequestInProgress = false;
      _notify();
    }
  }

  Future<bool> submit(ClientRegistrationRequest request) async {
    if (state.isBusy ||
        state.loadingLegalConfig ||
        state.legalConfigError != null) {
      return false;
    }

    final legalConfig = state.legalConfig;

    state = RegistrationState(
      phase: RegistrationPhase.validating,
      legalConfig: legalConfig,
      loadingLegalConfig: false,
    );
    _notify();

    state = RegistrationState(
      phase: RegistrationPhase.submitting,
      legalConfig: legalConfig,
      loadingLegalConfig: false,
    );
    _notify();

    try {
      await _repository.registerClient(request);
      if (_disposed) return false;
      state = RegistrationState(
        phase: RegistrationPhase.success,
        legalConfig: legalConfig,
        loadingLegalConfig: false,
      );
      _notify();
      return true;
    } on RegistrationException catch (error) {
      if (_disposed) return false;
      state = RegistrationState(
        phase: RegistrationPhase.error,
        message: error.message,
        failureKind: error.kind,
        fieldErrors: error.fieldErrors,
        legalConfig: legalConfig,
        loadingLegalConfig: false,
      );
      _notify();
      return false;
    } catch (_) {
      if (_disposed) return false;
      state = RegistrationState(
        phase: RegistrationPhase.error,
        message:
            'Não foi possível criar sua conta agora. Tente novamente mais tarde.',
        failureKind: RegistrationFailureKind.unknown,
        legalConfig: legalConfig,
        loadingLegalConfig: false,
      );
      _notify();
      return false;
    }
  }

  void clearErrorsFor(Iterable<String> fields) {
    if (state.phase != RegistrationPhase.error) return;
    final remaining = Map<String, String>.from(state.fieldErrors);
    for (final field in fields) {
      remaining.remove(field);
    }
    state = RegistrationState(
      phase: RegistrationPhase.idle,
      fieldErrors: remaining,
      legalConfig: state.legalConfig,
      loadingLegalConfig: state.loadingLegalConfig,
      legalConfigError: state.legalConfigError,
    );
    _notify();
  }
}
