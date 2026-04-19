import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/mercado_pago_service.dart';
import '../../../core/utils/logger.dart';

class PixPaymentScreen extends StatefulWidget {
  final String qrCode;
  final String qrCodeBase64;
  final String paymentId;
  final double amount;
  final MercadoPagoService mercadoPagoService;

  const PixPaymentScreen({
    super.key,
    required this.qrCode,
    required this.qrCodeBase64,
    required this.paymentId,
    required this.amount,
    required this.mercadoPagoService,
  });

  @override
  State<PixPaymentScreen> createState() => _PixPaymentScreenState();
}

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  Timer? _statusCheckTimer;
  bool _isCheckingStatus = false;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _startStatusCheck();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _startStatusCheck() {
    // Verifica o status do pagamento a cada 3 segundos
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isCheckingStatus) return;
      
      setState(() => _isCheckingStatus = true);
      
      try {
        final result = await widget.mercadoPagoService.getPaymentStatus(widget.paymentId);
        
        if (result['success'] == true) {
          final status = result['status'];
          
          setState(() {
            _status = status;
            _isCheckingStatus = false;
          });

          // Se o pagamento foi aprovado, fecha a tela e retorna sucesso
          if (status == 'approved') {
            _statusCheckTimer?.cancel();
            if (mounted) {
              Navigator.of(context).pop(true); // Retorna true = pagamento aprovado
            }
          }
        } else {
          setState(() => _isCheckingStatus = false);
        }
      } catch (e) {
        AppLogger.error('Erro ao verificar status do pagamento', e, null, 'PixPaymentScreen');
        setState(() => _isCheckingStatus = false);
      }
    });
  }

  void _copyQrCode() {
    Clipboard.setData(ClipboardData(text: widget.qrCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código PIX copiado!'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pagamento PIX'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ícone PIX
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pix,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Título
            Text(
              'Pague com PIX',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Valor
            Text(
              'R\$ ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}',
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: widget.qrCode,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instruções
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como pagar:',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStep('1', 'Abra o app do seu banco'),
                  const SizedBox(height: 8),
                  _buildStep('2', 'Escolha pagar com PIX'),
                  const SizedBox(height: 8),
                  _buildStep('3', 'Escaneie o QR Code ou copie o código'),
                  const SizedBox(height: 8),
                  _buildStep('4', 'Confirme o pagamento'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão copiar código
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _copyQrCode,
                icon: const Icon(Icons.content_copy, size: 20),
                label: const Text('Copiar código PIX'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Status
            if (_isCheckingStatus)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Aguardando pagamento...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 8),
            
            // Aviso
            Text(
              'O pagamento será confirmado automaticamente',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }
}
