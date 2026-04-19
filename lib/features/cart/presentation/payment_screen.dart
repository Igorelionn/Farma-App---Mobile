import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/models/address.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/cart_repository.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/order_success_animation.dart';

class PaymentScreen extends StatefulWidget {
  final Address address;
  
  const PaymentScreen({
    super.key,
    required this.address,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;
  bool _isLoadingMethods = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoadingMethods = true);
    
    try {
      final orderRepo = context.read<OrderRepository>();
      final methods = await orderRepo.getPaymentMethods();
      
      setState(() {
        _paymentMethods = methods;
        _isLoadingMethods = false;
        // Selecionar PIX por padrão se disponível
        if (methods.isNotEmpty) {
          _selectedPaymentMethod = methods.firstWhere(
            (m) => m.type == PaymentType.pix,
            orElse: () => methods.first,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoadingMethods = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar métodos de pagamento: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmOrder() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um método de pagamento')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cartBloc = context.read<CartBloc>();
      final cartState = cartBloc.state;
      
      if (cartState is! CartLoaded) {
        throw Exception('Erro ao acessar o carrinho');
      }

      final orderRepo = context.read<OrderRepository>();
      final cartRepo = context.read<CartRepository>();

      // Validar carrinho antes de criar pedido
      final isCartValid = await cartRepo.validateCart();
      if (!isCartValid) {
        throw Exception('Alguns produtos no carrinho não estão mais disponíveis ou sem estoque');
      }

      // Criar pedido
      final order = await orderRepo.createOrder(
        items: cartState.items,
        address: widget.address,
        paymentMethod: _selectedPaymentMethod!,
        totals: cartState.totals,
      );

      // Limpar carrinho
      await cartRepo.clearCart();
      cartBloc.add(ClearCart());

      if (mounted) {
        // Voltar para a tela inicial
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Mostrar animação de sucesso
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black54,
          builder: (context) => OrderSuccessAnimation(
            orderNumber: order.number,
            onClose: () {
              Navigator.of(context).pop();
            },
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppLogger.error('Erro ao criar pedido', e, null, 'PaymentScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao criar pedido. Tente novamente.'),
            duration: Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const SvgIcon(
            assetPath: 'assets/icons/arrow_back_icon.svg',
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Método de Pagamento',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingMethods
          ? const LoadingIndicator()
          : BlocBuilder<CartBloc, CartState>(
              builder: (context, cartState) {
                if (cartState is! CartLoaded) {
                  return const Center(child: Text('Erro ao carregar carrinho'));
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecione a forma de pagamento',
                              style: AppTextStyles.h6.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (_paymentMethods.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.payment_outlined,
                                        size: 64,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Nenhum método de pagamento disponível',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
                            
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            
                            // Resumo do pedido
                            Text(
                              'Resumo do Pedido',
                              style: AppTextStyles.h6.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSummaryRow('Subtotal', cartState.subtotal),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Frete', cartState.shipping),
                            if (cartState.discount > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow('Desconto', -cartState.discount, color: AppColors.error),
                            ],
                            const Divider(height: 24),
                            _buildSummaryRow('Total', cartState.total, isTotal: true),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    IconData icon;
    switch (method.type) {
      case PaymentType.pix:
        icon = Icons.pix;
        break;
      case PaymentType.creditCard:
        icon = Icons.credit_card;
        break;
      case PaymentType.boleto:
        icon = Icons.description_outlined;
        break;
      case PaymentType.accountCredit:
        icon = Icons.account_balance_wallet;
        break;
      default:
        icon = Icons.payment;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.textPrimary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                size: 28,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (method.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        method.description!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color? color, bool isTotal = false}) {
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
          'R\$ ${value.abs().toStringAsFixed(2).replaceAll('.', ',')}',
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF020B21),
              foregroundColor: AppColors.primary,
              overlayColor: const Color(0xFF020B21),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Text(
                    'Finalizar Pedido',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
