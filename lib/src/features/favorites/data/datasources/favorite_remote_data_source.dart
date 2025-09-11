import 'package:dio/dio.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';

abstract class FavoriteRemoteDataSource {
  Future<List<Favorite>> getFavorites();
  Future<bool> addFavorite(String key, Favorite favorite);
  Future<bool> deleteFavorite(String key);
  Future<Favorite?> getFavoriteStatus(String key);
}

class FavoriteRemoteDataSourceImpl implements FavoriteRemoteDataSource {
  final ApiClient apiClient;

  FavoriteRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<Favorite>> getFavorites() async {
    try {
      final response = await apiClient.dio.get('/api/favorites');
      final data = response.data as Map<String, dynamic>;

      List<Favorite> favorites = [];
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final favorite = Favorite.fromJson(value);
          favorites.add(favorite);
        }
      });

      return favorites;
    } on DioException catch (e) {
      throw Exception('Failed to load favorites: ${e.message}');
    }
  }

  @override
  Future<bool> addFavorite(String key, Favorite favorite) async {
    try {
      // 对key进行URL编码，确保特殊字符如"+"被正确处理
      final encodedKey = Uri.encodeComponent(key);
      final data = {
        'key': encodedKey,
        'favorite': favorite.toJson(),
      };

      final response = await apiClient.dio.post(
        '/api/favorites',
        data: data,
      );

      // 检查响应是否成功
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return responseData['success'] as bool? ?? false;
      }

      return false;
    } on DioException catch (e) {
      throw Exception('Failed to add favorite: ${e.message}');
    }
  }

  @override
  Future<bool> deleteFavorite(String key) async {
    try {
      // 对key进行URL编码，确保特殊字符如"+"被正确处理
      final encodedKey = Uri.encodeComponent(key);
      await apiClient.dio.delete('/api/favorites?key=$encodedKey');
      return true;
    } on DioException catch (e) {
      throw Exception('Failed to delete favorite: ${e.message}');
    }
  }

  @override
  Future<Favorite?> getFavoriteStatus(String key) async {
    try {
      // 对key进行URL编码，确保特殊字符如"+"被正确处理
      final encodedKey = Uri.encodeComponent(key);
      final response = await apiClient.dio.get('/api/favorites?key=$encodedKey');
      if (response.data != null) {
        return Favorite.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get favorite status: ${e.message}');
    }
  }
}
