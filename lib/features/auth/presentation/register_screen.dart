import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

const _kEmerald = Color(0xFF2DD4A8);
const _kDark = Color(0xFF1A1A1A);
const _kLabel = Color(0xFF3C3C3C);
const _kHint = Color(0xFFB5B5B5);
const _kFieldBg = Color(0xFFF4F5F7);
const _kBg = Color(0xFFFBFBFB);
const _totalSteps = 6;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  final _keys = List.generate(_totalSteps, (_) => GlobalKey<FormState>());

  // Estados do botão animado
  bool _isCheckingDuplicate = false;
  bool _showDuplicateError = false;
  String _duplicateErrorMessage = '';

  // Etapa 1: Dados da Empresa
  final _empresaCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _tipoOutroCtrl = TextEditingController();
  String _tipo = 'farmacia';

  // Etapa 2: Endereço
  bool _cepLoading = false;
  final _cepCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _numeroFocus = FocusNode();
  final _complementoCtrl = TextEditingController();
  final _bairroCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();

  // Etapa 3: Documentação Legal e Fiscal
  // Inscrição Estadual e Municipal são números → texto
  final _inscEstadualCtrl = TextEditingController();
  final _inscMunicipalCtrl = TextEditingController();
  // Alvará é documento físico anual → upload
  List<PlatformFile> _filesAlvara = [];
  String? _step3Error;

  // Etapa 4: Documentação Sanitária
  // AFE e AE são números verificáveis na ANVISA → texto
  final _afeCtrl = TextEditingController();
  final _autEspecialCtrl = TextEditingController();
  // Licença Sanitária e CRT são documentos físicos com validade → upload
  List<PlatformFile> _filesLicenca = [];
  List<PlatformFile> _filesCrt = [];
  String? _step4Error;

  // Etapa 5: Responsável Técnico
  final _respNomeCtrl = TextEditingController();
  final _respCpfCtrl = TextEditingController();
  final _respCrfCtrl = TextEditingController();

  // Etapa 6: Criar Senha
  final _senhaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  // ValueNotifier para evitar setState completo ao alternar visibilidade
  final _obscureSenha = ValueNotifier<bool>(true);
  final _obscureConfirm = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _cepCtrl.addListener(_onCepChanged);
  }

  void _onCepChanged() {
    final digits = _cepCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) _lookupCep(digits);
  }

  Future<void> _lookupCep(String cep) async {
    if (_cepLoading) return;
    setState(() => _cepLoading = true);
    try {
      final res = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['erro'] == null) {
          setState(() {
            _enderecoCtrl.text = data['logradouro'] ?? '';
            _bairroCtrl.text = data['bairro'] ?? '';
            _cidadeCtrl.text = data['localidade'] ?? '';
            _estadoCtrl.text = (data['uf'] ?? '').toString().toUpperCase();
          });
          // Foca no campo número após preenchimento automático
          Future.microtask(() => _numeroFocus.requestFocus());
        }
      }
    } catch (_) {
      // Ignora erros silenciosamente — usuário preenche manualmente
    } finally {
      if (mounted) setState(() => _cepLoading = false);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _empresaCtrl.dispose();
    _cnpjCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _tipoOutroCtrl.dispose();
    _cepCtrl.removeListener(_onCepChanged);
    _cepCtrl.dispose();
    _numeroFocus.dispose();
    _enderecoCtrl.dispose();
    _numeroCtrl.dispose();
    _complementoCtrl.dispose();
    _bairroCtrl.dispose();
    _cidadeCtrl.dispose();
    _estadoCtrl.dispose();
    _inscEstadualCtrl.dispose();
    _inscMunicipalCtrl.dispose();
    _afeCtrl.dispose();
    _autEspecialCtrl.dispose();
    _respNomeCtrl.dispose();
    _respCpfCtrl.dispose();
    _respCrfCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    _obscureSenha.dispose();
    _obscureConfirm.dispose();
    super.dispose();
  }

  void _next() async {
    // Etapa 1: Validar se CNPJ, email ou telefone já existem
    if (_step == 0) {
      if (!_keys[0].currentState!.validate()) return;
      
      debugPrint('[RegisterScreen] Iniciando verificação de duplicados...');
      
      // Mostrar loading
      setState(() => _isCheckingDuplicate = true);
      
      try {
        final authRepo = context.read<AuthRepository>();
        debugPrint('[RegisterScreen] Repository obtido com sucesso');
        
        // Verificar CNPJ
        final cnpj = _cnpjCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
        debugPrint('[RegisterScreen] Verificando CNPJ: $cnpj');
        final cnpjExists = await authRepo.checkCnpjExists(cnpj);
        debugPrint('[RegisterScreen] CNPJ existe? $cnpjExists');
        
        if (cnpjExists) {
          setState(() {
            _isCheckingDuplicate = false;
            _showDuplicateError = true;
            _duplicateErrorMessage = 'CNPJ já cadastrado';
          });
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) setState(() => _showDuplicateError = false);
          });
          return;
        }
        
        // Verificar Email
        final email = _emailCtrl.text.trim().toLowerCase();
        debugPrint('[RegisterScreen] Verificando email: $email');
        final emailExists = await authRepo.checkEmailExists(email);
        debugPrint('[RegisterScreen] Email existe? $emailExists');
        
        if (emailExists) {
          setState(() {
            _isCheckingDuplicate = false;
            _showDuplicateError = true;
            _duplicateErrorMessage = 'Email já cadastrado';
          });
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) setState(() => _showDuplicateError = false);
          });
          return;
        }
        
        // Verificar Telefone
        if (_telefoneCtrl.text.trim().isNotEmpty) {
          final telefone = _telefoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
          debugPrint('[RegisterScreen] Verificando telefone: $telefone');
          final telefoneExists = await authRepo.checkTelefoneExists(telefone);
          debugPrint('[RegisterScreen] Telefone existe? $telefoneExists');
          
          if (telefoneExists) {
            setState(() {
              _isCheckingDuplicate = false;
              _showDuplicateError = true;
              _duplicateErrorMessage = 'Telefone já cadastrado';
            });
            Future.delayed(const Duration(milliseconds: 2500), () {
              if (mounted) setState(() => _showDuplicateError = false);
            });
            return;
          }
        }
        
        debugPrint('[RegisterScreen] Todas as verificações passaram, avançando...');
        setState(() => _isCheckingDuplicate = false);
      } catch (e, stackTrace) {
        debugPrint('[RegisterScreen] Erro ao verificar duplicados: $e');
        debugPrint('[RegisterScreen] StackTrace: $stackTrace');
        setState(() => _isCheckingDuplicate = false);
        // Em caso de erro na verificação, NÃO permite continuar
        setState(() {
          _showDuplicateError = true;
          _duplicateErrorMessage = 'Erro ao verificar dados';
        });
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) setState(() => _showDuplicateError = false);
        });
        return;
      }
    }
    
    // Etapa 3: texto validado pelo Form + upload do Alvará
    if (_step == 2) {
      final formOk = _keys[2].currentState!.validate();
      final uploadOk = _filesAlvara.isNotEmpty;
      setState(() => _step3Error =
          !uploadOk ? 'Envie o Alvará de Funcionamento' : null);
      if (!formOk || !uploadOk) return;
    // Etapa 4: texto validado pelo Form + uploads de Licença e CRT
    } else if (_step == 3) {
      final formOk = _keys[3].currentState!.validate();
      final uploadOk = _filesLicenca.isNotEmpty && _filesCrt.isNotEmpty;
      setState(() => _step4Error =
          !uploadOk ? 'Envie a Licença Sanitária e o CRT' : null);
      if (!formOk || !uploadOk) return;
    } else if (_step != 0) {
      if (!_keys[_step].currentState!.validate()) return;
    }

    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<Uint8List?> _readFile(PlatformFile f) async {
    if (f.bytes != null) return f.bytes;
    if (f.path != null) return File(f.path!).readAsBytes();
    return null;
  }

  Future<void> _submit() async {
    final Map<String, List<(String, Uint8List)>> docs = {};

    Future<void> addDocs(String key, List<PlatformFile> files) async {
      final list = <(String, Uint8List)>[];
      for (final f in files) {
        final bytes = await _readFile(f);
        if (bytes != null) list.add((f.name, bytes));
      }
      if (list.isNotEmpty) docs[key] = list;
    }

    // Apenas os documentos físicos (com validade) precisam de upload
    await addDocs('alvara_funcionamento', _filesAlvara);
    await addDocs('licenca_sanitaria', _filesLicenca);
    await addDocs('crt', _filesCrt);

    if (!mounted) return;
    context.read<AuthBloc>().add(RegisterSubmitted(
          email: _emailCtrl.text.trim(),
          password: _senhaCtrl.text,
          nome: _respNomeCtrl.text.trim(),
          empresa: _empresaCtrl.text.trim(),
          cnpj: _cnpjCtrl.text.trim(),
          tipo: _tipo == 'outro' ? _tipoOutroCtrl.text.trim() : _tipo,
          telefone: _n(_telefoneCtrl),
          cep: _n(_cepCtrl),
          endereco: _n(_enderecoCtrl),
          numero: _n(_numeroCtrl),
          complemento: _n(_complementoCtrl),
          bairro: _n(_bairroCtrl),
          cidade: _n(_cidadeCtrl),
          estado: _n(_estadoCtrl),
          inscricaoEstadual: _n(_inscEstadualCtrl),
          inscricaoMunicipal: _n(_inscMunicipalCtrl),
          afe: _n(_afeCtrl),
          autorizacaoEspecial: _n(_autEspecialCtrl),
          documents: docs.isEmpty ? null : docs,
          responsavelNome: _n(_respNomeCtrl),
          responsavelCpf: _n(_respCpfCtrl),
          responsavelCrf: _n(_respCrfCtrl),
        ));
  }

  String? _n(TextEditingController c) =>
      c.text.trim().isNotEmpty ? c.text.trim() : null;

  // Estilos cacheados para evitar re-alocação no build
  static final _tsTitle = GoogleFonts.urbanist(
      fontSize: 30, fontWeight: FontWeight.w400, color: _kDark, height: 1.15);
  static final _tsSubtitle = GoogleFonts.urbanist(
      fontSize: 14, fontWeight: FontWeight.w400, color: _kHint, height: 1.4);
  static final _tsStep = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w500, color: _kHint);

  static const _titles = [
    'Dados da empresa',
    'Endereço completo',
    'Documentação legal',
    'Documentação sanitária',
    'Responsável técnico',
    'Criar senha',
  ];
  static const _subtitles = [
    'Informações sobre seu estabelecimento.',
    'Onde sua empresa está localizada?',
    'Registros fiscais e licença de funcionamento.',
    'Autorizações sanitárias obrigatórias.',
    'Farmacêutico responsável técnico.',
    'Defina uma senha segura para sua conta.',
  ];

  @override
  Widget build(BuildContext context) {

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistered || state is AuthPendingApproval) {
          Navigator.of(context).pushReplacementNamed('/register-success');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(state.message,
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w500)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(20),
            ));
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _back,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F1F3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              size: 20, color: _kDark),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Etapa ${_step + 1}/$_totalSteps',
                        style: _tsStep,
                      ),
                    ],
                  ),
                ),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _totalSteps,
                      minHeight: 3,
                      backgroundColor: const Color(0xFFECEDEF),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_kEmerald),
                    ),
                  ),
                ),

                // Content: título fixo + PageView preenchendo o espaço disponível
                // Um único scroll por página elimina a competição entre scrolls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título animado fora do PageView (sem participar do scroll)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(28, 28, 28, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: SizedBox(
                            key: ValueKey(_step),
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_titles[_step], style: _tsTitle),
                                const SizedBox(height: 8),
                                Text(_subtitles[_step], style: _tsSubtitle),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // PageView ocupa todo o espaço restante — cada página rola
                      // de forma independente, sem scroll externo concorrente
                      Expanded(
                        child: PageView(
                          controller: _pageCtrl,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _step1(),
                            _step2(),
                            _step3(),
                            _step4(),
                            _step5(),
                            _step6(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom button
                _buildBottom(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTipoLabel() {
    switch (_tipo) {
      case 'farmacia':
        return 'Farmácia';
      case 'clinica':
        return 'Clínica';
      case 'hospital':
        return 'Hospital';
      case 'outro':
        return _tipoOutroCtrl.text.trim().isNotEmpty
            ? _tipoOutroCtrl.text.trim()
            : 'Outro';
      default:
        return 'Selecione';
    }
  }

  void _showTipoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de estabelecimento',
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _TipoOption(
                      label: 'Farmácia',
                      value: 'farmacia',
                      selected: _tipo == 'farmacia',
                      onTap: () {
                        setState(() => _tipo = 'farmacia');
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _TipoOption(
                      label: 'Clínica',
                      value: 'clinica',
                      selected: _tipo == 'clinica',
                      onTap: () {
                        setState(() => _tipo = 'clinica');
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _TipoOption(
                      label: 'Hospital',
                      value: 'hospital',
                      selected: _tipo == 'hospital',
                      onTap: () {
                        setState(() => _tipo = 'hospital');
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _TipoOption(
                      label: 'Outro',
                      value: 'outro',
                      selected: _tipo == 'outro',
                      onTap: () {
                        setModalState(() {});
                        setState(() => _tipo = 'outro');
                      },
                    ),
                    if (_tipo == 'outro') ...[
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Especifique o tipo',
                        ctrl: _tipoOutroCtrl,
                        hint: 'Ex: Laboratório, Consultório, etc.',
                        validator: (v) =>
                            Validators.required(v, 'Tipo de estabelecimento'),
                        action: TextInputAction.done,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_tipoOutroCtrl.text.trim().isNotEmpty) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navBarBackground,
                            overlayColor: AppColors.navBarBackground,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'Confirmar',
                            style: GoogleFonts.urbanist(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ETAPA 1: Dados da Empresa
  Widget _step1() {
    return Form(
      key: _keys[0],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Razão social',
              ctrl: _empresaCtrl,
              hint: 'Nome da empresa',
              validator: (v) => Validators.required(v, 'Razão social'),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'CNPJ',
              ctrl: _cnpjCtrl,
              hint: '00.000.000/0000-00',
              validator: Validators.cnpj,
              keyboard: TextInputType.number,
              action: TextInputAction.next,
              formatters: [_CnpjFormatter()],
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'Telefone',
              ctrl: _telefoneCtrl,
              hint: '(00) 00000-0000',
              validator: (v) => Validators.required(v, 'Telefone'),
              keyboard: TextInputType.phone,
              action: TextInputAction.next,
              formatters: [_PhoneFormatter()],
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'Email',
              ctrl: _emailCtrl,
              hint: 'email@empresa.com',
              validator: Validators.email,
              keyboard: TextInputType.emailAddress,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 26),
            GestureDetector(
              onTap: () => _showTipoSheet(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de estabelecimento',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kLabel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: _kFieldBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getTipoLabel(),
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: _kDark,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kHint,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ETAPA 2: Endereço
  Widget _step2() {
    return Form(
      key: _keys[1],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
          children: [
            _Field(
              label: 'CEP',
              ctrl: _cepCtrl,
              hint: '00000-000',
              validator: (v) => Validators.required(v, 'CEP'),
              keyboard: TextInputType.number,
              action: TextInputAction.next,
              formatters: [_CepFormatter()],
            ),
            if (_cepLoading) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_kEmerald),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Buscando endereço...',
                    style: GoogleFonts.urbanist(
                        fontSize: 12, color: _kHint),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _Field(
              label: 'Endereço',
              ctrl: _enderecoCtrl,
              hint: 'Rua, avenida, etc.',
              validator: (v) => Validators.required(v, 'Endereço'),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _Field(
                    label: 'Número',
                    ctrl: _numeroCtrl,
                    focusNode: _numeroFocus,
                    hint: '123',
                    validator: (v) => Validators.required(v, 'Número'),
                    keyboard: TextInputType.text,
                    action: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: _Field(
                    label: 'Complemento',
                    ctrl: _complementoCtrl,
                    hint: 'Sala, Andar, etc.',
                    action: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'Bairro',
              ctrl: _bairroCtrl,
              hint: 'Nome do bairro',
              validator: (v) => Validators.required(v, 'Bairro'),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _Field(
                    label: 'Cidade',
                    ctrl: _cidadeCtrl,
                    hint: 'Cidade',
                    validator: (v) => Validators.required(v, 'Cidade'),
                    action: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 1,
                  child: _Field(
                    label: 'UF',
                    ctrl: _estadoCtrl,
                    hint: 'SP',
                    validator: (v) => Validators.required(v, 'Estado'),
                    action: TextInputAction.done,
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                      LengthLimitingTextInputFormatter(2),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ETAPA 3: Documentação Legal e Fiscal
  // Inscrição Estadual e Municipal → número (texto)
  // Alvará de Funcionamento → upload (documento físico anual)
  Widget _step3() {
    return Form(
      key: _keys[2],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'Inscrição Estadual',
              ctrl: _inscEstadualCtrl,
              hint: 'Número ou ISENTO',
              validator: (v) => Validators.required(v, 'Inscrição Estadual'),
              keyboard: TextInputType.text,
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'Inscrição Municipal',
              ctrl: _inscMunicipalCtrl,
              hint: 'Número ou ISENTO',
              validator: (v) => Validators.required(v, 'Inscrição Municipal'),
              keyboard: TextInputType.text,
              action: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            _DocUploadField(
              label: 'Alvará de Funcionamento',
              required: true,
              maxFiles: 2,
              files: _filesAlvara,
              onAdd: (f) => setState(() {
                _filesAlvara = [..._filesAlvara, f];
                _step3Error = null;
              }),
              onRemove: (i) => setState(
                  () => _filesAlvara = List.from(_filesAlvara)..removeAt(i)),
            ),
            if (_step3Error != null) ...[
              const SizedBox(height: 12),
              _ErrorRow(_step3Error!),
            ],
          ],
        ),
      ),
    );
  }

  // ETAPA 4: Documentação Sanitária
  // AFE e AE → número verificável na ANVISA (texto)
  // Licença Sanitária e CRT → upload (documentos físicos com validade)
  Widget _step4() {
    return Form(
      key: _keys[3],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Field(
              label: 'AFE — Nº de Autorização de Funcionamento (ANVISA)',
              ctrl: _afeCtrl,
              hint: 'Ex: 1.23456/7-89',
              validator: (v) => Validators.required(v, 'AFE'),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'Autorização Especial — AE (se aplicável)',
              ctrl: _autEspecialCtrl,
              hint: 'Número da AE',
              action: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            _DocUploadField(
              label: 'Licença Sanitária',
              required: true,
              maxFiles: 3,
              files: _filesLicenca,
              onAdd: (f) => setState(() {
                _filesLicenca = [..._filesLicenca, f];
                _step4Error = null;
              }),
              onRemove: (i) => setState(
                  () => _filesLicenca = List.from(_filesLicenca)..removeAt(i)),
            ),
            const SizedBox(height: 18),
            _DocUploadField(
              label: 'CRT — Certidão de Regularidade Técnica (CRF)',
              required: true,
              maxFiles: 2,
              files: _filesCrt,
              onAdd: (f) => setState(() {
                _filesCrt = [..._filesCrt, f];
                _step4Error = null;
              }),
              onRemove: (i) => setState(
                  () => _filesCrt = List.from(_filesCrt)..removeAt(i)),
            ),
            if (_step4Error != null) ...[
              const SizedBox(height: 12),
              _ErrorRow(_step4Error!),
            ],
          ],
        ),
      ),
    );
  }

  // ETAPA 5: Responsável Técnico
  Widget _step5() {
    return Form(
      key: _keys[4],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
          children: [
            _Field(
              label: 'Nome do farmacêutico responsável',
              ctrl: _respNomeCtrl,
              hint: 'Nome completo',
              validator: (v) => Validators.required(v, 'Nome do responsável'),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'Número do CRF',
              ctrl: _respCrfCtrl,
              hint: 'Ex: CRF 12345/SP',
              validator: (v) => Validators.required(v, 'CRF'),
              action: TextInputAction.next,
            ),
            const SizedBox(height: 22),
            _Field(
              label: 'CPF do responsável',
              ctrl: _respCpfCtrl,
              hint: '000.000.000-00',
              validator: Validators.cpf,
              keyboard: TextInputType.number,
              action: TextInputAction.done,
              formatters: [_CpfFormatter()],
            ),
          ],
        ),
      ),
    );
  }

  // ETAPA 6: Criar Senha
  Widget _step6() {
    return Form(
      key: _keys[5],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
        child: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _obscureSenha,
            builder: (_, obscure, __) => _Field(
              label: 'Senha',
              ctrl: _senhaCtrl,
              hint: 'Mínimo 6 caracteres',
              obscure: obscure,
              validator: Validators.password,
              action: TextInputAction.next,
              suffix: GestureDetector(
                onTap: () => _obscureSenha.value = !_obscureSenha.value,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _kHint,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          ValueListenableBuilder<bool>(
            valueListenable: _obscureConfirm,
            builder: (_, obscure, __) => _Field(
              label: 'Confirmar senha',
              ctrl: _confirmCtrl,
              hint: 'Repita a senha',
              obscure: obscure,
              action: TextInputAction.done,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirme sua senha';
                if (v != _senhaCtrl.text) return 'As senhas não coincidem';
                return null;
              },
              suffix: GestureDetector(
                onTap: () => _obscureConfirm.value = !_obscureConfirm.value,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: _kHint,
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildBottom() {
    final isLast = _step == _totalSteps - 1;
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (p, c) => (p is AuthLoading) != (c is AuthLoading),
      builder: (context, state) {
        final loading = state is AuthLoading;
        final isButtonLoading = loading || _isCheckingDuplicate;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(28, 6, 28, 22),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: _showDuplicateError 
                    ? AppColors.error 
                    : AppColors.navBarBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: (isButtonLoading || _showDuplicateError) ? null : _next,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        if (child.key == const ValueKey('error-message')) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        }
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0)
                                .animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _buildButtonContent(isButtonLoading, _showDuplicateError, isLast),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(bool loading, bool showError, bool isLast) {
    if (loading) {
      return const SizedBox(
        key: ValueKey('loading'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_duplicateErrorMessage.isNotEmpty && showError) {
      return Text(
        key: const ValueKey('error-message'),
        _duplicateErrorMessage,
        style: GoogleFonts.urbanist(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      );
    }

    if (showError) {
      return const Icon(
        key: ValueKey('error-icon'),
        Icons.close_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    return Row(
      key: const ValueKey('normal'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isLast ? 'Solicitar Cadastro' : 'Continuar',
          style: GoogleFonts.urbanist(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.arrow_forward_rounded,
            size: 20, color: AppColors.primary),
      ],
    );
  }

}

// ── Field widget ──
// Estilos e bordas cacheados como static para evitar alocações em cada build

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final bool obscure;
  final Widget? suffix;
  final List<TextInputFormatter>? formatters;
  final FocusNode? focusNode;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.validator,
    this.keyboard,
    this.action,
    this.obscure = false,
    this.suffix,
    this.formatters,
    this.focusNode,
  });

  // ── Estilos cacheados (criados uma única vez) ──
  static final _tsLabel = GoogleFonts.urbanist(
      fontSize: 14, fontWeight: FontWeight.w600, color: _kLabel);
  static final _tsInput = GoogleFonts.urbanist(
      fontSize: 15, fontWeight: FontWeight.w400, color: _kDark);
  static final _tsHint =
      GoogleFonts.urbanist(fontSize: 14, color: _kHint);
  static final _tsError =
      GoogleFonts.urbanist(fontSize: 11, color: AppColors.error);

  // ── Bordas cacheadas ──
  static final _border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none);
  static final _focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kEmerald, width: 1.5));
  static final _errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.error, width: 1));
  static final _focusErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.error, width: 1.5));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _tsLabel),
        const SizedBox(height: 10),
        TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          validator: validator,
          keyboardType: keyboard,
          textInputAction: action,
          obscureText: obscure,
          inputFormatters: formatters,
          style: _tsInput,
          cursorColor: _kEmerald,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _tsHint,
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14), child: suffix)
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 44),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            filled: true,
            fillColor: _kFieldBg,
            border: _border,
            enabledBorder: _border,
            focusedBorder: _focusBorder,
            errorBorder: _errorBorder,
            focusedErrorBorder: _focusErrorBorder,
            errorStyle: _tsError,
          ),
        ),
      ],
    );
  }
}

// ── Tipo Option widget (minimal) ──

class _TipoOption extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TipoOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kEmerald : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _kDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tipo Card widget ──

class _TipoCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TipoCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _kEmerald.withValues(alpha: 0.08) : _kFieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kEmerald : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kEmerald.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? _kEmerald.withValues(alpha: 0.15)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? _kEmerald : const Color(0xFF9CA3AF),
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? _kDark : const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Document upload field (multi-arquivo) ──

class _DocUploadField extends StatelessWidget {
  final String label;
  final bool required;
  final int maxFiles;
  final List<PlatformFile> files;
  final void Function(PlatformFile) onAdd;
  final void Function(int index) onRemove;

  const _DocUploadField({
    required this.label,
    required this.required,
    required this.maxFiles,
    required this.files,
    required this.onAdd,
    required this.onRemove,
  });

  // Estilos cacheados
  static final _tsLabel = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w600, color: _kLabel);
  static final _tsOptional = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w400, color: _kHint);
  static final _tsAction = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w500, color: _kLabel);
  static final _tsHint = GoogleFonts.urbanist(fontSize: 12, color: _kHint);
  static final _tsFileName = GoogleFonts.urbanist(
      fontSize: 13, fontWeight: FontWeight.w500, color: _kDark);
  static final _tsAddMore = GoogleFonts.urbanist(
      fontSize: 12.5, fontWeight: FontWeight.w500, color: _kEmerald);
  static final _tsCounter = GoogleFonts.urbanist(
      fontSize: 11, fontWeight: FontWeight.w400, color: _kHint);

  static Future<bool> _requestPermission(BuildContext ctx) async {
    if (!Platform.isAndroid) return true;
    final photos = await Permission.photos.status;
    final storage = await Permission.storage.status;
    if (photos.isDenied) await Permission.photos.request();
    if (storage.isDenied) await Permission.storage.request();

    final denied = (await Permission.photos.status).isPermanentlyDenied &&
        (await Permission.storage.status).isPermanentlyDenied;
    if (denied && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text(
          'Permissão negada. Habilite o acesso ao armazenamento nas configurações.',
          style: GoogleFonts.urbanist(fontSize: 13),
        ),
        action: SnackBarAction(
            label: 'Configurações', onPressed: openAppSettings),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return false;
    }
    return true;
  }

  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  Future<void> _pick(BuildContext ctx) async {
    if (!await _requestPermission(ctx)) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final size = file.size;
      if (size > _maxFileSizeBytes) {
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
            content: Text(
              'Arquivo muito grande (máx. 10 MB). Tamanho atual: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB',
              style: GoogleFonts.urbanist(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ));
        }
        return;
      }
      onAdd(file);
    }
  }


  @override
  Widget build(BuildContext context) {
    final hasFiles = files.isNotEmpty;
    final canAddMore = files.length < maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + badge opcional + contador
        Row(
          children: [
            Expanded(child: Text(label, style: _tsLabel)),
            if (hasFiles)
              Text('${files.length}/$maxFiles', style: _tsCounter)
            else if (!required)
              Text('opcional', style: _tsOptional),
          ],
        ),
        const SizedBox(height: 8),

        // Lista de arquivos já adicionados
        if (hasFiles) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kEmerald, width: 1),
              color: _kEmerald.withValues(alpha: 0.03),
            ),
            child: Column(
              children: [
                for (int i = 0; i < files.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: _kEmerald.withValues(alpha: 0.15)),
                  _FileRow(
                    file: files[i],
                    onRemove: () => onRemove(i),
                    tsFileName: _tsFileName,
                  ),
                ],
              ],
            ),
          ),
          // Botão "adicionar mais" abaixo da lista
          if (canAddMore) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pick(context),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded,
                      size: 16, color: _kEmerald),
                  const SizedBox(width: 6),
                  Text(
                    'Adicionar outra foto (opcional)',
                    style: _tsAddMore,
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // Área de upload vazia com borda tracejada
          GestureDetector(
            onTap: () => _pick(context),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                  color: const Color(0xFFD0D3D9), radius: 14),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.upload_file_outlined,
                          size: 28, color: _kHint),
                      const SizedBox(height: 10),
                      Text('Anexar documento', style: _tsAction),
                      const SizedBox(height: 4),
                      Text(
                          'PDF, JPG ou PNG · até $maxFiles foto${maxFiles > 1 ? 's' : ''}',
                          style: _tsHint),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;
  final TextStyle tsFileName;

  const _FileRow({
    required this.file,
    required this.onRemove,
    required this.tsFileName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              file.name,
              style: tsFileName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 17, color: _kHint),
          ),
        ],
      ),
    );
  }
}

