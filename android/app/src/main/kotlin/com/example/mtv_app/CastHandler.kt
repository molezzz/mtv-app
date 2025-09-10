package com.example.mtv_app.cast

import android.content.Context
import androidx.mediarouter.app.MediaRouteButton
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.*
import com.google.android.gms.cast.framework.*
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.images.WebImage
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.example.mtv_app.DlnaHandler
import com.example.mtv_app.MiracastHandler
import android.util.Log
import android.os.Build

class CastHandler(private val context: Context) : MethodCallHandler {
    
    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null
    private var remoteMediaClient: RemoteMediaClient? = null
    private var dlnaHandler: DlnaHandler? = null
    private var miracastHandler: MiracastHandler? = null
    private var currentDeviceType: String = ""
    private var isDiscoveryActive = false
    
    companion object {
        private const val CHANNEL = "mtv_app/cast"
        private const val CAST_APP_ID = CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
        private const val TAG = "CastHandler"
    }
    
    fun initialize() {
        try {
            // 初始化DLNA处理器
            dlnaHandler = DlnaHandler(context)
            dlnaHandler?.initialize()
            
            // 初始化Miracast处理器（Android 4.2+）
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                miracastHandler = MiracastHandler(context)
                miracastHandler?.initialize()
                Log.d(TAG, "Miracast handler initialized")
            } else {
                Log.w(TAG, "Miracast not supported on this Android version")
            }
            
            // 检查Google Play Services
            val availability = GoogleApiAvailability.getInstance()
            val result = availability.isGooglePlayServicesAvailable(context)
            
            if (result == ConnectionResult.SUCCESS) {
                // 初始化Cast Context
                castContext = CastContext.getSharedInstance(context)
                sessionManager = castContext?.sessionManager
                
                // 设置会话监听器
                sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)
                Log.d(TAG, "Cast framework initialized successfully")
            } else {
                Log.w(TAG, "Google Play Services not available, Cast will not work")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize cast services", e)
        }
    }
    
    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
            remoteMediaClient = session.remoteMediaClient
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            remoteMediaClient = null
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            remoteMediaClient = session.remoteMediaClient
        }

        override fun onSessionSuspended(session: CastSession, reason: Int) {
            remoteMediaClient = null
        }

        override fun onSessionEnding(session: CastSession) {
            // Session is about to end
        }

        override fun onSessionStarting(session: CastSession) {
            // Session is about to start
        }

        override fun onSessionStartFailed(session: CastSession, error: Int) {
            // Session start failed
        }

        override fun onSessionResuming(session: CastSession, sessionId: String) {
            // Session is about to resume
        }

        override fun onSessionResumeFailed(session: CastSession, error: Int) {
            // Session resume failed
        }
    }
    
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                initialize()
                result.success(null)
            }
            
            "getAvailableDevices" -> {
                getAvailableDevices(result)
            }
            
            "connectToDevice" -> {
                val deviceId = call.argument<String>("deviceId")
                connectToDevice(deviceId, result)
            }
            
            "castVideo" -> {
                val videoUrl = call.argument<String>("videoUrl")
                val title = call.argument<String>("title")
                val poster = call.argument<String>("poster")
                val currentTime = call.argument<Int>("currentTime") ?: 0
                castVideo(videoUrl, title, poster, currentTime, result)
            }
            
            "togglePlayPause" -> {
                togglePlayPause(result)
            }
            
            "setVolume" -> {
                val volume = call.argument<Double>("volume") ?: 0.0
                setVolume(volume, result)
            }
            
            "seekTo" -> {
                val time = call.argument<Int>("time") ?: 0
                seekTo(time, result)
            }
            
            "stopCasting" -> {
                stopCasting(result)
            }
            
            "disconnect" -> {
                disconnect(result)
            }
            
            "isConnected" -> {
                isConnected(result)
            }
            
            "getPlaybackState" -> {
                getPlaybackState(result)
            }
            
            "startDiscovery" -> {
                startDiscovery(result)
            }
            
            "stopDiscovery" -> {
                stopDiscovery(result)
            }
            
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun getAvailableDevices(result: Result) {
        try {
            Log.d(TAG, "=== Getting Available Devices ===")
            val devices = mutableListOf<Map<String, Any>>()
            
            // 获取Chromecast设备
            Log.d(TAG, "Checking for Chromecast devices...")
            if (castContext != null) {
                val mediaRouter = MediaRouter.getInstance(context)
                val selector = MediaRouteSelector.Builder()
                    .addControlCategory(CastMediaControlIntent.categoryForCast(CAST_APP_ID))
                    .build()
                
                val routes = mediaRouter.getRoutes()
                Log.d(TAG, "Found ${routes.size} total media routes")
                
                var chromecastCount = 0
                for (route in routes) {
                    Log.d(TAG, "Route: ${route.name}, ID: ${route.id}, Enabled: ${route.isEnabled}, Matches selector: ${route.matchesSelector(selector)}")
                    
                    if (route.matchesSelector(selector) && route.isEnabled) {
                        chromecastCount++
                        val device = mapOf(
                            "id" to route.id,
                            "name" to route.name,
                            "type" to "chromecast",
                            "isAvailable" to true
                        )
                        devices.add(device)
                        Log.d(TAG, "Added Chromecast device: ${route.name}")
                    }
                }
                Log.d(TAG, "Total Chromecast devices found: $chromecastCount")
            } else {
                Log.w(TAG, "CastContext is null, no Chromecast devices available")
            }
            
            // 获取DLNA设备
            Log.d(TAG, "Checking for DLNA devices...")
            dlnaHandler?.let { handler ->
                val dlnaDevices = handler.getAvailableDevices()
                Log.d(TAG, "DLNA handler returned ${dlnaDevices.size} devices")
                
                dlnaDevices.forEachIndexed { index, device ->
                    Log.d(TAG, "DLNA Device #${index + 1}: ${device["name"]} (ID: ${device["id"]}, Type: ${device["type"]})")
                    Log.d(TAG, "  - Available: ${device["isAvailable"]}")
                    Log.d(TAG, "  - Manufacturer: ${device["manufacturer"]}")
                    Log.d(TAG, "  - Model: ${device["model"]}")
                    device["address"]?.let { address ->
                        Log.d(TAG, "  - Address: $address")
                    }
                    device["isMock"]?.let { isMock ->
                        Log.d(TAG, "  - Is Mock: $isMock")
                    }
                }
                
                devices.addAll(dlnaDevices)
            } ?: run {
                Log.w(TAG, "DLNA handler is null")
            }
            
            // 获取Miracast设备
            Log.d(TAG, "Checking for Miracast devices...")
            miracastHandler?.let { handler ->
                val miracastDevices = handler.getAvailableDevices()
                Log.d(TAG, "Miracast handler returned ${miracastDevices.size} devices")
                
                miracastDevices.forEachIndexed { index, device ->
                    Log.d(TAG, "Miracast Device #${index + 1}: ${device["name"]} (ID: ${device["id"]})")
                }
                
                devices.addAll(miracastDevices)
            } ?: run {
                Log.w(TAG, "Miracast handler is null")
            }
            
            Log.d(TAG, "=== Device Summary ===")
            Log.d(TAG, "Total devices found: ${devices.size}")
            val devicesByType = devices.groupBy { it["type"] }
            devicesByType.forEach { (type, deviceList) ->
                Log.d(TAG, "  - $type: ${deviceList.size} devices")
            }
            
            Log.d(TAG, "Device names: ${devices.map { "${it["name"]} (${it["type"]})" }}")
            
            result.success(devices)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get available devices", e)
            e.printStackTrace()
            result.error("ERROR", "Failed to get available devices", e.message)
        }
    }
    
    private fun connectToDevice(deviceId: String?, result: Result) {
        if (deviceId == null) {
            result.error("INVALID_ARGUMENT", "Device ID is required", null)
            return
        }
        
        try {
            // 先尝试DLNA设备
            dlnaHandler?.let { handler ->
                val dlnaDevices = handler.getAvailableDevices()
                val dlnaDevice = dlnaDevices.find { it["id"] == deviceId }
                if (dlnaDevice != null) {
                    Log.d(TAG, "Connecting to DLNA device: ${dlnaDevice["name"]}")
                    val success = handler.connectToDevice(deviceId)
                    if (success) {
                        currentDeviceType = "dlna"
                        result.success(true)
                        return
                    }
                }
            }
            
            // 尝试Miracast设备
            miracastHandler?.let { handler ->
                val miracastDevices = handler.getAvailableDevices()
                val miracastDevice = miracastDevices.find { it["id"] == deviceId }
                if (miracastDevice != null) {
                    Log.d(TAG, "Connecting to Miracast device: ${miracastDevice["name"]}")
                    val success = handler.connectToDevice(deviceId)
                    if (success) {
                        currentDeviceType = "miracast"
                        result.success(true)
                        return
                    }
                }
            }
            
            // 如果不是DLNA或Miracast设备，尝试Chromecast
            if (castContext != null) {
                val mediaRouter = MediaRouter.getInstance(context)
                val selector = MediaRouteSelector.Builder()
                    .addControlCategory(CastMediaControlIntent.categoryForCast(CAST_APP_ID))
                    .build()
                
                val routes = mediaRouter.getRoutes()
                val targetRoute = routes.find { it.id == deviceId }
                if (targetRoute != null) {
                    Log.d(TAG, "Connecting to Cast device: ${targetRoute.name}")
                    mediaRouter.selectRoute(targetRoute)
                    currentDeviceType = "chromecast"
                    result.success(true)
                    return
                }
            }
            
            Log.w(TAG, "Device not found: $deviceId")
            result.success(false)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect to device: $deviceId", e)
            result.error("ERROR", "Failed to connect to device", e.message)
        }
    }
    
    private fun castVideo(videoUrl: String?, title: String?, poster: String?, currentTime: Int, result: Result) {
        if (videoUrl == null || title == null) {
            result.error("INVALID_ARGUMENT", "Video URL and title are required", null)
            return
        }
        
        try {
            when (currentDeviceType) {
                "dlna" -> {
                    Log.d(TAG, "Casting to DLNA device: $videoUrl")
                    dlnaHandler?.castVideo(videoUrl, title, poster, currentTime) { success ->
                        result.success(success)
                    } ?: result.success(false)
                }
                "miracast" -> {
                    Log.d(TAG, "Casting to Miracast device: $videoUrl")
                    miracastHandler?.castVideo(videoUrl, title, poster, currentTime) { success ->
                        result.success(success)
                    } ?: result.success(false)
                }
                "chromecast" -> {
                    Log.d(TAG, "Casting to Chromecast device: $videoUrl")
                    val mediaMetadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE).apply {
                        putString(MediaMetadata.KEY_TITLE, title)
                        poster?.let { 
                            addImage(WebImage(Uri.parse(it)))
                        }
                    }
                    
                    val mediaInfo = MediaInfo.Builder(videoUrl)
                        .setStreamType(MediaInfo.STREAM_TYPE_BUFFERED)
                        .setContentType("video/mp4")
                        .setMetadata(mediaMetadata)
                        .build()
                    
                    val mediaLoadOptions = MediaLoadOptions.Builder()
                        .setAutoplay(true)
                        .setPlayPosition(currentTime.toLong() * 1000) // 转换为毫秒
                        .build()
                    
                    remoteMediaClient?.load(mediaInfo, mediaLoadOptions)
                    result.success(true)
                }
                else -> {
                    Log.w(TAG, "No device connected or unknown device type: $currentDeviceType")
                    result.success(false)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to cast video", e)
            result.error("ERROR", "Failed to cast video", e.message)
        }
    }
    
    private fun togglePlayPause(result: Result) {
        try {
            when (currentDeviceType) {
                "dlna" -> {
                    // DLNA需要分别处理播放和暂停，这里简化为暂停
                    dlnaHandler?.pauseCasting { success ->
                        // 这里实际上需要根据当前状态决定是播放还是暂停
                        result.success(null)
                    }
                }
                "miracast" -> {
                    // Miracast主要用于屏幕镜像，播放控制通常由本地应用处理
                    Log.d(TAG, "Miracast play/pause control - handled by source device")
                    result.success(null)
                }
                "chromecast" -> {
                    remoteMediaClient?.let { client ->
                        if (client.isPlaying) {
                            client.pause()
                        } else {
                            client.play()
                        }
                    }
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "No device connected")
                    result.success(null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to toggle play/pause", e)
            result.error("ERROR", "Failed to toggle play/pause", e.message)
        }
    }
    
    private fun setVolume(volume: Double, result: Result) {
        try {
            sessionManager?.currentCastSession?.setVolume(volume)
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to set volume", e.message)
        }
    }
    
    private fun seekTo(time: Int, result: Result) {
        try {
            when (currentDeviceType) {
                "dlna" -> {
                    dlnaHandler?.seekTo(time) { success ->
                        result.success(null)
                    }
                }
                "miracast" -> {
                    // Miracast主要用于屏幕镜像，进度控制通常由本地应用处理
                    Log.d(TAG, "Miracast seek control - handled by source device")
                    result.success(null)
                }
                "chromecast" -> {
                    remoteMediaClient?.seek(time.toLong() * 1000) // 转换为毫秒
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "No device connected")
                    result.success(null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to seek", e)
            result.error("ERROR", "Failed to seek", e.message)
        }
    }
    
    private fun stopCasting(result: Result) {
        try {
            when (currentDeviceType) {
                "dlna" -> {
                    dlnaHandler?.stopCasting { success ->
                        result.success(null)
                    }
                }
                "miracast" -> {
                    miracastHandler?.stopCasting { success ->
                        result.success(null)
                    }
                }
                "chromecast" -> {
                    remoteMediaClient?.stop()
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "No device connected")
                    result.success(null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop casting", e)
            result.error("ERROR", "Failed to stop casting", e.message)
        }
    }
    
    private fun disconnect(result: Result) {
        try {
            when (currentDeviceType) {
                "dlna" -> {
                    dlnaHandler?.disconnect()
                }
                "miracast" -> {
                    miracastHandler?.disconnect()
                }
                "chromecast" -> {
                    sessionManager?.endCurrentSession(true)
                }
            }
            currentDeviceType = ""
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disconnect", e)
            result.error("ERROR", "Failed to disconnect", e.message)
        }
    }
    
    private fun isConnected(result: Result) {
        try {
            val connected = sessionManager?.currentCastSession?.isConnected ?: false
            result.success(connected)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to check connection status", e.message)
        }
    }
    
    private fun getPlaybackState(result: Result) {
        try {
            remoteMediaClient?.let { client ->
                val mediaStatus = client.mediaStatus
                val state = mapOf(
                    "isPlaying" to client.isPlaying,
                    "currentTime" to (client.approximateStreamPosition / 1000), // 转换为秒
                    "duration" to (mediaStatus?.mediaInfo?.streamDuration ?: 0) / 1000, // 转换为秒
                    "volume" to (sessionManager?.currentCastSession?.volume ?: 0.0)
                )
                result.success(state)
            } ?: result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get playback state", e.message)
        }
    }
    
    private fun startDiscovery(result: Result) {
        try {
            Log.d(TAG, "=== Starting Device Discovery ===")
            
            if (isDiscoveryActive) {
                Log.d(TAG, "Discovery already active, skipping")
                result.success(null)
                return
            }
            
            isDiscoveryActive = true
            Log.d(TAG, "Discovery state set to active")
            
            // 启动DLNA设备发现
            Log.d(TAG, "Starting DLNA device discovery...")
            dlnaHandler?.startDiscovery { devices ->
                Log.d(TAG, "DLNA discovery callback triggered with ${devices.size} devices")
                devices.forEachIndexed { index, device ->
                    Log.d(TAG, "  DLNA Device #${index + 1}: ${device["name"]} (${device["type"]})")
                }
            } ?: run {
                Log.w(TAG, "DLNA handler is null, skipping DLNA discovery")
            }
            
            // 启动Miracast设备发现
            Log.d(TAG, "Starting Miracast device discovery...")
            miracastHandler?.startDiscovery { devices ->
                Log.d(TAG, "Miracast discovery callback triggered with ${devices.size} devices")
                devices.forEachIndexed { index, device ->
                    Log.d(TAG, "  Miracast Device #${index + 1}: ${device["name"]} (${device["type"]})")
                }
            } ?: run {
                Log.w(TAG, "Miracast handler is null, skipping Miracast discovery")
            }
            
            // Cast设备发现通常是自动的，这里可以触发扫描
            Log.d(TAG, "Chromecast discovery is automatic via MediaRouter")
            
            Log.d(TAG, "=== Device Discovery Started Successfully ===")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start discovery", e)
            e.printStackTrace()
            result.error("ERROR", "Failed to start discovery", e.message)
        }
    }
    
    private fun stopDiscovery(result: Result) {
        try {
            isDiscoveryActive = false
            
            // 停止DLNA设备发现
            dlnaHandler?.stopDiscovery()
            
            // 停止Miracast设备发现
            miracastHandler?.stopDiscovery()
            
            Log.d(TAG, "Stopped device discovery")
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop discovery", e)
            result.error("ERROR", "Failed to stop discovery", e.message)
        }
    }
}