import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum FeedState { idle, loading, loaded, error }

class PatternStat {
  final String patternName;
  final int timesEncountered;
  final int timesSolved;
  final bool owned;

  PatternStat({
    required this.patternName,
    required this.timesEncountered,
    required this.timesSolved,
    required this.owned,
  });
}

class AppProvider extends ChangeNotifier {
  UserRole? _role;
  String? _userId;
  String? _userName;
  int _streak = 0;
  int _currentIndex = 0;
  int _solvedToday = 0;
  List<Problem> _problems = [];
  FeedState _feedState = FeedState.idle;
  String? _errorMessage;

  final Set<String> _vaultIds = {};
  final Set<String> _solvedIds = {};
  final Map<String, PatternStat> _patternStats = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  UserRole? get role => _role;
  String? get userId => _userId;
  String? get userName => _userName;
  int get streak => _streak;
  int get solvedToday => _solvedToday;
  FeedState get feedState => _feedState;
  String? get errorMessage => _errorMessage;
  List<Problem> get problems => _problems;
  List<PatternStat> get patternStats => _patternStats.values.toList()
    ..sort((a, b) => b.timesSolved.compareTo(a.timesSolved));

  Problem? get currentProblem =>
      _problems.isEmpty ? null : _problems[_currentIndex % _problems.length];

  List<Problem> get solvedProblems =>
      _problems.where((p) => _solvedIds.contains(p.id)).toList();

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> initUser({
    required String email,
    required UserRole role,
    String? name,
    String? interviewDate,
  }) async {
    _role = role;
    _userName = name;
    notifyListeners();
    try {
      _userId = await ApiService.createUser(
        email: email,
        role: role.name,
        name: name,
        interviewDate: interviewDate,
      );
      await AuthService.saveSession(
        userId: _userId!,
        email: email,
        name: name ?? 'Engineer',
      );
      await loadFeed();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> tryRestoreSession() async {
    final session = await AuthService.getSavedSession();
    if (session == null) return;
    _userId = session.userId;
    _userName = session.name;
    await loadFeed();
    try {
      await refreshStreak();
    } catch (_) {}
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    await ApiService.clearFeedCache();
    _userId = null;
    _userName = null;
    _role = null;
    _problems = [];
    _streak = 0;
    _solvedToday = 0;
    _currentIndex = 0;
    _vaultIds.clear();
    _solvedIds.clear();
    _patternStats.clear();
    _feedState = FeedState.idle;
    notifyListeners();
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  Future<void> loadFeed() async {
    if (_userId == null) return;
    _feedState = FeedState.loading;
    notifyListeners();
    try {
      _problems = await ApiService.getFeed(_userId!);
      _currentIndex = 0;
      _feedState = FeedState.loaded;
    } catch (e) {
      _feedState = FeedState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void nextProblem() {
    _currentIndex++;
    notifyListeners();
  }

  void skipProblem() {
    if (_userId != null && currentProblem != null) {
      ApiService.updateProgress(
        userId: _userId!,
        problemId: currentProblem!.id,
        status: 'skipped',
      );
    }
    _currentIndex++;
    notifyListeners();
  }

  void saveToVault(String id) {
    _vaultIds.add(id);
    if (_userId != null) {
      ApiService.updateProgress(
        userId: _userId!,
        problemId: id,
        status: 'vaulted',
      );
    }
    _currentIndex++;
    notifyListeners();
  }

  void setCurrentProblemById(String id) {
    final index = _problems.indexWhere((p) => p.id == id);
    if (index != -1) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // ── Solved / Unsolved ─────────────────────────────────────────────────────

  /// Called by feed_screen after server validates the answer
  void markSolvedLocally(String id) {
    if (!_solvedIds.contains(id)) {
      _solvedIds.add(id);
      _solvedToday++;
      _streak++;
      final problem = _problems.firstWhere(
        (p) => p.id == id,
        orElse: () => _problems.first,
      );
      _updateLocalPatternStat(problem.pattern);
      notifyListeners();
      // Refresh streak from server async
      refreshStreak().catchError((_) {});
    }
  }

  /// Legacy — still used by vault screen
  Future<void> markSolved(String id,
      {int? timeToSolve, int hintsUsed = 0}) async {
    if (!_solvedIds.contains(id)) {
      _solvedIds.add(id);
      _solvedToday++;
      _streak++;
      final problem = _problems.firstWhere(
        (p) => p.id == id,
        orElse: () => _problems.first,
      );
      _updateLocalPatternStat(problem.pattern);
      if (_userId != null) {
        await ApiService.updateProgress(
          userId: _userId!,
          problemId: id,
          status: 'solved',
          timeToSolve: timeToSolve,
          hintsUsed: hintsUsed,
        );
        await refreshStreak();
      }
    }
    notifyListeners();
  }

  Future<void> markUnsolved(String id) async {
    _solvedIds.remove(id);
    if (_solvedToday > 0) _solvedToday--;

    // Revert local pattern stat
    final problem = _problems.firstWhere(
      (p) => p.id == id,
      orElse: () => _problems.first,
    );
    final existing = _patternStats[problem.pattern];
    if (existing != null && existing.timesSolved > 0) {
      final newSolved = existing.timesSolved - 1;
      _patternStats[problem.pattern] = PatternStat(
        patternName: problem.pattern,
        timesEncountered: existing.timesEncountered,
        timesSolved: newSolved,
        owned: newSolved >= 5,
      );
    }

    if (_userId != null) {
      try {
        await ApiService.markUnsolved(
          userId: _userId!,
          problemId: id,
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  void _updateLocalPatternStat(String pattern) {
    final existing = _patternStats[pattern];
    if (existing != null) {
      final newSolved = existing.timesSolved + 1;
      _patternStats[pattern] = PatternStat(
        patternName: pattern,
        timesEncountered: existing.timesEncountered + 1,
        timesSolved: newSolved,
        owned: newSolved >= 5,
      );
    } else {
      _patternStats[pattern] = PatternStat(
        patternName: pattern,
        timesEncountered: 1,
        timesSolved: 1,
        owned: false,
      );
    }
  }

  Future<void> refreshStreak() async {
    if (_userId == null) return;
    try {
      final data = await ApiService.getStreak(_userId!);
      _streak = data['streak'] as int? ?? _streak;
      _solvedToday = data['solved_today'] as int? ?? _solvedToday;
      notifyListeners();
    } catch (_) {}
  }

  bool isSolved(String id) => _solvedIds.contains(id);
  bool isInVault(String id) => _vaultIds.contains(id);
}
