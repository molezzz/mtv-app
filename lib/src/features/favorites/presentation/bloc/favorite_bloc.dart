import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_event.dart'
    as favorite_event;
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_state.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/get_favorites.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/delete_favorite.dart'
    as delete_usecase;
import 'package:mtv_app/src/features/favorites/domain/usecases/add_favorite.dart'
    as add_usecase;
import 'package:mtv_app/src/features/favorites/domain/usecases/get_favorite_status.dart';

class FavoriteBloc extends Bloc<favorite_event.FavoriteEvent, FavoriteState> {
  final GetFavorites getFavorites;
  final delete_usecase.DeleteFavorite deleteFavorite;
  final add_usecase.AddFavorite addFavorite;
  final GetFavoriteStatus getFavoriteStatus; // Add this line

  FavoriteBloc({
    required this.getFavorites,
    required this.deleteFavorite,
    required this.addFavorite,
    required this.getFavoriteStatus, // Add this line
  }) : super(FavoriteInitial()) {
    on<favorite_event.LoadFavorites>(_onLoadFavorites);
    on<favorite_event.DeleteFavorite>(_onDeleteFavorite);
    on<favorite_event.AddFavorite>(_onAddFavorite);
    on<favorite_event.CheckFavoriteStatus>(
        _onCheckFavoriteStatus); // Add this line
  }

  Future<void> _onLoadFavorites(
    favorite_event.LoadFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(FavoriteLoading());
    try {
      final favorites = await getFavorites();
      final favoriteItems = favorites
          .map((f) => FavoriteItem(
                // NOTE: 当前后端未返回 key，这里临时用组合字段；
                // 列表展示不影响新增/删除逻辑（删除场景另行计算 key）。
                key: '${f.searchTitle}_${f.sourceName}',
                cover: f.cover,
                title: f.title,
                sourceName: f.sourceName,
                totalEpisodes: f.totalEpisodes,
                searchTitle: f.searchTitle,
                year: f.year ?? '',
                saveTime: f.saveTime,
              ))
          .toList();
      emit(FavoritesLoaded(favoriteItems));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _onDeleteFavorite(
    favorite_event.DeleteFavorite event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final ok = await deleteFavorite(event.key);
      if (ok) {
        add(favorite_event.LoadFavorites());
      } else {
        emit(FavoriteError('Failed to delete favorite'));
      }
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _onAddFavorite(
    favorite_event.AddFavorite event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final ok = await addFavorite(event.key, event.favorite);
      if (ok) {
        add(favorite_event.LoadFavorites());
      } else {
        emit(FavoriteError('Failed to add favorite'));
      }
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }

  Future<void> _onCheckFavoriteStatus(
    favorite_event.CheckFavoriteStatus event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final favorite = await getFavoriteStatus(event.key);
      emit(FavoriteStatusChecked(favorite != null));
    } catch (e) {
      emit(FavoriteError(e.toString()));
    }
  }
}
