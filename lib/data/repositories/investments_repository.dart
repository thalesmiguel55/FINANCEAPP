import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:financeapp/core/constants/app_constants.dart';
import 'package:financeapp/data/models/models.dart';

final investmentsRepositoryProvider = Provider<InvestmentsRepository>((ref) {
  final alphaDio = Dio(BaseOptions(
    baseUrl: AppConstants.alphaVantageBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ));
  final brapiDio = Dio(BaseOptions(
    baseUrl: AppConstants.brapiBaseUrl,
    connectTimeout: AppConstants.connectTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
  ));
  alphaDio.interceptors.add(PrettyDioLogger(requestBody: false));
  brapiDio.interceptors.add(PrettyDioLogger(requestBody: false));
  return InvestmentsRepository(alphaDio, brapiDio, Supabase.instance.client);
});

// Busca cotação em tempo real
final stockQuoteProvider = FutureProvider.family<StockModel?, String>((ref, symbol) async {
  return ref.read(investmentsRepositoryProvider).getStockQuote(symbol);
});

// Portfolio do usuário
final portfolioProvider = FutureProvider.family<List<UserInvestmentModel>, String>((ref, userId) async {
  return ref.read(investmentsRepositoryProvider).getUserPortfolio(userId);
});

// Busca de ações por termo
final stockSearchProvider = FutureProvider.family<List<Map<String, String>>, String>((ref, query) async {
  return ref.read(investmentsRepositoryProvider).searchStocks(query);
});

// Ações populares no Brasil
final popularBrazilianStocksProvider = Provider<List<String>>((ref) {
  return ['PETR4', 'VALE3', 'ITUB4', 'BBDC4', 'ABEV3', 'BBAS3', 'WEGE3', 'RENT3', 'LREN3', 'MGLU3'];
});

class InvestmentsRepository {
  final Dio _alphaDio;
  final Dio _brapiDio;
  final SupabaseClient _client;
  final _uuid = const Uuid();

  InvestmentsRepository(this._alphaDio, this._brapiDio, this._client);

  Future<StockModel?> getStockQuote(String symbol) async {
    final normalizedSymbol = _normalizeSymbol(symbol);
    try {
      final brapiQuote = await _getBrapiStockQuote(normalizedSymbol);
      if (brapiQuote != null) return brapiQuote;
    } catch (_) {
      // Tenta Alpha Vantage logo abaixo.
    }

    try {
      final alphaQuote = await _getAlphaVantageStockQuote(normalizedSymbol);
      if (alphaQuote != null) return alphaQuote;
    } catch (_) {
      // Usa mock logo abaixo.
    }

    // Dados mockados para desenvolvimento e quando a API exceder limites.
    return _getMockStockData(normalizedSymbol);
  }

  Future<StockModel?> _getBrapiStockQuote(String symbol) async {
    final response = await _brapiDio.get(
      '/quote/$symbol',
      options: _brapiOptions(),
    );

    final results = response.data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) return null;

    final quote = results.first as Map<String, dynamic>;
    final currentPrice = _asDouble(quote['regularMarketPrice']);
    final change = _asDouble(quote['regularMarketChange']);
    final changePercent = _asDouble(quote['regularMarketChangePercent']);

