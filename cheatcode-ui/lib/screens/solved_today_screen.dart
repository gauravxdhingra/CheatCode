import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SolvedTodayScreen extends StatefulWidget {
  const SolvedTodayScreen({super.key});

  @override
  State<SolvedTodayScreen> createState() => _SolvedTodayScreenState();
}

class _SolvedTodayScreenState extends State<SolvedTodayScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AppProvider>().userId;
    if (userId == null) return;
    try {
      final data = await ApiService.getSolvedToday(userId);
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markUnsolved(String problemId) async {
    await context.read<AppProvider>().markUnsolved(problemId);
    setState(() {
      _items.removeWhere((i) => i['problem_id'] == problemId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as unsolved',
              style: AppTheme.mono(size: 12, color: AppTheme.black)),
          backgroundColor: AppTheme.yellow,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  Text('✓ today',
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
                    'Solved Today',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '// tap to mark as unsolved',
                    style: AppTheme.mono(
                        size: 11,
                        color: AppTheme.white.withOpacity(0.3)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.green),
                ),
              )
            else if (_items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('✦', style: TextStyle(fontSize: 48, color: AppTheme.green)),
                      const SizedBox(height: 16),
                      Text('Nothing solved today yet',
                          style: AppTheme.mono(
                              size: 16,
                              color: AppTheme.white,
                              weight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Go solve something',
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
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = _items[i];
                    final problem = item['problems'] as Map<String, dynamic>?;
                    final problemId = item['problem_id'] as String;
                    final title = problem?['title'] as String? ?? 'Unknown';
                    final badge = problem?['company_badge'] as String? ?? '';
                    final pattern = problem?['pattern'] as String? ?? '';
                    final difficulty = problem?['difficulty'] as int? ?? 1;

                    final diffColor = difficulty == 1
                        ? AppTheme.green
                        : difficulty == 2
                            ? AppTheme.yellow
                            : AppTheme.red;

                    return GestureDetector(
                      onLongPress: () => _showUnsolvedDialog(problemId, title),
                      child: Container(
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
                                  Colors.transparent,
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
                                          title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w800),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(badge,
                                                style: AppTheme.mono(
                                                    size: 10,
                                                    color: AppTheme.green)),
                                            const SizedBox(width: 8),
                                            Text('// $pattern',
                                                style: AppTheme.mono(
                                                    size: 10,
                                                    color: AppTheme.white
                                                        .withOpacity(0.3))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        color:
                                            AppTheme.green.withOpacity(0.1),
                                        child: Text('✓ solved',
                                            style: AppTheme.mono(
                                                size: 9,
                                                color: AppTheme.green)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('hold to unsolved',
                                          style: AppTheme.mono(
                                              size: 8,
                                              color: AppTheme.white
                                                  .withOpacity(0.2))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  void _showUnsolvedDialog(String problemId, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.dim,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Mark as unsolved?',
            style: AppTheme.mono(
                size: 14, color: AppTheme.white, weight: FontWeight.bold)),
        content: Text(
          '"$title" will be removed from today\'s solved list and returned to your feed.',
          style:
              AppTheme.mono(size: 12, color: AppTheme.white.withOpacity(0.6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTheme.mono(
                    size: 12, color: AppTheme.white.withOpacity(0.4))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _markUnsolved(problemId);
            },
            child: Text('Mark Unsolved',
                style: AppTheme.mono(size: 12, color: AppTheme.red)),
          ),
        ],
      ),
    );
  }
}
