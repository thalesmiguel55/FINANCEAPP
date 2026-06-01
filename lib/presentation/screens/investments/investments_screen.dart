import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/models/models.dart';
import 'package:financeapp/data/repositories/auth_repository.dart';
import 'package:financeapp/data/repositories/investments_repository.dart';

class InvestmentsScreen extends ConsumerStatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  ConsumerState<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends ConsumerState<InvestmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final popularStocks = ref.watch(popularBrazilianStocksProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investimentos'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(text: 'Mercado'),
            Tab(text: 'Minha Carteira'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Market Tab
          _MarketTab(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            popularStocks: popularStocks,
          ),

          // Portfolio Tab
          userAsync.when(
            data: (user) => user != null
                ? _PortfolioTab(userId: user.id, currencyFormat: currencyFormat)
                : const Center(child: Text('Faça login para ver sua carteira')),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          ),
        ],
      ),
    );
  }
}

class _MarketTab extends ConsumerWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final List<String> popularStocks;

  const _MarketTab({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.popularStocks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar ação (ex: PETR4, AAPL)...',
                prefixIcon: const Icon(Iconsax.search_normal),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Market summary strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MarketSummaryStrip(),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              searchQuery.isEmpty ? 'Ações Populares' : 'Resultados da busca',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final symbol = searchQuery.isEmpty
                  ? popularStocks[index]
                  : '${searchQuery.toUpperCase().trim()}';

              if (searchQuery.isNotEmpty && index > 0) return null;

              final stockAsync = ref.watch(stockQuoteProvider(symbol));

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: stockAsync.when(
                  data: (stock) => stock != null
                      ? _StockCard(stock: stock, currencyFormat: currencyFormat)
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 60))
                      : const SizedBox(),
                  loading: () => _StockCardSkeleton(),
                  error: (e, _) => const SizedBox(),
                ),
              );
            },
            childCount: searchQuery.isEmpty ? popularStocks.length : 1,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _MarketSummaryStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indices = [
      {'name': 'IBOVESPA', 'value': '128.450', 'change': '+1.24%', 'positive': true},
      {'name': 'S&P 500', 'value': '5.204', 'change': '+0.87%', 'positive': true},
      {'name': 'USD/BRL', 'value': '4.98', 'change': '-0.32%', 'positive': false},
    ];

    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: indices.length,
        itemBuilder: (context, i) {
          final idx = indices[i];
          final positive = idx['positive'] as bool;
          return Container(
            width: 140,
            margin: EdgeInsets.only(right: 8, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(idx['name'] as String, style: const TextStyle(fontSize: 11, fontFamily: 'Poppins', color: Colors.grey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(idx['value'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                    Text(
                      idx['change'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: positive ? AppTheme.primaryGreen : AppTheme.dangerRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockModel stock;
  final NumberFormat currencyFormat;

  const _StockCard({required this.stock, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/investments/${stock.symbol}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stock.isPositive
                  ? AppTheme.primaryGreen.withAlpha((0.15 * 255).round())
                  : AppTheme.dangerRed.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  stock.symbol.substring(0, stock.symbol.length.clamp(0, 2)),
                  style: TextStyle(
                    color: stock.isPositive ? AppTheme.primaryGreen : AppTheme.dangerRed,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.symbol, style: Theme.of(context).textTheme.titleMedium),
                  Text(stock.name, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(stock.currentPrice),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: stock.isPositive
                      ? AppTheme.primaryGreen.withAlpha((0.15 * 255).round())
                      : AppTheme.dangerRed.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${stock.isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: stock.isPositive ? AppTheme.primaryGreen : AppTheme.dangerRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StockCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _PortfolioTab extends ConsumerWidget {
  final String userId;
  final NumberFormat currencyFormat;

  const _PortfolioTab({required this.userId, required this.currencyFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider(userId));

    return portfolioAsync.when(
      data: (investments) {
        if (investments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.chart_fail, size: 64, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.3 * 255).round())),
                const SizedBox(height: 16),
                Text('Carteira vazia', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Vá ao Mercado e adicione seus investimentos', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: investments.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _PortfolioSummary(investments: investments, currencyFormat: currencyFormat);

            final inv = investments[index - 1];
            final stockAsync = ref.watch(stockQuoteProvider(inv.symbol));

            return stockAsync.when(
              data: (stock) {
                final currentPrice = stock?.currentPrice ?? inv.averagePrice;
                final pl = inv.profitLoss(currentPrice);
                final plPct = inv.profitLossPercent(currentPrice);
                final isPos = pl >= 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inv.symbol, style: Theme.of(context).textTheme.titleMedium),
                                Text('${inv.quantity.toStringAsFixed(0)} ações', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(inv.currentValue(currentPrice)),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${isPos ? '+' : ''}${currencyFormat.format(pl)} (${plPct.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  color: isPos ? AppTheme.primaryGreen : AppTheme.dangerRed,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
              },
              loading: () => const SizedBox(height: 80),
              error: (_, __) => const SizedBox(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  final List<UserInvestmentModel> investments;
  final NumberFormat currencyFormat;

  const _PortfolioSummary({required this.investments, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final totalInvested = investments.fold<double>(0, (sum, inv) => sum + inv.totalInvested);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C2537), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total investido', style: TextStyle(color: Colors.white60, fontFamily: 'Poppins', fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(totalInvested),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 12),
          Text('${investments.length} ativo(s) na carteira', style: const TextStyle(color: Colors.white60, fontFamily: 'Poppins', fontSize: 13)),
        ],
      ),
    );
  }
}
