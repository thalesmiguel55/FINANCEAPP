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
import 'package:financeapp/data/repositories/investments_repository.dart';
import 'package:financeapp/presentation/widgets/loading_button.dart';

class StockDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  const StockDetailScreen({super.key, required this.symbol});

  @override
  ConsumerState<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends ConsumerState<StockDetailScreen> {
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isBuying = false;

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockAsync = ref.watch(stockQuoteProvider(widget.symbol));
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.notification),
            onPressed: () {},
          ),
        ],
      ),
      body: stockAsync.when(
        data: (stock) {
          if (stock == null) {
            return const Center(child: Text('Ação não encontrada'));
          }
          return _StockDetailContent(
            stock: stock,
            currencyFormat: currencyFormat,
            onBuy: () => _showBuySheet(context, stock, currencyFormat),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }

  void _showBuySheet(BuildContext context, StockModel stock, NumberFormat fmt) {
    _priceController.text = stock.currentPrice.toStringAsFixed(2);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar à carteira', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(stock.symbol, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            TextField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantidade de ações'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Preço médio (R\$)'),
            ),
            const SizedBox(height: 24),
            StatefulBuilder(
              builder: (ctx, setLocal) => LoadingButton(
                onPressed: () async {
                  final user = await ref.read(currentUserProvider.future);
                  if (user == null) return;
                  final qty = double.tryParse(_qtyController.text) ?? 0;
                  final price = double.tryParse(_priceController.text) ?? 0;
                  if (qty <= 0 || price <= 0) return;

                  setLocal(() => _isBuying = true);
                  try {
                    await ref.read(investmentsRepositoryProvider).addInvestment(
                          userId: user.id,
                          symbol: stock.symbol,
                          name: stock.name,
                          quantity: qty,
                          price: price,
                          purchaseDate: DateTime.now(),
                        );
                    ref.invalidate(portfolioProvider(user.id));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${stock.symbol} adicionado à carteira!')),
                      );
                    }
                  } finally {
                    setLocal(() => _isBuying = false);
                  }
                },
                isLoading: _isBuying,
                child: const Text('Adicionar à Carteira'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockDetailContent extends ConsumerWidget {
  final StockModel stock;
  final NumberFormat currencyFormat;
  final VoidCallback onBuy;

  const _StockDetailContent({
    required this.stock,
    required this.currencyFormat,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // removed unused histAsync

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(stock.currentPrice),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: stock.isPositive
                          ? AppTheme.primaryGreen.withAlpha((0.15 * 255).round())
                          : AppTheme.dangerRed.withAlpha((0.15 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${stock.isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: stock.isPositive ? AppTheme.primaryGreen : AppTheme.dangerRed,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: -0.1),

                const SizedBox(height: 4),
                Text(
                  'Variação: ${currencyFormat.format(stock.change.abs())}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 24),

                // Chart
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: ref.read(investmentsRepositoryProvider).getHistoricalData(stock.symbol),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = snap.data!;
                    final spots = data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), (e.value['close'] as num).toDouble());
                    }).toList();

                    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
                    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

                    return Container(
                      height: 200,
                      padding: const EdgeInsets.only(top: 16, right: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: LineChart(
                        LineChartData(
                          minY: minY * 0.98,
                          maxY: maxY * 1.02,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: stock.isPositive ? AppTheme.primaryGreen : AppTheme.dangerRed,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: (stock.isPositive ? AppTheme.primaryGreen : AppTheme.dangerRed)
                                  .withAlpha((0.1 * 255).round()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms);
                  },
                ),

                const SizedBox(height: 24),

                // Stats grid
                Text('Detalhes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatTile(label: 'Abertura', value: currencyFormat.format(stock.openPrice ?? 0)),
                    _StatTile(label: 'Máxima', value: currencyFormat.format(stock.highPrice ?? 0)),
                    _StatTile(label: 'Mínima', value: currencyFormat.format(stock.lowPrice ?? 0)),
                    _StatTile(label: 'Volume', value: _formatVolume(stock.volume ?? 0)),
                  ],
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),

        // Buy button
        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton.icon(
            onPressed: onBuy,
            icon: const Icon(Iconsax.add_circle),
            label: const Text('Adicionar à Carteira'),
          ),
        ),
      ],
    );
  }

  String _formatVolume(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}B';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}M';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).textTheme.titleLarge?.color,
          )),
        ],
      ),
    );
  }
}
