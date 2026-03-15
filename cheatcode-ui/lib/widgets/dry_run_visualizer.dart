import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DryRunStep {
  final String description;
  final List<int> highlightedIndices;
  final int windowStart;
  final int windowEnd;
  final Map<String, dynamic> variables;

  const DryRunStep({
    required this.description,
    required this.highlightedIndices,
    required this.windowStart,
    required this.windowEnd,
    required this.variables,
  });
}

/// Generates dry run steps for the sliding window max sum problem
List<DryRunStep> generateSlidingWindowSteps(List<int> nums, int k) {
  final steps = <DryRunStep>[];
  int sum = 0;

  // Build initial window
  for (int i = 0; i < k; i++) {
    sum += nums[i];
    steps.add(DryRunStep(
      description: 'Building initial window: add nums[$i] = ${nums[i]}',
      highlightedIndices: List.generate(i + 1, (j) => j),
      windowStart: 0,
      windowEnd: i,
      variables: {'sum': sum, 'max': sum, 'i': i},
    ));
  }

  int max = sum;
  steps.add(DryRunStep(
    description: 'Initial window complete. sum = $sum, max = $max',
    highlightedIndices: List.generate(k, (j) => j),
    windowStart: 0,
    windowEnd: k - 1,
    variables: {'sum': sum, 'max': max},
  ));

  // Slide
  for (int i = k; i < nums.length; i++) {
    final leaving = nums[i - k];
    final entering = nums[i];
    sum = sum + entering - leaving;
    max = sum > max ? sum : max;

    steps.add(DryRunStep(
      description:
          'Slide: +nums[$i]($entering) −nums[${i - k}]($leaving) → sum=$sum',
      highlightedIndices: List.generate(k, (j) => j + (i - k + 1)),
      windowStart: i - k + 1,
      windowEnd: i,
      variables: {
        'sum': sum,
        'max': max,
        'entering': entering,
        'leaving': leaving,
      },
    ));
  }

  steps.add(DryRunStep(
    description: 'Done. Max sum = $max',
    highlightedIndices: [],
    windowStart: -1,
    windowEnd: -1,
    variables: {'result': max},
  ));

  return steps;
}

class DryRunVisualizer extends StatefulWidget {
  final List<int> nums;
  final int k;

  const DryRunVisualizer({
    super.key,
    required this.nums,
    required this.k,
  });

  @override
  State<DryRunVisualizer> createState() => _DryRunVisualizerState();
}

