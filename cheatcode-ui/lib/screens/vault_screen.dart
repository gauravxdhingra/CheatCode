import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/problem_card.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final vaultProblems = provider.problems
        .where((p) => provider.isInVault(p.id))
        .toList();

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
                    '🔒 vault',
                    style: AppTheme.mono(
                        size: 14,
                        color: AppTheme.yellow,
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
                    'EOD Challenges',
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
                    '// problems you saved to think about',
                    style: AppTheme.mono(
                        size: 11,
                        color: AppTheme.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (vaultProblems.isEmpty)
              Expanded(child: _EmptyVault())
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: vaultProblems.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final problem = vaultProblems[i];
                    return _VaultCard(
                      problem: problem,
                      solved: provider.isSolved(problem.id),
                      onAttempt: () {
                        provider.setCurrentProblemById(problem.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProblemCard()),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔒',
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Vault is empty',
            style: AppTheme.mono(
                size: 16,
                color: AppTheme.white,
                weight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Swipe ↑ on any problem\nto save it for EOD',
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

class _VaultCard extends StatelessWidget {
  final dynamic problem;
  final bool solved;
  final VoidCallback onAttempt;

  const _VaultCard({
    required this.problem,
    required this.solved,
    required this.onAttempt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.dim,
        border: Border.all(
          color: solved
              ? AppTheme.green.withOpacity(0.3)
              : AppTheme.yellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  solved ? AppTheme.green : AppTheme.yellow,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        problem.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            problem.companyBadge,
                            style: AppTheme.mono(
                                size: 10, color: AppTheme.green),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '// ${problem.pattern}',
                            style: AppTheme.mono(
                                size: 10,
                                color:
                                    AppTheme.white.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                solved
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        color: AppTheme.green.withOpacity(0.1),
                        child: Text(
                          '✓ solved',
                          style: AppTheme.mono(
                              size: 10, color: AppTheme.green),
                        ),
                      )
                    : GestureDetector(
                        onTap: onAttempt,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: AppTheme.yellow.withOpacity(0.1),
                          child: Text(
                            'attempt →',
                            style: AppTheme.mono(
                                size: 10, color: AppTheme.yellow),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
