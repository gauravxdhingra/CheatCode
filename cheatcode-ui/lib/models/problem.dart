import 'dart:convert';

class CodeLine {
  final String text;
  final bool isBlank;
  final String? blankAnswer;

  const CodeLine({
    required this.text,
    this.isBlank = false,
    this.blankAnswer,
  });

  factory CodeLine.fromJson(Map<String, dynamic> json) {
    final isBlank = json['is_blank'];
    return CodeLine(
      text: json['text'] as String? ?? '',
      isBlank: isBlank == true || isBlank == 'true',
      blankAnswer: json['blank_answer'] as String?,
    );
  }
}

class Problem {
  final String id;
  final String title;
  final String company;
  final String companyBadge;
  final String pattern;
  final String patternDescription;
  final String problemStatement;
  final List<String> relatedPatterns;
  final List<CodeLine> codeLines;
  final String explanation;
  final String bruteForce;
  final String optimised;
  final String bruteComplexity;
  final String optimisedComplexity;
  final int difficulty;
  final List<String> hints;
  final List<String> wrongOptions;

  const Problem({
    required this.id,
    required this.title,
    required this.company,
    required this.companyBadge,
    required this.pattern,
    this.patternDescription = '',
    this.problemStatement = '',
    required this.relatedPatterns,
    required this.codeLines,
    required this.explanation,
    required this.bruteForce,
    required this.optimised,
    required this.bruteComplexity,
    required this.optimisedComplexity,
    required this.difficulty,
    required this.hints,
    this.wrongOptions = const [],
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    List<dynamic> _parse(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw;
      if (raw is String) {
        try { return jsonDecode(raw) as List<dynamic>; } catch (_) { return []; }
      }
      return [];
    }

    return Problem(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      companyBadge: json['company_badge'] as String,
      pattern: json['pattern'] as String,
      patternDescription: json['pattern_description'] as String? ?? '',
      problemStatement: json['problem_statement'] as String? ?? '',
      relatedPatterns: _parse(json['related_patterns']).map((e) => e as String).toList(),
      codeLines: _parse(json['code_lines'])
          .map((e) => CodeLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanation: json['explanation'] as String,
      bruteForce: json['brute_force'] as String,
      optimised: json['optimised'] as String,
      bruteComplexity: json['brute_complexity'] as String,
      optimisedComplexity: json['optimised_complexity'] as String,
      difficulty: json['difficulty'] as int,
      hints: _parse(json['hints']).map((e) => e as String).toList(),
      wrongOptions: _parse(json['wrong_options']).map((e) => e as String).toList(),
    );
  }

  List<String> get multipleChoiceOptions {
    if (wrongOptions.isEmpty) return [];
    final blank = codeLines.firstWhere(
      (l) => l.isBlank,
      orElse: () => const CodeLine(text: ''),
    );
    if (blank.blankAnswer == null) return [];
    final options = [blank.blankAnswer!, ...wrongOptions.take(3)];
    options.shuffle();
    return options;
  }

  String get difficultyLabel =>
      difficulty == 1 ? 'Easy' : difficulty == 2 ? 'Medium' : 'Hard';
}

enum SwipeDirection { right, left, up, down }

enum UserRole { student, professional, competitive }
