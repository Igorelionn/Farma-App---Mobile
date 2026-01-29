import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final SharedPreferences prefs;
  
  AuthRepository({required this.prefs});
  
  Future<User?> login(String email, String password) async {
    // Simular delay de API
    await Future.delayed(AppConstants.apiDelay);
    
    // Carregar usuários mockados
    final String response = await rootBundle.loadString('assets/data/users.json');
    final List<dynamic> usersJson = json.decode(response);
    
    // Procurar usuário
    for (var userJson in usersJson) {
      if (userJson['email'] == email && userJson['senha'] == password) {
        final user = User.fromJson(userJson);
        
        // Salvar token simulado e dados do usuário
        await prefs.setString(AppConstants.keyToken, 'mock_token_${user.id}');
        await prefs.setString(AppConstants.keyUserId, user.id);
        await prefs.setString(AppConstants.keyUserEmail, user.email);
        
        return user;
      }
    }
    
    // Usuário não encontrado ou senha incorreta
    throw Exception('Email ou senha incorretos');
  }
  
  Future<void> logout() async {
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
  }
  
  Future<bool> isAuthenticated() async {
    final token = prefs.getString(AppConstants.keyToken);
    return token != null && token.isNotEmpty;
  }
  
  Future<User?> getCurrentUser() async {
    final userId = prefs.getString(AppConstants.keyUserId);
    if (userId == null) return null;
    
    // Carregar usuários mockados
    final String response = await rootBundle.loadString('assets/data/users.json');
    final List<dynamic> usersJson = json.decode(response);
    
    // Procurar usuário pelo ID
    for (var userJson in usersJson) {
      if (userJson['id'] == userId) {
        return User.fromJson(userJson);
      }
    }
    
    return null;
  }
  
  Future<void> setRememberMe(bool value) async {
    await prefs.setBool(AppConstants.keyRememberMe, value);
  }
  
  Future<bool> getRememberMe() async {
    return prefs.getBool(AppConstants.keyRememberMe) ?? false;
  }
}

