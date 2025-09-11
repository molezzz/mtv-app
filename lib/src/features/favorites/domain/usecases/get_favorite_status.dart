import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';
import 'package:mtv_app/src/features/favorites/domain/repositories/favorite_repository.dart';

class GetFavoriteStatus {
  final FavoriteRepository repository;

  GetFavoriteStatus(this.repository);

  Future<Favorite?> call(String key) async {
    return await repository.getFavoriteStatus(key);
  }
}
