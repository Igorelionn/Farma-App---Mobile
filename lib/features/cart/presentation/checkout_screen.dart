import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/address.dart';
import '../../../data/models/payment_method.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/cart_repository.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import '../bloc/cart_event.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0;
  Address? _selectedAddress;
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = false;
  
  List<Address> _addresses = [];
  List<PaymentMethod> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  Future<void> _loadCheckoutData() async {
    setState(() => _isLoading = true);
    
    final orderRepo = context.read<OrderRepository>();
    
    try {
      final addresses = await orderRepo.getAddresses();
      final paymentMethods = await orderRepo.getPaymentMethods();
      
      setState(() {
        _addresses = addresses;
        _paymentMethods = paymentMethods;
        // Selecionar endereço padrão
        _selectedAddress = addresses.firstWhere(
          (addr) => addr.isDefault,
          orElse: () => addresses.first,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Pedido'),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  CustomButton(
                    text: _currentStep == 2 ? 'Confirmar Pedido' : 'Continuar',
                    onPressed: details.onStepContinue,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(width: 8),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Voltar'),
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Endereço de Entrega'),
              content: _buildAddressStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Forma de Pagamento'),
              content: _buildPaymentStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Confirmação'),
              content: _buildConfirmationStep(),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione o endereço de entrega:',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: 12),
        ..._addresses.map((address) => _buildAddressCard(address)),
      ],
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddress?.id == address.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() => _selectedAddress = address);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: AppTextStyles.labelLarge,
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Padrão',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione a forma de pagamento:',
          style: AppTextStyles.labelMedium,
        ),
        const SizedBox(height: 12),
        ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    IconData icon;
    switch (method.type) {
      case PaymentType.boleto:
        icon = Icons.receipt_long;
        break;
      case PaymentType.creditCard:
        icon = Icons.credit_card;
        break;
      case PaymentType.pix:
        icon = Icons.pix;
        break;
      case PaymentType.accountCredit:
        icon = Icons.account_balance_wallet;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() => _selectedPaymentMethod = method);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: AppTextStyles.labelLarge,
                    ),
                    if (method.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        method.description!,
                        style: AppTextStyles.bodySmall,
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

  Widget _buildConfirmationStep() {
    final cartState = context.read<CartBloc>().state;
    
    if (cartState is! CartLoaded) {
      return const Text('Erro ao carregar carrinho');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address Summary
        Text('Endereço de Entrega', style: AppTextStyles.h6),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedAddress!.label, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(_selectedAddress!.fullAddress, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Payment Summary
        Text('Forma de Pagamento', style: AppTextStyles.h6),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedPaymentMethod!.label, style: AppTextStyles.labelLarge),
                if (_selectedPaymentMethod!.description != null)
                  Text(_selectedPaymentMethod!.description!, 
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Order Summary
        Text('Resumo do Pedido', style: AppTextStyles.h6),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', cartState.subtotal),
                _buildSummaryRow('Frete', cartState.shipping),
                if (cartState.discount > 0)
                  _buildSummaryRow('Desconto', -cartState.discount),
                const Divider(),
                _buildSummaryRow('Total', cartState.total, isTotal: true),
              ],
            ),
          ),
        ),
      ],
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

  void _onStepContinue() async {
    if (_currentStep == 0) {
      if (_selectedAddress == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um endereço')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_selectedPaymentMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma forma de pagamento')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      await _confirmOrder();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _confirmOrder() async {
    setState(() => _isLoading = true);

    try {
      final cartBloc = context.read<CartBloc>();
      final cartState = cartBloc.state as CartLoaded;
      final orderRepo = context.read<OrderRepository>();
      final cartRepo = context.read<CartRepository>();

      final order = await orderRepo.createOrder(
        items: cartState.items,
        address: _selectedAddress!,
        paymentMethod: _selectedPaymentMethod!,
        totals: cartState.totals,
      );

      // Limpar carrinho
      await cartRepo.clearCart();
      cartBloc.add(ClearCart());

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                SizedBox(width: 12),
                Text('Pedido Realizado!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Seu pedido foi realizado com sucesso!'),
                const SizedBox(height: 8),
                Text(
                  'Número do pedido: ${order.number}',
                  style: AppTextStyles.labelMedium,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar pedido: $e')),
        );
      }
    }
  }
}


