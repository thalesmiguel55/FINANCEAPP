import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/models/models.dart';

// ─────────────────────────────────────────
// AppTextField
// ─────────────────────────────────────────
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// LoadingButton
// ─────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final Widget child;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }
}

// ─────────────────────────────────────────
// TransactionTile
// ─────────────────────────────────────────
class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final NumberFormat currencyFormat;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currencyFormat,
    this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      'Alimentação' => Iconsax.coffee,
      'Transporte' => Iconsax.car,
      'Moradia' => Iconsax.home,
      'Saúde' => Iconsax.health,
      'Educação' => Iconsax.book,
      'Lazer' => Iconsax.game,
      'Roupas' => Iconsax.bag,
      'Tecnologia' => Iconsax.cpu,
      'Investimentos' => Iconsax.chart_2,
      'Salário' => Iconsax.dollar_circle,
      'Freelance' => Iconsax.briefcase,
      _ => Iconsax.receipt,
    };
  }

  Color _getCategoryColor(String category) {
    return switch (category) {
      'Alimentação' => const Color(0xFFEF4444),
      'Transporte' => const Color(0xFF3B82F6),
      'Moradia' => const Color(0xFF8B5CF6),
      'Saúde' => const Color(0xFF10B981),
      'Educação' => const Color(0xFFF59E0B),
      'Lazer' => const Color(0xFF06B6D4),
      'Roupas' => const Color(0xFFEC4899),
      'Tecnologia' => const Color(0xFF6366F1),
      'Investimentos' || 'Salário' || 'Freelance' => AppTheme.primaryGreen,
      _ => const Color(0xFF94A3B8),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = _getCategoryColor(transaction.category);

    return Dismissible(
      key: Key(transaction.id),
      direction: onDelete != null ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppTheme.dangerRed,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Iconsax.trash, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                color: color.withAlpha((0.15 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getCategoryIcon(transaction.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(transaction.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(transaction.category, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${currencyFormat.format(transaction.amount)}',
                  style: TextStyle(
                    color: isIncome ? AppTheme.primaryGreen : AppTheme.dangerRed,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                  ),
                ),
                if (transaction.isRecurring)
                  const Icon(Iconsax.repeat, size: 12, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
