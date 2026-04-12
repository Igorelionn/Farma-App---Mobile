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
  final List<int>? installmentOptions;
  final int? daysToExpire;
  
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
    final typeStr = json['type'] as String;
    final paymentType = PaymentType.values.firstWhere(
      (e) => e.toString() == 'PaymentType.$typeStr' || e.name == typeStr,
      orElse: () => PaymentType.boleto,
    );

    List<int>? installments;
    if (json['installment_options'] != null) {
      installments = List<int>.from(json['installment_options'] as List);
    } else if (json['installmentOptions'] != null) {
      installments = List<int>.from(json['installmentOptions'] as List);
    }

    return PaymentMethod(
      id: json['id'] as String,
      type: paymentType,
      label: json['label'] as String,
      description: json['description'] as String?,
      installmentOptions: installments,
      daysToExpire: json['days_to_expire'] as int? ?? json['daysToExpire'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'description': description,
      'installment_options': installmentOptions,
      'days_to_expire': daysToExpire,
    };
  }
  
  @override
  List<Object?> get props => [
    id, type, label, description, installmentOptions, daysToExpire,
  ];
}
