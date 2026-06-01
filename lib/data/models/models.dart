import 'package:equatable/equatable.dart';

// ============================================================
// USER MODEL
// ============================================================
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final double monthlyIncome;
  final double monthlyBudget;
  final String currency;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.monthlyIncome = 0,
    this.monthlyBudget = 0,
    this.currency = 'BRL',
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        monthlyIncome: (json['monthly_income'] as num?)?.toDouble() ?? 0,
        monthlyBudget: (json['monthly_budget'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String? ?? 'BRL',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'avatar_url': avatarUrl,
        'monthly_income': monthlyIncome,
        'monthly_budget': monthlyBudget,
        'currency': currency,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? avatarUrl,
    double? monthlyIncome,
    double? monthlyBudget,
    String? currency,
  }) =>
      UserModel(
        id: id,
        email: email,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
        currency: currency ?? this.currency,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, email, name, avatarUrl, monthlyIncome, monthlyBudget, currency];
}

// ============================================================
// TRANSACTION MODEL
// ============================================================
enum TransactionType { income, expense }

class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String? description;
  final DateTime date;
  final bool isRecurring;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    this.isRecurring = false,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        category: json['category'] as String,
        description: json['description'] as String?,
        date: DateTime.parse(json['date'] as String),
        isRecurring: json['is_recurring'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'is_recurring': isRecurring,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, title, amount, type, category, date];
}

// ============================================================
// INVESTMENT / STOCK MODEL
// ============================================================
class StockModel extends Equatable {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double? openPrice;
  final double? highPrice;
  final double? lowPrice;
  final double? volume;
  final String? marketCap;
  final DateTime lastUpdated;

  const StockModel({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.volume,
    this.marketCap,
    required this.lastUpdated,
  });

  bool get isPositive => change >= 0;

  @override
  List<Object?> get props => [symbol, currentPrice, change, changePercent];
}

// ============================================================
// USER INVESTMENT MODEL (portfolio)
// ============================================================
class UserInvestmentModel extends Equatable {
  final String id;
  final String userId;
  final String symbol;
  final String name;
  final double quantity;
  final double averagePrice;
  final DateTime purchaseDate;
  final DateTime createdAt;

  const UserInvestmentModel({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.purchaseDate,
    required this.createdAt,
  });

  double get totalInvested => quantity * averagePrice;

  double currentValue(double currentPrice) => quantity * currentPrice;

  double profitLoss(double currentPrice) => currentValue(currentPrice) - totalInvested;

  double profitLossPercent(double currentPrice) =>
      totalInvested > 0 ? (profitLoss(currentPrice) / totalInvested) * 100 : 0;

  factory UserInvestmentModel.fromJson(Map<String, dynamic> json) => UserInvestmentModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        averagePrice: (json['average_price'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'symbol': symbol,
        'name': name,
        'quantity': quantity,
        'average_price': averagePrice,
        'purchase_date': purchaseDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, userId, symbol, quantity, averagePrice];
}

// ============================================================
// BUDGET SUMMARY MODEL
// ============================================================
class BudgetSummaryModel extends Equatable {
  final double totalIncome;
  final double totalExpenses;
  final double totalSavings;
  final double savingsRate;
  final Map<String, double> expensesByCategory;
  final DateTime periodStart;
  final DateTime periodEnd;

  const BudgetSummaryModel({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalSavings,
    required this.savingsRate,
    required this.expensesByCategory,
    required this.periodStart,
    required this.periodEnd,
  });

  double get balance => totalIncome - totalExpenses;

  @override
  List<Object?> get props => [totalIncome, totalExpenses, periodStart, periodEnd];
}
