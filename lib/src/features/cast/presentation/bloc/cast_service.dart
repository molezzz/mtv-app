
import 'package:flutter/services.dart';

class CastService {
  static const MethodChannel _channel = MethodChannel('mtv_app/cast');

  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      print("Failed to initialize cast service: '${e.message}'.");
    }
  }

  Future<void> startDiscovery() async {
    try {
      await _channel.invokeMethod('startDiscovery');
    } on PlatformException catch (e) {
      print("Failed to start discovery: '${e.message}'.");
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
    } on PlatformException catch (e) {
      print("Failed to stop discovery: '${e.message}'.");
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableDevices() async {
    try {
      final List<dynamic>? devices = await _channel.invokeMethod('getAvailableDevices');
      return devices?.map((device) => Map<String, dynamic>.from(device)).toList() ?? [];
    } on PlatformException catch (e) {
      print("Failed to get available devices: '${e.message}'.");
      return [];
    }
  }

  Future<bool> connectToDevice(String deviceId) async {
    try {
      final bool? success = await _channel.invokeMethod('connectToDevice', {'deviceId': deviceId});
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to connect to device: '${e.message}'.");
      return false;
    }
  }

  Future<bool> castVideo(String videoUrl, String title, {String? poster, int currentTime = 0}) async {
    try {
      final bool? success = await _channel.invokeMethod('castVideo', {
        'videoUrl': videoUrl,
        'title': title,
        'poster': poster,
        'currentTime': currentTime,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      print("Failed to cast video: '${e.message}'.");
      return false;
    }
  }

  Future<void> stopCasting() async {
    try {
      await _channel.invokeMethod('stopCasting');
    } on PlatformException catch (e) {
      print("Failed to stop casting: '${e.message}'.");
    }
  }
}
