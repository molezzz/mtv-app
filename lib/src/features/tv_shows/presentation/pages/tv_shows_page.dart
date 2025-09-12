import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/media_list_page.dart';

class TvShowsPage extends StatefulWidget {
  const TvShowsPage({super.key});

  @override
  State<TvShowsPage> createState() => _TvShowsPageState();
}

class _TvShowsPageState extends State<TvShowsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // 使用BlocProvider包装，确保MovieBloc可用
    return BlocProvider.value(
      value: context.read<MovieBloc>(),
      child: MediaListPage(
        mediaType: 'tv',
        title: localizations?.tvShows ?? 'TV Shows',
        defaultCategory: 'tv',
        categoryType: 'tv',
      ),
    );
  }
}
