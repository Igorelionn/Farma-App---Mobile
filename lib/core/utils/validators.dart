class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    
    return null;
  }
  
  static String? cpf(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    // Remove caracteres não numéricos
    final cleanCpf = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanCpf.length != 11) {
      return 'CPF inválido';
    }
    
    return null;
  }
  
  static String? cnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    
    // Remove caracteres não numéricos
    final cleanCnpj = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanCnpj.length != 14) {
      return 'CNPJ inválido';
    }
    
    return null;
  }
  
  static String? required(String? value, [String fieldName = 'Campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }
}

