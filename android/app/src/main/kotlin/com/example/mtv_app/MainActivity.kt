package com.example.mtv_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.mtv_app.cast.CastHandler

class MainActivity: FlutterActivity() {
    private val CAST_CHANNEL = "mtv_app/cast"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册投屏方法通道
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAST_CHANNEL)
            .setMethodCallHandler(CastHandler(this))
    }
}
