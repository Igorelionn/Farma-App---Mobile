class AppConstants {
  // App Info
  static const String appName = 'Suevit';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserEmail = 'user_email';
  static const String keyRememberMe = 'remember_me';
  
  // API (Mock)
  static const Duration apiDelay = Duration(milliseconds: 800);
  
  // Pedidos
  static const double minOrderValue = 200.0;
  static const double freeShippingThreshold = 1000.0;
  
  // Pagination
  static const int productsPerPage = 20;
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Images
  static const String placeholderImage = 'assets/images/placeholder.png';
  static const String logoImage = 'assets/images/logo.png';
  
  // Categorias
  static const List<String> categories = [
    'Genéricos',
    'Marca',
    'Controlados',
    'Hospitalares',
    'Material Médico',
    'Dermocosméticos',
  ];
}

