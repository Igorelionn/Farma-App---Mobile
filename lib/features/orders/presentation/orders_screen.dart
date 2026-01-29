import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../data/models/order.dart';
import '../bloc/orders_bloc.dart';
import '../bloc/orders_event.dart';
import '../bloc/orders_state.dart';
import '../widgets/order_card.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  OrderStatus? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendentes', OrderStatus.pending),
                  const SizedBox(width: 8),
                  _buildFilterChip('Em Separação', OrderStatus.processing),
                  const SizedBox(width: 8),
                  _buildFilterChip('Enviados', OrderStatus.shipped),
                  const SizedBox(width: 8),
                  _buildFilterChip('Entregues', OrderStatus.delivered),
                ],
              ),
            ),
          ),
          
          // Orders List
          Expanded(
            child: BlocConsumer<OrdersBloc, OrdersState>(
              listener: (context, state) {
                if (state is OrderCancelled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido cancelado com sucesso'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is OrdersLoading || state is OrderCancelling) {
                  return const LoadingIndicator();
                }
                
                if (state is OrdersError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<OrdersBloc>().add(LoadOrders());
                    },
                  );
                }
                
                if (state is OrdersEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhum Pedido',
                    message: _selectedFilter == null
                        ? 'Você ainda não realizou nenhum pedido'
                        : 'Nenhum pedido encontrado com este filtro',
                    actionText: 'Ver Catálogo',
                    onActionPressed: () {
                      Navigator.of(context).pop();
                    },
                  );
                }
                
                if (state is OrdersLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<OrdersBloc>().add(RefreshOrders());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        return OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsScreen(
                                  order: order,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, OrderStatus? status) {
    final isSelected = _selectedFilter == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = status;
        });
        context.read<OrdersBloc>().add(FilterOrders(status: status));
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}


