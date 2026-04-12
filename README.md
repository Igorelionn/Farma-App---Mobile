# Suevit - Plataforma B2B para Pedidos Farmaceuticos

Aplicativo mobile (Flutter) para compra de produtos farmaceuticos, exclusivo para clinicas e farmacias aprovadas.

## Stack

- **Frontend**: Flutter/Dart com BLoC pattern
- **Backend**: Supabase (PostgreSQL + Auth + Row Level Security)
- **State Management**: flutter_bloc + Equatable
- **UI**: Material 3, Google Fonts (Urbanist)

## Configuracao

### 1. Supabase

1. Crie um projeto no [Supabase](https://supabase.com)
2. Execute as migrations em `supabase/migrations/` na ordem:
   - `001_initial_schema.sql` - Tabelas e triggers
   - `002_rls_policies.sql` - Politicas de seguranca (RLS)
   - `003_seed_data.sql` - Dados iniciais (categorias e metodos de pagamento)
3. Copie a URL e anon key do projeto

### 2. Variaveis de Ambiente

Copie `.env.example` para `.env` e preencha:

```
SUPABASE_URL=https://SEU_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=SUA_ANON_KEY_AQUI
```

### 3. Executar

```bash
flutter pub get
flutter run
```

### 4. Seed de Produtos

Na primeira execucao, importe os 1060 produtos do JSON para o Supabase usando a classe `SeedData`:

```dart
import 'package:suevit_app/core/utils/seed_data.dart';

await SeedData.seedAll(onProgress: (msg) => print(msg));
```

### 5. iOS

Para gerar o projeto iOS (requer macOS):

```bash
flutter create . --platforms ios --org com.suevit
```

## Estrutura

```
lib/
  core/
    constants/     # Constantes do app
    services/      # SupabaseService, VoiceRecognitionService
    theme/         # Cores, tipografia, tema
    utils/         # Formatters, Validators, SeedData
    widgets/       # Widgets reutilizaveis
  data/
    models/        # User, Product, Order, CartItem, etc.
    repositories/  # Auth, Product, Cart, Order, Favorites
  features/
    auth/          # Login, Registro, Splash, Aprovacao
    catalog/       # Home, Lista de Produtos, Detalhes
    cart/          # Carrinho, Checkout
    orders/        # Pedidos, Detalhes
    favorites/     # Favoritos, Listas de Compras
supabase/
  migrations/      # SQL para criar schema no Supabase
```

## Autenticacao

O app usa autenticacao com sistema de aprovacao:

- **Cadastro**: usuario se registra e aguarda aprovacao do admin
- **Convite**: admin pode criar contas ja aprovadas via Supabase Dashboard
- **Status**: pending -> approved / rejected

Somente usuarios com `status: approved` acessam o catalogo.

## Requisitos

- Flutter 3.0+
- Dart 3.0+
- Conta Supabase (free tier disponivel)
- Android: API 26+ (Android 8.0)
- iOS: requer macOS para build
