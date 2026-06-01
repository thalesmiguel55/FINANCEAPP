import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/models/models.dart';
import 'package:financeapp/data/repositories/auth_repository.dart';
import 'package:financeapp/presentation/widgets/loading_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: userAsync.when(
        data: (user) => _ProfileContent(user: user, themeMode: themeMode),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserModel? user;
  final ThemeMode themeMode;

  const _ProfileContent({this.user, required this.themeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar & name
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryGreen.withAlpha((0.2 * 255).round()),
                child: Text(
                  user!.name.isNotEmpty ? user!.name[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(user!.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(user!.email, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ).animate().fadeIn(),

          const SizedBox(height: 32),

          // Config section
          _SectionTitle('Configurações'),

          _SettingsTile(
            icon: Iconsax.moon,
            title: 'Tema escuro',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeThumbColor: AppTheme.primaryGreen,
            ),
          ).animate().fadeIn(delay: 100.ms),

          _SettingsTile(
            icon: Iconsax.user_edit,
            title: 'Editar perfil',
            onTap: () => _showEditProfile(context, ref),
          ).animate().fadeIn(delay: 150.ms),

          _SettingsTile(
            icon: Iconsax.wallet,
            title: 'Configurar orçamento',
            onTap: () => _showBudgetConfig(context, ref),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          _SectionTitle('Sobre'),

          _SettingsTile(
            icon: Iconsax.info_circle,
            title: 'Versão do app',
            trailing: Text('1.0.0', style: Theme.of(context).textTheme.bodyMedium),
          ).animate().fadeIn(delay: 250.ms),

          _SettingsTile(
            icon: Iconsax.shield_tick,
            title: 'Política de privacidade',
            onTap: () {},
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          _SettingsTile(
            icon: Iconsax.logout,
            title: 'Sair',
            titleColor: AppTheme.dangerRed,
            iconColor: AppTheme.dangerRed,
            onTap: () => _confirmLogout(context, ref),
          ).animate().fadeIn(delay: 350.ms),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: user?.name);
    final incomeCtrl = TextEditingController(text: user?.monthlyIncome.toStringAsFixed(0));
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Editar Perfil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: incomeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Renda mensal (R\$)'),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                onPressed: () async {
                  if (user == null) return;
                  setLocal(() => loading = true);
                  try {
                    final updated = user!.copyWith(
                      name: nameCtrl.text.trim(),
                      monthlyIncome: double.tryParse(incomeCtrl.text) ?? 0,
                    );
                    await ref.read(authRepositoryProvider).updateProfile(updated);
                    ref.invalidate(currentUserProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } finally {
                    setLocal(() => loading = false);
                  }
                },
                isLoading: loading,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetConfig(BuildContext context, WidgetRef ref) {
    final budgetCtrl = TextEditingController(text: user?.monthlyBudget.toStringAsFixed(0));
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orçamento Mensal', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Define o limite máximo de gastos por mês', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Orçamento (R\$)',
                  prefixText: 'R\$ ',
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                onPressed: () async {
                  if (user == null) return;
                  setLocal(() => loading = true);
                  try {
                    final updated = user!.copyWith(
                      monthlyBudget: double.tryParse(budgetCtrl.text) ?? 0,
                    );
                    await ref.read(authRepositoryProvider).updateProfile(updated);
                    ref.invalidate(currentUserProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } finally {
                    setLocal(() => loading = false);
                  }
                },
                isLoading: loading,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza que deseja sair da conta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/auth/login');
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
