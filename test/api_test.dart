import 'dart:convert';

import 'package:mtv_app/src/features/movies/data/models/douban_movie_model.dart';

void main() {
  // 模拟API响应
  final apiResponse = '''
  {
    "code": 200,
    "message": "获取成功",
    "list": [
      {
        "id": "36176467",
        "title": "小人物2",
        "poster": "https://img3.doubanio.com/view/photo/s_ratio_poster/public/p2921502283.jpg",
        "rate": "6.3",
        "year": ""
      },
      {
        "id": "36770063",
        "title": "天国与地狱",
        "poster": "https://img1.doubanio.com/view/photo/s_ratio_poster/public/p2923992779.jpg",
        "rate": "6.1",
        "year": ""
      }
    ]
  }
  ''';

  try {
    final data = json.decode(apiResponse) as Map<String, dynamic>;
    final movieList = data['list'] as List;
    
    print('API Response parsed successfully!');
    print('Movies count: ${movieList.length}');
    
    // 测试单个电影的解析
    for (var movieJson in movieList) {
      try {
        final movie = DoubanMovieModel.fromJson(movieJson);
        print('Movie: ${movie.title}, Rating: ${movie.rating}, Poster: ${movie.pic}');
      } catch (e) {
        print('Error parsing movie: $e');
        print('Movie JSON: $movieJson');
      }
    }
  } catch (e) {
    print('Error parsing API response: $e');
  }
}