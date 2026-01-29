import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/order.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;
  
  const OrderTimeline({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final statusHistory = order.statusHistory ?? [];
    
    if (statusHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico do Pedido', style: AppTextStyles.h6),
        const SizedBox(height: 16),
        ...statusHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final statusUpdate = entry.value;
          final isLast = index == statusHistory.length - 1;
          final isCurrent = statusUpdate.status == order.status;
          
          return _buildTimelineItem(
            statusUpdate: statusUpdate,
            isLast: isLast,
            isCurrent: isCurrent,
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem({
    required OrderStatusUpdate statusUpdate,
    required bool isLast,
    required bool isCurrent,
  }) {
    IconData icon;
    Color color;
    
    switch (statusUpdate.status) {
      case OrderStatus.pending:
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case OrderStatus.processing:
        icon = Icons.inventory_2;
        color = AppColors.info;
        break;
      case OrderStatus.shipped:
        icon = Icons.local_shipping;
        color = AppColors.primary;
        break;
      case OrderStatus.delivered:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case OrderStatus.cancelled:
        icon = Icons.cancel;
        color = AppColors.error;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrent ? color : color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isCurrent ? Colors.white : color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: color.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusLabel(statusUpdate.status),
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(statusUpdate.date),
                    style: AppTextStyles.caption,
                  ),
                  if (statusUpdate.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      statusUpdate.description!,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pedido Pendente';
      case OrderStatus.processing:
        return 'Em Separação';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}


