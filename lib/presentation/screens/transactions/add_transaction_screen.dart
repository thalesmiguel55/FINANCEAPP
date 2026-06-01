import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:financeapp/core/constants/app_constants.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/models/models.dart';
import 'package:financeapp/data/repositories/auth_repository.dart';
import 'package:financeapp/data/repositories/transactions_repository.dart';
import 'package:financeapp/presentation/widgets/loading_button.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _category = AppConstants.transactionCategories.first;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categoryIcons = [
    {'name': 'Alimentação', 'icon': Iconsax.coffee, 'color': Color(0xFFEF4444)},
    {'name': 'Transporte', 'icon': Iconsax.car, 'color': Color(0xFF3B82F6)},
    {'name': 'Moradia', 'icon': Iconsax.home, 'color': Color(0xFF8B5CF6)},
    {'name': 'Saúde', 'icon': Iconsax.health, 'color': Color(0xFF10B981)},
    {'name': 'Educação', 'icon': Iconsax.book, 'color': Color(0xFFF59E0B)},
    {'name': 'Lazer', 'icon': Iconsax.game, 'color': Color(0xFF06B6D4)},
    {'name': 'Roupas', 'icon': Iconsax.bag, 'color': Color(0xFFEC4899)},
    {'name': 'Tecnologia', 'icon': Iconsax.cpu, 'color': Color(0xFF6366F1)},
    {'name': 'Investimentos', 'icon': Iconsax.chart_2, 'color': Color(0xFF00D09C)},
    {'name': 'Salário', 'icon': Iconsax.dollar_circle, 'color': Color(0xFF00D09C)},
    {'name': 'Freelance', 'icon': Iconsax.briefcase, 'color': Color(0xFF3B82F6)},
    {'name': 'Outros', 'icon': Iconsax.more_circle, 'color': Color(0xFF94A3B8)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(transactionsRepositoryProvider).addTransaction(
            userId: user.id,
            title: _titleController.text.trim(),
            amount: double.parse(_amountController.text.replaceAll(',', '.')),
            type: _type,
            category: _category,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            date: _date,
            isRecurring: _isRecurring,
          );

      ref.invalidate(transactionsProvider(user.id));
      ref.invalidate(monthlySummaryProvider(user.id));
      ref.invalidate(recentTransactionsProvider(user.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação adicionada com sucesso!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Transação'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: TransactionType.values.map((type) {
                    final isSelected = _type == type;
                    final isIncome = type == TransactionType.income;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = type),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isIncome ? AppTheme.primaryGreen : AppTheme.dangerRed)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isIncome ? Iconsax.arrow_down : Iconsax.arrow_up,
                                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isIncome ? 'Receita' : 'Despesa',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withAlpha((0.5 * 255).round()),
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // Amount
              Text('Valor', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: _type == TransactionType.income ? AppTheme.primaryGreen : AppTheme.dangerRed,
                      fontWeight: FontWeight.w700,
                    ),
                decoration: InputDecoration(
                  prefixText: 'R\$ ',
                  prefixStyle: TextStyle(
                    color: _type == TransactionType.income ? AppTheme.primaryGreen : AppTheme.dangerRed,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                  hintText: '0,00',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Digite o valor';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                  if (double.parse(v.replaceAll(',', '.')) <= 0) return 'Valor deve ser maior que zero';
                  return null;
                },
              ).animate().fadeIn(delay: 100.ms),

              Divider(color: Theme.of(context).dividerColor),

              const SizedBox(height: 20),

              // Title
              Text('Descrição', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Ex: Almoço no restaurante...'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Digite uma descrição';
                  return null;
                },
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // Category
              Text('Categoria', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categoryIcons.length,
                  itemBuilder: (context, i) {
                    final cat = _categoryIcons[i];
                    final isSelected = _category == cat['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat['name'] as String),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: isSelected
                              ? (cat['color'] as Color).withAlpha((0.15 * 255).round())
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? cat['color'] as Color : Theme.of(context).dividerColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              (cat['name'] as String).length > 8
                                  ? '${(cat['name'] as String).substring(0, 8)}.'
                                  : cat['name'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'Poppins',
                                color: isSelected ? cat['color'] as Color : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 20),

              // Date
              Text('Data', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('pt', 'BR'),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.calendar, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat("dd 'de' MMMM 'de' yyyy", 'pt_BR').format(_date),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 16),

              // Notes (optional)
              Text('Observações (opcional)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Alguma nota adicional...'),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Recurring
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: SwitchListTile(
                  title: const Text('Transação recorrente', style: TextStyle(fontFamily: 'Poppins')),
                  subtitle: Text('Repete todo mês', style: Theme.of(context).textTheme.bodySmall),
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                  activeThumbColor: AppTheme.primaryGreen,
                  contentPadding: EdgeInsets.zero,
                ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 32),

              LoadingButton(
                onPressed: _save,
                isLoading: _isLoading,
                child: const Text('Salvar Transação'),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
