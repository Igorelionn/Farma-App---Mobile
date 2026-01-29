import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nome;
  final String email;
  final String empresa;
  final String cnpj;
  final String tipo; // 'farmacia', 'clinica'
  final String? telefone;
  final double? limiteCredito;
  
  const User({
    required this.id,
    required this.nome,
    required this.email,
    required this.empresa,
    required this.cnpj,
    required this.tipo,
    this.telefone,
    this.limiteCredito,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      empresa: json['empresa'] as String,
      cnpj: json['cnpj'] as String,
      tipo: json['tipo'] as String,
      telefone: json['telefone'] as String?,
      limiteCredito: json['limiteCredito'] != null 
          ? (json['limiteCredito'] as num).toDouble()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'empresa': empresa,
      'cnpj': cnpj,
      'tipo': tipo,
      'telefone': telefone,
      'limiteCredito': limiteCredito,
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    nome,
    email,
    empresa,
    cnpj,
    tipo,
    telefone,
    limiteCredito,
  ];
}

