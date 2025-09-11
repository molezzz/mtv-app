import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_bloc.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_event.dart';
import 'package:mtv_app/src/features/favorites/presentation/bloc/favorite_state.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/get_favorites.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/delete_favorite.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/add_favorite.dart';
import 'package:mtv_app/src/features/favorites/domain/usecases/get_favorite_status.dart';
import 'package:mtv_app/src/features/favorites/domain/entities/favorite.dart';

@GenerateMocks([
  GetFavorites,
  DeleteFavorite,
  AddFavorite,
  GetFavoriteStatus,
])
import 'favorite_bloc_test.mocks.dart';

void main() {
  group('FavoriteBloc', () {
    late MockGetFavorites mockGetFavorites;
    late MockDeleteFavorite mockDeleteFavorite;
    late MockAddFavorite mockAddFavorite;
    late MockGetFavoriteStatus mockGetFavoriteStatus;
    late FavoriteBloc bloc;

    setUp(() {
      mockGetFavorites = MockGetFavorites();
      mockDeleteFavorite = MockDeleteFavorite();
      mockAddFavorite = MockAddFavorite();
      mockGetFavoriteStatus = MockGetFavoriteStatus();
      bloc = FavoriteBloc(
        getFavorites: mockGetFavorites,
        deleteFavorite: mockDeleteFavorite,
        addFavorite: mockAddFavorite,
        getFavoriteStatus: mockGetFavoriteStatus,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is FavoriteInitial', () {
      expect(bloc.state, equals(FavoriteInitial()));
    });

    group('LoadFavorites', () {
      test('emits [FavoriteLoading, FavoritesLoaded] when successful', () async {
        final favorites = [
          Favorite(
            cover: 'cover1',
            title: 'Title 1',
            sourceName: 'Source 1',
            totalEpisodes: 10,
            searchTitle: 'Search Title 1',
            year: '2023',
            saveTime: 1234567890,
          )
        ];

        when(mockGetFavorites()).thenAnswer((_) async => favorites);

        final expected = [
          FavoriteInitial(),
          FavoriteLoading(),
          FavoritesLoaded([
            FavoriteItem(
              key: 'Search Title 1_Source 1',
              cover: 'cover1',
              title: 'Title 1',
              sourceName: 'Source 1',
              totalEpisodes: 10,
              searchTitle: 'Search Title 1',
              year: '2023',
              saveTime: 1234567890,
            )
          ]),
        ];

        expectLater(bloc.stream, emitsInOrder(expected));
        bloc.add(LoadFavorites());
        await untilCalled(mockGetFavorites());
      });
    });

    group('DeleteFavorite', () {
      test('emits updated FavoritesLoaded state when successful', () async {
        // First load some favorites
        final favorites = [
          FavoriteItem(
            key: 'key1',
            cover: 'cover1',
            title: 'Title 1',
            sourceName: 'Source 1',
            totalEpisodes: 10,
            searchTitle: 'Search Title 1',
            year: '2023',
            saveTime: 1234567890,
          ),
          FavoriteItem(
            key: 'key2',
            cover: 'cover2',
            title: 'Title 2',
            sourceName: 'Source 2',
            totalEpisodes: 5,
            searchTitle: 'Search Title 2',
            year: '2022',
            saveTime: 1234567891,
          )
        ];

        // Set initial state
        bloc.emit(FavoritesLoaded(favorites));

        when(mockDeleteFavorite('key1')).thenAnswer((_) async => true);

        final expected = [
          FavoritesLoaded([favorites[1]]), // Only key2 should remain
        ];

        expectLater(bloc.stream, emitsInOrder(expected));
        bloc.add(DeleteFavorite('key1'));
        await untilCalled(mockDeleteFavorite('key1'));
      });
    });

    group('AddFavorite', () {
      test('emits updated FavoritesLoaded state when successful', () async {
        // First load some favorites
        final existingFavorites = [
          FavoriteItem(
            key: 'key1',
            cover: 'cover1',
            title: 'Title 1',
            sourceName: 'Source 1',
            totalEpisodes: 10,
            searchTitle: 'Search Title 1',
            year: '2023',
            saveTime: 1234567890,
          )
        ];

        final newFavorite = Favorite(
          cover: 'cover2',
          title: 'Title 2',
          sourceName: 'Source 2',
          totalEpisodes: 5,
          searchTitle: 'Search Title 2',
          year: '2022',
          saveTime: 1234567891,
        );

        // Set initial state
        bloc.emit(FavoritesLoaded(existingFavorites));

        when(mockAddFavorite('key2', newFavorite)).thenAnswer((_) async => true);

        final expected = [
          FavoritesLoaded([
            existingFavorites[0],
            FavoriteItem(
              key: 'key2',
              cover: 'cover2',
              title: 'Title 2',
              sourceName: 'Source 2',
              totalEpisodes: 5,
              searchTitle: 'Search Title 2',
              year: '2022',
              saveTime: 1234567891,
            )
          ]),
        ];

        expectLater(bloc.stream, emitsInOrder(expected));
        bloc.add(AddFavorite('key2', newFavorite));
        await untilCalled(mockAddFavorite('key2', newFavorite));
      });
    });
  });
}