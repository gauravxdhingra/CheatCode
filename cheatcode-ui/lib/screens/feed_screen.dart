import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/problem_card.dart';
import '../models/problem.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  SwipeDirection? _swipeHint;

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _isDragging = true;
      final dx = _dragOffset.dx;
      final dy = _dragOffset.dy;
      if (dx.abs() > dy.abs()) {
        _swipeHint = dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      } else {
        _swipeHint = dy < 0 ? SwipeDirection.up : SwipeDirection.down;
      }
    });
  }

  void _onPanEnd(DragEndDetails details, AppProvider provider) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;
    const threshold = 80.0;

    if (dx > threshold) {
      _handleSwipe(SwipeDirection.right, provider);
    } else if (dx < -threshold) {
      _handleSwipe(SwipeDirection.left, provider);
    } else if (dy < -threshold) {
      _handleSwipe(SwipeDirection.up, provider);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
        _swipeHint = null;
      });
    }
  }

  void _handleSwipe(SwipeDirection dir, AppProvider provider) {
    final problem = provider.currentProblem;
    if (problem == null) return;

    setState(() {
      _dragOffset = Offset.zero;
      _isDragging = false;
      _swipeHint = null;
    });

    switch (dir) {
      case SwipeDirection.right:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProblemCard()),
        );
        break;
      case SwipeDirection.left:
        provider.skipProblem();
        _showToast('Skipped');
        break;
      case SwipeDirection.up:
        provider.saveToVault(problem.id);
        _showToast('🔒 Saved to Vault');
        break;
      case SwipeDirection.down:
        provider.skipProblem();
        break;
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: AppTheme.mono(size: 12, color: AppTheme.black)),
        backgroundColor: AppTheme.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Loading state
    if (provider.feedState == FeedState.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.green),
              SizedBox(height: 16),
              Text(
                '// loading your feed',
                style: TextStyle(
                    color: AppTheme.green, fontFamily: 'Courier New'),
              ),
            ],
          ),
        ),
      );
    }

    // Error state
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  color: AppTheme.green,
                  child: Text('Retry',
                      style: AppTheme.mono(
                          color: AppTheme.black, size: 13)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final problem = provider.currentProblem;
    if (problem == null) {
      return const Scaffold(
        body: Center(child: Text('No problems available')),
      );
    }

    final rotation = _dragOffset.dx / 600;
    final scale = _isDragging ? 0.97 : 1.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'cheatcode()',
                    style: AppTheme.mono(
                        size: 14,
                        color: AppTheme.green,
                        weight: FontWeight.bold),
                  ),
                  const Spacer(),
                  _StreakBadge(streak: provider.streak),
                  const SizedBox(width: 12),
                  _SolvedBadge(count: provider.solvedToday),
                ],
              ),
            ),

            // Swipe hints
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SwipeHint(
                    label: '← skip',
                    active: _swipeHint == SwipeDirection.left,
                    color: AppTheme.red,
                  ),
                  _SwipeHint(
                    label: '↑ vault',
                    active: _swipeHint == SwipeDirection.up,
                    color: AppTheme.yellow,
                  ),
                  _SwipeHint(
                    label: 'attempt →',
                    active: _swipeHint == SwipeDirection.right,
                    color: AppTheme.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card
            Expanded(
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: (d) => _onPanEnd(d, provider),
                child: AnimatedContainer(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  transform: Matrix4.identity()
                    ..translate(_dragOffset.dx, _dragOffset.dy)
                    ..rotateZ(rotation)
                    ..scale(scale),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: _FeedCard(problem: problem),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final dynamic problem;
  const _FeedCard({required this.problem});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.dim,
        border: Border.all(color: AppTheme.mid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.green, Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      color: AppTheme.green.withOpacity(0.1),
                      child: Text(
                        problem.companyBadge,
                        style: AppTheme.mono(
                            size: 10, color: AppTheme.green),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      color: AppTheme.mid,
                      child: Text(
                        problem.difficultyLabel,
                        style: AppTheme.mono(
                          size: 10,
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
                const SizedBox(height: 16),
                Text(
                  problem.title,
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                ),
                const SizedBox(height: 4),
                Text(
                  '// pattern: ${problem.pattern}',
                  style: AppTheme.mono(
                      size: 11,
                      color: AppTheme.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin:
                  const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0D0D0D),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: problem.codeLines.map<Widget>((line) {
                    if (line.isBlank) return _BlankLine();
                    return Text(
                      line.text.isEmpty ? ' ' : line.text,
                      style: AppTheme.mono(
                        size: 12,
                        color: AppTheme.white.withOpacity(0.6),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              '→ swipe right to attempt',
              style: AppTheme.mono(
                  size: 11,
                  color: AppTheme.green.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlankLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('    ',
            style: AppTheme.mono(
                size: 12,
                color: AppTheme.white.withOpacity(0.6))),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.green.withOpacity(0.1),
            border:
                Border.all(color: AppTheme.green.withOpacity(0.5)),
          ),
          child: Text('______',
              style:
                  AppTheme.mono(size: 12, color: AppTheme.green)),
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.dim,
        border: Border.all(color: AppTheme.mid),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('$streak',
              style: AppTheme.mono(size: 12, color: AppTheme.white)),
        ],
      ),
    );
  }
}

class _SolvedBadge extends StatelessWidget {
  final int count;
  const _SolvedBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.green.withOpacity(0.08),
        border:
            Border.all(color: AppTheme.green.withOpacity(0.3)),
      ),
      child: Text(
        '$count solved today',
        style: AppTheme.mono(size: 11, color: AppTheme.green),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;

  const _SwipeHint({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1.0 : 0.2,
      duration: const Duration(milliseconds: 100),
      child: Text(
        label,
        style: AppTheme.mono(
          size: 10,
          color: active ? color : AppTheme.white,
        ),
      ),
    );
  }
}
