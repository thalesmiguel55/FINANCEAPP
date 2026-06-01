import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/models/models.dart';
import 'package:financeapp/data/repositories/auth_repository.dart';
import 'package:financeapp/data/repositories/transactions_repository.dart';
import 'package:financeapp/presentation/widgets/transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _selectedCategory;
  TransactionType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter),
            onPressed: () => _showFilters(),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();
          final transactionsAsync = ref.watch(transactionsProvider(user.id));

          return transactionsAsync.when(
            data: (transactions) {
              // Filter
              var filtered = transactions;
              if (_selectedType != null) {
                filtered = filtered.where((t) => t.type == _selectedType).toList();
              }
              if (_selectedCategory != null) {
                filtered = filtered.where((t) => t.category == _selectedCategory).toList();
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _FilterChips(
                        selectedType: _selectedType,
                        selectedCategory: _selectedCategory,
                        onTypeChanged: (t) => setState(() => _selectedType = t),
                        onCategoryChanged: (c) => setState(() => _selectedCategory = c),
                      ),
                    ),
                  ),
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.receipt_2_1, size: 64, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round())),
                            const SizedBox(height: 16),
                            Text('Nenhuma transação', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('Toque em + para adicionar', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final t = filtered[index];
                          final showDate = index == 0 ||
                              !_isSameDay(t.date, filtered[index - 1].date);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    _formatDate(t.date),
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: TransactionTile(
                                  transaction: t,
                                  currencyFormat: currencyFormat,
                                  onDelete: () => _deleteTransaction(context, ref, user.id, t.id),
                                ).animate().fadeIn(delay: Duration(milliseconds: index * 30)),
                              ),
                            ],
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/transactions/add'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('Nova transação'),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    final today = DateTime.now();
    if (_isSameDay(date, today)) return 'Hoje';
    if (_isSameDay(date, today.subtract(const Duration(days: 1)))) return 'Ontem';
    return DateFormat("dd 'de' MMMM", 'pt_BR').format(date);
  }

  Future<void> _deleteTransaction(BuildContext context, WidgetRef ref, String userId, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir transação'),
        content: const Text('Tem certeza que deseja excluir esta transação?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(transactionsRepositoryProvider).deleteTransaction(id);
      ref.invalidate(transactionsProvider(userId));
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Tipo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Receitas'),
                  selected: _selectedType == TransactionType.income,
                  onSelected: (v) {
                    setState(() => _selectedType = v ? TransactionType.income : null);
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Despesas'),
                  selected: _selectedType == TransactionType.expense,
                  onSelected: (v) {
                    setState(() => _selectedType = v ? TransactionType.expense : null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedCategory = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Limpar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final TransactionType? selectedType;
  final String? selectedCategory;
  final ValueChanged<TransactionType?> onTypeChanged;
  final ValueChanged<String?> onCategoryChanged;

  const _FilterChips({
    this.selectedType,
    this.selectedCategory,
    required this.onTypeChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedType == null && selectedCategory == null) return const SizedBox();

    return Wrap(
      spacing: 8,
      children: [
        if (selectedType != null)
          Chip(
            label: Text(selectedType == TransactionType.income ? 'Receitas' : 'Despesas'),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => onTypeChanged(null),
          ),
        if (selectedCategory != null)
          Chip(
            label: Text(selectedCategory!),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: () => onCategoryChanged(null),
          ),
      ],
    );
  }
}
