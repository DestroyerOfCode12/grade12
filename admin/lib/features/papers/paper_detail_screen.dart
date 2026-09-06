import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/paper_models.dart';
import '../../widgets/status_pill.dart';

/// Section 7: paper metadata + the question paper / memorandum / addendum / formula sheet files
/// themselves, uploaded to Supabase Storage. `association_confidence` stays `unconfirmed` until a
/// reviewer explicitly marks it `confirmed` here — nothing auto-promotes it.
class PaperDetailScreen extends ConsumerWidget {
  final String paperId;
  const PaperDetailScreen({super.key, required this.paperId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paperAsync = ref.watch(_paperProvider(paperId));
    final assetsAsync = ref.watch(_assetsProvider(paperId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/papers'),
        ),
        title: paperAsync.when(
          data: (p) => Text(p.title),
          loading: () => const Text('Loading…'),
          error: (e, _) => const Text('Paper'),
        ),
      ),
      body: paperAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load paper: $e')),
        data: (paper) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusPill(status: paper.contentStatus),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(
                            'Association: ${paper.associationConfidence}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Source: ${paper.sourceUrl}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(papersRepositoryProvider)
                                .updateStatus(
                                  paper.id,
                                  associationConfidence: 'confirmed',
                                );
                            ref.invalidate(_paperProvider(paperId));
                          },
                          child: const Text('Confirm association'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(papersRepositoryProvider)
                                .updateStatus(
                                  paper.id,
                                  contentStatus: 'in_review',
                                );
                            ref.invalidate(_paperProvider(paperId));
                          },
                          child: const Text('Move to in review'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(papersRepositoryProvider)
                                .updateStatus(
                                  paper.id,
                                  contentStatus: 'published',
                                );
                            ref.invalidate(_paperProvider(paperId));
                          },
                          child: const Text('Publish'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Files', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            assetsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Could not load files: $e'),
              data: (assets) => Column(
                children: [
                  for (final a in assets)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file_rounded),
                        title: Text(a.assetKind.replaceAll('_', ' ')),
                        subtitle: Text(a.storagePath),
                        trailing: a.fileSizeBytes == null
                            ? null
                            : Text('${(a.fileSizeBytes! / 1024).round()} KB'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final kind in AdminPaperAsset.assetKinds)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: Text('Upload ${kind.replaceAll('_', ' ')}'),
                    onPressed: () => _uploadAsset(context, ref, kind),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAsset(
    BuildContext context,
    WidgetRef ref,
    String assetKind,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    await ref
        .read(papersRepositoryProvider)
        .uploadAsset(
          paperId: paperId,
          assetKind: assetKind,
          fileName: file.name,
          bytes: file.bytes!,
          mimeType: 'application/pdf',
        );
    ref.invalidate(_assetsProvider(paperId));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('File uploaded.')));
    }
  }
}

final _paperProvider = FutureProvider.family(
  (ref, String id) => ref.read(papersRepositoryProvider).fetchOne(id),
);
final _assetsProvider = FutureProvider.family(
  (ref, String id) => ref.read(papersRepositoryProvider).fetchAssets(id),
);
