# Suevit - App Mobile

Aplicativo mobile B2B da Suevit, permitindo que clínicas e farmácias realizem pedidos de medicamentos de forma rápida e segura.

## 📱 Sobre o Projeto

Este é o MVP (Minimum Viable Product) do aplicativo Suevit, implementado em Flutter com as funcionalidades principais:

- ✅ Autenticação (Login com dados mockados)
- ✅ Catálogo de Produtos com busca e filtros
- ✅ Detalhes de Produtos
- ✅ Dashboard/Home com categorias
- ✅ Perfil de usuário

## 🛠️ Tecnologias Utilizadas

- **Flutter** - Framework cross-platform
- **BLoC** - Gerenciamento de estado
- **Equatable** - Comparação de objetos
- **SharedPreferences** - Persistência local
- **Google Fonts** - Tipografia
- **Intl** - Formatação de valores

## 📋 Requisitos

- Flutter SDK 3.0.0 ou superior
- Android SDK (mínimo: API 26 - Android 8.0)
- Android Gradle Plugin 8.1.1+ ✅

## 🚀 Como Executar

### 1. Instalar Dependências

```bash
flutter pub get
```

### 2. Executar o App

```bash
flutter run
```

### 3. Build para Android

```bash
flutter build apk
```

ou para App Bundle:

```bash
flutter build appbundle
```

## 👤 Usuários de Teste

Para testar o login, utilize um dos seguintes usuários mockados:

**Farmácia:**
- Email: `maria@farmaciaexemplo.com.br`
- Senha: `123456`

**Clínica:**
- Email: `joao@clinicasaude.com.br`
- Senha: `123456`

**Drogaria:**
- Email: `ana@drogariapopular.com.br`
- Senha: `123456`

## 📂 Estrutura do Projeto

```
lib/
├── core/                   # Recursos compartilhados
│   ├── theme/             # Cores, tipografia, tema
│   ├── constants/         # Constantes da aplicação
│   ├── widgets/           # Widgets reutilizáveis
│   └── utils/             # Utilitários (validators, formatters)
├── data/                  # Camada de dados
│   ├── models/            # Modelos (User, Product, Category)
│   └── repositories/      # Repositórios com dados mock
├── features/              # Features do app
│   ├── auth/              # Autenticação
│   │   ├── bloc/
│   │   └── presentation/
│   └── catalog/           # Catálogo de produtos
│       ├── bloc/
│       ├── presentation/
│       └── widgets/
└── main.dart              # Entry point

assets/
├── data/                  # JSONs com dados mockados
│   ├── products.json
│   ├── users.json
│   └── categories.json
├── images/                # Imagens
└── icons/                 # Ícones
```

## 🎨 Design System

O app utiliza um design system profissional com:

- **Cores primárias:** Azul (#1E40AF) para ações principais
- **Cores secundárias:** Verde (#059669) para sucesso
- **Tipografia:** Inter (Google Fonts)
- **Componentes:** Botões, campos de texto, cards customizados

## 📦 Dados Mockados

O app utiliza dados simulados (mock) armazenados em arquivos JSON:

- **30 produtos** variados por categoria
- **4 usuários** de teste
- **6 categorias** de medicamentos

## 🔄 Próximas Fases

### Fase 2 (Pendente)
- Carrinho de compras
- Checkout e finalização de pedidos
- Meus Pedidos (histórico)
- Favoritos e listas
- Notificações push
- Perfil completo

### Fase 3 (Pendente)
- Integração com backend real
- Sistema de pagamento
- Tracking de entregas
- Relatórios e analytics

## 📱 Versões Suportadas

- **Android:** 8.0 (API 26) ou superior
- **iOS:** (será implementado futuramente)

## 📄 Licença

Copyright © 2025 Suevit Distribuidora. Todos os direitos reservados.

## 🤝 Suporte

Para dúvidas ou problemas, entre em contato com a equipe Suevit.

