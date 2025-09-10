import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';

abstract class FavoriteRepository {
  Future<List<Favorite>> getFavorites();
  Future<bool> addFavorite(String key, Favorite favorite);
  Future<bool> deleteFavorite(String key);
}
