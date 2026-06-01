import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/investments')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.16 * 255).round()),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                  case 1:
                    context.go('/transactions');
                  case 2:
                    context.go('/investments');
                  case 3:
                    context.go('/profile');
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.home_2),
                  activeIcon: Icon(Iconsax.home),
                  label: 'Início',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.receipt),
                  activeIcon: Icon(Iconsax.receipt_add),
                  label: 'Transações',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.chart),
                  activeIcon: Icon(Iconsax.chart_2),
                  label: 'Investimentos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Iconsax.profile_circle),
                  activeIcon: Icon(Iconsax.profile_circle),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
