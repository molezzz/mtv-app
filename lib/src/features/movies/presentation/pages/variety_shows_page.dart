import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/media_list_page.dart';

class VarietyShowsPage extends StatefulWidget {
  const VarietyShowsPage({super.key});

  @override
  State<VarietyShowsPage> createState() => _VarietyShowsPageState();
}

class _VarietyShowsPageState extends State<VarietyShowsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // 使用BlocProvider包装，确保MovieBloc可用
    return BlocProvider.value(
      value: context.read<MovieBloc>(),
      child: MediaListPage(
        mediaType: 'show',
        title: localizations?.varietyShows ?? 'Variety Shows',
        defaultCategory: 'show',
        categoryType: 'show',
      ),
    );
  }
}
