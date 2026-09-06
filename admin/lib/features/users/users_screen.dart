import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../domain/models/governance_models.dart';

/// Section 12: "Manage roles and permissions". admin-only (nav item hidden for content_reviewer,
/// and `admin_set_user_role` itself refuses a non-admin caller server-side — see 0013).
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(_usersProvider(_searchController.text));

    return Scaffold(
      appBar: AppBar(title: const Text('Users & roles')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search nickname',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load users: $e'),
                data: (users) => ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, i) => _UserRow(profile: users[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _usersProvider = FutureProvider.family(
  (ref, String search) =>
      ref.read(usersRepositoryProvider).fetchAll(searchNickname: search),
);

class _UserRow extends ConsumerWidget {
  final AdminProfile profile;
  const _UserRow({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_rounded)),
        title: Text(profile.nickname),
        subtitle: Text(
          profile.id,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: DropdownButton<String>(
          value: profile.role,
          items: [
            for (final r in AdminProfile.assignableRoles)
              DropdownMenuItem(value: r, child: Text(r)),
          ],
          onChanged: (newRole) async {
            if (newRole == null || newRole == profile.role) return;
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Change role?'),
                content: Text(
                  'Change ${profile.nickname}\'s role from ${profile.role} to $newRole?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await ref
                .read(usersRepositoryProvider)
                .setRole(profile.id, newRole);
            ref.invalidate(_usersProvider(''));
          },
        ),
      ),
    );
  }
}
