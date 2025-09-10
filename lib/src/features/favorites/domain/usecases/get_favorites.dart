import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';
import 'package:mtv_app/src/features/favorites/domain/repositories/favorite_repository.dart';

class GetFavorites {
  final FavoriteRepository repository;

  GetFavorites(this.repository);

  Future<List<Favorite>> call() async {
    return await repository.getFavorites();
  }
}
