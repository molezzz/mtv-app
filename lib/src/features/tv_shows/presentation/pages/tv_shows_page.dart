import 'package:flutter/material.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/core/widgets/language_selector.dart';
import 'package:mtv_app/src/features/settings/presentation/pages/settings_page.dart';

class TvShowsPage extends StatefulWidget {
  const TvShowsPage({super.key});

  @override
  State<TvShowsPage> createState() => _TvShowsPageState();
}

class _TvShowsPageState extends State<TvShowsPage> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.tvShows ?? 'TV Shows'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.tvShows ?? 'TV Shows',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              localizations?.comingSoon ?? 'Coming Soon',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}