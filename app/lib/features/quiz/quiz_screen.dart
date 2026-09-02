import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/idempotency.dart';
import '../../domain/models/question.dart';
import '../../domain/services/mastery_calculator.dart';
import '../../widgets/demo_content_badge.dart';

/// Section 11, screen 10. Checkpoint quiz for the vertical slice: multiple-choice only (structured/
/// essay self-marking is a Phase 3 item, docs/CONTINUATION.md). Correctness is shown with an icon
/// AND colour AND text, never colour alone (section 15). A wrong answer offers "practise again"
/// rather than blocking progress (section 8: never punish struggling learners).
class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _revealed = false;
  int _correctCount = 0;
  final _attemptIdempotencyKey = IdempotencyKeys.generate();

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(_quizQuestionsProvider(widget.quizId));

    return Scaffold(
      appBar: AppBar(title: const Text('Checkpoint quiz')),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load quiz: $e')),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('No questions available yet.'));
          }
          if (_currentIndex >= questions.length) {
            return _summary(questions.length);
          }
          return _questionView(questions[_currentIndex], questions.length);
        },
      ),
    );
  }

  Widget _questionView(Question question, int total) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: (_currentIndex) / total),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Question ${_currentIndex + 1} of $total',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              if (question.isSeedDemoContent) const DemoContentBadge(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.promptMarkdown,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          for (final option in question.options) _optionTile(question, option),
          const Spacer(),
          if (_revealed)
            FilledButton(
              onPressed: () => setState(() {
                _currentIndex++;
                _selectedOptionId = null;
                _revealed = false;
              }),
              child: Text(
                _currentIndex + 1 < total ? 'Next question' : 'Finish',
              ),
            )
          else
            FilledButton(
              onPressed: _selectedOptionId == null
                  ? null
                  : () => _reveal(question),
              child: const Text('Check answer'),
            ),
        ],
      ),
    );
  }

  Widget _optionTile(Question question, QuestionOption option) {
    final isSelected = _selectedOptionId == option.id;
    Color? tileColor;
    IconData? icon;

    if (_revealed && isSelected) {
      tileColor = option.isCorrect
          ? AppColors.success.withValues(alpha: 0.12)
          : AppColors.error.withValues(alpha: 0.12);
      icon = option.isCorrect
          ? FeedbackStyle.correctIcon
          : FeedbackStyle.incorrectIcon;
    } else if (_revealed && option.isCorrect) {
      tileColor = AppColors.success.withValues(alpha: 0.08);
      icon = FeedbackStyle.correctIcon;
    }

    return Card(
      color: tileColor,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: _revealed
            ? null
            : () => setState(() => _selectedOptionId = option.id),
        leading: CircleAvatar(child: Text(option.label)),
        title: Text(option.bodyMarkdown),
        trailing: icon == null
            ? null
            : Icon(
                icon,
                color: option.isCorrect ? AppColors.success : AppColors.error,
              ),
        selected: isSelected,
      ),
    );
  }

  void _reveal(Question question) {
    final correct = question.options
        .firstWhere((o) => o.id == _selectedOptionId)
        .isCorrect;
    setState(() {
      _revealed = true;
      if (correct) _correctCount++;
    });
    if (!correct && question.teachingExplanation != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(question.teachingExplanation!)));
    }
  }

  Widget _summary(int total) {
    final percent = total == 0 ? 0 : (_correctCount / total * 100).round();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            percent >= 50 ? Icons.emoji_events_rounded : Icons.replay_rounded,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            '$_correctCount / $total correct ($percent%)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => _finishAndAwardXp(percent),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishAndAwardXp(int percent) async {
    final repo = ref.read(gamificationRepositoryProvider);
    final outcome = await repo.awardXp(
      profileId: ref.read(currentUserIdProvider),
      amount: percent >= 50 ? XpRules.quizPassed : XpRules.correctionCompleted,
      reason: percent >= 50 ? 'quiz_passed' : 'correction_completed',
      sourceEntityType: 'quiz',
      sourceEntityId: widget.quizId,
      idempotencyKey: _attemptIdempotencyKey,
    );
    if (!mounted) return;
    context.go('/results', extra: outcome);
  }
}

final _quizQuestionsProvider = FutureProvider.family(
  (ref, String quizId) =>
      ref.read(quizRepositoryProvider).fetchQuizQuestions(quizId),
);