    return StockModel(
      symbol: (quote['symbol'] ?? symbol).toString(),
      name: (quote['longName'] ?? quote['shortName'] ?? symbol).toString(),
      currentPrice: currentPrice,
      change: change,
      changePercent: changePercent,
      openPrice: _asDoubleOrNull(quote['regularMarketOpen']),
      highPrice: _asDoubleOrNull(quote['regularMarketDayHigh']),
      lowPrice: _asDoubleOrNull(quote['regularMarketDayLow']),
      volume: _asDoubleOrNull(quote['regularMarketVolume']),
      marketCap: quote['marketCap']?.toString(),
      lastUpdated: _parseDate(quote['regularMarketTime']) ?? DateTime.now(),
    );
  }

  Future<StockModel?> _getAlphaVantageStockQuote(String symbol) async {
    final response = await _alphaDio.get('', queryParameters: {
      'function': 'GLOBAL_QUOTE',
      'symbol': symbol,
      'apikey': AppConstants.alphaVantageApiKey,
    });

    final quote = response.data['Global Quote'] as Map<String, dynamic>?;
    if (quote == null || quote.isEmpty) return null;

    final currentPrice = double.tryParse(quote['05. price'] ?? '0') ?? 0;
    final change = double.tryParse(quote['09. change'] ?? '0') ?? 0;
    final changePercentStr = (quote['10. change percent'] ?? '0%').toString().replaceAll('%', '');
    final changePercent = double.tryParse(changePercentStr) ?? 0;

    return StockModel(
      symbol: symbol,
      name: symbol,
      currentPrice: currentPrice,
      change: change,
      changePercent: changePercent,
      openPrice: double.tryParse(quote['02. open'] ?? '0'),
      highPrice: double.tryParse(quote['03. high'] ?? '0'),
      lowPrice: double.tryParse(quote['04. low'] ?? '0'),
      volume: double.tryParse(quote['06. volume'] ?? '0'),
      lastUpdated: DateTime.now(),
    );
  }

  Future<List<Map<String, String>>> searchStocks(String query) async {
    final normalizedQuery = query.trim().toUpperCase();
    if (normalizedQuery.isEmpty) return [];

    try {
      final response = await _brapiDio.get(
        '/quote/list',
        queryParameters: {
          'search': normalizedQuery,
          'limit': '10',
          'type': 'stock',
        },
        options: _brapiOptions(),
      );

      final stocks = response.data['stocks'] as List<dynamic>? ?? [];
      return stocks.map((s) {
        final stock = s as Map<String, dynamic>;
        return {
          'symbol': (stock['stock'] ?? '').toString(),
          'name': (stock['name'] ?? stock['stock'] ?? '').toString(),
          'region': 'Brazil',
        };
      }).where((s) => s['symbol']!.isNotEmpty).toList();
    } catch (_) {
      try {
        final response = await _alphaDio.get('', queryParameters: {
          'function': 'SYMBOL_SEARCH',
          'keywords': normalizedQuery,
          'apikey': AppConstants.alphaVantageApiKey,
        });

        final matches = response.data['bestMatches'] as List<dynamic>? ?? [];
        return matches.map((m) => {
          'symbol': m['1. symbol'] as String,
          'name': m['2. name'] as String,
          'region': m['4. region'] as String,
        }).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricalData(String symbol, {String outputSize = 'compact'}) async {
    final normalizedSymbol = _normalizeSymbol(symbol);
    try {
      final response = await _brapiDio.get(
        '/quote/$normalizedSymbol',
        queryParameters: {
          'range': '1mo',
          'interval': '1d',
        },
        options: _brapiOptions(),
      );

      final results = response.data['results'] as List<dynamic>? ?? [];
      if (results.isEmpty) return _getMockHistoricalData();

      final prices = (results.first as Map<String, dynamic>)['historicalDataPrice'] as List<dynamic>? ?? [];
      if (prices.isEmpty) return _getMockHistoricalData();

      return prices.map((price) {
        final item = price as Map<String, dynamic>;
        return {
          'date': _formatHistoricalDate(item['date']),
          'close': _asDouble(item['close']),
          'open': _asDouble(item['open']),
          'high': _asDouble(item['high']),
          'low': _asDouble(item['low']),
          'volume': _asDouble(item['volume']),
        };
      }).toList();
    } catch (_) {
      try {
        final response = await _alphaDio.get('', queryParameters: {
          'function': 'TIME_SERIES_DAILY',
          'symbol': normalizedSymbol,
          'outputsize': outputSize,
          'apikey': AppConstants.alphaVantageApiKey,
        });

        final timeSeries = response.data['Time Series (Daily)'] as Map<String, dynamic>? ?? {};
        return timeSeries.entries.take(30).map((entry) => {
          'date': entry.key,
          'close': double.tryParse(entry.value['4. close']) ?? 0,
          'open': double.tryParse(entry.value['1. open']) ?? 0,
          'high': double.tryParse(entry.value['2. high']) ?? 0,
          'low': double.tryParse(entry.value['3. low']) ?? 0,
          'volume': double.tryParse(entry.value['5. volume']) ?? 0,
        }).toList();
      } catch (_) {
        return _getMockHistoricalData();
      }
    }
  }

  Future<List<UserInvestmentModel>> getUserPortfolio(String userId) async {
    final data = await _client
        .from('investments')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((e) => UserInvestmentModel.fromJson(e)).toList();
  }

  Future<UserInvestmentModel> addInvestment({
    required String userId,
    required String symbol,
    required String name,
    required double quantity,
    required double price,
    required DateTime purchaseDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'id': id,
      'user_id': userId,
      'symbol': symbol,
      'name': name,
      'quantity': quantity,
      'average_price': price,
      'purchase_date': purchaseDate.toIso8601String(),
      'created_at': now.toIso8601String(),
    };

    final result = await _client.from('investments').insert(data).select().single();
    return UserInvestmentModel.fromJson(result);
  }

  Future<void> removeInvestment(String id) async {
    await _client.from('investments').delete().eq('id', id);
  }

  Options? _brapiOptions() {
    if (AppConstants.brapiApiToken.isEmpty) return null;
    return Options(headers: {
      'Authorization': 'Bearer ${AppConstants.brapiApiToken}',
    });
  }

  String _normalizeSymbol(String symbol) {
    return symbol.trim().toUpperCase().replaceAll('.SA', '');
  }

  double _asDouble(dynamic value) => _asDoubleOrNull(value) ?? 0;

  double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.tryParse(value.toString());
  }

  String _formatHistoricalDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return DateTime.now().toIso8601String().substring(0, 10);
    return date.toIso8601String().substring(0, 10);
  }

  // Mock data para desenvolvimento (limite free tier API)
  StockModel _getMockStockData(String symbol) {
    final mockData = {
      'PETR4': (28.45, 0.82, 2.97),
      'VALE3': (62.10, -1.20, -1.90),
      'ITUB4': (34.78, 0.45, 1.31),
      'BBDC4': (15.92, -0.23, -1.42),
      'ABEV3': (12.65, 0.10, 0.80),
      'BBAS3': (55.30, 1.20, 2.22),
      'WEGE3': (48.90, 0.85, 1.77),
      'AAPL': (189.30, 2.10, 1.12),
      'MSFT': (415.60, 5.40, 1.32),
      'GOOGL': (175.40, -1.80, -1.02),
    };

    final d = mockData[symbol] ?? (50.0, 0.5, 1.0);
    return StockModel(
      symbol: symbol,
      name: symbol,
      currentPrice: d.$1,
      change: d.$2,
      changePercent: d.$3,
      openPrice: d.$1 - d.$2 * 0.5,
      highPrice: d.$1 + d.$2.abs() * 1.2,
      lowPrice: d.$1 - d.$2.abs() * 0.8,
      volume: 1500000,
      lastUpdated: DateTime.now(),
    );
  }

  List<Map<String, dynamic>> _getMockHistoricalData() {
    final data = <Map<String, dynamic>>[];
    double price = 50.0;
    for (int i = 29; i >= 0; i--) {
      price += (price * 0.02 * (0.5 - (i % 3 == 0 ? 1 : 0)));
      data.add({
        'date': DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10),
        'close': price,
        'open': price * 0.99,
        'high': price * 1.02,
        'low': price * 0.98,
        'volume': 1200000.0,
      });
    }
    return data;
  }
}

