import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String? userId;
  final String label;
  final String street;
  final String number;
  final String? complement;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;
  
  const Address({
    required this.id,
    this.userId,
    required this.label,
    required this.street,
    required this.number,
    this.complement,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
    this.isDefault = false,
  });
  
  String get fullAddress {
    final comp = complement != null && complement!.isNotEmpty 
        ? ', $complement' 
        : '';
    return '$street, $number$comp - $neighborhood, $city/$state - CEP: $zipCode';
  }
  
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      label: json['label'] as String,
      street: json['street'] as String,
      number: json['number'] as String,
      complement: json['complement'] as String?,
      neighborhood: json['neighborhood'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String? ?? json['zipCode'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'street': street,
      'number': number,
      'complement': complement,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'is_default': isDefault,
    };
  }
  
  @override
  List<Object?> get props => [
    id, userId, label, street, number, complement, 
    neighborhood, city, state, zipCode, isDefault,
  ];
}
