import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtv_app/src/core/locale_notifier.dart';
import 'package:mtv_app/l10n/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleNotifier>(
      builder: (context, localeNotifier, child) {
        return PopupMenuButton<String>(
          icon: Icon(
            Icons.language,
            color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white,
          ),
          tooltip: AppLocalizations.of(context)?.language ?? 'Language',
          onSelected: (String languageCode) {
            localeNotifier.setLocale(Locale(languageCode));
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'zh',
              child: Row(
                children: [
                  const Text('🇨🇳'),
                  const SizedBox(width: 8),
                  Text(
                    '中文',
                    style: TextStyle(
                      fontWeight: localeNotifier.locale?.languageCode == 'zh' 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (localeNotifier.locale?.languageCode == 'zh')
                    const SizedBox(width: 8),
                  if (localeNotifier.locale?.languageCode == 'zh')
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  const Text('🇺🇸'),
                  const SizedBox(width: 8),
                  Text(
                    'English',
                    style: TextStyle(
                      fontWeight: localeNotifier.locale?.languageCode == 'en' 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                  if (localeNotifier.locale?.languageCode == 'en')
                    const SizedBox(width: 8),
                  if (localeNotifier.locale?.languageCode == 'en')
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}