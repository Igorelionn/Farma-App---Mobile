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
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
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
      },
    );

    if (response.user == null) {
      throw Exception('Erro ao criar conta');
    }

    // Upload de documentos após criação do usuário (sessão autenticada)
    if (documents != null && documents.isNotEmpty) {
      await _uploadDocuments(response.user!.id, documents);
    }

    // Profile is created automatically via database trigger
    return await getCurrentUser();
  }

  Future<void> _uploadDocuments(
    String userId,
    Map<String, List<(String, Uint8List)>> documents,
  ) async {
    final storage = _client.storage;
    final docPaths = <String, String>{};
    final uploadErrors = <String>[];

    for (final entry in documents.entries) {
      final fieldName = entry.key;
      final fileList = entry.value;
      final paths = <String>[];

      for (int i = 0; i < fileList.length; i++) {
        final (fileName, bytes) = fileList[i];
        final ext = _sanitizeExtension(fileName);
        final path = '$userId/${fieldName}_$i.$ext';

        try {
          await storage.from('documents').uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(
                  contentType: _mimeType(ext),
                  upsert: true,
                ),
              );
          // Armazena o PATH do storage (não URL pública).
          // URLs assinadas são geradas sob demanda via getDocumentSignedUrls().
          paths.add(path);
        } catch (e) {
          debugPrint('[AuthRepository] Falha no upload de $fieldName[$i]: $e');
          uploadErrors.add('$fieldName[$i]');
        }
      }

      if (paths.isNotEmpty) {
        // Prefixo distingue paths de URLs legadas já salvas no banco.
        docPaths[fieldName] = '$_storagePrefix${paths.join('|')}';
      }
    }

    if (docPaths.isNotEmpty) {
      final updates = <String, dynamic>{};
      docPaths.forEach((key, val) => updates[key] = val);
      await _client.from('profiles').update(updates).eq('id', userId);
    }

    if (uploadErrors.isNotEmpty) {
      throw Exception(
        'UPLOAD_PARTIAL_FAILURE:${uploadErrors.join(',')}',
      );
    }
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
      final response = await _client.rpc(
        'check_email_exists',
        params: {'p_email': email},
      );
      return response == true;
    } catch (e) {
      debugPrint('[AuthRepository] Erro ao verificar email: $e');
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
