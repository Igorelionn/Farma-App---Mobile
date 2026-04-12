import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/custom_button.dart';
import '../widgets/order_timeline.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;
  
  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido ${order.number}'),
        actions: [
          if (order.trackingCode != null)
            IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: order.trackingCode!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código de rastreio copiado'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Copiar código de rastreio',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Informações do Pedido', style: AppTextStyles.h6),
                        _buildStatusBadge(),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('Pedido', order.number),
                    _buildInfoRow(
                      'Data',
                      DateFormat('dd/MM/yyyy HH:mm').format(order.date),
                    ),
                    if (order.estimatedDelivery != null)
                      _buildInfoRow(
                        'Previsão de entrega',
                        DateFormat('dd/MM/yyyy').format(order.estimatedDelivery!),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Timeline
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: OrderTimeline(order: order),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Itens do Pedido', style: AppTextStyles.h6),
                    const Divider(height: 24),
                    ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.medication,
                              size: 30,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product?.nome ?? 'Produto',
                                  style: AppTextStyles.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.product?.laboratorio ?? '',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Qtd: ${item.quantity}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.currency(item.subtotal),
                            style: AppTextStyles.labelMedium,
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Address
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Endereço de Entrega', style: AppTextStyles.h6),
                    const Divider(height: 24),
                    Text(order.address?.label ?? 'Endereço não disponível', style: AppTextStyles.labelMedium),
                    const SizedBox(height: 4),
                    Text(order.address?.fullAddress ?? '', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Payment
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pagamento', style: AppTextStyles.h6),
                    const Divider(height: 24),
                    Text(order.paymentMethod?.label ?? 'Não informado', style: AppTextStyles.labelMedium),
                    if (order.paymentMethod?.description != null)
                      Text(
                        order.paymentMethod!.description!,
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumo de Valores', style: AppTextStyles.h6),
                    const Divider(height: 24),
                    _buildSummaryRow('Subtotal', order.subtotal),
                    _buildSummaryRow('Frete', order.shipping),
                    if (order.discount > 0)
                      _buildSummaryRow('Desconto', -order.discount),
                    const Divider(),
                    _buildSummaryRow('Total', order.total, isTotal: true),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions
            if (order.canCancel)
              CustomButton(
                text: 'Cancelar Pedido',
                onPressed: () => _showCancelDialog(context),
                isOutlined: true,
                width: double.infinity,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    
    switch (order.status) {
      case OrderStatus.pending:
        color = AppColors.warning;
        break;
      case OrderStatus.confirmed:
        color = const Color(0xFF8B5CF6);
        break;
      case OrderStatus.processing:
        color = AppColors.info;
        break;
      case OrderStatus.shipped:
        color = AppColors.primary;
        break;
      case OrderStatus.delivered:
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
        color = AppColors.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        order.statusLabel,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
          ),
          Text(
            Formatters.currency(value.abs()),
            style: isTotal
                ? AppTextStyles.h6.copyWith(color: AppColors.primary)
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: Text(
            'Deseja realmente cancelar o pedido ${order.number}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<OrdersBloc>().add(CancelOrder(orderId: order.id));
                Navigator.pop(context);
              },
              child: const Text(
                'Sim, Cancelar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}