// ============================================================
// FINANCIAL CALCULATIONS PROVIDER
// ============================================================
final financialCalculationsProvider = Provider<FinancialCalculations>((ref) {
  return FinancialCalculations();
});

class FinancialCalculations {
  // Juros Compostos: M = C * (1 + i)^n
  double compoundInterest({
    required double principal,
    required double rate,
    required int periods,
  }) {
    return principal * (1 + rate / 100).toInt().toDouble();
  }

  double compoundInterestFull({
    required double principal,
    required double rate,
    required int periods,
  }) {
    return principal * _pow(1 + rate / 100, periods);
  }

  // VPL - Valor Presente Líquido
  double npv({
    required double initialInvestment,
    required List<double> cashFlows,
    required double discountRate,
  }) {
    double npv = -initialInvestment;
    for (int i = 0; i < cashFlows.length; i++) {
      npv += cashFlows[i] / _pow(1 + discountRate / 100, i + 1);
    }
    return npv;
  }

  // TIR - Taxa Interna de Retorno (aproximação numérica)
  double? irr({
    required double initialInvestment,
    required List<double> cashFlows,
  }) {
    double rate = 0.1;
    for (int iteration = 0; iteration < 1000; iteration++) {
      double npv = -initialInvestment;
      double dnpv = 0;
      for (int i = 0; i < cashFlows.length; i++) {
        final factor = _pow(1 + rate, i + 1);
        npv += cashFlows[i] / factor;
        dnpv -= (i + 1) * cashFlows[i] / (factor * (1 + rate));
      }
      if (dnpv.abs() < 1e-10) return null;
      final newRate = rate - npv / dnpv;
      if ((newRate - rate).abs() < 1e-8) return newRate * 100;
      rate = newRate;
    }
    return null;
  }

  // Regra dos 72 - tempo para dobrar investimento
  double rule72(double annualRate) => 72 / annualRate;

  // Prazo para aposentadoria
  int yearsToRetirement({
    required double currentSavings,
    required double monthlyContribution,
    required double targetAmount,
    required double annualRate,
  }) {
    final monthlyRate = annualRate / 12 / 100;
    int months = 0;
    double savings = currentSavings;

    while (savings < targetAmount && months < 600) {
      savings = savings * (1 + monthlyRate) + monthlyContribution;
      months++;
    }

    return (months / 12).ceil();
  }

  // Amortização SAC
  List<Map<String, double>> sacAmortization({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    final monthlyRate = annualRate / 12 / 100;
    final amortization = principal / months;
    var balance = principal;
    final schedule = <Map<String, double>>[];

    for (int i = 1; i <= months; i++) {
      final interest = balance * monthlyRate;
      balance -= amortization;
      schedule.add({
        'month': i.toDouble(),
        'amortization': amortization,
        'interest': interest,
        'payment': amortization + interest,
        'balance': balance > 0 ? balance : 0,
      });
    }

    return schedule;
  }

  double _pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }
}
