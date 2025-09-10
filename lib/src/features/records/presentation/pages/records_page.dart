import 'package:flutter/material.dart';
import 'package:mtv_app/l10n/app_localizations.dart';
import 'package:mtv_app/src/core/widgets/language_selector.dart';
import 'package:mtv_app/src/features/settings/presentation/pages/settings_page.dart';
import 'package:mtv_app/src/features/movies/data/datasources/movie_remote_data_source.dart';
import 'package:mtv_app/src/core/api/api_client.dart';
import 'package:mtv_app/src/features/movies/data/models/play_record_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  late MovieRemoteDataSource _dataSource;
  Map<String, PlayRecordModel> _playRecords = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeDataSource().then((_) {
      _loadPlayRecords();
    });
  }

  Future<void> _initializeDataSource() async {
    final prefs = await SharedPreferences.getInstance();
    // 修复：使用正确的键名 'api_server_address' 而不是 'server_url'
    final serverUrl =
        prefs.getString('api_server_address') ?? 'http://localhost:3000';
    final apiClient = ApiClient(baseUrl: serverUrl);
    _dataSource = MovieRemoteDataSourceImpl(apiClient);
  }

  Future<void> _loadPlayRecords() async {
    // 检查组件是否仍然挂载
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final records = await _dataSource.getPlayRecords();
      // 再次检查组件是否仍然挂载
      if (!mounted) return;

      setState(() {
        _playRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      // 检查组件是否仍然挂载
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.records ?? 'Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadPlayRecords();
            },
          ),
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
                      _initializeDataSource().then((_) {
                        _loadPlayRecords();
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _initializeDataSource().then((_) {
                            _loadPlayRecords();
                          });
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _playRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations?.records ?? 'Records',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            localizations?.watchHistory ?? 'Watch History',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations?.noRecords ?? 'No records yet',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _playRecords.length,
                      itemBuilder: (context, index) {
                        final recordKey = _playRecords.keys.elementAt(index);
                        final record = _playRecords[recordKey]!;

                        return _buildRecordCard(record, localizations);
                      },
                    ),
    );
  }

  Widget _buildRecordCard(
      PlayRecordModel record, AppLocalizations? localizations) {
    final progress =
        record.totalTime > 0 ? record.playTime / record.totalTime : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 海报部分
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: record.cover.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(record.cover),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: record.cover.isNotEmpty ? null : Colors.grey[300],
              ),
              child: record.cover.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.movie,
                        color: Colors.grey,
                        size: 50,
                      ),
                    )
                  : null,
            ),
          ),
          // 进度条
          SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.9 ? Colors.green : Colors.orange,
              ),
            ),
          ),
          // 信息部分
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title.isNotEmpty ? record.title : 'Unknown Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  record.sourceName.isNotEmpty
                      ? record.sourceName
                      : 'Unknown Source',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${localizations?.episode ?? 'Episode'} ${record.index}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      record.year.isNotEmpty ? record.year : 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDuration(Duration(seconds: record.playTime))} / ${_formatDuration(Duration(seconds: record.totalTime))}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  String _formatDateTime(int timestamp) {
    // 处理可能的毫秒时间戳
    final milliseconds = timestamp > 9999999999 ? timestamp : timestamp * 1000;
    final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