class _DryRunVisualizerState extends State<DryRunVisualizer>
    with TickerProviderStateMixin {
  late List<DryRunStep> _steps;
  int _currentStep = 0;
  bool _playing = false;

  late AnimationController _highlightController;
  late Animation<double> _highlightAnim;

  @override
  void initState() {
    super.initState();
    _steps = generateSlidingWindowSteps(widget.nums, widget.k);

    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _highlightAnim = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    );
    _highlightController.forward();
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _highlightController.forward(from: 0);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _highlightController.forward(from: 0);
    }
  }

  void _reset() {
    setState(() => _currentStep = 0);
    _highlightController.forward(from: 0);
  }

  Future<void> _autoPlay() async {
    setState(() => _playing = true);
    while (_currentStep < _steps.length - 1 && _playing) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && _playing) {
        setState(() => _currentStep++);
        _highlightController.forward(from: 0);
      }
    }
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.dim,
        border: Border.all(color: AppTheme.mid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppTheme.mid)),
            ),
            child: Row(
              children: [
                const Text('▶',
                    style: TextStyle(
                        color: AppTheme.green, fontSize: 12)),
                const SizedBox(width: 8),
                Text(
                  'Dry Run — nums=${widget.nums}, k=${widget.k}',
                  style: AppTheme.mono(size: 11, color: AppTheme.green),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1}/${_steps.length}',
                  style: AppTheme.mono(
                      size: 10,
                      color: AppTheme.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),

          // Array visualization
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Array:',
                  style: AppTheme.mono(
                      size: 10,
                      color: AppTheme.white.withOpacity(0.35)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(widget.nums.length, (i) {
                    final isHighlighted =
                        step.highlightedIndices.contains(i);
                    final isEntering = step.variables['entering'] != null &&
                        i == step.windowEnd;
                    final isLeaving = step.variables['leaving'] != null &&
                        i == step.windowStart - 1;

                    Color bgColor = AppTheme.mid;
                    Color textColor = AppTheme.white.withOpacity(0.5);

                    if (isHighlighted) {
                      bgColor = AppTheme.green.withOpacity(0.2);
                      textColor = AppTheme.green;
                    }
                    if (isEntering) {
                      bgColor = AppTheme.green.withOpacity(0.4);
                      textColor = AppTheme.green;
                    }
                    if (isLeaving) {
                      bgColor = AppTheme.red.withOpacity(0.2);
                      textColor = AppTheme.red;
                    }

                    return AnimatedBuilder(
                      animation: _highlightAnim,
                      builder: (_, __) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(
                              color: isHighlighted
                                  ? AppTheme.green.withOpacity(0.5)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${widget.nums[i]}',
                                textAlign: TextAlign.center,
                                style: AppTheme.mono(
                                    size: 13,
                                    color: textColor,
                                    weight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '[$i]',
                                textAlign: TextAlign.center,
                                style: AppTheme.mono(
                                    size: 9,
                                    color: AppTheme.white
                                        .withOpacity(0.2)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // Window indicator arrows
                if (step.windowStart >= 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(widget.nums.length, (i) {
                      String label = '';
                      if (i == step.windowStart &&
                          i == step.windowEnd) {
                        label = '↑↑';
                      } else if (i == step.windowStart) {
                        label = '↑L';
                      } else if (i == step.windowEnd) {
                        label = 'R↑';
                      }
                      return Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(
                              size: 9,
                              color: AppTheme.green.withOpacity(0.6)),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),

          // Step description
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0D0D0D),
            child: Text(
              step.description,
              style: AppTheme.mono(
                  size: 12, color: AppTheme.white.withOpacity(0.7)),
            ),
          ),

          // Variables
          if (step.variables.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: step.variables.entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.green.withOpacity(0.06),
                      border: Border.all(
                          color: AppTheme.green.withOpacity(0.2)),
                    ),
                    child: Text(
                      '${e.key} = ${e.value}',
                      style: AppTheme.mono(
                          size: 11, color: AppTheme.green),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Progress bar
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _steps.length,
              backgroundColor: AppTheme.mid,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.green),
              minHeight: 2,
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ControlBtn(
                  label: '↺',
                  onTap: _reset,
                  enabled: _currentStep > 0,
                ),
                const SizedBox(width: 8),
                _ControlBtn(
                  label: '◀',
                  onTap: _prev,
                  enabled: _currentStep > 0 && !_playing,
                ),
                const SizedBox(width: 8),
                _ControlBtn(
                  label: _playing ? '⏸' : '▶',
                  onTap: _playing
                      ? () => setState(() => _playing = false)
                      : _autoPlay,
                  enabled: _currentStep < _steps.length - 1,
                  primary: true,
                ),
                const SizedBox(width: 8),
                _ControlBtn(
                  label: '▶|',
                  onTap: _next,
                  enabled:
                      _currentStep < _steps.length - 1 && !_playing,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool primary;

  const _ControlBtn({
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primary
              ? (enabled
                  ? AppTheme.green
                  : AppTheme.green.withOpacity(0.2))
              : AppTheme.mid,
          border: Border.all(
            color: primary
                ? Colors.transparent
                : enabled
                    ? AppTheme.white.withOpacity(0.1)
                    : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.mono(
            size: 13,
            color: primary
                ? AppTheme.black
                : enabled
                    ? AppTheme.white
                    : AppTheme.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}
