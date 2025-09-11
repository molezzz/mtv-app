abstract class FavoriteState {}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoritesLoaded extends FavoriteState {
  final List<FavoriteItem> favorites;

  FavoritesLoaded(this.favorites);
}

class FavoriteError extends FavoriteState {
  final String message;

  FavoriteError(this.message);
}

class FavoriteStatusChecked extends FavoriteState {
  final bool isFavorite;

  FavoriteStatusChecked(this.isFavorite);
}

class FavoriteItem {
  final String key;
  final String cover;
  final String title;
  final String sourceName;
  final int totalEpisodes;
  final String searchTitle;
  final String year;
  final int? saveTime;

  FavoriteItem({
    required this.key,
    required this.cover,
    required this.title,
    required this.sourceName,
    required this.totalEpisodes,
    required this.searchTitle,
    required this.year,
    this.saveTime,
  });
}