// ── Borda tracejada ──

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashLen;
  final double gapLen;
  final double strokeWidth;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dashLen = 5,
    this.gapLen = 4,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    final dashed = Path();
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        dashed.addPath(m.extractPath(d, d + dashLen), Offset.zero);
        d += dashLen + gapLen;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

// ── Error row ──

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow(this.message);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded,
            size: 15, color: Color(0xFFEF4444)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.urbanist(
                fontSize: 13, color: const Color(0xFFEF4444)),
          ),
        ),
      ],
    );
  }
}

// ── Info box ──

class _InfoBox extends StatelessWidget {
  final String text;
  const _InfoBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _kHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.urbanist(
                  fontSize: 12, color: _kHint, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formatters de máscara ──

/// CNPJ: 00.000.000/0000-00
class _CnpjFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final n = d.length.clamp(0, 14);
    final s = d.substring(0, n);
    String r;
    if (n <= 2) {
      r = s;
    } else if (n <= 5) {
      r = '${s.substring(0, 2)}.${s.substring(2)}';
    } else if (n <= 8) {
      r = '${s.substring(0, 2)}.${s.substring(2, 5)}.${s.substring(5)}';
    } else if (n <= 12) {
      r = '${s.substring(0, 2)}.${s.substring(2, 5)}.${s.substring(5, 8)}/${s.substring(8)}';
    } else {
      r = '${s.substring(0, 2)}.${s.substring(2, 5)}.${s.substring(5, 8)}/${s.substring(8, 12)}-${s.substring(12)}';
    }
    return TextEditingValue(
        text: r, selection: TextSelection.collapsed(offset: r.length));
  }
}

