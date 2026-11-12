import 'dart:convert';

/// Modèle représentant une citation ou un conseil motivant sport-santé.
class DailyMotivation {
  final String quote;
  final String author;
  final String category;
  final DateTime? date;
  final bool isFromApi;

  const DailyMotivation({
    required this.quote,
    required this.author,
    this.category = 'Wellness & Motivation',
    this.date,
    this.isFromApi = false,
  });

  /// Crée une instance depuis le JSON renvoyé par l'API ZenQuotes :
  /// `[ { "q": "Citation...", "a": "Auteur...", "h": "..." } ]`
  factory DailyMotivation.fromZenQuotesJson(Map<String, dynamic> json, {DateTime? date}) {
    final rawQuote = (json['q'] as String?)?.trim();
    final rawAuthor = (json['a'] as String?)?.trim();

    return DailyMotivation(
      quote: (rawQuote != null && rawQuote.isNotEmpty)
          ? rawQuote
          : 'Every step counts towards your health and well-being.',
      author: (rawAuthor != null && rawAuthor.isNotEmpty) ? rawAuthor : 'ZenQuotes',
      category: 'Daily motivation',
      date: date ?? DateTime.now(),
      isFromApi: true,
    );
  }

  /// Conversion vers Map pour la persistance locale (SharedPreferences / Cache)
  Map<String, dynamic> toMap() {
    return {
      'quote': quote,
      'author': author,
      'category': category,
      'date': (date ?? DateTime.now()).toIso8601String(),
      'isFromApi': isFromApi ? 1 : 0,
    };
  }

  /// Création depuis une Map
  factory DailyMotivation.fromMap(Map<String, dynamic> map) {
    return DailyMotivation(
      quote: map['quote'] as String? ?? '',
      author: map['author'] as String? ?? 'MediTrack Tip',
      category: map['category'] as String? ?? 'Wellness & Motivation',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String)
          : null,
      isFromApi: (map['isFromApi'] is int)
          ? (map['isFromApi'] as int) == 1
          : (map['isFromApi'] as bool? ?? false),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DailyMotivation.fromJson(String source) =>
      DailyMotivation.fromMap(jsonDecode(source) as Map<String, dynamic>);

  DailyMotivation copyWith({
    String? quote,
    String? author,
    String? category,
    DateTime? date,
    bool? isFromApi,
  }) {
    return DailyMotivation(
      quote: quote ?? this.quote,
      author: author ?? this.author,
      category: category ?? this.category,
      date: date ?? this.date,
      isFromApi: isFromApi ?? this.isFromApi,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyMotivation &&
        other.quote == quote &&
        other.author == author &&
        other.category == category &&
        other.isFromApi == isFromApi;
  }

  @override
  int get hashCode =>
      quote.hashCode ^ author.hashCode ^ category.hashCode ^ isFromApi.hashCode;
}
