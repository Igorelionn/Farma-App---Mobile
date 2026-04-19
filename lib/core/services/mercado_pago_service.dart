import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

enum MercadoPagoEnvironment {
  sandbox,
  production,
}

class MercadoPagoService {
  static const String _sandboxUrl = 'https://api.mercadopago.com';
  static const String _productionUrl = 'https://api.mercadopago.com';
  
  final String _accessToken;
  final MercadoPagoEnvironment _environment;
  
  MercadoPagoService({
    required String accessToken,
    MercadoPagoEnvironment environment = MercadoPagoEnvironment.sandbox,
  })  : _accessToken = accessToken,
        _environment = environment;

  String get _baseUrl =>
      _environment == MercadoPagoEnvironment.sandbox ? _sandboxUrl : _productionUrl;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };

  /// Cria um pagamento PIX
  /// Retorna o QR Code e o código de pagamento
  Future<Map<String, dynamic>> createPixPayment({
    required double amount,
    required String description,
    required String payerEmail,
    String? externalReference,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/payments');
      
      final body = jsonEncode({
        'transaction_amount': amount,
        'description': description,
        'payment_method_id': 'pix',
        'external_reference': externalReference,
        'payer': {
          'email': payerEmail,
        },
      });

      AppLogger.info('Criando pagamento PIX', 'MercadoPagoService');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // Extrai informações do PIX
        final qrCode = data['point_of_interaction']['transaction_data']['qr_code'];
        final qrCodeBase64 = data['point_of_interaction']['transaction_data']['qr_code_base64'];
        final ticketUrl = data['point_of_interaction']['transaction_data']['ticket_url'];
        
        AppLogger.info('Pagamento PIX criado com sucesso', 'MercadoPagoService');
        
        return {
          'success': true,
          'payment_id': data['id'],
          'status': data['status'],
          'qr_code': qrCode,
          'qr_code_base64': qrCodeBase64,
          'ticket_url': ticketUrl,
          'expiration_date': data['date_of_expiration'],
        };
      } else {
        final error = jsonDecode(response.body);
        AppLogger.error(
          'Erro ao criar pagamento PIX',
          error,
          null,
          'MercadoPagoService',
        );
        
        return {
          'success': false,
          'error': error['message'] ?? 'Erro desconhecido',
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exceção ao criar pagamento PIX', e, stackTrace, 'MercadoPagoService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cria um pagamento com cartão de crédito
  Future<Map<String, dynamic>> createCardPayment({
    required double amount,
    required String description,
    required String token, // Token do cartão gerado pelo SDK
    required int installments,
    required String payerEmail,
    String? externalReference,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/payments');
      
      final body = jsonEncode({
        'transaction_amount': amount,
        'token': token,
        'description': description,
        'installments': installments,
        'payment_method_id': 'visa', // Será detectado automaticamente pelo token
        'external_reference': externalReference,
        'payer': {
          'email': payerEmail,
        },
      });

      AppLogger.info('Criando pagamento com cartão', 'MercadoPagoService');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        AppLogger.info('Pagamento com cartão criado com sucesso', 'MercadoPagoService');
        
        return {
          'success': true,
          'payment_id': data['id'],
          'status': data['status'],
          'status_detail': data['status_detail'],
        };
      } else {
        final error = jsonDecode(response.body);
        AppLogger.error(
          'Erro ao criar pagamento com cartão',
          error,
          null,
          'MercadoPagoService',
        );
        
        return {
          'success': false,
          'error': error['message'] ?? 'Erro desconhecido',
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exceção ao criar pagamento com cartão', e, stackTrace, 'MercadoPagoService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Consulta o status de um pagamento
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/payments/$paymentId');
      
      final response = await http.get(url, headers: _headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        return {
          'success': true,
          'status': data['status'],
          'status_detail': data['status_detail'],
          'payment_type': data['payment_type_id'],
        };
      } else {
        return {
          'success': false,
          'error': 'Não foi possível consultar o pagamento',
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao consultar status do pagamento', e, stackTrace, 'MercadoPagoService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Cria um boleto bancário
  Future<Map<String, dynamic>> createBoletoPayment({
    required double amount,
    required String description,
    required String payerEmail,
    required String payerName,
    required String payerCpf,
    String? externalReference,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/payments');
      
      final body = jsonEncode({
        'transaction_amount': amount,
        'description': description,
        'payment_method_id': 'bolbradesco',
        'external_reference': externalReference,
        'payer': {
          'email': payerEmail,
          'first_name': payerName.split(' ').first,
          'last_name': payerName.split(' ').skip(1).join(' '),
          'identification': {
            'type': 'CPF',
            'number': payerCpf,
          },
        },
      });

      AppLogger.info('Criando boleto bancário', 'MercadoPagoService');
      
      final response = await http.post(
        url,
        headers: _headers,
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        AppLogger.info('Boleto criado com sucesso', 'MercadoPagoService');
        
        return {
          'success': true,
          'payment_id': data['id'],
          'status': data['status'],
          'boleto_url': data['transaction_details']['external_resource_url'],
          'barcode': data['barcode']['content'],
          'due_date': data['date_of_expiration'],
        };
      } else {
        final error = jsonDecode(response.body);
        AppLogger.error(
          'Erro ao criar boleto',
          error,
          null,
          'MercadoPagoService',
        );
        
        return {
          'success': false,
          'error': error['message'] ?? 'Erro desconhecido',
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Exceção ao criar boleto', e, stackTrace, 'MercadoPagoService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
