import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../services/api_service.dart';

enum FeedState { idle, loading, loaded, error }

class AppProvider extends ChangeNotifier {
  UserRole? _role;
  String? _userId;
  int _streak = 0;
  int _currentIndex = 0;
  int _solvedToday = 0;
  List<Problem> _problems = [];
  FeedState _feedState = FeedState.idle;
  String? _errorMessage;

  final Set<String> _vaultIds = {};
  final Set<String> _solvedIds = {};

  // ── Getters ───────────────────────────────────────────────────────────────

  UserRole? get role => _role;
  String? get userId => _userId;
  int get streak => _streak;
  int get solvedToday => _solvedToday;
  FeedState get feedState => _feedState;
  String? get errorMessage => _errorMessage;
  List<Problem> get problems => _problems;

  Problem? get currentProblem =>
      _problems.isEmpty ? null : _problems[_currentIndex % _problems.length];

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<void> initUser({
    required String email,
    required UserRole role,
    String? interviewDate,
  }) async {
    _role = role;
    notifyListeners();

    try {
      _userId = await ApiService.createUser(
        email: email,
        role: role.name,
        interviewDate: interviewDate,
      );
      await loadFeed();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> tryRestoreSession() async {
    final savedId = await ApiService.getSavedUserId();
    if (savedId != null) {
      _userId = savedId;
      await loadFeed();
      await refreshStreak();
    }
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

  Future<void> markSolved(String id, {int? timeToSolve, int hintsUsed = 0}) async {
    if (!_solvedIds.contains(id)) {
      _solvedIds.add(id);
      _solvedToday++;
      _streak++;

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

  Future<void> refreshStreak() async {
    if (_userId == null) return;
    final data = await ApiService.getStreak(_userId!);
    _streak = data['streak'] as int? ?? _streak;
    _solvedToday = data['solved_today'] as int? ?? _solvedToday;
    notifyListeners();
  }

  bool isSolved(String id) => _solvedIds.contains(id);
  bool isInVault(String id) => _vaultIds.contains(id);
}
