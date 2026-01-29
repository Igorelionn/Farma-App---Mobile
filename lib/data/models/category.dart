import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Category extends Equatable {
  final String id;
  final String nome;
  final String icone;
  final String? descricao;
  final int? produtoCount;
  
  const Category({
    required this.id,
    required this.nome,
    required this.icone,
    this.descricao,
    this.produtoCount,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nome: json['nome'] as String,
      icone: json['icone'] as String,
      descricao: json['descricao'] as String?,
      produtoCount: json['produtoCount'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'icone': icone,
      'descricao': descricao,
      'produtoCount': produtoCount,
    };
  }
  
  IconData getIconData() {
    switch (icone) {
      case 'medication':
        return Icons.medication;
      case 'science':
        return Icons.science;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'medical_services':
        return Icons.medical_services;
      case 'healing':
        return Icons.healing;
      case 'spa':
        return Icons.spa;
      default:
        return Icons.category;
    }
  }
  
  @override
  List<Object?> get props => [id, nome, icone, descricao, produtoCount];
}

