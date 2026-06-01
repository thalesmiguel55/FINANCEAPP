import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/models/models.dart';
import 'package:financeapp/data/repositories/auth_repository.dart';
import 'package:financeapp/data/repositories/transactions_repository.dart';
import 'package:financeapp/presentation/widgets/transaction_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.primary.withAlpha((0.06 * 255).round()),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0, 0.34, 1],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(monthlySummaryProvider);
              ref.invalidate(recentTransactionsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: userAsync.when(
                data: (user) => _HomeContent(user: user),
                loading: () => const Center(
                  heightFactor: 10,
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final UserModel? user;
  const _HomeContent({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = user?.id ?? '';
    final summaryAsync = ref.watch(monthlySummaryProvider(userId));
    final recentAsync = ref.watch(recentTransactionsProvider(userId));
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    // removed unused 'now' variable

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      user?.name.split(' ').first ?? 'Usuário',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryGreen.withAlpha((0.2 * 255).round()),
                child: Text(
                  (user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U'),
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.1),

          const SizedBox(height: 24),

          // Balance Card
          summaryAsync.when(
            data: (summary) => _BalanceCard(
              summary: summary,
              currencyFormat: currencyFormat,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            loading: () => _ShimmerCard(height: 180),
            error: (e, _) => _BalanceCard(
              summary: null,
              currencyFormat: currencyFormat,
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          _QuickActionsRow().animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

          const SizedBox(height: 24),

          // Monthly Chart
          summaryAsync.when(
            data: (summary) => _MonthlyChart(userId: user?.id ?? ''),
            loading: () => _ShimmerCard(height: 200),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          summaryAsync.when(
            data: (summary) {
              if (summary.expensesByCategory.isEmpty) return const SizedBox();
              return _CategoryBreakdown(
                summary: summary,
                currencyFormat: currencyFormat,
              ).animate().fadeIn(delay: 350.ms);
            },
            loading: () => _ShimmerCard(height: 150),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 24),

          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recentes', style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => context.go('/transactions'),
                child: const Text('Ver todos'),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 12),

          recentAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Iconsax.receipt_2_1, size: 48, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round())),
                        const SizedBox(height: 8),
                        Text('Nenhuma transação ainda', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: transactions
                    .asMap()
                    .entries
                    .map((e) => TransactionTile(
                          transaction: e.value,
                          currencyFormat: currencyFormat,
                        ).animate().fadeIn(delay: Duration(milliseconds: 450 + e.key * 50)))
                    .toList(),
              );
            },
            loading: () => Column(
              children: List.generate(3, (i) => _ShimmerCard(height: 68, margin: const EdgeInsets.only(bottom: 8))),
            ),
            error: (e, _) => const SizedBox(),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}

class _BalanceCard extends StatelessWidget {
  final BudgetSummaryModel? summary;
  final NumberFormat currencyFormat;

  const _BalanceCard({this.summary, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryGreenDark, AppTheme.primaryGreen, AppTheme.accentCoral],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withAlpha((0.22 * 255).round()),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo do mês',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary != null ? currencyFormat.format(summary!.balance) : 'R\$ --,--',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  icon: Iconsax.arrow_down,
                  label: 'Receitas',
                  value: summary != null ? currencyFormat.format(summary!.totalIncome) : 'R\$ --',
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _BalanceItem(
                  icon: Iconsax.arrow_up,
                  label: 'Despesas',
                  value: summary != null ? currencyFormat.format(summary!.totalExpenses) : 'R\$ --',
                ),
              ),
            ],
          ),
          if (summary != null && summary!.totalIncome > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (summary!.totalExpenses / summary!.totalIncome).clamp(0.0, 1.0),
                backgroundColor: Colors.white30,
                valueColor: AlwaysStoppedAnimation<Color>(
                  summary!.totalExpenses > summary!.totalIncome ? Colors.red[300]! : Colors.white,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${summary!.savingsRate.toStringAsFixed(1)}% de economia',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BalanceItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.1,
      children: [
        _QuickAction(
          icon: Iconsax.add_circle,
          label: 'Adicionar',
          color: AppTheme.primaryGreen,
          onTap: () => context.go('/transactions/add'),
        ),
        _QuickAction(
          icon: Iconsax.chart_2,
          label: 'Investir',
          color: AppTheme.secondaryBlue,
          onTap: () => context.go('/investments'),
        ),
        _QuickAction(
          icon: Iconsax.calculator,
          label: 'Calcular',
          color: AppTheme.accentPurple,
          onTap: () => _showCalculator(context),
        ),
        _QuickAction(
          icon: Iconsax.profile_circle,
          label: 'Perfil',
          color: AppTheme.accentCoral,
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }

  void _showCalculator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _FinancialCalculatorSheet(),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha((0.2 * 255).round())),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withAlpha((0.13 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyChart extends ConsumerWidget {
  final String userId;
  const _MonthlyChart({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data for chart
    final incomes = [3200.0, 3500.0, 2800.0, 4200.0, 3800.0, 4500.0];
    final expenses = [2100.0, 2800.0, 1900.0, 3100.0, 2600.0, 3200.0];
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Evolução Mensal', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  _ChartLegend(color: AppTheme.primaryGreen, label: 'Receita'),
                  const SizedBox(width: 12),
                  _ChartLegend(color: AppTheme.accentCoral, label: 'Despesa'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: 5000,
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: incomes[i],
                        color: AppTheme.primaryGreen,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expenses[i],
                        color: AppTheme.accentCoral.withAlpha((0.85 * 255).round()),
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        months[v.toInt()],
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 0.5,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final BudgetSummaryModel summary;
  final NumberFormat currencyFormat;

  const _CategoryBreakdown({required this.summary, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final sorted = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(4).toList();

    final colors = [AppTheme.dangerRed, AppTheme.secondaryBlue, AppTheme.accentPurple, AppTheme.accentCoral];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Por categoria', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...top.asMap().entries.map((e) {
            final pct = summary.totalExpenses > 0 ? e.value.value / summary.totalExpenses : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.value.key, style: Theme.of(context).textTheme.titleSmall),
                      Text(currencyFormat.format(e.value.value), style: Theme.of(context).textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: colors[e.key].withAlpha((0.15 * 255).round()),
                      valueColor: AlwaysStoppedAnimation<Color>(colors[e.key]),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsets margin;
  const _ShimmerCard({required this.height, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// Financial Calculator Bottom Sheet
class _FinancialCalculatorSheet extends StatefulWidget {
  const _FinancialCalculatorSheet();

  @override
  State<_FinancialCalculatorSheet> createState() => _FinancialCalculatorSheetState();
}

class _FinancialCalculatorSheetState extends State<_FinancialCalculatorSheet> {
  final _principalCtrl = TextEditingController(text: '10000');
  final _rateCtrl = TextEditingController(text: '12');
  final _periodCtrl = TextEditingController(text: '12');
  double? _result;

  void _calculate() {
    final p = double.tryParse(_principalCtrl.text) ?? 0;
    final r = (double.tryParse(_rateCtrl.text) ?? 0) / 100;
    final n = int.tryParse(_periodCtrl.text) ?? 0;
    double result = p;
    for (int i = 0; i < n; i++) {
      result *= (1 + r / 12);
    }
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calculadora de Juros Compostos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          TextField(controller: _principalCtrl, decoration: const InputDecoration(labelText: 'Capital inicial (R\$)'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: _rateCtrl, decoration: const InputDecoration(labelText: 'Taxa anual (%)'), keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          TextField(controller: _periodCtrl, decoration: const InputDecoration(labelText: 'Período (meses)'), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _calculate, child: const Text('Calcular')),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withAlpha((0.3 * 255).round())),
              ),
              child: Column(
                children: [
                  Text('Montante final', style: Theme.of(context).textTheme.bodyMedium),
                  Text(format.format(_result), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryGreen)),
                  Text(
                    'Lucro: ${format.format(_result! - (double.tryParse(_principalCtrl.text) ?? 0))}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
