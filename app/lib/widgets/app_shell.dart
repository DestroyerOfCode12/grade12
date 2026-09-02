import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation for Home / Learn / Papers / Play / Profile — section 11's explicit
/// requirement. Large tap targets (56dp height) and text labels always visible, not just on
/// selection, per section 15 accessibility guidance (plain-language, clear affordances).
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_rounded),
            label: 'Papers',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'Play',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
