import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/address.dart';
import '../../../data/repositories/order_repository.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_state.dart';
import 'payment_screen.dart';

class CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    
    if (text.length <= 5) {
      formatted = text;
    } else {
      formatted = '${text.substring(0, 5)}-${text.substring(5, text.length > 8 ? 8 : text.length)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  Address? _selectedAddress;
  bool _isLoading = false;
  bool _showAddNewAddress = false;
  bool _saveAddress = false;
  bool _isLoadingCep = false;
  bool _hasShownSaveDialog = false;
  
  List<Address> _addresses = [];
  Map<String, bool> _expandedProducts = {};
  
  // Variáveis de erro para validação
  String? _zipCodeError;
  String? _streetError;
  String? _numberError;
  String? _neighborhoodError;
  String? _cityError;
  String? _stateError;
  String? _addressNameError;
  
  // Controllers para novo endereço
  final TextEditingController _addressNameController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _neighborhoodController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }
  
  @override
  void dispose() {
    _addressNameController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    
    final orderRepo = context.read<OrderRepository>();
    
    try {
      final addresses = await orderRepo.getAddresses();
      
      setState(() {
        _addresses = addresses;
        if (addresses.isNotEmpty) {
          _selectedAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.first,
          );
        } else {
          _showAddNewAddress = true;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar endereços: $e')),
        );
      }
    }
  }

  Future<void> _searchCep(String cep) async {
    // Remove caracteres não numéricos
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanCep.length != 8) return;
    
    setState(() => _isLoadingCep = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['erro'] != null && data['erro'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado')),
            );
          }
        } else {
          setState(() {
            _streetController.text = data['logradouro'] ?? '';
            _neighborhoodController.text = data['bairro'] ?? '';
            _cityController.text = data['localidade'] ?? '';
            _stateController.text = data['uf'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao buscar CEP')),
        );
      }
    } finally {
      setState(() => _isLoadingCep = false);
    }
  }

  void _showSaveAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        'Deseja salvar este endereço?',
                        style: AppTextStyles.h6.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você poderá usar este endereço em próximas compras',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Campo nome do endereço (aparece se escolher salvar)
                      if (_saveAddress) ...[
                        TextField(
                          controller: _addressNameController,
                          autofocus: true,
                          onChanged: (value) {
                            // Limpar erro quando começar a digitar
                            if (_addressNameError != null) {
                              setState(() => _addressNameError = null);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Nome do endereço',
                            hintText: 'Ex: Casa, Trabalho, Escritório',
                            errorText: _addressNameError,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _addressNameError != null ? AppColors.error : AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _addressNameError != null ? AppColors.error : AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _addressNameError != null ? AppColors.error : AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.error),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.error, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Botão Salvar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!_saveAddress) {
                              setModalState(() {
                                _saveAddress = true;
                              });
                            } else {
                              if (_addressNameController.text.isEmpty) {
                                setState(() => _addressNameError = 'Campo obrigatório');
                                return;
                              }
                              Navigator.pop(sheetContext);
                              setState(() {});
                              // Continuar com a criação do pedido
                              _confirmOrder();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: const Color(0xFF020B21),
                            overlayColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            _saveAddress ? 'Confirmar' : 'Salvar Endereço',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Botão Não salvar
                      if (!_saveAddress)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            setState(() {
                              _saveAddress = false;
                            });
                            // Continuar com a criação do pedido
                            _confirmOrder();
                          },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              overlayColor: Colors.grey.shade100,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: const Text(
                              'Usar apenas desta vez',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

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
          'Finalizar Pedido',
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          if (cartState is! CartLoaded) {
            return const Center(child: Text('Erro ao carregar carrinho'));
          }

          return GestureDetector(
            onTap: () {
              // Remove o foco de qualquer campo quando clicar fora
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Produtos Section
                  _buildProductsSection(cartState),
                  
                  const Divider(height: 32, thickness: 8, color: Color(0xFFF5F5F5)),
                  
                  // Endereço Section
                  _buildAddressSection(),
                  
                  const Divider(height: 32, thickness: 8, color: Color(0xFFF5F5F5)),
                  
                  // Summary Section
                  _buildSummarySection(cartState),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductsSection(CartLoaded cartState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produtos (${cartState.items.length})',
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...cartState.items.map((item) {
            final isExpanded = _expandedProducts[item.id] ?? false;
            return _buildProductItem(item, isExpanded);
          }),
        ],
      ),
    );
  }

  Widget _buildProductItem(dynamic item, bool isExpanded) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Imagem do produto
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imagemUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imagemUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.image, size: 24, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              
              // Nome
              Expanded(
                child: Text(
                  product.nome,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Quantidade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          // Botão Exibir detalhes
          if (product.descricao != null && product.descricao!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _expandedProducts[item.id] = !isExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded ? 'Ocultar detalhes' : 'Exibir detalhes',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
          
          // Descrição expandida
          if (isExpanded && product.descricao != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.descricao!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Endereço de Entrega',
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Se tem endereços cadastrados
          if (_addresses.isNotEmpty && !_showAddNewAddress) ...[
            ..._addresses.map((address) => _buildSavedAddressCard(address)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showAddNewAddress = true;
                });
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Adicionar novo endereço'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
          
          // Formulário para novo endereço
          if (_showAddNewAddress) ...[
            if (_addresses.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAddNewAddress = false;
                  });
                },
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Voltar para endereços salvos'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                ),
              ),
            const SizedBox(height: 16),
            _buildNewAddressForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedAddressCard(Address address) {
    final isSelected = _selectedAddress?.id == address.id;
    
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
            _selectedAddress = address;
            _showAddNewAddress = false;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.fullAddress,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.textSecondary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Padrão',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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

  Widget _buildNewAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCepField(),
        const SizedBox(height: 12),
        _buildTextField(
          'Rua/Avenida',
          _streetController,
          errorText: _streetError,
          onErrorClear: (_) => setState(() => _streetError = null),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                'Número',
                _numberController,
                keyboardType: TextInputType.number,
                errorText: _numberError,
                onErrorClear: (_) => setState(() => _numberError = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildTextField('Complemento', _complementController),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          'Bairro',
          _neighborhoodController,
          errorText: _neighborhoodError,
          onErrorClear: (_) => setState(() => _neighborhoodError = null),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildTextField(
                'Cidade',
                _cityController,
                errorText: _cityError,
                onErrorClear: (_) => setState(() => _cityError = null),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildTextField(
                'UF',
                _stateController,
                maxLength: 2,
                errorText: _stateError,
                onErrorClear: (_) => setState(() => _stateError = null),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCepField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CEP',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _zipCodeController,
          keyboardType: TextInputType.number,
          maxLength: 9,
          inputFormatters: [
            CepInputFormatter(),
          ],
          onChanged: (value) {
            // Limpar erro quando o usuário começar a digitar
            if (_zipCodeError != null) {
              setState(() => _zipCodeError = null);
            }
            // Remove o hífen para verificar se tem 8 dígitos
            final cleanValue = value.replaceAll('-', '');
            if (cleanValue.length == 8) {
              _searchCep(cleanValue);
            }
          },
          decoration: InputDecoration(
            counterText: '',
            hintText: '00000-000',
            errorText: _zipCodeError,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            suffixIcon: _isLoadingCep
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _zipCodeError != null ? AppColors.error : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _zipCodeError != null ? AppColors.error : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _zipCodeError != null ? AppColors.error : AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? errorText,
    Function(String?)? onErrorClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: (value) {
            // Limpar erro quando o usuário começar a digitar
            if (errorText != null && onErrorClear != null) {
              onErrorClear(null);
            }
          },
          decoration: InputDecoration(
            counterText: '',
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: errorText != null ? AppColors.error : AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(CartLoaded cartState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            _buildSummaryRow('Desconto', -cartState.discount),
          ],
          const Divider(height: 24),
          _buildSummaryRow('Total', cartState.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.h6.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium,
        ),
        Text(
          Formatters.currency(value.abs()),
          style: isTotal
              ? AppTextStyles.h6.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )
              : AppTextStyles.labelMedium,
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
                    'Ir para o pagamento',
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

  Future<void> _confirmOrder() async {
    // Limpar erros anteriores
    setState(() {
      _zipCodeError = null;
      _streetError = null;
      _numberError = null;
      _neighborhoodError = null;
      _cityError = null;
      _stateError = null;
      _addressNameError = null;
    });

    // Validar endereço
    if (_selectedAddress == null && !_showAddNewAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um endereço de entrega')),
      );
      return;
    }

    // Se está criando novo endereço, validar campos
    if (_showAddNewAddress) {
      bool hasError = false;

      if (_zipCodeController.text.isEmpty) {
        setState(() => _zipCodeError = 'Campo obrigatório');
        hasError = true;
      }
      if (_streetController.text.isEmpty) {
        setState(() => _streetError = 'Campo obrigatório');
        hasError = true;
      }
      if (_numberController.text.isEmpty) {
        setState(() => _numberError = 'Campo obrigatório');
        hasError = true;
      }
      if (_neighborhoodController.text.isEmpty) {
        setState(() => _neighborhoodError = 'Campo obrigatório');
        hasError = true;
      }
      if (_cityController.text.isEmpty) {
        setState(() => _cityError = 'Campo obrigatório');
        hasError = true;
      }
      if (_stateController.text.isEmpty) {
        setState(() => _stateError = 'Campo obrigatório');
        hasError = true;
      }

      if (hasError) {
        return;
      }

      // Se ainda não mostrou o modal de salvar endereço, mostrar agora
      if (!_hasShownSaveDialog) {
        _hasShownSaveDialog = true;
        _showSaveAddressBottomSheet();
        return; // Aguarda o usuário escolher se quer salvar ou não
      }

      // Se vai salvar, validar nome
      if (_saveAddress && _addressNameController.text.isEmpty) {
        setState(() => _addressNameError = 'Campo obrigatório');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final cartBloc = context.read<CartBloc>();
      final cartState = cartBloc.state;
      if (cartState is! CartLoaded) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao acessar o carrinho')),
          );
        }
        return;
      }

      final orderRepo = context.read<OrderRepository>();

      // Se o endereço é novo e não foi salvo ainda, precisamos salvá-lo
      if (_showAddNewAddress) {
        // Se vai salvar permanentemente ou temporariamente, adicionar ao banco
        final tempAddress = Address(
          id: '', // Será gerado pelo banco
          label: _saveAddress ? _addressNameController.text : 'Entrega única',
          street: _streetController.text,
          number: _numberController.text,
          complement: _complementController.text.isEmpty ? null : _complementController.text,
          neighborhood: _neighborhoodController.text,
          city: _cityController.text,
          state: _stateController.text,
          zipCode: _zipCodeController.text,
          isDefault: false,
        );
        
        // Salvar o endereço (mesmo que temporário, para ter um ID válido)
        _selectedAddress = await orderRepo.addAddress(tempAddress);
      }

      setState(() => _isLoading = false);

      // Navegar para tela de pagamento
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              address: _selectedAddress!,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        AppLogger.error('Erro ao processar endereço', e, null, 'CheckoutScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar endereço. Tente novamente.'),
            duration: Duration(seconds: 3),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}


