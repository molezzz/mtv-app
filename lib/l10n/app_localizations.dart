import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  final String localeName;

  static Future<AppLocalizations> load(Locale locale) {
    final String name = locale.countryCode == null || locale.countryCode!.isEmpty
        ? locale.languageCode
        : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    
    return Future.value(AppLocalizations(localeName));
  }

  String get appTitle {
    switch (localeName) {
      case 'zh':
        return 'MTV 应用';
      case 'en':
      default:
        return 'MTV App';
    }
  }

  String get popularMovies {
    switch (localeName) {
      case 'zh':
        return '热门电影';
      case 'en':
      default:
        return 'Popular Movies';
    }
  }

  String get settings {
    switch (localeName) {
      case 'zh':
        return '设置';
      case 'en':
      default:
        return 'Settings';
    }
  }

  String get language {
    switch (localeName) {
      case 'zh':
        return '语言';
      case 'en':
      default:
        return 'Language';
    }
  }

  String get english {
    return 'English';
  }

  String get chinese {
    return '中文';
  }

  String get apiServerAddress {
    switch (localeName) {
      case 'zh':
        return 'API 服务器地址';
      case 'en':
      default:
        return 'API Server Address';
    }
  }

  String get save {
    switch (localeName) {
      case 'zh':
        return '保存';
      case 'en':
      default:
        return 'Save';
    }
  }

  String get loading {
    switch (localeName) {
      case 'zh':
        return '加载中...';
      case 'en':
      default:
        return 'Loading...';
    }
  }

  String get error {
    switch (localeName) {
      case 'zh':
        return '错误';
      case 'en':
      default:
        return 'Error';
    }
  }

  String get retry {
    switch (localeName) {
      case 'zh':
        return '重试';
      case 'en':
      default:
        return 'Retry';
    }
  }

  String get login {
    switch (localeName) {
      case 'zh':
        return '登录';
      case 'en':
      default:
        return 'Login';
    }
  }

  String get username {
    switch (localeName) {
      case 'zh':
        return '用户名';
      case 'en':
      default:
        return 'Username';
    }
  }

  String get password {
    switch (localeName) {
      case 'zh':
        return '密码';
      case 'en':
      default:
        return 'Password';
    }
  }

  String get cancel {
    switch (localeName) {
      case 'zh':
        return '取消';
      case 'en':
      default:
        return 'Cancel';
    }
  }

  String get usernameRequired {
    switch (localeName) {
      case 'zh':
        return '用户名不能为空';
      case 'en':
      default:
        return 'Username is required';
    }
  }

  String get passwordRequired {
    switch (localeName) {
      case 'zh':
        return '密码不能为空';
      case 'en':
      default:
        return 'Password is required';
    }
  }

  String get loginSuccessful {
    switch (localeName) {
      case 'zh':
        return '登录成功！设置已保存。';
      case 'en':
      default:
        return 'Login successful! Settings saved.';
    }
  }

  String get movies {
    switch (localeName) {
      case 'zh':
        return '电影';
      case 'en':
      default:
        return 'Movies';
    }
  }

  String get tvShows {
    switch (localeName) {
      case 'zh':
        return '剧集';
      case 'en':
      default:
        return 'TV Shows';
    }
  }

  String get varietyShows {
    switch (localeName) {
      case 'zh':
        return '综艺';
      case 'en':
      default:
        return 'Variety Shows';
    }
  }

  String get records {
    switch (localeName) {
      case 'zh':
        return '记录';
      case 'en':
      default:
        return 'Records';
    }
  }

  String get favorites {
    switch (localeName) {
      case 'zh':
        return '收藏';
      case 'en':
      default:
        return 'Favorites';
    }
  }

  String get comingSoon {
    switch (localeName) {
      case 'zh':
        return '即将推出';
      case 'en':
      default:
        return 'Coming Soon';
    }
  }

  String get watchHistory {
    switch (localeName) {
      case 'zh':
        return '观看历史';
      case 'en':
      default:
        return 'Watch History';
    }
  }

  String get yourFavoriteContent {
    switch (localeName) {
      case 'zh':
        return '您收藏的内容';
      case 'en':
      default:
        return 'Your Favorite Content';
    }
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
