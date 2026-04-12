import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';

class CartSummary extends StatelessWidget {
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final VoidCallback onCheckout;
  final bool isLoading;
  
  const CartSummary({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.onCheckout,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo do Pedido',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        _buildSummaryRow('Subtotal', subtotal),
        
        if (discount > 0) ...[
          const SizedBox(height: 12),
          _buildSummaryRow('Desconto', -discount, color: AppColors.error),
        ],
        
        const SizedBox(height: 20),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.h6.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(total.abs()),
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: isLoading ? null : onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF020B21),
                foregroundColor: AppColors.primary,
                elevation: 0,
                shadowColor: Colors.transparent,
                overlayColor: const Color(0xFF020B21),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                minimumSize: const Size(160, 52),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Text(
                      'Continuar',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSummaryRow(String label, double value, {
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal 
              ? AppTextStyles.h6.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          Formatters.currency(value.abs()),
          style: isTotal 
              ? AppTextStyles.h5.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )
              : AppTextStyles.labelLarge.copyWith(
                  color: color ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}
