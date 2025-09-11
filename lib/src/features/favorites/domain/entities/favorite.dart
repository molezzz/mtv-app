class Favorite {
  final String cover;
  final String title;
  final String sourceName;
  final int totalEpisodes;
  final String searchTitle;
  final String? year;
  final int? saveTime;

  Favorite({
    required this.cover,
    required this.title,
    required this.sourceName,
    required this.totalEpisodes,
    required this.searchTitle,
    this.year,
    this.saveTime,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      cover: json['cover'] as String,
      title: json['title'] as String,
      sourceName: json['source_name'] as String,
      totalEpisodes: json['total_episodes'] as int,
      searchTitle: json['search_title'] as String? ?? json['title'] as String,
      year: json['year'] as String?,
      saveTime: json['save_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cover': cover,
      'title': title,
      'source_name': sourceName,
      'total_episodes': totalEpisodes,
      'search_title': searchTitle,
      'year': year,
      'save_time': saveTime,
    };
  }
}
