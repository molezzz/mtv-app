import 'package:flutter/material.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/home_page.dart';
import 'package:mtv_app/src/features/tv_shows/presentation/pages/tv_shows_page.dart';
import 'package:mtv_app/src/features/records/presentation/pages/records_page.dart';
import 'package:mtv_app/src/features/favorites/presentation/pages/favorites_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MoviesPage(),
    const TvShowsPage(),
    const RecordsPage(),
    const FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.movie),
            label: localizations?.movies ?? 'Movies',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.tv),
            label: localizations?.tvShows ?? 'TV Shows',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: localizations?.records ?? 'Records',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite),
            label: localizations?.favorites ?? 'Favorites',
          ),
        ],
      ),
    );
  }
}