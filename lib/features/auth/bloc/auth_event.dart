import 'dart:typed_data';

import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String username;
  final String password;
  
  const LoginSubmitted({
    required this.username,
    required this.password,
  });
  
  @override
  List<Object?> get props => [username, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String nome;
  final String empresa;
  final String cnpj;
  final String tipo;
  final String? telefone;

  // Endereço
  final String? cep;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;

  // Documentação Legal e Fiscal (números verificáveis)
  final String? inscricaoEstadual;
  final String? inscricaoMunicipal;

  // Documentação Sanitária (números verificáveis na ANVISA)
  final String? afe;
  final String? autorizacaoEspecial;

  // Documentos físicos com validade → upload: Map<fieldName, List<(fileName, bytes)>>
  final Map<String, List<(String, Uint8List)>>? documents;

  // Responsável Técnico
  final String? responsavelNome;
  final String? responsavelCpf;
  final String? responsavelCrf;

  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.nome,
    required this.empresa,
    required this.cnpj,
    required this.tipo,
    this.telefone,
    this.cep,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.inscricaoEstadual,
    this.inscricaoMunicipal,
    this.afe,
    this.autorizacaoEspecial,
    this.documents,
    this.responsavelNome,
    this.responsavelCpf,
    this.responsavelCrf,
  });

  @override
  List<Object?> get props => [
        email, password, nome, empresa, cnpj, tipo, telefone,
        cep, endereco, numero, complemento, bairro, cidade, estado,
        inscricaoEstadual, inscricaoMunicipal, afe, autorizacaoEspecial,
        responsavelNome, responsavelCpf, responsavelCrf,
      ];
}

class LogoutRequested extends AuthEvent {}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
