# 🎨 Como Adicionar a Logo do Suevit

## 📍 Onde Colocar a Imagem da Logo

### Passo 1: Preparar a Imagem

Prepare sua logo nos seguintes formatos:
- **PNG** com fundo transparente (recomendado)
- **Resolução:** 512x512 pixels ou superior
- **Nome do arquivo:** `logo.png`

### Passo 2: Adicionar ao Projeto

Coloque o arquivo da logo na pasta:

```
assets/images/logo.png
```

**Caminho completo:**
```
AplicativooficialdaSuevit/
├── assets/
│   └── images/
│       └── logo.png  ← COLOQUE AQUI
```

### Passo 3: Atualizar a Splash Screen

A splash screen já está configurada para usar a logo. Você só precisa descomentar as linhas:

**Arquivo:** `lib/features/auth/presentation/splash_screen.dart`

**Linha 57-61** - Descomente este bloco:

```dart
// ANTES (comentado):
// Image.asset(
//   'assets/images/logo.png',
//   width: 200,
//   height: 200,
// ),

// DEPOIS (descomentado):
Image.asset(
  'assets/images/logo.png',
  width: 200,
  height: 200,
),
```

**E comente o Container temporário** (linhas 63-74):

```dart
// ANTES:
Container(
  width: 150,
  height: 150,
  decoration: BoxDecoration(
    color: AppColors.primary.withOpacity(0.1),
    shape: BoxShape.circle,
  ),
  child: const Icon(
    Icons.medical_services,
    size: 80,
    color: AppColors.primary,
  ),
),

// DEPOIS:
// Container(
//   width: 150,
//   height: 150,
//   decoration: BoxDecoration(
//     color: AppColors.primary.withOpacity(0.1),
//     shape: BoxShape.circle,
//   ),
//   child: const Icon(
//     Icons.medical_services,
//     size: 80,
//     color: AppColors.primary,
//   ),
// ),
```

---

## 🎯 Outros Lugares para Adicionar a Logo (Opcional)

### 1. Drawer/Menu Lateral

**Arquivo:** `lib/features/catalog/presentation/home_screen.dart`

**Linha aproximada:** 564 (dentro do DrawerHeader)

Substitua o ícone por:

```dart
Image.asset(
  'assets/images/logo.png',
  width: 60,
  height: 60,
),
```

### 2. Login Screen (Opcional)

**Arquivo:** `lib/features/auth/presentation/login_screen.dart`

**Linha aproximada:** 67-76

Substitua o Container por:

```dart
Image.asset(
  'assets/images/logo.png',
  width: 100,
  height: 100,
),
```

---

## 🔧 Diferentes Tamanhos de Logo

Se você quiser logos de diferentes tamanhos para melhor performance:

### Estrutura Recomendada:

```
assets/images/
├── logo.png           (512x512 - alta resolução)
├── logo_small.png     (128x128 - ícones pequenos)
└── logo_medium.png    (256x256 - tamanho médio)
```

### Uso:

```dart
// Splash (grande)
Image.asset('assets/images/logo.png', width: 200)

// Drawer (médio)
Image.asset('assets/images/logo_medium.png', width: 80)

// AppBar (pequeno)
Image.asset('assets/images/logo_small.png', width: 40)
```

---

## ✨ Efeitos na Logo (Opcional)

### Adicionar Sombra:

```dart
Container(
  decoration: BoxDecoration(
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: Image.asset(
    'assets/images/logo.png',
    width: 200,
    height: 200,
  ),
)
```

### Logo Circular:

```dart
ClipOval(
  child: Image.asset(
    'assets/images/logo.png',
    width: 150,
    height: 150,
    fit: BoxFit.cover,
  ),
)
```

---

## 🚀 Testando

Após adicionar a logo:

```bash
# Limpar o projeto
flutter clean

# Obter dependências
flutter pub get

# Executar o app
flutter run
```

---

## ⚠️ Problemas Comuns

### Logo não aparece?

1. **Verifique o caminho:** `assets/images/logo.png`
2. **Verifique o pubspec.yaml:** A linha `- assets/images/` deve estar descomentada
3. **Execute:** `flutter clean` e `flutter pub get`
4. **Reinicie** o app

### Logo muito grande/pequena?

Ajuste os valores de `width` e `height`:

```dart
Image.asset(
  'assets/images/logo.png',
  width: 150,  // Ajuste aqui
  height: 150, // Ajuste aqui
)
```

---

## 🎨 Formato da Logo

**Recomendações:**
- ✅ PNG com fundo transparente
- ✅ Proporção 1:1 (quadrada)
- ✅ Resolução mínima: 512x512px
- ✅ Cores da marca Suevit

**Evitar:**
- ❌ JPG (sem transparência)
- ❌ Resolução muito baixa (<256px)
- ❌ Formatos exóticos (WebP, AVIF)

---

## 📞 Exemplo Completo

**Splash Screen com Logo:**

```dart
// Após adicionar assets/images/logo.png
Image.asset(
  'assets/images/logo.png',
  width: 200,
  height: 200,
),
const SizedBox(height: 32),
Text(
  'Suevit Distribuidora',
  style: AppTextStyles.h2.copyWith(
    color: AppColors.primary,
  ),
),
```

---

**Pronto! Sua logo aparecerá na splash screen com fade in automático! 🎉**

