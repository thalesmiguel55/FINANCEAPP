import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:financeapp/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Iconsax.wallet,
      color: AppTheme.primaryGreen,
      title: 'Controle suas\nfinanças',
      subtitle: 'Acompanhe receitas, despesas e economias em um só lugar. Simples e eficiente.',
    ),
    OnboardingData(
      icon: Iconsax.chart_21,
      color: AppTheme.secondaryBlue,
      title: 'Invista com\ninteligência',
      subtitle: 'Acompanhe ações, fundos e criptomoedas com dados em tempo real do mercado.',
    ),
    OnboardingData(
      icon: Iconsax.security_safe,
      color: AppTheme.accentPurple,
      title: 'Seguro e\nConfiável',
      subtitle: 'Seus dados protegidos com criptografia de ponta. Acesso biométrico disponível.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Pular'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: page.color.withAlpha((0.15 * 255).round()),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: Icon(page.icon, size: 64, color: page.color),
                        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: 300.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: i == _currentPage
                              ? AppTheme.primaryGreen
                              : AppTheme.primaryGreen.withAlpha((0.3 * 255).round()),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: 400.ms,
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go('/auth/login');
                      }
                    },
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Próximo' : 'Começar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/auth/register'),
                    child: const Text('Criar conta grátis'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const OnboardingData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
