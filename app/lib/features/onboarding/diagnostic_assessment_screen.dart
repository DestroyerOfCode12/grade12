import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/diagnostic_repository.dart';
import '../../domain/models/question.dart';
import '../../domain/services/mastery_calculator.dart';
import '../../widgets/demo_content_badge.dart';

/// Section 11, screen 4 / section 9: "Run a short diagnostic assessment for each selected
/// subject." Sits between subject selection and Home in onboarding. Every result feeds
/// `mastery_scores` (via [MasteryRepository]) — nothing else in the app writes an initial
/// mastery estimate, so skipping this screen is exactly equivalent to every topic starting at
/// "not started", which the study planner already treats correctly (section 9's readiness
/// language, never presented as a predicted result).
class DiagnosticAssessmentScreen extends ConsumerStatefulWidget {
  const DiagnosticAssessmentScreen({super.key});

  @override
  ConsumerState<DiagnosticAssessmentScreen> createState() =>
      _DiagnosticAssessmentScreenState();
}

enum _Phase { loading, intro, answering, summary, none }

class _TopicResult {
  final DiagnosticTopicQuiz quiz;
  final bool skipped;
  final double? scorePercent;
  const _TopicResult({
    required this.quiz,
    required this.skipped,
    this.scorePercent,
  });
}

class _DiagnosticAssessmentScreenState
    extends ConsumerState<DiagnosticAssessmentScreen> {
  List<DiagnosticTopicQuiz> _topics = [];
  int _topicIndex = 0;
  int _questionIndex = 0;
  int _correctCount = 0;
  String? _selectedOptionId;
  bool _revealed = false;
  final List<_TopicResult> _results = [];
  _Phase _phase = _Phase.loading;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTopics());
  }

  Future<void> _loadTopics() async {
    final selected = ref.read(selectedSubjectIdsProvider);
    final topics = await ref
        .read(diagnosticRepositoryProvider)
        .fetchAvailable(selected);
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _phase = topics.isEmpty ? _Phase.none : _Phase.intro;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Check'),
        automaticallyImplyLeading: false,
      ),
      body: switch (_phase) {
        _Phase.loading => const Center(child: CircularProgressIndicator()),
        _Phase.none => _noneAvailable(),
        _Phase.intro => _topicIntro(),
        _Phase.answering => _questionView(),
        _Phase.summary => _summary(),
      },
    );
  }

  Widget _noneAvailable() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'No diagnostic is available yet for your subjects — we\'ll start you at the '
              'beginning and adjust as you go.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _finish,
              child: const Text('Continue to MatricQuest SA'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicIntro() {
    final quiz = _topics[_topicIndex];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_topicIndex + 1} of ${_topics.length}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Icon(Icons.quiz_outlined, size: 48, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              quiz.subjectName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              quiz.topicTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const DemoContentBadge(
              label: 'Demo diagnostic — for illustration only',
            ),
            const SizedBox(height: 16),
            Text(
              'This helps set your starting point for this topic — answer honestly, and it\'s '
              'fine to guess. It won\'t affect your XP.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => setState(() {
                _questionIndex = 0;
                _correctCount = 0;
                _selectedOptionId = null;
                _revealed = false;
                _phase = _Phase.answering;
              }),
              child: Text('Start (${quiz.questions.length} questions)'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _recordAndAdvance(skipped: true),
              child: const Text('Skip this subject'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _questionView() {
    final quiz = _topics[_topicIndex];
    final question = quiz.questions[_questionIndex];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: _questionIndex / quiz.questions.length,
          ),
          const SizedBox(height: 16),
          Text(
            'Question ${_questionIndex + 1} of ${quiz.questions.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            question.promptMarkdown,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          for (final option in question.options) _optionTile(question, option),
          const Spacer(),
          if (_revealed)
            FilledButton(
              onPressed: () => _nextQuestion(quiz),
              child: Text(
                _questionIndex + 1 < quiz.questions.length
                    ? 'Next question'
                    : 'Finish this topic',
              ),
            )
          else
            FilledButton(
              onPressed: _selectedOptionId == null
                  ? null
                  : () => setState(() => _revealed = true),
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
            : () {
                setState(() => _selectedOptionId = option.id);
                if (option.isCorrect) _correctCount++;
              },
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

  void _nextQuestion(DiagnosticTopicQuiz quiz) {
    if (_questionIndex + 1 < quiz.questions.length) {
      setState(() {
        _questionIndex++;
        _selectedOptionId = null;
        _revealed = false;
      });
    } else {
      final scorePercent = quiz.questions.isEmpty
          ? 0.0
          : (_correctCount / quiz.questions.length) * 100;
      _recordAndAdvance(skipped: false, scorePercent: scorePercent);
    }
  }

  Future<void> _recordAndAdvance({
    required bool skipped,
    double? scorePercent,
  }) async {
    final quiz = _topics[_topicIndex];
    if (!skipped && scorePercent != null) {
      await ref
          .read(masteryRepositoryProvider)
          .recordAttempt(
            topicId: quiz.topicId,
            subjectId: quiz.subjectId,
            scorePercent: scorePercent,
          );
    }
    _results.add(
      _TopicResult(quiz: quiz, skipped: skipped, scorePercent: scorePercent),
    );

    if (!mounted) return;
    if (_topicIndex + 1 < _topics.length) {
      setState(() {
        _topicIndex++;
        _phase = _Phase.intro;
      });
    } else {
      setState(() => _phase = _Phase.summary);
    }
  }

  Widget _summary() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.emoji_flags_rounded, size: 48, color: AppColors.secondary),
          const SizedBox(height: 12),
          Text(
            'Your starting point',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'A readiness estimate, not a prediction of your final result — it\'ll keep updating '
            'as you study.',
          ),
          const SizedBox(height: 16),
          for (final result in _results)
            Card(
              child: ListTile(
                title: Text(result.quiz.topicTitle),
                subtitle: Text(result.quiz.subjectName),
                trailing: result.skipped
                    ? const Chip(label: Text('Skipped'))
                    : Text(
                        MasteryCalculator.displayLabel(
                          MasteryCalculator.labelFor(
                            result.scorePercent ?? 0,
                            attemptsCount: 1,
                          ),
                        ),
                      ),
              ),
            ),
          const Spacer(),
          FilledButton(
            onPressed: _finish,
            child: const Text('Continue to MatricQuest SA'),
          ),
        ],
      ),
    );
  }

  void _finish() {
    context.go('/home');
  }
}
