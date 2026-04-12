class Validators {
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Usuário ou senha inválidos';
    }
    if (value.length < 3) {
      return 'Usuário ou senha inválidos';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    // RFC 5321 simplificado — aceita TLDs longos (.store, .museum etc.)
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Email inválido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Usuário ou senha inválidos';
    }
    if (value.length < 6) {
      return 'Usuário ou senha inválidos';
    }
    return null;
  }

  /// Valida CPF com verificação dos dígitos verificadores (algoritmo oficial).
  static String? cpf(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 11) return 'CPF inválido';

    // Rejeita sequências de dígitos idênticos (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return 'CPF inválido';

    // Cálculo do 1º dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(digits[i]) * (10 - i);
    }
    int remainder = (sum * 10) % 11;
    if (remainder == 10 || remainder == 11) remainder = 0;
    if (remainder != int.parse(digits[9])) return 'CPF inválido';

    // Cálculo do 2º dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * (11 - i);
    }
    remainder = (sum * 10) % 11;
    if (remainder == 10 || remainder == 11) remainder = 0;
    if (remainder != int.parse(digits[10])) return 'CPF inválido';

    return null;
  }

  /// Valida CNPJ com verificação dos dígitos verificadores (algoritmo oficial).
  static String? cnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNPJ é obrigatório';
    }

    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length != 14) return 'CNPJ inválido';

    // Rejeita sequências de dígitos idênticos (ex: 00.000.000/0000-00)
    if (RegExp(r'^(\d)\1{13}$').hasMatch(digits)) return 'CNPJ inválido';

    // Cálculo do 1º dígito verificador
    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(digits[i]) * weights1[i];
    }
    int remainder = sum % 11;
    final d1 = remainder < 2 ? 0 : 11 - remainder;
    if (d1 != int.parse(digits[12])) return 'CNPJ inválido';

    // Cálculo do 2º dígito verificador
    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(digits[i]) * weights2[i];
    }
    remainder = sum % 11;
    final d2 = remainder < 2 ? 0 : 11 - remainder;
    if (d2 != int.parse(digits[13])) return 'CNPJ inválido';

    return null;
  }

  static String? required(String? value, [String fieldName = 'Campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }
}
