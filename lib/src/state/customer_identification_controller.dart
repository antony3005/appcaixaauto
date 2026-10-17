import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/client_repository.dart';
import '../domain/models.dart';

enum CustomerIdentificationPhase {
  initial,
  loading,
  valid,
  expired,
  error,
  offline,
}

class CustomerIdentificationController extends ChangeNotifier {
  CustomerIdentificationController({
    required this.repository,
    required this.session,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ClientRepository repository;
  final AuthSession session;
  final DateTime Function() _now;

  CustomerIdentificationPhase phase = CustomerIdentificationPhase.initial;
  CustomerIdentificationToken? token;
  String? errorMessage;
  Timer? _timer;
  Duration _serverClockOffset = Duration.zero;
  int _generation = 0;
  bool _disposed = false;

  bool get isLoading => phase == CustomerIdentificationPhase.loading;
  bool get hasValidQr => phase == CustomerIdentificationPhase.valid;

  Duration get remaining {
    final active = token;
    if (active == null) return Duration.zero;
    final value = active.expiresAt.difference(_serverNow);
    return value.isNegative ? Duration.zero : value;
  }

  DateTime get _serverNow => _now().add(_serverClockOffset);

  Future<void> generate() async {
    if (isLoading || _disposed) return;
    final requestGeneration = ++_generation;
    _timer?.cancel();
    token = null;
    errorMessage = null;
    phase = CustomerIdentificationPhase.loading;
    notifyListeners();
    try {
      final result = await repository.createIdentificationToken(session);
      if (_disposed || requestGeneration != _generation) return;
      _serverClockOffset = result.serverTime.difference(_now());
      if (!result.expiresAt.isAfter(_serverNow)) {
        token = null;
        phase = CustomerIdentificationPhase.expired;
      } else {
        token = result;
        phase = CustomerIdentificationPhase.valid;
        _startTimer();
      }
    } on NetworkUnavailableException catch (error) {
      if (_disposed || requestGeneration != _generation) return;
      token = null;
      errorMessage = error.message;
      phase = CustomerIdentificationPhase.offline;
    } on AppException catch (error) {
      if (_disposed || requestGeneration != _generation) return;
      token = null;
      errorMessage = error.message;
      phase = CustomerIdentificationPhase.error;
    } catch (_) {
      if (_disposed || requestGeneration != _generation) return;
      token = null;
      errorMessage =
          'Não foi possível gerar seu QR. Verifique sua conexão e tente novamente.';
      phase = CustomerIdentificationPhase.error;
    }
    if (!_disposed && requestGeneration == _generation) notifyListeners();
  }

  void refreshForCurrentTime() {
    if (_disposed || phase != CustomerIdentificationPhase.valid) return;
    final active = token;
    if (active == null || !active.expiresAt.isAfter(_serverNow)) {
      _timer?.cancel();
      token = null;
      phase = CustomerIdentificationPhase.expired;
    }
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => refreshForCurrentTime(),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    super.dispose();
  }
}
