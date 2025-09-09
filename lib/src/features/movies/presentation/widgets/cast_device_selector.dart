import 'package:flutter/material.dart';
import 'package:mtv_app/src/core/services/cast_service.dart';

class CastDeviceSelector extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String? poster;
  final int? currentTime;

  const CastDeviceSelector({
    super.key,
    required this.videoUrl,
    required this.title,
    this.poster,
    this.currentTime,
  });

  @override
  State<CastDeviceSelector> createState() => _CastDeviceSelectorState();
}

class _CastDeviceSelectorState extends State<CastDeviceSelector> {
  List<CastDevice> _devices = [];
  bool _isLoading = true;
  bool _isConnecting = false;
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    _initializeCasting();
  }

  Future<void> _initializeCasting() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await CastService.initialize();
      await CastService.startDiscovery();
      
      // 等待一段时间让设备发现完成
      await Future.delayed(const Duration(seconds: 2));
      
      final devices = await CastService.getAvailableDevices();
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化投屏失败: $e')),
        );
      }
    }
  }

  Future<void> _connectToDevice(CastDevice device) async {
    setState(() {
      _isConnecting = true;
      _selectedDeviceId = device.id;
    });

    try {
      final success = await CastService.connectToDevice(device.id);
      if (success) {
        // 连接成功，开始投屏
        final castSuccess = await CastService.castVideo(
          videoUrl: widget.videoUrl,
          title: widget.title,
          poster: widget.poster,
          currentTime: widget.currentTime,
        );

        if (castSuccess) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已投屏到 ${device.name}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('投屏失败');
        }
      } else {
        throw Exception('连接设备失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('投屏失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isConnecting = false;
        _selectedDeviceId = null;
      });
    }
  }

  @override
  void dispose() {
    CastService.stopDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cast,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                '选择投屏设备',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _initializeCasting,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    '正在搜索设备...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          else if (_devices.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.cast_connected,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '未发现可用设备',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请确保设备在同一网络下',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeCasting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('重新搜索'),
                  ),
                ],
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  final isConnecting = _isConnecting && _selectedDeviceId == device.id;
                  
                  return Card(
                    color: Colors.grey[800],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getDeviceColor(device.type),
                        child: Icon(
                          _getDeviceIcon(device.type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        device.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _getDeviceTypeText(device.type),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      trailing: isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            )
                          : Icon(
                              device.isAvailable ? Icons.cast : Icons.cast_connected,
                              color: device.isAvailable ? Colors.orange : Colors.grey,
                            ),
                      onTap: device.isAvailable && !isConnecting
                          ? () => _connectToDevice(device)
                          : null,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'chromecast':
      case 'android_tv':
        return Icons.cast;
      case 'airplay':
      case 'apple_tv':
        return Icons.airplay;
      default:
        return Icons.tv;
    }
  }

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'chromecast':
      case 'android_tv':
        return Colors.green;
      case 'airplay':
      case 'apple_tv':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getDeviceTypeText(String type) {
    switch (type.toLowerCase()) {
      case 'chromecast':
        return 'Chromecast';
      case 'android_tv':
        return 'Android TV';
      case 'airplay':
        return 'AirPlay';
      case 'apple_tv':
        return 'Apple TV';
      default:
        return '智能电视';
    }
  }
}