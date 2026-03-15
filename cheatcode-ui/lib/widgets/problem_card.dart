import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/problem.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'dry_run_visualizer.dart';

// Safely convert a dynamic codeLines entry to CodeLine
CodeLine _toCodeLine(dynamic e) {
  if (e is CodeLine) return e;
  if (e is Map<String, dynamic>) return CodeLine.fromJson(e);
  if (e is Map) return CodeLine.fromJson(Map<String, dynamic>.from(e));
  if (e is String) return CodeLine.fromJson(jsonDecode(e) as Map<String, dynamic>);
  return const CodeLine(text: '');
}

class ProblemCard extends StatefulWidget {
  const ProblemCard({super.key});

  @override
  State<ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends State<ProblemCard>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _stopwatch = Stopwatch();
  int _hintsRevealed = 0;
  bool _submitted = false;
  bool _correct = false;
  bool _showPattern = false;
  bool _showEvolution = false;
  bool _showDryRun = false;

  late AnimationController _resultController;
  late Animation<double> _resultScale;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _resultScale = CurvedAnimation(
      parent: _resultController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _submit(Problem problem) {
    final answer = _controller.text.trim();
    final codeLines = problem.codeLines.map(_toCodeLine).toList();
    final blank = codeLines.firstWhere(
      (l) => l.isBlank,
      orElse: () => const CodeLine(text: '', isBlank: true, blankAnswer: ''),
    );
    final correct = answer == blank.blankAnswer;
    _stopwatch.stop();

    setState(() {
      _submitted = true;
      _correct = correct;
    });
    _resultController.forward();

    if (correct) {
      context.read<AppProvider>().markSolved(
            problem.id,
            timeToSolve: _stopwatch.elapsed.inSeconds,
            hintsUsed: _hintsRevealed,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final problem = provider.currentProblem;

    if (problem == null) {
      return const Scaffold(body: Center(child: Text('No problem loaded')));
    }

    final codeLines = problem.codeLines.map(_toCodeLine).toList();
    final blank = codeLines.firstWhere(
      (l) => l.isBlank,
      orElse: () => const CodeLine(text: '', isBlank: true, blankAnswer: ''),
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + badge
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('← back',
                              style: AppTheme.mono(
                                  size: 12,
                                  color: AppTheme.white.withOpacity(0.4))),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          color: AppTheme.green.withOpacity(0.1),
                          child: Text(problem.companyBadge,
                              style: AppTheme.mono(
                                  size: 10, color: AppTheme.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Text(
                      problem.title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text('// ${problem.pattern}',
                        style: AppTheme.mono(
                            size: 11,
                            color: AppTheme.white.withOpacity(0.3))),
                    const SizedBox(height: 24),

                    // Code block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF0D0D0D),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: codeLines.map<Widget>((line) {
                          if (line.isBlank) {
                            final prefix = line.text
                                .replaceAll('______', '')
                                .trimRight();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (prefix.isNotEmpty)
                                  Text(
                                    prefix,
                                    style: AppTheme.mono(
                                      size: 12,
                                      color:
                                          AppTheme.white.withOpacity(0.65),
                                    ),
                                  ),
                                SizedBox(
                                  width: 200,
                                  child: _BlankInputRow(
                                    controller: _controller,
                                    submitted: _submitted,
                                    correct: _correct,
                                    correctAnswer: blank.blankAnswer ?? '',
                                  ),
                                ),
                              ],
                            );
                          }
                          return Text(
                            line.text.isEmpty ? ' ' : line.text,
                            style: AppTheme.mono(
                              size: 12,
                              color: AppTheme.white.withOpacity(0.65),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Result
                    if (_submitted)
                      ScaleTransition(
                        scale: _resultScale,
                        child: _ResultCard(
                          correct: _correct,
                          correctAnswer: blank.blankAnswer ?? '',
                          explanation: problem.explanation,
                        ),
                      ),

                    if (!_submitted) ...[
                      // Hints
                      if (_hintsRevealed < problem.hints.length)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _hintsRevealed++),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.dim,
                              border: Border.all(color: AppTheme.mid),
                            ),
                            child: Row(
                              children: [
                                const Text('💡',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Text(
                                  _hintsRevealed == 0
                                      ? 'Tap for a hint'
                                      : 'Tap for another hint',
                                  style: AppTheme.mono(
                                      size: 12,
                                      color: AppTheme.white.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_hintsRevealed > 0) ...[
                        const SizedBox(height: 8),
                        ...List.generate(
                          _hintsRevealed,
                          (i) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(12),
                            color: AppTheme.yellow.withOpacity(0.06),
                            child: Text(
                              '${i + 1}. ${problem.hints[i]}',
                              style: AppTheme.mono(
                                  size: 12,
                                  color: AppTheme.yellow.withOpacity(0.8)),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Submit
                      GestureDetector(
                        onTap: () => _submit(problem),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: AppTheme.green,
                          child: Center(
                            child: Text('SUBMIT',
                                style: AppTheme.mono(
                                    size: 13,
                                    color: AppTheme.black,
                                    weight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],

                    if (_submitted) ...[
                      const SizedBox(height: 24),

                      // Dry Run
                      _ExpandableSection(
                        icon: '▶',
                        title: 'Interactive Dry Run',
                        expanded: _showDryRun,
                        onTap: () =>
                            setState(() => _showDryRun = !_showDryRun),
                        child: DryRunVisualizer(
                          nums: const [2, 1, 5, 1, 3, 2],
                          k: 3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Pattern card
                      _ExpandableSection(
                        icon: '🔍',
                        title: 'Pattern: ${problem.pattern}',
                        expanded: _showPattern,
                        onTap: () =>
                            setState(() => _showPattern = !_showPattern),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              problem.patternDescription.isNotEmpty
                                  ? problem.patternDescription
                                  : problem.explanation,
                              style: AppTheme.mono(
                                  size: 12,
                                  color: AppTheme.white.withOpacity(0.6)),
                            ),
                            const SizedBox(height: 16),
                            Text("You'll see this pattern in:",
                                style: AppTheme.mono(
                                    size: 11,
                                    color: AppTheme.white.withOpacity(0.35))),
                            const SizedBox(height: 8),
                            ...problem.relatedPatterns.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('→ $p',
                                      style: AppTheme.mono(
                                          size: 12, color: AppTheme.green)),
                                )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Evolution
                      _ExpandableSection(
                        icon: '📈',
                        title: 'Brute Force → Optimised',
                        expanded: _showEvolution,
                        onTap: () =>
                            setState(() => _showEvolution = !_showEvolution),
                        child: Column(
                          children: [
                            _CodeEvolutionPanel(
                              label: '✗ Brute Force',
                              complexity: problem.bruteComplexity,
                              code: problem.bruteForce,
                              isBad: true,
                            ),
                            const SizedBox(height: 8),
                            _CodeEvolutionPanel(
                              label: '✓ Optimised',
                              complexity: problem.optimisedComplexity,
                              code: problem.optimised,
                              isBad: false,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Next
                      GestureDetector(
                        onTap: () {
                          provider.nextProblem();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: AppTheme.green,
                          child: Center(
                            child: Text('NEXT PROBLEM →',
                                style: AppTheme.mono(
                                    size: 13,
                                    color: AppTheme.black,
                                    weight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlankInputRow extends StatelessWidget {
  final TextEditingController controller;
  final bool submitted;
  final bool correct;
  final String correctAnswer;

  const _BlankInputRow({
    required this.controller,
    required this.submitted,
    required this.correct,
    required this.correctAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = submitted
        ? (correct ? AppTheme.green : AppTheme.red)
        : AppTheme.green.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: submitted
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (correct ? AppTheme.green : AppTheme.red)
                    .withOpacity(0.1),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                correct ? controller.text : correctAnswer,
                style: AppTheme.mono(
                    size: 12,
                    color: correct ? AppTheme.green : AppTheme.red),
              ),
            )
          : Container(
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.08),
                border:
                    Border.all(color: AppTheme.green.withOpacity(0.4)),
              ),
              child: TextField(
                controller: controller,
                style: AppTheme.mono(size: 12, color: AppTheme.green),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  hintText: '___',
                  hintStyle:
                      TextStyle(color: AppTheme.green, fontSize: 12),
                ),
                autofocus: true,
              ),
            ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool correct;
  final String correctAnswer;
  final String explanation;

  const _ResultCard({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppTheme.green : AppTheme.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? '✓ Correct.' : '✗ Not quite.',
            style: AppTheme.mono(
                size: 14, color: color, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!correct) ...[
            Text('Correct answer:',
                style: AppTheme.mono(
                    size: 11, color: AppTheme.white.withOpacity(0.4))),
            const SizedBox(height: 4),
            Text(correctAnswer,
                style: AppTheme.mono(
                    size: 13,
                    color: AppTheme.green,
                    weight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],
          Text(explanation,
              style: AppTheme.mono(
                  size: 12, color: AppTheme.white.withOpacity(0.6))),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatelessWidget {
  final String icon;
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _ExpandableSection({
    required this.icon,
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.dim, border: Border.all(color: AppTheme.mid)),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Text(title,
                      style: AppTheme.mono(
                          size: 12,
                          color: AppTheme.white.withOpacity(0.8))),
                  const Spacer(),
                  Text(expanded ? '▲' : '▼',
                      style: AppTheme.mono(
                          size: 10,
                          color: AppTheme.white.withOpacity(0.3))),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _CodeEvolutionPanel extends StatelessWidget {
  final String label;
  final String complexity;
  final String code;
  final bool isBad;

  const _CodeEvolutionPanel({
    required this.label,
    required this.complexity,
    required this.code,
    required this.isBad,
  });

  @override
  Widget build(BuildContext context) {
    final color = isBad ? AppTheme.red : AppTheme.green;
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF0D0D0D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTheme.mono(size: 10, color: color)),
              const Spacer(),
              Text(complexity,
                  style: AppTheme.mono(
                      size: 9,
                      color: AppTheme.white.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 8),
          Text(code,
              style: AppTheme.mono(
                  size: 11, color: AppTheme.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}
