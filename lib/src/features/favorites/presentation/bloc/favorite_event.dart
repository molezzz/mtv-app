import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';

abstract class FavoriteEvent {}

class LoadFavorites extends FavoriteEvent {}

class DeleteFavorite extends FavoriteEvent {
  final String key;

  DeleteFavorite(this.key);
}

class AddFavorite extends FavoriteEvent {
  final String key;
  final Favorite favorite;

  AddFavorite(this.key, this.favorite);
}
