import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final solved = provider.problems
        .where((p) => provider.isSolved(p.id))
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
                    child: Text('← back',
                        style: AppTheme.mono(
                            size: 12,
                            color: AppTheme.white.withOpacity(0.4))),
                  ),
                  const Spacer(),
                  Text('📋 history',
                      style: AppTheme.mono(
                          size: 14,
                          color: AppTheme.green,
                          weight: FontWeight.bold)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solved Problems',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '// ${solved.length} problems solved',
                    style: AppTheme.mono(
                        size: 11, color: AppTheme.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (solved.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No solved problems yet',
                          style: AppTheme.mono(
                              size: 16,
                              color: AppTheme.white,
                              weight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Solve problems to build your history',
                          style: AppTheme.mono(
                              size: 12,
                              color: AppTheme.white.withOpacity(0.35))),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: solved.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final problem = solved[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.dim,
                        border: Border.all(
                            color: AppTheme.green.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 2,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [
                                AppTheme.green,
                                Colors.transparent
                              ]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        problem.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                                fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(problem.companyBadge,
                                              style: AppTheme.mono(
                                                  size: 10,
                                                  color: AppTheme.green)),
                                          const SizedBox(width: 10),
                                          Text('// ${problem.pattern}',
                                              style: AppTheme.mono(
                                                  size: 10,
                                                  color: AppTheme.white
                                                      .withOpacity(0.3))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  color: AppTheme.green.withOpacity(0.1),
                                  child: Text('✓ solved',
                                      style: AppTheme.mono(
                                          size: 10, color: AppTheme.green)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
