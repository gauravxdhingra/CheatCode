import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/problem.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dry_run_visualizer.dart';
import 'vault_screen.dart';
import 'progress_screen.dart';
import 'history_screen.dart';
import 'solved_today_screen.dart';

CodeLine _toCodeLine(dynamic e) {
  if (e is CodeLine) return e;
  Map<String, dynamic> map;
  if (e is Map<String, dynamic>) {
    map = e;
  } else if (e is Map) {
    map = Map<String, dynamic>.from(e);
  } else if (e is String) {
    map = jsonDecode(e) as Map<String, dynamic>;
  } else {
    return const CodeLine(text: '');
  }
  final isBlank = map['is_blank'];
  final blankBool = isBlank == true || isBlank == 'true';
  return CodeLine(
    text: map['text'] as String? ?? '',
    isBlank: blankBool,
    blankAnswer: map['blank_answer'] as String?,
  );
}

// Generate 3 wrong options for multiple choice

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _stopwatch = Stopwatch();
  int _hintsRevealed = 0;
  bool _submitted = false;
  bool _correct = false;
  bool _showPattern = false;
  bool _showEvolution = false;
  bool _showDryRun = false;
  bool _showMultiChoice = false;
  String? _selectedChoice;
  List<String> _choices = [];

  late AnimationController _resultController;
  late Animation<double> _resultScale;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late AnimationController _hintController;

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
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _resultController.dispose();
    _slideController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _resetForNextProblem() {
    _controller.clear();
    _stopwatch.reset();
    _stopwatch.start();
    _resultController.reset();
    _slideController.reset();
    _hintController.reset();
    setState(() {
      _submitted = false;
      _correct = false;
      _hintsRevealed = 0;
      _showPattern = false;
      _showEvolution = false;
      _showDryRun = false;
      _showMultiChoice = false;
      _selectedChoice = null;
      _choices = [];
    });
    _slideController.forward();
  }

  Future<void> _submit(Problem problem, CodeLine blank) async {
    final answer = _controller.text.trim();
    if (answer.isEmpty) return;
    _stopwatch.stop();

    try {
      final provider = context.read<AppProvider>();
      if (provider.userId != null) {
        final result = await ApiService.validateAnswer(
          userId: provider.userId!,
          problemId: problem.id,
          userAnswer: answer,
        );
        final correct = result['correct'] as bool;
        setState(() {
          _submitted = true;
          _correct = correct;
        });
        _resultController.forward();
        if (correct) {
          provider.markSolvedLocally(problem.id);
        }
      } else {
        // Fallback client-side
        final norm = (s) => s.replaceAll(' ', '').toLowerCase();
        final correct = norm(answer) == norm(blank.blankAnswer ?? '');
        setState(() { _submitted = true; _correct = correct; });
        _resultController.forward();
      }
    } catch (_) {
      // Network error — fall back to client-side comparison
      final norm = (String s) => s.replaceAll(' ', '').toLowerCase();
      final correct = norm(answer) == norm(blank.blankAnswer ?? '');
      setState(() { _submitted = true; _correct = correct; });
      _resultController.forward();
      if (correct) context.read<AppProvider>().markSolvedLocally(problem.id);
    }
  }

  Future<void> _submitChoice(Problem problem, CodeLine blank, String choice) async {
    _stopwatch.stop();
    try {
      final provider = context.read<AppProvider>();
      if (provider.userId != null) {
        final result = await ApiService.validateAnswer(
          userId: provider.userId!,
          problemId: problem.id,
          userAnswer: choice,
        );
        final correct = result['correct'] as bool;
        setState(() { _selectedChoice = choice; _submitted = true; _correct = correct; });
        _resultController.forward();
        if (correct) provider.markSolvedLocally(problem.id);
      } else {
        final correct = choice == blank.blankAnswer;
        setState(() { _selectedChoice = choice; _submitted = true; _correct = correct; });
        _resultController.forward();
      }
    } catch (_) {
      final correct = choice == blank.blankAnswer;
      setState(() { _selectedChoice = choice; _submitted = true; _correct = correct; });
      _resultController.forward();
      if (correct) context.read<AppProvider>().markSolvedLocally(problem.id);
    }
  }

  void _revealHint(Problem problem) {
    if (_hintsRevealed < problem.hints.length) {
      _hintController.forward(from: 0);
      setState(() => _hintsRevealed++);
    }
  }

  void _toggleMultiChoice(Problem problem) {
    if (_choices.isEmpty) {
      _choices = problem.multipleChoiceOptions;
    }
    setState(() => _showMultiChoice = !_showMultiChoice);
  }

  void _skip(AppProvider provider) {
    provider.skipProblem();
    _resetForNextProblem();
  }

  void _vault(AppProvider provider, String id) {
    provider.saveToVault(id);
    _resetForNextProblem();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔒 Saved to Vault',
            style: AppTheme.mono(size: 12, color: AppTheme.black)),
        backgroundColor: AppTheme.yellow,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.feedState == FeedState.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.green),
              SizedBox(height: 16),
              Text('// loading your feed',
                  style: TextStyle(color: AppTheme.green, fontFamily: 'Courier New')),
            ],
          ),
        ),
      );
    }

    if (provider.feedState == FeedState.error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Something went wrong',
                  style: AppTheme.mono(color: AppTheme.red, size: 14)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: provider.loadFeed,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: AppTheme.green,
                  child: Text('Retry',
                      style: AppTheme.mono(color: AppTheme.black, size: 13)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final problem = provider.currentProblem;
    if (problem == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                streak: provider.streak,
                solvedToday: provider.solvedToday,
                onHistory: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen())),
                onSolvedToday: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SolvedTodayScreen())),
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎉', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('All caught up!',
                          style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Come back tomorrow for more',
                          style: TextStyle(color: AppTheme.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final codeLines = problem.codeLines.map(_toCodeLine).toList();
    final blank = codeLines.firstWhere(
      (l) => l.isBlank,
      orElse: () => const CodeLine(text: '', isBlank: true, blankAnswer: ''),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              streak: provider.streak,
              solvedToday: provider.solvedToday,
              onHistory: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen())),
              onSolvedToday: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SolvedTodayScreen())),
            ),
            Expanded(
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Problem header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            color: AppTheme.green.withOpacity(0.1),
                                            child: Text(problem.companyBadge,
                                                style: AppTheme.mono(
                                                    size: 9, color: AppTheme.green)),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            color: AppTheme.mid,
                                            child: Text(
                                              problem.difficultyLabel,
                                              style: AppTheme.mono(
                                                size: 9,
                                                color: problem.difficulty == 1
                                                    ? AppTheme.green
                                                    : problem.difficulty == 2
                                                        ? AppTheme.yellow
                                                        : AppTheme.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        problem.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.5),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('// ${problem.pattern}',
                                          style: AppTheme.mono(
                                              size: 10,
                                              color:
                                                  AppTheme.white.withOpacity(0.3))),
                                    ],
                                  ),
                                ),
                                if (!_submitted) ...[
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      _IconAction(
                                        label: 'skip',
                                        icon: '→',
                                        color: AppTheme.white.withOpacity(0.2),
                                        onTap: () => _skip(provider),
                                      ),
                                      const SizedBox(height: 8),
                                      _IconAction(
                                        label: 'vault',
                                        icon: '🔒',
                                        color: AppTheme.yellow.withOpacity(0.6),
                                        onTap: () => _vault(provider, problem.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Code block
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D0D0D),
                                border: Border.all(
                                    color: AppTheme.mid.withOpacity(0.5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top bar
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: AppTheme.mid
                                                  .withOpacity(0.5))),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFFFF5F57),
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 5),
                                        Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFFFFBD2E),
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 5),
                                        Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                                color: Color(0xFF28CA41),
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 10),
                                        Text('solution.js',
                                            style: AppTheme.mono(
                                                size: 9,
                                                color: AppTheme.white
                                                    .withOpacity(0.25))),
                                      ],
                                    ),
                                  ),
                                  // Code lines
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: codeLines.map<Widget>((line) {
                                        if (line.isBlank) {
                                          final prefix = line.text
                                              .replaceAll('______', '')
                                              .trimRight();
                                          return _InlineBlank(
                                            prefix: prefix,
                                            controller: _controller,
                                            submitted: _submitted,
                                            correct: _correct,
                                            correctAnswer:
                                                blank.blankAnswer ?? '',
                                            selectedChoice: _selectedChoice,
                                          );
                                        }
                                        return Text(
                                          line.text.isEmpty ? ' ' : line.text,
                                          style: AppTheme.mono(
                                            size: 12,
                                            color:
                                                AppTheme.white.withOpacity(0.65),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
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
                              // Hints row
                              _HintSection(
                                hints: problem.hints,
                                hintsRevealed: _hintsRevealed,
                                hintController: _hintController,
                                onReveal: () => _revealHint(problem),
                              ),

                              const SizedBox(height: 16),

                              // Action row: multiple choice toggle + submit
                              Row(
                                children: [
                                  // Multiple choice toggle
                                  GestureDetector(
                                    onTap: () => _toggleMultiChoice(problem),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _showMultiChoice
                                            ? AppTheme.green.withOpacity(0.12)
                                            : AppTheme.dim,
                                        border: Border.all(
                                          color: _showMultiChoice
                                              ? AppTheme.green.withOpacity(0.4)
                                              : AppTheme.mid,
                                        ),
                                      ),
                                      child: Text(
                                        '⊞',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: _showMultiChoice
                                              ? AppTheme.green
                                              : AppTheme.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Submit
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: _showMultiChoice
                                          ? null
                                          : () => _submit(problem, blank),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        color: _showMultiChoice
                                            ? AppTheme.green.withOpacity(0.3)
                                            : AppTheme.green,
                                        child: Center(
                                          child: Text(
                                            _showMultiChoice
                                                ? 'pick an option above'
                                                : 'SUBMIT',
                                            style: AppTheme.mono(
                                              size: 13,
                                              color: _showMultiChoice
                                                  ? AppTheme.black
                                                      .withOpacity(0.4)
                                                  : AppTheme.black,
                                              weight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Multiple choice options
                              if (_showMultiChoice) ...[
                                const SizedBox(height: 12),
                                ..._choices.map((choice) => GestureDetector(
                                      onTap: () =>
                                          _submitChoice(problem, blank, choice),
                                      child: Container(
                                        width: double.infinity,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppTheme.dim,
                                          border: Border.all(
                                              color: AppTheme.mid),
                                        ),
                                        child: Text(
                                          choice,
                                          style: AppTheme.mono(
                                              size: 13,
                                              color: AppTheme.white
                                                  .withOpacity(0.8)),
                                        ),
                                      ),
                                    )),
                              ],
                            ],

                            if (_submitted) ...[
                              const SizedBox(height: 24),

                              _ExpandableSection(
                                icon: '▶',
                                title: 'Interactive Dry Run',
                                expanded: _showDryRun,
                                onTap: () => setState(
                                    () => _showDryRun = !_showDryRun),
                                child: DryRunVisualizer(
                                    nums: const [2, 1, 5, 1, 3, 2], k: 3),
                              ),
                              const SizedBox(height: 12),

                              _ExpandableSection(
                                icon: '🔍',
                                title: 'Pattern: ${problem.pattern}',
                                expanded: _showPattern,
                                onTap: () => setState(
                                    () => _showPattern = !_showPattern),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      problem.patternDescription.isNotEmpty
                                          ? problem.patternDescription
                                          : problem.explanation,
                                      style: AppTheme.mono(
                                          size: 12,
                                          color:
                                              AppTheme.white.withOpacity(0.6)),
                                    ),
                                    const SizedBox(height: 16),
                                    Text("You'll see this pattern in:",
                                        style: AppTheme.mono(
                                            size: 11,
                                            color: AppTheme.white
                                                .withOpacity(0.35))),
                                    const SizedBox(height: 8),
                                    ...problem.relatedPatterns.map((p) =>
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text('→ $p',
                                              style: AppTheme.mono(
                                                  size: 12,
                                                  color: AppTheme.green)),
                                        )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              _ExpandableSection(
                                icon: '📈',
                                title: 'Brute Force → Optimised',
                                expanded: _showEvolution,
                                onTap: () => setState(
                                    () => _showEvolution = !_showEvolution),
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

                              GestureDetector(
                                onTap: () {
                                  provider.nextProblem();
                                  _resetForNextProblem();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
            ),

            // Bottom nav
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.mid)),
                color: AppTheme.black,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: '⚡', label: 'Feed', active: true, onTap: () {}),
                  _NavItem(
                    icon: '🔒',
                    label: 'Vault',
                    badge: provider.problems
                        .where((p) => provider.isInVault(p.id))
                        .length,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const VaultScreen())),
                  ),
                  _NavItem(
                    icon: '📈',
                    label: 'Progress',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ProgressScreen())),
                  ),
                  _NavItem(
                    icon: '📋',
                    label: 'History',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const HistoryScreen())),
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

// ── Inline blank — prefix text + input in one row ─────────────────────────────

class _InlineBlank extends StatelessWidget {
  final String prefix;
  final TextEditingController controller;
  final bool submitted;
  final bool correct;
  final String correctAnswer;
  final String? selectedChoice;

  const _InlineBlank({
    required this.prefix,
    required this.controller,
    required this.submitted,
    required this.correct,
    required this.correctAnswer,
    this.selectedChoice,
  });

  @override
  Widget build(BuildContext context) {
    final displayAnswer = selectedChoice ?? controller.text;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix.isNotEmpty)
            Text(prefix,
                style: AppTheme.mono(
                    size: 12, color: AppTheme.white.withOpacity(0.65))),
          submitted
              ? Container(
                  constraints: const BoxConstraints(minWidth: 80),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: (correct ? AppTheme.green : AppTheme.red)
                        .withOpacity(0.15),
                    border: Border.all(
                      color: correct ? AppTheme.green : AppTheme.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    correct ? displayAnswer : correctAnswer,
                    style: AppTheme.mono(
                        size: 12,
                        color: correct ? AppTheme.green : AppTheme.red,
                        weight: FontWeight.bold),
                  ),
                )
              : Container(
                  constraints:
                      const BoxConstraints(minWidth: 100, maxWidth: 220),
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.green.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(
                          color: AppTheme.green.withOpacity(0.6), width: 1.5),
                    ),
                  ),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: controller,
                      style: AppTheme.mono(
                          size: 12,
                          color: AppTheme.green,
                          weight: FontWeight.bold),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        hintText: '// type here',
                        hintStyle: TextStyle(
                            color: AppTheme.green.withOpacity(0.3),
                            fontSize: 11,
                            fontFamily: 'Courier New'),
                        isCollapsed: true,
                      ),
                      autofocus: false,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ── Hint section ──────────────────────────────────────────────────────────────

class _HintSection extends StatelessWidget {
  final List<String> hints;
  final int hintsRevealed;
  final AnimationController hintController;
  final VoidCallback onReveal;

  const _HintSection({
    required this.hints,
    required this.hintsRevealed,
    required this.hintController,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revealed hints
        ...List.generate(hintsRevealed, (i) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (_, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.yellow.withOpacity(0.05),
                border: Border(
                    left: BorderSide(
                        color: AppTheme.yellow.withOpacity(0.5), width: 2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}.',
                      style: AppTheme.mono(
                          size: 10,
                          color: AppTheme.yellow.withOpacity(0.5))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hints[i],
                        style: AppTheme.mono(
                            size: 12,
                            color: AppTheme.yellow.withOpacity(0.85))),
                  ),
                ],
              ),
            ),
          );
        }),

        // Reveal button
        if (hintsRevealed < hints.length)
          GestureDetector(
            onTap: onReveal,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.dim,
                border: Border.all(color: AppTheme.mid),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💡',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.yellow.withOpacity(
                              hintsRevealed == 0 ? 1.0 : 0.6))),
                  const SizedBox(width: 8),
                  Text(
                    hintsRevealed == 0
                        ? 'Unlock hint  ${hintsRevealed + 1}/${hints.length}'
                        : 'Unlock hint ${hintsRevealed + 1}/${hints.length}',
                    style: AppTheme.mono(
                        size: 11,
                        color: AppTheme.white.withOpacity(
                            hintsRevealed == 0 ? 0.6 : 0.4)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '→',
                    style: TextStyle(
                        color: AppTheme.yellow.withOpacity(0.4),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int streak;
  final int solvedToday;
  final VoidCallback onHistory;
  final VoidCallback onSolvedToday;

  const _Header({
    required this.streak,
    required this.solvedToday,
    required this.onHistory,
    required this.onSolvedToday,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text('cheatcode()',
              style: AppTheme.mono(
                  size: 14,
                  color: AppTheme.green,
                  weight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: AppTheme.dim, border: Border.all(color: AppTheme.mid)),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text('$streak',
                    style: AppTheme.mono(size: 12, color: AppTheme.white)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSolvedToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.08),
                border: Border.all(color: AppTheme.green.withOpacity(0.3)),
              ),
              child: Text('$solvedToday solved today',
                  style: AppTheme.mono(size: 11, color: AppTheme.green)),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _IconAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(icon,
              style: TextStyle(
                  fontSize: icon.length == 1 ? 16 : 18, color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.mono(size: 9, color: color)),
        ],
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
            style: AppTheme.mono(size: 14, color: color, weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (!correct) ...[
            Text('Correct answer:',
                style: AppTheme.mono(
                    size: 11, color: AppTheme.white.withOpacity(0.4))),
            const SizedBox(height: 4),
            Text(correctAnswer,
                style: AppTheme.mono(
                    size: 13, color: AppTheme.green, weight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],
          Text(explanation,
              style:
                  AppTheme.mono(size: 12, color: AppTheme.white.withOpacity(0.6))),
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
                          size: 12, color: AppTheme.white.withOpacity(0.8))),
                  const Spacer(),
                  Text(expanded ? '▲' : '▼',
                      style: AppTheme.mono(
                          size: 10, color: AppTheme.white.withOpacity(0.3))),
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
                      size: 9, color: AppTheme.white.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(code,
                style: AppTheme.mono(
                    size: 11, color: AppTheme.white.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.badge = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              if (badge > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: AppTheme.yellow, shape: BoxShape.circle),
                    child: Text('$badge',
                        style: const TextStyle(
                            fontSize: 8,
                            color: AppTheme.black,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(label,
              style: AppTheme.mono(
                  size: 9,
                  color: active
                      ? AppTheme.green
                      : AppTheme.white.withOpacity(0.4))),
        ],
      ),
    );
  }
}
