enum RegistrationFailureKind {
  cpfAlreadyRegistered,
  emailAlreadyRegistered,
  invalidCpf,
  validation,
  network,
  server,
  rateLimited,
  unknown,
}

class ClientRegistrationRequest {
  const ClientRegistrationRequest({
    required this.firstName,
    required this.lastName,
    required this.cpf,
    required this.email,
    required this.phone,
    required this.password,
    this.termsAccepted,
    this.privacyAccepted,
    this.termsVersion,
    this.privacyVersion,
  });

  factory ClientRegistrationRequest.fromForm({
    required String fullName,
    required String cpf,
    required String email,
    required String phone,
    required String password,
    RegistrationLegalConfig legalConfig = const RegistrationLegalConfig.none(),
    bool termsAccepted = false,
    bool privacyAccepted = false,
  }) {
    final normalizedName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parts = normalizedName.split(' ');
    return ClientRegistrationRequest(
      firstName: parts.first,
      lastName: parts.skip(1).join(' '),
      cpf: cpf.replaceAll(RegExp(r'\D'), ''),
      email: email.trim(),
      phone: phone.replaceAll(RegExp(r'\D'), ''),
      password: password,
      termsAccepted: legalConfig.configured ? termsAccepted : null,
      privacyAccepted: legalConfig.configured ? privacyAccepted : null,
      termsVersion: legalConfig.configured ? legalConfig.termsVersion : null,
      privacyVersion: legalConfig.configured
          ? legalConfig.privacyVersion
          : null,
    );
  }

  final String firstName;
  final String lastName;
  final String cpf;
  final String email;
  final String phone;
  final String password;
  final bool? termsAccepted;
  final bool? privacyAccepted;
  final String? termsVersion;
  final String? privacyVersion;

  /// Espelha somente os campos pessoais de `ClientRegistrationRequest`.
  /// Papel, Empresa e Condomínio nunca são controlados pelo app cliente.
  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'nome': firstName,
      'sobrenome': lastName,
      'email': email,
      'senha': password,
      'cpf': cpf,
      'telefone': phone.isEmpty ? null : phone,
    };
    if (termsAccepted != null) {
      json.addAll({
        'termsAccepted': termsAccepted,
        'privacyAccepted': privacyAccepted,
        'termsVersion': termsVersion,
        'privacyVersion': privacyVersion,
      });
    }
    return json;
  }
}

class RegistrationLegalConfig {
  const RegistrationLegalConfig({
    required this.termsUrl,
    required this.privacyUrl,
    required this.termsVersion,
    required this.privacyVersion,
  }) : configured = true;

  const RegistrationLegalConfig.none()
    : termsUrl = null,
      privacyUrl = null,
      termsVersion = null,
      privacyVersion = null,
      configured = false;

  factory RegistrationLegalConfig.fromJson(Map<String, dynamic> json) {
    if (json['legalDocumentsConfigured'] != true) {
      return const RegistrationLegalConfig.none();
    }
    final termsUrl = Uri.tryParse(json['termsUrl']?.toString() ?? '');
    final privacyUrl = Uri.tryParse(json['privacyUrl']?.toString() ?? '');
    final termsVersion = json['termsVersion']?.toString().trim() ?? '';
    final privacyVersion = json['privacyVersion']?.toString().trim() ?? '';
    if (termsUrl == null ||
        privacyUrl == null ||
        termsUrl.scheme != 'https' ||
        privacyUrl.scheme != 'https' ||
        termsVersion.isEmpty ||
        privacyVersion.isEmpty) {
      throw const FormatException('Configuração legal inválida.');
    }
    return RegistrationLegalConfig(
      termsUrl: termsUrl,
      privacyUrl: privacyUrl,
      termsVersion: termsVersion,
      privacyVersion: privacyVersion,
    );
  }

  final bool configured;
  final Uri? termsUrl;
  final Uri? privacyUrl;
  final String? termsVersion;
  final String? privacyVersion;
}

class RegistrationException implements Exception {
  const RegistrationException({
    required this.kind,
    required this.message,
    this.code,
    this.fieldErrors = const {},
  });

  final RegistrationFailureKind kind;
  final String message;
  final String? code;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

bool isValidCpf(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
    return false;
  }

  int verifier(int length, int weight) {
    var total = 0;
    for (var index = 0; index < length; index++) {
      total += int.parse(digits[index]) * (weight - index);
    }
    final remainder = (total * 10) % 11;
    return remainder == 10 ? 0 : remainder;
  }

  return verifier(9, 10) == int.parse(digits[9]) &&
      verifier(10, 11) == int.parse(digits[10]);
}
