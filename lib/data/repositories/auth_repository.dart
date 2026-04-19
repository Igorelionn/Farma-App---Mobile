import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../../core/services/supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  /// Prefixo usado para distinguir paths de storage de URLs legadas no banco.
  static const _storagePrefix = 'storage:';

  Future<app_user.User?> login(String username, String password) async {
    String email = username;

    if (!username.contains('@')) {
      final result = await _client.rpc(
        'get_email_by_username',
        params: {'p_username': username},
      );

      if (result == null || (result is String && result.isEmpty)) {
        throw Exception('NOT_FOUND');
      }
      email = result as String;
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('INVALID_CREDENTIALS');
      }
    } on AuthException catch (_) {
      throw Exception('INVALID_CREDENTIALS');
    }

    return await getCurrentUser();
  }

  Future<app_user.User?> register({
    required String email,
    required String password,
    required String nome,
    required String empresa,
    required String cnpj,
    required String tipo,
    String? telefone,
    String? cep,
    String? endereco,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
    String? inscricaoEstadual,
    String? inscricaoMunicipal,
    String? afe,
    String? autorizacaoEspecial,
    Map<String, List<(String, Uint8List)>>? documents,
    String? responsavelNome,
    String? responsavelCpf,
    String? responsavelCrf,
  }) async {
    debugPrint('[AuthRepository] Iniciando cadastro para email: $email');
    debugPrint('[AuthRepository] CNPJ: $cnpj');
    debugPrint('[AuthRepository] Telefone: $telefone');
    
    try {
      final userData = {
        'nome': nome,
        'empresa': empresa,
        'cnpj': cnpj,
        'tipo': tipo,
        'telefone': telefone,
        'cep': cep,
        'endereco': endereco,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'inscricao_estadual': inscricaoEstadual,
        'inscricao_municipal': inscricaoMunicipal,
        'afe': afe,
        'autorizacao_especial': autorizacaoEspecial,
        'responsavel_nome': responsavelNome,
        'responsavel_cpf': responsavelCpf,
        'responsavel_crf': responsavelCrf,
      };

      debugPrint('[AuthRepository] User data: $userData');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );

      debugPrint('[AuthRepository] SignUp concluído. User ID: ${response.user?.id}');
      debugPrint('[AuthRepository] Session: ${response.session?.accessToken != null ? "Ativa" : "Inativa"}');

      if (response.user == null) {
        debugPrint('[AuthRepository] Erro: response.user é null');
        throw Exception('Erro ao criar conta');
      }

      // Se a sessão não foi criada automaticamente, aguarda um pouco
      // para garantir que está tudo sincronizado
      if (response.session == null || response.session!.accessToken.isEmpty) {
        debugPrint('[AuthRepository] Aguardando sincronização da sessão...');
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Verifica sessão atual antes do upload
      final currentSession = _client.auth.currentSession;
      debugPrint('[AuthRepository] Sessão atual: ${currentSession?.user.id}');
      debugPrint('[AuthRepository] Access token presente: ${currentSession?.accessToken != null}');

      // Upload de documentos após criação do usuário (sessão autenticada)
      if (documents != null && documents.isNotEmpty) {
        debugPrint('[AuthRepository] Iniciando upload de ${documents.length} tipos de documentos');
        await _uploadDocuments(response.user!.id, documents);
      } else {
        debugPrint('[AuthRepository] Sem documentos para upload');
      }

      // Profile is created automatically via database trigger
      debugPrint('[AuthRepository] Buscando usuário atual...');
      return await getCurrentUser();
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] ERRO no cadastro: $e');
      debugPrint('[AuthRepository] Tipo do erro: ${e.runtimeType}');
      if (e.toString().contains('Database error')) {
        debugPrint('[AuthRepository] ERRO DE BANCO! Possível constraint violation ou trigger failure');
      }
      debugPrint('[AuthRepository] StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _uploadDocuments(
    String userId,
    Map<String, List<(String, Uint8List)>> documents,
  ) async {
    debugPrint('[AuthRepository] Iniciando upload de documentos para userId: $userId');
    final storage = _client.storage;
    final docPaths = <String, String>{};
    final uploadErrors = <String>[];

    for (final entry in documents.entries) {
      final fieldName = entry.key;
      final fileList = entry.value;
      final paths = <String>[];

      debugPrint('[AuthRepository] Uploading $fieldName (${fileList.length} arquivos)');

      for (int i = 0; i < fileList.length; i++) {
        final (fileName, bytes) = fileList[i];
        final ext = _sanitizeExtension(fileName);
        final path = '$userId/${fieldName}_$i.$ext';

        try {
          debugPrint('[AuthRepository] Tentando upload: $path (${bytes.length} bytes)');
          await storage.from('documents').uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(
                  contentType: _mimeType(ext),
                  upsert: true,
                ),
              );
          debugPrint('[AuthRepository] Upload bem-sucedido: $path');
          paths.add(path);
        } catch (e) {
          debugPrint('[AuthRepository] Falha no upload de $fieldName[$i]: $e');
          uploadErrors.add('$fieldName[$i]');
        }
      }

      if (paths.isNotEmpty) {
        docPaths[fieldName] = '$_storagePrefix${paths.join('|')}';
      }
    }

    debugPrint('[AuthRepository] Total de paths salvos: ${docPaths.length}');
    debugPrint('[AuthRepository] Erros de upload: ${uploadErrors.length}');

    if (docPaths.isNotEmpty) {
      final updates = <String, dynamic>{};
      docPaths.forEach((key, val) => updates[key] = val);
      debugPrint('[AuthRepository] Atualizando profiles com: $updates');
      await _client.from('profiles').update(updates).eq('id', userId);
    }

    if (uploadErrors.isNotEmpty) {
      final errorMsg = 'UPLOAD_PARTIAL_FAILURE:${uploadErrors.join(',')}';
      debugPrint('[AuthRepository] Lançando exceção: $errorMsg');
      throw Exception(errorMsg);
    }
    
    debugPrint('[AuthRepository] Upload de documentos concluído com sucesso');
  }

  /// Gera URLs assinadas (expiram em 1 hora) para os documentos de um usuário.
  /// Retorna Map<fieldName, List<signedUrl>>.
  Future<Map<String, List<String>>> getDocumentSignedUrls(String userId) async {
    final response = await _client
        .from('profiles')
        .select(
          'alvara_funcionamento, licenca_sanitaria, crt, afe, autorizacao_especial',
        )
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return {};

    final result = <String, List<String>>{};
    const fields = [
      'alvara_funcionamento',
      'licenca_sanitaria',
      'crt',
      'afe',
      'autorizacao_especial',
    ];

    for (final field in fields) {
      final raw = response[field] as String?;
      if (raw == null || raw.isEmpty) continue;

      final urls = await _resolveDocumentUrls(raw);
      if (urls.isNotEmpty) result[field] = urls;
    }

    return result;
  }

  /// Converte valor do banco (path prefixado OU URL legada) em lista de URLs acessíveis.
  Future<List<String>> _resolveDocumentUrls(String raw) async {
    if (raw.startsWith(_storagePrefix)) {
      // Novo formato: paths do storage → gera signed URLs (1 hora)
      final paths = raw.substring(_storagePrefix.length).split('|');
      final signedUrls = <String>[];
      for (final path in paths) {
        try {
          final signed = await _client.storage
              .from('documents')
              .createSignedUrl(path, 3600);
          signedUrls.add(signed);
        } catch (e) {
          debugPrint('[AuthRepository] Erro ao gerar signed URL para $path: $e');
        }
      }
      return signedUrls;
    } else {
      // Formato legado: URLs completas separadas por '|'
      return raw.split('|').where((u) => u.isNotEmpty).toList();
    }
  }

  /// Extrai e sanitiza a extensão do arquivo, aceitando apenas tipos permitidos.
  String _sanitizeExtension(String fileName) {
    const allowed = {'pdf', 'jpg', 'jpeg', 'png'};
    if (!fileName.contains('.')) return 'bin';
    final ext = fileName.split('.').last.toLowerCase();
    return allowed.contains(ext) ? ext : 'bin';
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
  
  Future<void> logout() async {
    await _client.auth.signOut();
  }
  
  Future<bool> isAuthenticated() async {
    return _client.auth.currentUser != null;
  }
  
  Future<app_user.User?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    final response = await _client.from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (response == null) return null;
    return app_user.User.fromJson(response);
  }

  Future<String> getUserStatus() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return 'unauthenticated';

    final response = await _client.from('profiles')
        .select('status')
        .eq('id', authUser.id)
        .maybeSingle();

    return response?['status'] as String? ?? 'pending';
  }

  Future<void> updateProfile({
    String? nome,
    String? telefone,
    String? empresa,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuário não autenticado');

    final updates = <String, dynamic>{};
    if (nome != null) updates['nome'] = nome;
    if (telefone != null) updates['telefone'] = telefone;
    if (empresa != null) updates['empresa'] = empresa;

    if (updates.isNotEmpty) {
      await _client.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      debugPrint('[AuthRepository] Verificando email: $email');
      
      final response = await _client.rpc(
        'check_email_exists',
        params: {'p_email': email},
      );
      
      debugPrint('[AuthRepository] Resposta da verificação de email: $response');
      
      return response == true;
    } catch (e) {
      debugPrint('[AuthRepository] Erro ao verificar email: $e');
      return false;
    }
  }

  Future<bool> checkCnpjExists(String cnpj) async {
    try {
      final response = await _client.rpc(
        'check_cnpj_exists',
        params: {'p_cnpj': cnpj},
      );
      return response == true;
    } catch (e) {
      debugPrint('[AuthRepository] Erro ao verificar CNPJ: $e');
      return false;
    }
  }

  Future<bool> checkTelefoneExists(String telefone) async {
    try {
      final response = await _client.rpc(
        'check_telefone_exists',
        params: {'p_telefone': telefone},
      );
      return response == true;
    } catch (e) {
      debugPrint('[AuthRepository] Erro ao verificar telefone: $e');
      return false;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    // Por segurança, não validamos se o email existe
    // O Supabase Auth sempre retorna sucesso para não expor emails cadastrados
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.suevit.distribuidora://reset-password',
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
