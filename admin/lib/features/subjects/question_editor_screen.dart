import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../domain/models/question_models.dart';
import '../../domain/services/content_lifecycle.dart';
import '../../widgets/status_pill.dart';

/// Section 12: "Create and edit questions". Options and the official-memorandum/teaching-
/// explanation split (section 6) are edited here, matching the schema's separation in
/// `question_solutions.is_official_memorandum`.
class QuestionEditorScreen extends ConsumerWidget {
  final String subjectId;
  final String questionId;
  const QuestionEditorScreen({
    super.key,
    required this.subjectId,
    required this.questionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(_questionProvider(questionId));
    final optionsAsync = ref.watch(_optionsProvider(questionId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/subjects/$subjectId'),
        ),
        title: const Text('Question'),
      ),
      body: questionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load question: $e')),
        data: (question) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _QuestionHeader(question: question),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  question.promptMarkdown,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (question.kind == 'multiple_choice') ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add option'),
                    onPressed: () => _showAddOptionDialog(
                      context,
                      ref,
                      optionsAsync.valueOrNull?.length ?? 0,
                    ),
                  ),
                ],
              ),
              optionsAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (options) => Column(
                  children: [
                    for (final o in options)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(o.label)),
                          title: Text(o.bodyMarkdown),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (o.isCorrect)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                )
                              else
                                const SizedBox(width: 24),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () async {
                                  await ref
                                      .read(questionsRepositoryProvider)
                                      .deleteOption(o.id);
                                  ref.invalidate(_optionsProvider(questionId));
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            _SolutionEditor(questionId: questionId),
          ],
        ),
      ),
    );
  }

  void _showAddOptionDialog(
    BuildContext context,
    WidgetRef ref,
    int sortOrder,
  ) {
    final labelController = TextEditingController(
      text: String.fromCharCode(65 + sortOrder),
    );
    final bodyController = TextEditingController();
    bool isCorrect = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add option'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (A, B, C…)',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(labelText: 'Option text'),
                ),
                CheckboxListTile(
                  value: isCorrect,
                  onChanged: (v) => setState(() => isCorrect = v ?? false),
                  title: const Text('This is the correct answer'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(questionsRepositoryProvider)
                    .addOption(
                      questionId: questionId,
                      label: labelController.text.trim(),
                      bodyMarkdown: bodyController.text.trim(),
                      isCorrect: isCorrect,
                      sortOrder: sortOrder,
                    );
                ref.invalidate(_optionsProvider(questionId));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

final _questionProvider = FutureProvider.family(
  (ref, String id) => ref.read(questionsRepositoryProvider).fetchOne(id),
);
final _optionsProvider = FutureProvider.family(
  (ref, String id) => ref.read(questionsRepositoryProvider).fetchOptions(id),
);

class _QuestionHeader extends ConsumerWidget {
  final AdminQuestion question;
  const _QuestionHeader({required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = contentStatusFromDb(question.contentStatus);
    final nextStates = ContentLifecycle.allowedNextStates(status);
    final canPublish = ContentLifecycle.canPublish(
      isSeedDemoContent: question.isSeedDemoContent,
      verificationStatus: question.verificationStatus,
    );

    return Row(
      children: [
        StatusPill(status: question.contentStatus),
        const SizedBox(width: 8),
        VerificationPill(status: question.verificationStatus),
        const Spacer(),
        for (final next in nextStates)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: OutlinedButton(
              onPressed: (next == ContentStatus.published && !canPublish)
                  ? null
                  : () async {
                      await ref
                          .read(questionsRepositoryProvider)
                          .updateStatus(
                            question.id,
                            contentStatus: contentStatusToDb(next),
                          );
                      ref.invalidate(_questionProvider(question.id));
                    },
              child: Text(contentStatusLabel(next)),
            ),
          ),
      ],
    );
  }
}

class _SolutionEditor extends ConsumerStatefulWidget {
  final String questionId;
  const _SolutionEditor({required this.questionId});

  @override
  ConsumerState<_SolutionEditor> createState() => _SolutionEditorState();
}

class _SolutionEditorState extends ConsumerState<_SolutionEditor> {
  final _solutionController = TextEditingController();
  final _explanationController = TextEditingController();
  bool _isOfficialMemorandum = false;
  bool _saving = false;

  @override
  void dispose() {
    _solutionController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a solution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Kept separate end-to-end (section 6): mark it as official memorandum guidance only '
              'when it is sourced from a real DBE memorandum. Otherwise it is teaching guidance.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _solutionController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Solution / answer'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _explanationController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional teaching explanation (optional)',
              ),
            ),
            CheckboxListTile(
              value: _isOfficialMemorandum,
              onChanged: (v) =>
                  setState(() => _isOfficialMemorandum = v ?? false),
              title: const Text('Sourced from an official DBE memorandum'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save solution'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(questionsRepositoryProvider)
          .setSolution(
            questionId: widget.questionId,
            solutionMarkdown: _solutionController.text.trim(),
            isOfficialMemorandum: _isOfficialMemorandum,
            explanationMarkdown: _explanationController.text.trim().isEmpty
                ? null
                : _explanationController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Solution saved.')));
        _solutionController.clear();
        _explanationController.clear();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
