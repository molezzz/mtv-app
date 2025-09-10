import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';
import 'package:mtv_app/src/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:mtv_app/src/features/favorites/data/datasources/favorite_remote_data_source.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteRemoteDataSource remoteDataSource;

  FavoriteRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Favorite>> getFavorites() async {
    return await remoteDataSource.getFavorites();
  }

  @override
  Future<bool> addFavorite(String key, Favorite favorite) async {
    return await remoteDataSource.addFavorite(key, favorite);
  }

  @override
  Future<bool> deleteFavorite(String key) async {
    return await remoteDataSource.deleteFavorite(key);
  }
}
