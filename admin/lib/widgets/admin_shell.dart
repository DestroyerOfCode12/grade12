import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_providers.dart';
import '../core/theme/app_theme.dart';

class NavItem {
  final String label;
  final IconData icon;
  final String path;
  final bool adminOnly;
  const NavItem(this.label, this.icon, this.path, {this.adminOnly = false});
}

const navItems = [
  NavItem('Dashboard', Icons.dashboard_rounded, '/dashboard'),
  NavItem('Subjects', Icons.menu_book_rounded, '/subjects'),
  NavItem('Review queue', Icons.fact_check_rounded, '/review'),
  NavItem('Content reports', Icons.flag_rounded, '/reports'),
  NavItem('Past papers', Icons.description_rounded, '/papers'),
  NavItem('Users & roles', Icons.people_alt_rounded, '/users', adminOnly: true),
  NavItem('Audit log', Icons.history_rounded, '/audit', adminOnly: true),
];

/// Persistent side-nav layout wrapping every routed screen (via GoRouter's `ShellRoute`, which
/// passes the matched sub-route in as [child]) once [AuthGate] confirms staff access. Hides
/// admin-only nav items from a `content_reviewer` — a UX nicety; the underlying screens/RLS are
/// what actually enforce the boundary if someone navigates there by URL directly.
class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentStaffProfileProvider);
    final role = profileAsync.valueOrNull?['role'] as String?;
    final isAdmin = role == 'admin' || role == 'super_admin';
    final visibleItems = navItems
        .where((n) => !n.adminOnly || isAdmin)
        .toList();

    final currentPath = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 240,
            color: AppColors.sidebar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.school_rounded, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'MatricQuest SA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Staff dashboard',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 24),
                for (final item in visibleItems)
                  _NavTile(
                    item: item,
                    selected: currentPath.startsWith(item.path),
                    onTap: () => context.go(item.path),
                  ),
                const Spacer(),
                if (role != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          tooltip: 'Sign out',
                          onPressed: () =>
                              ref.read(supabaseClientProvider)?.auth.signOut(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
