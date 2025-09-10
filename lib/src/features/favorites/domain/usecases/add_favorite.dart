import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';
import 'package:mtv_app/src/features/favorites/domain/repositories/favorite_repository.dart';

class AddFavorite {
  final FavoriteRepository repository;

  AddFavorite(this.repository);

  Future<bool> call(String key, Favorite favorite) async {
    return await repository.addFavorite(key, favorite);
  }
}
