import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/problem.dart';

class ApiService {
  // Change this to your machine's IP when testing on physical device
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator
  static const String _baseUrl = 'http://localhost:8000';
  static const String _userIdKey = 'user_id';
  static const String _cachedFeedKey = 'cached_feed';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const int _cacheDurationHours = 24;

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String> createUser({
    required String email,
    required String role,
    String? interviewDate,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'role': role,
        if (interviewDate != null) 'interview_date': interviewDate,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userId = data['id'] as String;

      // Save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);

      return userId;
    }

    throw Exception('Failed to create user: ${response.body}');
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  static Future<List<Problem>> getFeed(String userId) async {
    // Check cache first
    final cached = await _getCachedFeed();
    if (cached != null) return cached;

    // Fetch from API
    final response = await http.get(
      Uri.parse('$_baseUrl/feed/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final problems = (data['problems'] as List)
          .map((p) => Problem.fromJson(p))
          .toList();

      // Cache it
      await _cacheFeed(response.body);

      return problems;
    }

    throw Exception('Failed to fetch feed: ${response.body}');
  }

  static Future<List<Problem>?> _getCachedFeed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);
    final cached = prefs.getString(_cachedFeedKey);

    if (timestamp == null || cached == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    final maxAge = _cacheDurationHours * 60 * 60 * 1000;

    if (age > maxAge) return null; // Cache expired

    final data = jsonDecode(cached);
    return (data['problems'] as List)
        .map((p) => Problem.fromJson(p))
        .toList();
  }

  static Future<void> _cacheFeed(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedFeedKey, rawJson);
    await prefs.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearFeedCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedFeedKey);
    await prefs.remove(_cacheTimestampKey);
  }

  // ── Progress ──────────────────────────────────────────────────────────────

  static Future<void> updateProgress({
    required String userId,
    required String problemId,
    required String status,
    int? timeToSolve,
    int hintsUsed = 0,
  }) async {
    await http.post(
      Uri.parse('$_baseUrl/progress/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'problem_id': problemId,
        'status': status,
        if (timeToSolve != null) 'time_to_solve': timeToSolve,
        'hints_used': hintsUsed,
      }),
    );
  }

  static Future<Map<String, dynamic>> getStreak(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/progress/$userId/streak'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {'streak': 0, 'solved_today': 0};
  }
}
