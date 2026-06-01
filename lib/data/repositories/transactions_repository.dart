import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:financeapp/data/models/models.dart';
import 'package:financeapp/core/constants/app_constants.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(Supabase.instance.client);
});

// Provider para lista de transações em tempo real
final transactionsProvider = StreamProvider.family<List<TransactionModel>, String>((ref, userId) {
  return ref.read(transactionsRepositoryProvider).watchTransactions(userId);
});

// Provider para resumo financeiro do mês
final monthlySummaryProvider = FutureProvider.family<BudgetSummaryModel, String>((ref, userId) async {
  final repo = ref.read(transactionsRepositoryProvider);
  return repo.getMonthlySummary(userId);
});

// Provider para transações recentes (home)
final recentTransactionsProvider = FutureProvider.family<List<TransactionModel>, String>((ref, userId) async {
  return ref.read(transactionsRepositoryProvider).getRecentTransactions(userId, limit: 5);
});

class TransactionsRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  TransactionsRepository(this._client);

  Stream<List<TransactionModel>> watchTransactions(String userId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('date', ascending: false)
        .map((data) => data.map((e) => TransactionModel.fromJson(e)).toList());
  }

  Future<List<TransactionModel>> getTransactions(
    String userId, {
    int page = 0,
    String? category,
    TransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('transactions')
        .select()
        .eq('user_id', userId);

    if (category != null) query = query.eq('category', category);
    if (type != null) query = query.eq('type', type.name);
    if (startDate != null) query = query.gte('date', startDate.toIso8601String());
    if (endDate != null) query = query.lte('date', endDate.toIso8601String());

    final data = await query
        .order('date', ascending: false)
        .range(page * AppConstants.pageSize, (page + 1) * AppConstants.pageSize - 1);

    return data.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions(String userId, {int limit = 5}) async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .limit(limit);

    return data.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<TransactionModel> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required TransactionType type,
    required String category,
    String? description,
    required DateTime date,
    bool isRecurring = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'is_recurring': isRecurring,
      'created_at': now.toIso8601String(),
    };

    final result = await _client.from('transactions').insert(data).select().single();
    return TransactionModel.fromJson(result);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id);
  }

  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  Future<BudgetSummaryModel> getMonthlySummary(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('date', startOfMonth.toIso8601String())
        .lte('date', endOfMonth.toIso8601String());

    final transactions = data.map((e) => TransactionModel.fromJson(e)).toList();

    double totalIncome = 0;
    double totalExpenses = 0;
    final expensesByCategory = <String, double>{};

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
        expensesByCategory[t.category] =
            (expensesByCategory[t.category] ?? 0) + t.amount;
      }
    }

    final totalSavings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0;

    return BudgetSummaryModel(
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      totalSavings: totalSavings,
      savingsRate: savingsRate.toDouble(),
      expensesByCategory: expensesByCategory,
      periodStart: startOfMonth,
      periodEnd: endOfMonth,
    );
  }

  // Funções financeiras
  Future<Map<String, List<double>>> getMonthlyEvolution(String userId, {int months = 6}) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, 1);

    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('date', startDate.toIso8601String())
        .order('date', ascending: true);

    final transactions = data.map((e) => TransactionModel.fromJson(e)).toList();

    final incomes = List<double>.filled(months, 0);
    final expenses = List<double>.filled(months, 0);

    for (final t in transactions) {
      final monthIndex = (t.date.year * 12 + t.date.month) -
          (startDate.year * 12 + startDate.month);
      if (monthIndex >= 0 && monthIndex < months) {
        if (t.type == TransactionType.income) {
          incomes[monthIndex] += t.amount;
        } else {
          expenses[monthIndex] += t.amount;
        }
      }
    }

    return {'income': incomes, 'expenses': expenses};
  }
}
