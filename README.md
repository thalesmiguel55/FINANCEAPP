# 💰 FinanceApp

> App financeiro completo em Flutter com controle de gastos, investimentos em tempo real e gerenciamento de estado com Riverpod.

![Flutter](https://img.shields.io/badge/Flutter-3.22-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-2.5-3ECF8E?logo=supabase)
![Riverpod](https://img.shields.io/badge/Riverpod-2.5-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📱 Telas

| Onboarding | Login | Home | Transações |
|---|---|---|---|
| Apresentação do app | Autenticação | Dashboard financeiro | Lista completa |

| Adicionar | Investimentos | Detalhe Ativo | Perfil |
|---|---|---|---|
| Formulário completo | Mercado + Carteira | Gráfico histórico | Configurações |

---

## 🏗️ Arquitetura

O projeto segue **Clean Architecture** com as camadas:

```
lib/
├── core/                          # Núcleo do app
│   ├── constants/                 # Constantes globais (AppConstants)
│   ├── router/                    # Roteamento (GoRouter)
│   ├── theme/                     # Tema dark/light (AppTheme)
│   └── utils/                     # Utilitários
│
├── data/                          # Camada de dados
│   ├── models/                    # Modelos de dados (UserModel, TransactionModel, StockModel...)
│   ├── repositories/              # Repositórios (Auth, Transactions, Investments)
│   └── datasources/               # Fontes de dados
│
└── presentation/                  # Camada de apresentação
    ├── screens/                   # Telas organizadas por feature
    │   ├── auth/                  # Onboarding, Login, Registro
    │   ├── home/                  # Dashboard principal
    │   ├── transactions/          # Lista + Formulário
    │   ├── investments/           # Mercado + Carteira + Detalhe
    │   ├── profile/               # Perfil + Configurações
    │   └── shell/                 # Shell de navegação
    └── widgets/                   # Widgets reutilizáveis
```

---

## ⚙️ Tecnologias

| Tecnologia | Uso |
|---|---|
| **Flutter 3.22** | Framework UI multiplataforma |
| **Riverpod 2.5** | Gerenciamento de estado reativo |
| **Supabase** | Backend (Auth + PostgreSQL + Realtime) |
| **GoRouter** | Navegação declarativa |
| **Alpha Vantage API** | Cotações de ações em tempo real |
| **fl_chart** | Gráficos financeiros |
| **flutter_animate** | Animações fluidas |
| **dio** | HTTP client para APIs |
| **flutter_secure_storage** | Armazenamento seguro de tokens |

---

## 🚀 Como rodar

### Pré-requisitos
- Flutter SDK 3.22+
- Dart SDK 3.4+
- Conta no [Supabase](https://supabase.com) (gratuita)
- Chave da [Alpha Vantage API](https://www.alphavantage.co/support/#api-key) (gratuita)

### 1. Clone o repositório
```bash
git clone https://github.com/seu-usuario/financeapp.git
cd financeapp
```

### 2. Configure o Supabase

1. Acesse [supabase.com](https://supabase.com) → New Project
2. Vá em **SQL Editor** e execute o arquivo `supabase_schema.sql`
3. Copie a **URL** e a **anon key** em Project Settings → API

### 3. Configure as credenciais

Edite o arquivo `lib/core/constants/app_constants.dart`:

```dart
static const String supabaseUrl = 'https://SEU_PROJECT.supabase.co';
static const String supabaseAnonKey = 'SUA_ANON_KEY';
static const String alphaVantageApiKey = 'SUA_ALPHA_VANTAGE_KEY';
```

> **Segurança em produção:** Use variáveis de ambiente via `--dart-define`:
> ```bash
> flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
> ```

### 4. Instale as dependências
```bash
flutter pub get
```

### 5. Execute o app
```bash
flutter run
```

---

## 📦 Gerar APK

### Debug
```bash
flutter build apk --debug
```

### Release (produção)
```bash
# APK separado por arquitetura (menor tamanho - recomendado)
flutter build apk --release --split-per-abi

# APK universal
flutter build apk --release

# App Bundle para Google Play
flutter build appbundle --release
```

Os arquivos gerados ficam em:
```
build/app/outputs/flutter-apk/
```

---

## 🗄️ Banco de Dados (Supabase)

### Tabelas criadas pelo `supabase_schema.sql`:

| Tabela | Descrição |
|---|---|
| `profiles` | Dados do usuário (nome, email, renda, orçamento) |
| `transactions` | Todas as transações financeiras |
| `investments` | Portfólio de investimentos do usuário |

### Row Level Security (RLS)
Todas as tabelas têm RLS habilitado — cada usuário só acessa os próprios dados.

---

## 📊 Gerenciamento de Estado (Riverpod)

O app usa **Riverpod** para todos os estados reativos:

```dart
// Provider simples
final authRepositoryProvider = Provider<AuthRepository>((ref) { ... });

// Estado reativo do usuário logado
final currentUserProvider = FutureProvider<UserModel?>((ref) async { ... });

// Stream em tempo real do banco
final transactionsProvider = StreamProvider.family<List<TransactionModel>, String>(
  (ref, userId) { ... }
);

// Resumo financeiro mensal
final monthlySummaryProvider = FutureProvider.family<BudgetSummaryModel, String>(
  (ref, userId) async { ... }
);
```

---

## 📈 API de Investimentos (Alpha Vantage)

```dart
// Cotação em tempo real
GET https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=PETR4&apikey=KEY

// Dados históricos (30 dias)
GET https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=PETR4&apikey=KEY

// Busca de ativos
GET https://www.alphavantage.co/query?function=SYMBOL_SEARCH&keywords=PETRO&apikey=KEY
```

> **Limite free tier:** 25 req/dia e 5 req/min. O app inclui dados mockados como fallback.

---

## 🧮 Funções Financeiras

O app inclui a classe `FinancialCalculations` com:

| Função | Descrição |
|---|---|
| `compoundInterestFull` | Juros compostos: M = C × (1+i)^n |
| `npv` | VPL - Valor Presente Líquido |
| `irr` | TIR - Taxa Interna de Retorno |
| `rule72` | Regra dos 72 (tempo para dobrar) |
| `yearsToRetirement` | Prazo para aposentadoria |
| `sacAmortization` | Tabela de amortização SAC |

---

## 🔄 CI/CD (GitHub Actions)

O arquivo `.github/workflows/ci.yml` automatiza:

1. **Análise**: `dart format` + `flutter analyze`
2. **Testes**: `flutter test --coverage`
3. **Build**: APK + AAB em push para `main`
4. **Release**: Upload automático ao criar uma tag `v*`

### Secrets necessários no GitHub:
```
SUPABASE_URL
SUPABASE_ANON_KEY
ALPHA_VANTAGE_KEY
```

---

## 🔐 Funcionalidades de Segurança

- Autenticação via Supabase Auth (email + senha)
- Reset de senha por email
- Row Level Security no banco
- Senhas validadas (8+ chars, maiúscula, número)
- Tokens armazenados com `flutter_secure_storage`

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch: `git checkout -b feature/nova-funcionalidade`
3. Commit: `git commit -m 'feat: adiciona nova funcionalidade'`
4. Push: `git push origin feature/nova-funcionalidade`
5. Abra um Pull Request

---

## 📄 Licença

MIT © 2025 - FinanceApp