/// Telefone: (00) 00000-0000 celular / (00) 0000-0000 fixo
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final n = d.length.clamp(0, 11);
    final s = d.substring(0, n);
    if (n == 0) return const TextEditingValue();
    String r;
    if (n <= 2) {
      r = '($s';
    } else if (n <= 6) {
      r = '(${s.substring(0, 2)}) ${s.substring(2)}';
    } else if (n <= 10) {
      // Fixo: (XX) XXXX-XXXX
      r = '(${s.substring(0, 2)}) ${s.substring(2, 6)}-${s.substring(6)}';
    } else {
      // Celular: (XX) XXXXX-XXXX
      r = '(${s.substring(0, 2)}) ${s.substring(2, 7)}-${s.substring(7)}';
    }
    return TextEditingValue(
        text: r, selection: TextSelection.collapsed(offset: r.length));
  }
}

/// CPF: 000.000.000-00
class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final n = d.length.clamp(0, 11);
    final s = d.substring(0, n);
    String r;
    if (n <= 3) {
      r = s;
    } else if (n <= 6) {
      r = '${s.substring(0, 3)}.${s.substring(3)}';
    } else if (n <= 9) {
      r = '${s.substring(0, 3)}.${s.substring(3, 6)}.${s.substring(6)}';
    } else {
      r = '${s.substring(0, 3)}.${s.substring(3, 6)}.${s.substring(6, 9)}-${s.substring(9)}';
    }
    return TextEditingValue(
        text: r, selection: TextSelection.collapsed(offset: r.length));
  }
}

/// CEP: 00000-000
class _CepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(_, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    final n = d.length.clamp(0, 8);
    final s = d.substring(0, n);
    if (n == 0) return const TextEditingValue();
    final r = n <= 5 ? s : '${s.substring(0, 5)}-${s.substring(5)}';
    return TextEditingValue(
        text: r, selection: TextSelection.collapsed(offset: r.length));
  }
}

// ── Type selection card (old) ──

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _kEmerald.withValues(alpha: 0.06) : _kFieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _kEmerald : const Color(0xFFE6E7EA),
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? _kEmerald.withValues(alpha: 0.12)
                    : const Color(0xFFE6E7EA),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, color: selected ? _kEmerald : _kHint, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.urbanist(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? _kDark : const Color(0xFF999999))),
          ],
        ),
      ),
    );
  }
}
