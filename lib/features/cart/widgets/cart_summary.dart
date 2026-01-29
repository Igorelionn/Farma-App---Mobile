import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumo do Pedido', style: AppTextStyles.h6),
          const SizedBox(height: 16),
          
          _buildSummaryRow('Subtotal', subtotal),
          const SizedBox(height: 8),
          
          _buildSummaryRow('Frete', shipping, 
            subtitle: shipping == 0 ? 'Grátis' : null),
          const SizedBox(height: 8),
          
          if (discount > 0) ...[
            _buildSummaryRow('Desconto', -discount, 
              color: AppColors.success),
            const SizedBox(height: 8),
          ],
          
          const Divider(),
          const SizedBox(height: 8),
          
          _buildSummaryRow('Total', total, 
            isTotal: true),
          
          if (shipping > 0 && subtotal < 1000) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Frete grátis para compras acima de ${Formatters.currency(1000)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          CustomButton(
            text: 'Finalizar Pedido',
            onPressed: onCheckout,
            isLoading: isLoading,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, double value, {
    String? subtitle,
    Color? color,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: isTotal 
                  ? AppTextStyles.h6 
                  : AppTextStyles.bodyMedium,
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                ),
              ),
          ],
        ),
        Text(
          Formatters.currency(value.abs()),
          style: isTotal 
              ? AppTextStyles.h5.copyWith(color: AppColors.primary)
              : AppTextStyles.labelLarge.copyWith(
                  color: color ?? AppColors.textPrimary,
                ),
        ),
      ],
    );
  }
}


