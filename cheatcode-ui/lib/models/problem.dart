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
    return CodeLine(
      text: json['text'] as String? ?? '',
      isBlank: json['is_blank'] as bool? ?? false,
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
  final List<String> relatedPatterns;
  final List<CodeLine> codeLines;
  final String explanation;
  final String bruteForce;
  final String optimised;
  final String bruteComplexity;
  final String optimisedComplexity;
  final int difficulty;
  final List<String> hints;

  const Problem({
    required this.id,
    required this.title,
    required this.company,
    required this.companyBadge,
    required this.pattern,
    this.patternDescription = '',
    required this.relatedPatterns,
    required this.codeLines,
    required this.explanation,
    required this.bruteForce,
    required this.optimised,
    required this.bruteComplexity,
    required this.optimisedComplexity,
    required this.difficulty,
    required this.hints,
  });

  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      companyBadge: json['company_badge'] as String,
      pattern: json['pattern'] as String,
      patternDescription: json['pattern_description'] as String? ?? '',
      relatedPatterns: (json['related_patterns'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      codeLines: (json['code_lines'] as List<dynamic>)
          .map((e) => CodeLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanation: json['explanation'] as String,
      bruteForce: json['brute_force'] as String,
      optimised: json['optimised'] as String,
      bruteComplexity: json['brute_complexity'] as String,
      optimisedComplexity: json['optimised_complexity'] as String,
      difficulty: json['difficulty'] as int,
      hints: (json['hints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  String get difficultyLabel =>
      difficulty == 1 ? 'Easy' : difficulty == 2 ? 'Medium' : 'Hard';
}

enum SwipeDirection { right, left, up, down }

enum UserRole { student, professional, competitive }
