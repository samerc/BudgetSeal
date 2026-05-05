import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WebServerStatus { stopped, starting, running, error }

class WebCompanionState {
  final WebServerStatus status;
  final String? ipAddress;
  final int port;
  final String? errorMessage;
  final DateTime? startedAt;

  const WebCompanionState({
    this.status = WebServerStatus.stopped,
    this.ipAddress,
    this.port = 7432,
    this.errorMessage,
    this.startedAt,
  });

  WebCompanionState copyWith({
    WebServerStatus? status,
    String? ipAddress,
    int? port,
    String? errorMessage,
    DateTime? startedAt,
    bool clearError = false,
    bool clearIp = false,
  }) {
    return WebCompanionState(
      status: status ?? this.status,
      ipAddress: clearIp ? null : (ipAddress ?? this.ipAddress),
      port: port ?? this.port,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      startedAt: startedAt ?? this.startedAt,
    );
  }

  String? get url => (status == WebServerStatus.running && ipAddress != null)
      ? 'http://$ipAddress:$port'
      : null;

  bool get isRunning => status == WebServerStatus.running;
  bool get isStopped => status == WebServerStatus.stopped;
  bool get isStarting => status == WebServerStatus.starting;
}

class WebCompanionNotifier extends Notifier<WebCompanionState> {
  @override
  WebCompanionState build() => const WebCompanionState();

  void setStarting() =>
      state = state.copyWith(status: WebServerStatus.starting, clearError: true);

  void setRunning(String ip, int port) => state = state.copyWith(
        status: WebServerStatus.running,
        ipAddress: ip,
        port: port,
        startedAt: DateTime.now(),
        clearError: true,
      );

  void setStopped() => state = state.copyWith(
        status: WebServerStatus.stopped,
        clearIp: true,
        clearError: true,
      );

  void setError(String message) =>
      state = state.copyWith(status: WebServerStatus.error, errorMessage: message);
}

final webCompanionProvider =
    NotifierProvider<WebCompanionNotifier, WebCompanionState>(
        WebCompanionNotifier.new);
