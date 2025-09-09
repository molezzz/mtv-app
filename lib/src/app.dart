import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/features/movies/data/repositories/movie_repository_impl.dart';
import 'package:mtv_app/src/features/movies/domain/usecases/get_popular_movies.dart';
import 'package:mtv_app/src/features/movies/presentation/bloc/movie_bloc.dart';
import 'package:mtv_app/src/features/movies/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mtv_app/src/core/locale_notifier.dart';
import 'package:mtv_app/src/core/auth/auth_notifier.dart';
import 'package:mtv_app/src/features/settings/presentation/widgets/login_dialog.dart';
import 'package:mtv_app/src/features/settings/presentation/pages/settings_page.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  ApiClient? _apiClient;
  late final LocaleNotifier _localeNotifier;

  @override
  void initState() {
    super.initState();
    _localeNotifier = LocaleNotifier();
    _initializeApiClient();
  }

  Future<void> _initializeApiClient() async {
    final prefs = await SharedPreferences.getInstance();
    final serverAddress = prefs.getString('api_server_address');
    if (serverAddress != null) {
      setState(() {
        _apiClient = ApiClient(baseUrl: serverAddress);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_apiClient == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.amber,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: const ColorScheme.dark(
        primary: Colors.amber,
        secondary: Colors.amberAccent,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        surface: Color(0xFF2C2C2C),
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
          bodyMedium: TextStyle(color: Color(0xFFBDBDBD)),
        ).apply(
          bodyColor: const Color(0xFFE0E0E0),
          displayColor: Colors.white,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF2C2C2C),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleNotifier>.value(value: _localeNotifier),
        // AuthNotifier is already provided by AppWrapper
      ],
      child: Consumer<LocaleNotifier>(
        builder: (context, localeNotifier, child) {
          return MaterialApp(
            title: 'MTV App',
            theme: darkTheme,
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('zh', ''), // Chinese
            ],
            locale: localeNotifier.locale ?? const Locale('zh', ''),
            home: Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                // Check if user is authenticated
                if (!authNotifier.isAuthenticated) {
                  return const _AuthRequiredScreen();
                }
                
                // User is authenticated, show main app
                return BlocProvider(
                  create: (context) => MovieBloc(
                    getPopularMovies: GetPopularMovies(
                      MovieRepositoryImpl(
                        remoteDataSource: MovieRemoteDataSourceImpl(
                          _apiClient!,
                        ),
                      ),
                    ),
                  ),
                  child: const HomePage(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AuthRequiredScreen extends StatelessWidget {
  const _AuthRequiredScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 24),
              Text(
                '需要身份认证',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '请登录以使用应用功能',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // 登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogin(context),
                  icon: const Icon(Icons.login),
                  label: Text(
                    '登录',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 更改服务器按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _handleChangeServer(context),
                  icon: const Icon(Icons.settings),
                  label: Text(
                    '更改服务器设置',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 服务器地址显示
              FutureBuilder<String?>(
                future: _getCurrentServerAddress(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.dns,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '当前服务器: ',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              snapshot.data!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _getCurrentServerAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('api_server_address');
    } catch (e) {
      return null;
    }
  }

  /// 处理登录按钮点击
  void _handleLogin(BuildContext context) async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final serverAddress = prefs.getString('api_server_address');
    
    if (serverAddress == null || serverAddress.isEmpty) {
      _handleChangeServer(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoginDialog(
        serverAddress: serverAddress,
        onLoginSuccess: () {
          // 登录成功后，状态会自动更新
        },
      ),
    );
  }

  /// 处理更改服务器按钮点击
  void _handleChangeServer(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MaterialApp(
          title: 'MTV App Settings',
          theme: ThemeData.dark(),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('zh', ''),
          ],
          home: SettingsPage(
            onSettingsSaved: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AppWrapper()),
                (route) => false,
              );
            },
          ),
        ),
      ),
      (route) => false,
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  _AppWrapperState createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  AuthNotifier? _authNotifier;
  
  Future<bool> _checkApiServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('api_server_address');
    return address != null && address.isNotEmpty;
  }

  Future<void> _initializeAuthNotifier() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString('api_server_address');
    if (address != null && address.isNotEmpty) {
      final apiClient = ApiClient(baseUrl: address);
      _authNotifier = AuthNotifier(apiClient.authService);
      await _authNotifier!.initialize();
    }
  }

  void _onSettingsSaved() {
    // Re-check the settings and rebuild the widget tree
    setState(() {
      _authNotifier = null; // Reset auth notifier
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkApiServerAddress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Address is set, initialize auth and show the main app
          return FutureBuilder<void>(
            future: _authNotifier == null ? _initializeAuthNotifier() : Future.value(),
            builder: (context, authSnapshot) {
              if (authSnapshot.connectionState == ConnectionState.waiting) {
                return const MaterialApp(
                  home: Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              
              return ChangeNotifierProvider<AuthNotifier>.value(
                value: _authNotifier!,
                child: const App(),
              );
            },
          );
        } else {
          // Address is not set, show the settings page
          return MaterialApp(
            title: 'MTV App Settings',
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('zh', ''), // Chinese
            ],
            home: SettingsPage(onSettingsSaved: _onSettingsSaved),
          );
        }
      },
    );
  }
}