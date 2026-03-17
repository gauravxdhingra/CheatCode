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

List<DryRunStep> generateSlidingWindowSteps(List<int> nums, int k) {
  final steps = <DryRunStep>[];
  int sum = 0;

  for (int i = 0; i < k; i++) {
    sum += nums[i];
    steps.add(DryRunStep(
      description: 'Step ${i + 1}: Add nums[$i] = ${nums[i]}  →  sum = $sum',
      highlightedIndices: List.generate(i + 1, (j) => j),
      windowStart: 0,
      windowEnd: i,
      variables: {'sum': sum, 'max': sum},
    ));
  }

  int max = sum;
  steps.add(DryRunStep(
    description: 'Initial window ready. sum = $sum → max = $max',
    highlightedIndices: List.generate(k, (j) => j),
    windowStart: 0,
    windowEnd: k - 1,
    variables: {'sum': sum, 'max': max},
  ));

  for (int i = k; i < nums.length; i++) {
    final leaving = nums[i - k];
    final entering = nums[i];
    sum = sum + entering - leaving;
    max = sum > max ? sum : max;

    steps.add(DryRunStep(
      description:
          'Slide: +nums[$i]($entering)  −nums[${i - k}]($leaving)  →  sum=$sum  max=$max',
      highlightedIndices: List.generate(k, (j) => j + (i - k + 1)),
      windowStart: i - k + 1,
      windowEnd: i,
      variables: {
        'sum': sum,
        'max': max,
        '+ entering': entering,
        '- leaving': leaving,
      },
    ));
  }

  steps.add(DryRunStep(
    description: '✓ Done.  Max sum = $max',
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

  // Slower speeds
  static const _speeds = {
    '0.5×': 2400,
    '1×': 1600,
    '2×': 800,
  };
  String _selectedSpeed = '1×';

  late AnimationController _highlightController;
  late Animation<double> _highlightAnim;

  @override
  void initState() {
    super.initState();
    _steps = generateSlidingWindowSteps(widget.nums, widget.k);
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _highlightAnim = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOut,
    );
    _highlightController.forward();
  }

  @override
  void dispose() {
    _playing = false;
    _highlightController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _steps.length) return;
    setState(() => _currentStep = index);
    _highlightController.forward(from: 0);
  }

  Future<void> _autoPlay() async {
    setState(() => _playing = true);
    while (_currentStep < _steps.length - 1 && _playing && mounted) {
      await Future.delayed(
          Duration(milliseconds: _speeds[_selectedSpeed] ?? 1600));
      if (mounted && _playing) {
        setState(() => _currentStep++);
        _highlightController.forward(from: 0);
      }
    }
    if (mounted) setState(() => _playing = false);
  }

  void _pause() => setState(() => _playing = false);

  void _reset() {
    setState(() {
      _playing = false;
      _currentStep = 0;
    });
    _highlightController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _steps.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: AppTheme.mid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.mid)),
            ),
            child: Row(
              children: [
                Text('▶  Dry Run',
                    style: AppTheme.mono(size: 11, color: AppTheme.green)),
                const SizedBox(width: 8),
                Text('nums=${widget.nums}  k=${widget.k}',
                    style: AppTheme.mono(
                        size: 10, color: AppTheme.white.withOpacity(0.3))),
                const Spacer(),
                Text(
                  '${_currentStep + 1} / ${_steps.length}',
                  style: AppTheme.mono(
                      size: 10, color: AppTheme.white.withOpacity(0.3)),
                ),
              ],
            ),
          ),

          // Array visualization
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('array:',
                    style: AppTheme.mono(
                        size: 9, color: AppTheme.white.withOpacity(0.3))),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(widget.nums.length, (i) {
                    final isInWindow = step.highlightedIndices.contains(i);
                    final isEntering =
                        step.windowEnd == i && step.windowStart > 0;
                    final isLeaving = i == step.windowStart - 1 &&
                        step.variables.containsKey('- leaving');

                    Color bg = AppTheme.mid;
                    Color fg = AppTheme.white.withOpacity(0.4);
                    Color border = Colors.transparent;

                    if (isLeaving) {
                      bg = AppTheme.red.withOpacity(0.15);
                      fg = AppTheme.red;
                      border = AppTheme.red.withOpacity(0.5);
                    } else if (isEntering) {
                      bg = AppTheme.green.withOpacity(0.25);
                      fg = AppTheme.green;
                      border = AppTheme.green;
                    } else if (isInWindow) {
                      bg = AppTheme.green.withOpacity(0.12);
                      fg = AppTheme.green;
                      border = AppTheme.green.withOpacity(0.4);
                    }

                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: bg,
                          border: Border.all(color: border, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Text(
                              '${widget.nums[i]}',
                              textAlign: TextAlign.center,
                              style: AppTheme.mono(
                                  size: 14,
                                  color: fg,
                                  weight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '[$i]',
                              textAlign: TextAlign.center,
                              style: AppTheme.mono(
                                  size: 8,
                                  color: AppTheme.white.withOpacity(0.2)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                // Window arrows
                if (step.windowStart >= 0 && step.windowEnd >= 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(widget.nums.length, (i) {
                      String label = '';
                      if (i == step.windowStart && i == step.windowEnd)
                        label = '↑↑';
                      else if (i == step.windowStart)
                        label = 'L↑';
                      else if (i == step.windowEnd)
                        label = '↑R';
                      return Expanded(
                        child: Text(label,
                            textAlign: TextAlign.center,
                            style: AppTheme.mono(
                                size: 9,
                                color: AppTheme.green.withOpacity(0.5))),
                      );
                    }),
                  ),
                ],

                const SizedBox(height: 14),

                // Step description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppTheme.dim,
                  child: Text(
                    step.description,
                    style: AppTheme.mono(
                        size: 12, color: AppTheme.white.withOpacity(0.8)),
                  ),
                ),

                // Variables
                if (step.variables.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: step.variables.entries.map((e) {
                      final isResult = e.key == 'result' || e.key == 'max';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isResult
                              ? AppTheme.green.withOpacity(0.1)
                              : AppTheme.dim,
                          border: Border.all(
                            color: isResult
                                ? AppTheme.green.withOpacity(0.4)
                                : AppTheme.mid,
                          ),
                        ),
                        child: Text(
                          '${e.key} = ${e.value}',
                          style: AppTheme.mono(
                            size: 11,
                            color: isResult
                                ? AppTheme.green
                                : AppTheme.white.withOpacity(0.6),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),

                // Progress bar
                ClipRRect(
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _steps.length,
                    backgroundColor: AppTheme.mid,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.green),
                    minHeight: 2,
                  ),
                ),

                const SizedBox(height: 14),

                // Controls
                Row(
                  children: [
                    // Reset
                    _CtrlBtn(
                      label: '↺',
                      tooltip: 'Reset',
                      enabled: !isFirst,
                      onTap: _reset,
                    ),
                    const SizedBox(width: 8),

                    // Previous
                    _CtrlBtn(
                      label: '◀',
                      tooltip: 'Previous',
                      enabled: !isFirst && !_playing,
                      onTap: () => _goTo(_currentStep - 1),
                    ),
                    const SizedBox(width: 8),

                    // Play / Pause
                    _CtrlBtn(
                      label: _playing ? '⏸  Pause' : '▶  Play',
                      tooltip: _playing ? 'Pause' : 'Play',
                      enabled: !isLast || _playing,
                      primary: true,
                      onTap: _playing ? _pause : _autoPlay,
                    ),
                    const SizedBox(width: 8),

                    // Next
                    _CtrlBtn(
                      label: '▶|',
                      tooltip: 'Next step',
                      enabled: !isLast && !_playing,
                      onTap: () => _goTo(_currentStep + 1),
                    ),

                    const Spacer(),

                    // Speed selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.mid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _speeds.keys.map((speed) {
                          final selected = speed == _selectedSpeed;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedSpeed = speed),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              color: selected
                                  ? AppTheme.green.withOpacity(0.15)
                                  : Colors.transparent,
                              child: Text(
                                speed,
                                style: AppTheme.mono(
                                  size: 10,
                                  color: selected
                                      ? AppTheme.green
                                      : AppTheme.white.withOpacity(0.35),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  const _CtrlBtn({
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: primary
                ? (enabled ? AppTheme.green : AppTheme.green.withOpacity(0.2))
                : (enabled ? AppTheme.dim : Colors.transparent),
            border: Border.all(
              color: primary
                  ? Colors.transparent
                  : enabled
                      ? AppTheme.mid
                      : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.mono(
              size: 12,
              color: primary
                  ? (enabled ? AppTheme.black : AppTheme.black.withOpacity(0.3))
                  : (enabled
                      ? AppTheme.white
                      : AppTheme.white.withOpacity(0.2)),
              weight: primary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
