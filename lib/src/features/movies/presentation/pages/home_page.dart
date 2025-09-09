import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_event.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_state.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/features/settings/presentation/pages/settings_page.dart';
import 'package:mtv_app/src/core/widgets/language_selector.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({super.key});

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  @override
  void initState() {
    super.initState();
    context.read<MovieBloc>().add(FetchPopularMovies());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.popularMovies ?? 'Popular Movies'),
        actions: [
          const LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onSettingsSaved: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MovieBloc, MovieState>(
        builder: (context, state) {
          if (state is MovieLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.loading ?? 'Loading...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          } else if (state is MovieLoaded) {
            return ListView.builder(
              itemCount: state.movies.length,
              itemBuilder: (context, index) {
                final movie = state.movies[index];
                return ListTile(
                  leading: Image.network(
                    'https://image.tmdb.org/t/p/w500/${movie.posterPath}',
                  ),
                  title: Text(movie.title),
                  subtitle: Text(movie.overview),
                );
              },
            );
          } else if (state is MovieError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)?.error ?? 'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MovieBloc>().add(FetchPopularMovies());
                    },
                    child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          } else {
            return Center(
              child: Text(
                AppLocalizations.of(context)?.loading ?? 'Loading...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          }
        },
      ),
    );
  }
}
