import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final stats = provider.patternStats;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      '← back',
                      style: AppTheme.mono(
                          size: 12,
                          color: AppTheme.white.withOpacity(0.4)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '📈 progress',
                    style: AppTheme.mono(
                        size: 14,
                        color: AppTheme.green,
                        weight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pattern Ownership',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '// 5 solves = pattern owned',
                    style: AppTheme.mono(
                        size: 11,
                        color: AppTheme.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Summary row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatBox(
                    value: '${provider.streak}',
                    label: 'day streak',
                    color: AppTheme.yellow,
                    emoji: '🔥',
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    value: '${provider.solvedToday}',
                    label: 'solved today',
                    color: AppTheme.green,
                    emoji: '✓',
                  ),
                  const SizedBox(width: 12),
                  _StatBox(
                    value: '${stats.where((s) => s.owned).length}',
                    label: 'patterns owned',
                    color: AppTheme.green,
                    emoji: '⚡',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (stats.isEmpty)
              Expanded(child: _EmptyProgress())
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: stats.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _PatternRow(stat: stats[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final String emoji;

  const _StatBox({
    required this.value,
    required this.label,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTheme.mono(
                  size: 22, color: color, weight: FontWeight.bold),
            ),
            Text(
              label,
              style: AppTheme.mono(
                  size: 9,
                  color: AppTheme.white.withOpacity(0.35)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  final PatternStat stat;
  const _PatternRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    final progress = (stat.timesSolved / 5).clamp(0.0, 1.0);
    final color = stat.owned ? AppTheme.green : AppTheme.yellow;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.dim,
        border: Border.all(
          color: stat.owned
              ? AppTheme.green.withOpacity(0.3)
              : AppTheme.mid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                stat.patternName,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (stat.owned)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  color: AppTheme.green.withOpacity(0.1),
                  child: Text(
                    '⚡ owned',
                    style: AppTheme.mono(
                        size: 9, color: AppTheme.green),
                  ),
                )
              else
                Text(
                  '${stat.timesSolved}/5',
                  style: AppTheme.mono(
                      size: 11,
                      color: AppTheme.white.withOpacity(0.4)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.mid,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stat.timesEncountered} encountered · ${stat.timesSolved} solved',
            style: AppTheme.mono(
                size: 10,
                color: AppTheme.white.withOpacity(0.25)),
          ),
        ],
      ),
    );
  }
}

class _EmptyProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📈', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No patterns yet',
            style: AppTheme.mono(
                size: 16,
                color: AppTheme.white,
                weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Solve problems to start\ntracking pattern ownership',
            textAlign: TextAlign.center,
            style: AppTheme.mono(
                size: 12,
                color: AppTheme.white.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }
}
