import 'package:equatable/equatable.dart';

enum PaymentType {
  boleto,
  creditCard,
  pix,
  accountCredit,
}

class PaymentMethod extends Equatable {
  final String id;
  final PaymentType type;
  final String label;
  final String? description;
  final List<int>? installmentOptions; // Opções de parcelamento
  final int? daysToExpire; // Para boleto
  
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.description,
    this.installmentOptions,
    this.daysToExpire,
  });
  
  String get typeLabel {
    switch (type) {
      case PaymentType.boleto:
        return 'Boleto Bancário';
      case PaymentType.creditCard:
        return 'Cartão de Crédito';
      case PaymentType.pix:
        return 'PIX';
      case PaymentType.accountCredit:
        return 'Crédito da Conta';
    }
  }
  
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: PaymentType.values.firstWhere(
        (e) => e.toString() == 'PaymentType.${json['type']}',
      ),
      label: json['label'] as String,
      description: json['description'] as String?,
      installmentOptions: json['installmentOptions'] != null
          ? List<int>.from(json['installmentOptions'] as List)
          : null,
      daysToExpire: json['daysToExpire'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'label': label,
      'description': description,
      'installmentOptions': installmentOptions,
      'daysToExpire': daysToExpire,
    };
  }
  
  @override
  List<Object?> get props => [
    id, type, label, description, installmentOptions, daysToExpire,
  ];
}


