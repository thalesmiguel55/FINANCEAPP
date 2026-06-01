import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:financeapp/core/theme/app_theme.dart';
import 'package:financeapp/data/repositories/auth_repository.dart';
import 'package:financeapp/presentation/widgets/app_text_field.dart';
import 'package:financeapp/presentation/widgets/loading_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada! Verifique seu email para confirmar.'),
          ),
        );
        context.go('/auth/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar conta: $e'),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () => context.go('/auth/login'),
                ),

                const SizedBox(height: 16),

                Text(
                  'Criar sua\nconta 🚀',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text(
                  'Comece a controlar suas finanças hoje',
                  style: Theme.of(context).textTheme.bodyLarge,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 36),

                AppTextField(
                  controller: _nameController,
                  label: 'Nome completo',
                  hint: 'João Silva',
                  prefixIcon: Iconsax.user,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Digite seu nome';
                    if (v.trim().length < 3) return 'Nome muito curto';
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'seu@email.com',
                  prefixIcon: Iconsax.sms,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Digite seu email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _passwordController,
                  label: 'Senha',
                  hint: '••••••••',
                  prefixIcon: Iconsax.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Digite uma senha';
                    if (v.length < 8) return 'Mínimo 8 caracteres';
                    if (!RegExp(r'(?=.*[A-Z])').hasMatch(v)) return 'Inclua uma letra maiúscula';
                    if (!RegExp(r'(?=.*[0-9])').hasMatch(v)) return 'Inclua um número';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar senha',
                  hint: '••••••••',
                  prefixIcon: Iconsax.lock_1,
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v != _passwordController.text) return 'Senhas não coincidem';
                    return null;
                  },
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                const SizedBox(height: 32),

                LoadingButton(
                  onPressed: _register,
                  isLoading: _isLoading,
                  child: const Text('Criar conta'),
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem conta? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('Entrar'),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
