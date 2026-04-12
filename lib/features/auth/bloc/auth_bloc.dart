import 'dart:io';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (error is SocketException || errorStr.contains('socket')) {
      return 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
    }
    
    if (error is TimeoutException || errorStr.contains('timeout')) {
      return 'A conexão demorou muito. Verifique sua internet e tente novamente.';
    }
    
    if (error is http.ClientException || 
        errorStr.contains('clientexception') || 
        errorStr.contains('connection closed') ||
        errorStr.contains('failed host lookup')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
    
    if (errorStr.contains('invalid_credentials') || errorStr.contains('invalid credentials')) {
      return 'Usuário ou senha inválidos';
    }
    
    if (errorStr.contains('not_found')) {
      return 'Usuário não encontrado';
    }
    
    if (errorStr.contains('already registered')) {
      return 'Este email já está cadastrado';
    }
    
    // Retorna mensagem original se for algo específico
    String message = error.toString().replaceAll('Exception: ', '');
    if (!message.toLowerCase().contains('exception') && 
        !message.contains('Error:') &&
        message.length < 100) {
      return message;
    }
    
    // Erro genérico
    return 'Ocorreu um erro. Tente novamente.';
  }
  
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final isAuthenticated = await authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        if (user != null) {
          _emitUserState(emit, user);
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authRepository.login(event.username, event.password);

      if (user != null) {
        _emitUserState(emit, user);
      } else {
        emit(const AuthError(message: 'Usuário ou senha inválidos'));
      }
    } catch (e) {
      emit(AuthError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.register(
        email: event.email,
        password: event.password,
        nome: event.nome,
        empresa: event.empresa,
        cnpj: event.cnpj,
        tipo: event.tipo,
        telefone: event.telefone,
        cep: event.cep,
        endereco: event.endereco,
        numero: event.numero,
        complemento: event.complemento,
        bairro: event.bairro,
        cidade: event.cidade,
        estado: event.estado,
        inscricaoEstadual: event.inscricaoEstadual,
        inscricaoMunicipal: event.inscricaoMunicipal,
        afe: event.afe,
        autorizacaoEspecial: event.autorizacaoEspecial,
        documents: event.documents,
        responsavelNome: event.responsavelNome,
        responsavelCpf: event.responsavelCpf,
        responsavelCrf: event.responsavelCrf,
      );

      emit(AuthRegistered());
    } catch (e) {
      emit(AuthError(message: _getFriendlyErrorMessage(e)));
    }
  }
  
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authRepository.requestPasswordReset(event.email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: _getFriendlyErrorMessage(e)));
    }
  }

  void _emitUserState(Emitter<AuthState> emit, User user) {
    if (user.isApproved) {
      emit(AuthAuthenticated(user: user));
    } else if (user.isPending) {
      emit(AuthPendingApproval(user: user));
    } else {
      emit(AuthRejected(user: user));
    }
  }
}
