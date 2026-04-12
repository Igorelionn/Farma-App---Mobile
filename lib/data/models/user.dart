import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String nome;
  final String email;
  final String? username;
  final String empresa;
  final String cnpj;
  final String tipo;
  final String? telefone;
  final double? limiteCredito;
  final String status;
  final String role;
  final DateTime? approvedAt;
  final DateTime createdAt;
  
  // Dados de endereço
  final String? cep;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  
  // Dados do responsável
  final String? responsavelNome;
  final String? responsavelCpf;
  
  // Documentação Legal e Fiscal
  final String? inscricaoEstadual;
  final String? inscricaoMunicipal;
  final String? alvaraFuncionamento;

  // Documentação Sanitária
  final String? afe;
  final String? autorizacaoEspecial;
  final String? licencaSanitaria;
  final String? crt;

  // Responsável Técnico
  final String? responsavelCrf;
  
  const User({
    required this.id,
    required this.nome,
    required this.email,
    this.username,
    required this.empresa,
    required this.cnpj,
    required this.tipo,
    this.telefone,
    this.limiteCredito,
    this.status = 'pending',
    this.role = 'customer',
    this.approvedAt,
    required this.createdAt,
    this.cep,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.responsavelNome,
    this.responsavelCpf,
    this.inscricaoEstadual,
    this.inscricaoMunicipal,
    this.alvaraFuncionamento,
    this.afe,
    this.autorizacaoEspecial,
    this.licencaSanitaria,
    this.crt,
    this.responsavelCrf,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isAdmin => role == 'admin';
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String?,
      empresa: json['empresa'] as String? ?? '',
      cnpj: json['cnpj'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'farmacia',
      telefone: json['telefone'] as String?,
      limiteCredito: json['limite_credito'] != null 
          ? (json['limite_credito'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'pending',
      role: json['role'] as String? ?? 'customer',
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      cep: json['cep'] as String?,
      endereco: json['endereco'] as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      responsavelNome: json['responsavel_nome'] as String?,
      responsavelCpf: json['responsavel_cpf'] as String?,
      inscricaoEstadual: json['inscricao_estadual'] as String?,
      inscricaoMunicipal: json['inscricao_municipal'] as String?,
      alvaraFuncionamento: json['alvara_funcionamento'] as String?,
      afe: json['afe'] as String?,
      autorizacaoEspecial: json['autorizacao_especial'] as String?,
      licencaSanitaria: json['licenca_sanitaria'] as String?,
      crt: json['crt'] as String?,
      responsavelCrf: json['responsavel_crf'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'username': username,
      'empresa': empresa,
      'cnpj': cnpj,
      'tipo': tipo,
      'telefone': telefone,
      'limite_credito': limiteCredito,
      'status': status,
      'role': role,
      'cep': cep,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'responsavel_nome': responsavelNome,
      'responsavel_cpf': responsavelCpf,
      'inscricao_estadual': inscricaoEstadual,
      'inscricao_municipal': inscricaoMunicipal,
      'alvara_funcionamento': alvaraFuncionamento,
      'afe': afe,
      'autorizacao_especial': autorizacaoEspecial,
      'licenca_sanitaria': licencaSanitaria,
      'crt': crt,
      'responsavel_crf': responsavelCrf,
    };
  }
  
  @override
  List<Object?> get props => [
    id, nome, email, username, empresa, cnpj, tipo,
    telefone, limiteCredito, status, role,
    approvedAt, createdAt,
    cep, endereco, numero, complemento, bairro, cidade, estado,
    responsavelNome, responsavelCpf, responsavelCrf,
    inscricaoEstadual, inscricaoMunicipal, alvaraFuncionamento,
    afe, autorizacaoEspecial, licencaSanitaria, crt,
  ];
}
