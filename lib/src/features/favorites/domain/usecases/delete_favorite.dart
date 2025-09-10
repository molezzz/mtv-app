import 'package:mtv_app/src/features/favorites/domain/repositories/favorite_repository.dart';

class DeleteFavorite {
  final FavoriteRepository repository;

  DeleteFavorite(this.repository);

  Future<bool> call(String key) async {
    return await repository.deleteFavorite(key);
  }
}
