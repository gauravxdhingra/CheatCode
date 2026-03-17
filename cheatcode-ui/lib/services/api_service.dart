import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/problem.dart';

class ApiService {
  // Configure via --dart-define=BASE_URL=https://...
  // Falls back to Railway URL if not provided
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://cheatcode-production-498b.up.railway.app',
  );

  // Passed via --dart-define=API_KEY=xxx at build time
  static const String _apiKey =
      String.fromEnvironment('API_KEY', defaultValue: '');

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
  };

  static const String _cacheDurationHours = 'cache_duration_hours';
  static const int _cacheHours = 24;

  static String _feedCacheKey(String userId) => 'cached_feed_$userId';
  static String _feedTimestampKey(String userId) => 'cache_timestamp_$userId';

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<String> createUser({
    required String email,
    required String role,
    String? name,
    String? interviewDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'role': role,
        if (name != null) 'name': name,
        if (interviewDate != null) 'interview_date': interviewDate,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final userId = data['id'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      return userId;
    }

    if (response.statusCode == 409 || response.statusCode == 500) {
      return await _getUserByEmail(email);
    }

    throw Exception('Failed to create user: ${response.body}');
  }

  static Future<String> _getUserByEmail(String email) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/by-email/$email'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'] as String;
    }
    throw Exception('User not found');
  }

  // ── Feed ──────────────────────────────────────────────────────────────────

  static Future<List<Problem>> getFeed(String userId) async {
    final cached = await _getCachedFeed(userId);
    if (cached != null) return cached;

    final response = await http.get(
      Uri.parse('$baseUrl/feed/$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final problems = (data['problems'] as List)
          .map((p) => Problem.fromJson(p))
          .toList();
      await _cacheFeed(userId, response.body);
      return problems;
    }

    throw Exception('Failed to fetch feed: ${response.body}');
  }

  static Future<List<Problem>?> _getCachedFeed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_feedTimestampKey(userId));
    final cached = prefs.getString(_feedCacheKey(userId));
    if (timestamp == null || cached == null) return null;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > _cacheHours * 60 * 60 * 1000) return null;
    final data = jsonDecode(cached);
    return (data['problems'] as List).map((p) => Problem.fromJson(p)).toList();
  }

  static Future<void> _cacheFeed(String userId, String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedCacheKey(userId), rawJson);
    await prefs.setInt(
        _feedTimestampKey(userId), DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearFeedCache([String? userId]) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.remove(_feedCacheKey(userId));
      await prefs.remove(_feedTimestampKey(userId));
    } else {
      final keys = prefs.getKeys().where((k) =>
          k.startsWith('cached_feed_') || k.startsWith('cache_timestamp_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    }
  }

  // ── Answer validation ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> validateAnswer({
    required String userId,
    required String problemId,
    required String userAnswer,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/answers/$userId/validate'),
      headers: _headers,
      body: jsonEncode({
        'problem_id': problemId,
        'user_answer': userAnswer,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Validation failed: ${response.body}');
  }

  // ── Solved today ──────────────────────────────────────────────────────────

  static Future<List<dynamic>> getSolvedToday(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/answers/$userId/solved-today'),
      headers: _headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<void> markUnsolved({
    required String userId,
    required String problemId,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/answers/$userId/unsolved/$problemId'),
      headers: _headers,
    );
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
      Uri.parse('$baseUrl/progress/$userId'),
      headers: _headers,
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
      Uri.parse('$baseUrl/progress/$userId/streak'),
      headers: _headers,
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {'streak': 0, 'solved_today': 0};
  }

  static Future<List<String>> getSolvedIds(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/progress/$userId/solved-ids'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return List<String>.from(jsonDecode(response.body));
      }
    } catch (_) {}
    return [];
  }
}