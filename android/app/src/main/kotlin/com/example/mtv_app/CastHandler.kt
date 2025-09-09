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

class CastHandler(private val context: Context) : MethodCallHandler {
    
    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null
    private var remoteMediaClient: RemoteMediaClient? = null
    
    companion object {
        private const val CHANNEL = "mtv_app/cast"
        private const val CAST_APP_ID = CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID
    }
    
    fun initialize() {
        try {
            // 检查Google Play Services
            val availability = GoogleApiAvailability.getInstance()
            val result = availability.isGooglePlayServicesAvailable(context)
            
            if (result != ConnectionResult.SUCCESS) {
                return
            }
            
            // 初始化Cast Context
            castContext = CastContext.getSharedInstance(context)
            sessionManager = castContext?.sessionManager
            
            // 设置会话监听器
            sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)
            
        } catch (e: Exception) {
            e.printStackTrace()
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
            val devices = mutableListOf<Map<String, Any>>()
            val mediaRouter = MediaRouter.getInstance(context)
            val selector = MediaRouteSelector.Builder()
                .addControlCategory(CastMediaControlIntent.categoryForCast(CAST_APP_ID))
                .build()
            
            val routes = mediaRouter.getRoutes()
            for (route in routes) {
                if (route.matchesSelector(selector) && route.isEnabled) {
                    devices.add(mapOf(
                        "id" to route.id,
                        "name" to route.name,
                        "type" to "chromecast",
                        "isAvailable" to true
                    ))
                }
            }
            
            result.success(devices)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to get available devices", e.message)
        }
    }
    
    private fun connectToDevice(deviceId: String?, result: Result) {
        if (deviceId == null) {
            result.error("INVALID_ARGUMENT", "Device ID is required", null)
            return
        }
        
        try {
            // 这里应该根据deviceId找到对应的路由并连接
            // 实际实现会更复杂，需要匹配设备ID
            // 对于Cast框架，通常通过MediaRouter来选择设备
            // 这里简化处理，实际应该根据deviceId找到对应的RouteInfo
            result.success(true)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to connect to device", e.message)
        }
    }
    
    private fun castVideo(videoUrl: String?, title: String?, poster: String?, currentTime: Int, result: Result) {
        if (videoUrl == null || title == null) {
            result.error("INVALID_ARGUMENT", "Video URL and title are required", null)
            return
        }
        
        try {
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
        } catch (e: Exception) {
            result.error("ERROR", "Failed to cast video", e.message)
        }
    }
    
    private fun togglePlayPause(result: Result) {
        try {
            remoteMediaClient?.let { client ->
                if (client.isPlaying) {
                    client.pause()
                } else {
                    client.play()
                }
            }
            result.success(null)
        } catch (e: Exception) {
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
            remoteMediaClient?.seek(time.toLong() * 1000) // 转换为毫秒
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to seek", e.message)
        }
    }
    
    private fun stopCasting(result: Result) {
        try {
            remoteMediaClient?.stop()
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to stop casting", e.message)
        }
    }
    
    private fun disconnect(result: Result) {
        try {
            sessionManager?.endCurrentSession(true)
            result.success(null)
        } catch (e: Exception) {
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
            // Cast设备发现通常是自动的，这里可以触发扫描
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to start discovery", e.message)
        }
    }
    
    private fun stopDiscovery(result: Result) {
        try {
            // 停止设备发现
            result.success(null)
        } catch (e: Exception) {
            result.error("ERROR", "Failed to stop discovery", e.message)
        }
    }
}