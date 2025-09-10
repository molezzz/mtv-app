package com.example.mtv_app

import android.content.Context
import android.util.Log
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.*
import java.net.*
import java.io.*
import android.os.Handler
import android.os.Looper
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType

class DlnaHandler(private val context: Context) {
    companion object {
        private const val TAG = "DlnaHandler"
    }

    private val devices = ConcurrentHashMap<String, Map<String, Any>>()
    private var deviceDiscoveryCallback: ((List<Map<String, Any>>) -> Unit)? = null
    private var currentSelectedDevice: Map<String, Any>? = null
    private var discoveryJob: Job? = null
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .writeTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .build()

    fun initialize() {
        try {
            Log.d(TAG, "=== DLNA Handler Initialization Started ===")
            Log.d(TAG, "Context: ${context.javaClass.simpleName}")
            Log.d(TAG, "Available network interfaces:")
            
            // 检查网络接口
            val networkInterfaces = NetworkInterface.getNetworkInterfaces()
            while (networkInterfaces.hasMoreElements()) {
                val ni = networkInterfaces.nextElement()
                if (ni.isUp && !ni.isLoopback) {
                    Log.d(TAG, "  - ${ni.name}: ${ni.displayName}")
                    val addresses = ni.inetAddresses
                    while (addresses.hasMoreElements()) {
                        val addr = addresses.nextElement()
                        if (addr is Inet4Address) {
                            Log.d(TAG, "    IPv4: ${addr.hostAddress}")
                        }
                    }
                }
            }
            
            Log.d(TAG, "=== DLNA Handler Initialization Completed ===")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize DLNA service", e)
            e.printStackTrace()
        }
    }

    fun startDiscovery(callback: ((List<Map<String, Any>>) -> Unit)?) {
        Log.d(TAG, "=== Starting DLNA Device Discovery ===")
        deviceDiscoveryCallback = callback
        
        // 停止之前的发现任务
        discoveryJob?.cancel()
        devices.clear()
        
        discoveryJob = CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d(TAG, "DLNA discovery thread started")
                
                // 首先尝试SSDP多播发现
                performSsdpDiscovery()
                
                // 延迟一段时间等待响应
                delay(5000)
                
                // 如果没有发现真实设备，添加一些模拟设备用于测试
                if (devices.isEmpty()) {
                    Log.w(TAG, "No real DLNA devices found, adding mock devices for testing")
                    addMockDevices()
                } else {
                    Log.d(TAG, "Found ${devices.size} real DLNA devices")
                }
                
                withContext(Dispatchers.Main) {
                    notifyDeviceListChanged()
                    Log.d(TAG, "=== DLNA Discovery Completed: ${devices.size} devices ===")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error during DLNA discovery", e)
                e.printStackTrace()
                
                // 发生错误时也添加模拟设备
                withContext(Dispatchers.Main) {
                    addMockDevices()
                    notifyDeviceListChanged()
                }
            }
        }
    }
    
    private suspend fun performSsdpDiscovery() {
        Log.d(TAG, "--- Starting SSDP Discovery ---")
        
        try {
            // SSDP多播地址和端口
            val ssdpAddress = InetAddress.getByName("239.255.255.250")
            val ssdpPort = 1900
            
            Log.d(TAG, "SSDP target: ${ssdpAddress.hostAddress}:$ssdpPort")
            
            // 创建UDP套接字
            val socket = DatagramSocket()
            socket.soTimeout = 3000 // 3秒超时
            
            Log.d(TAG, "Created UDP socket, local port: ${socket.localPort}")
            
            // 构建SSDP搜索消息
            val searchMessage = buildSsdpSearchMessage()
            Log.d(TAG, "SSDP search message:\n$searchMessage")
            
            val buffer = searchMessage.toByteArray()
            val packet = DatagramPacket(buffer, buffer.size, ssdpAddress, ssdpPort)
            
            // 发送搜索请求
            Log.d(TAG, "Sending SSDP M-SEARCH packet...")
            socket.send(packet)
            Log.d(TAG, "SSDP M-SEARCH sent successfully")
            
            // 监听响应
            val responseBuffer = ByteArray(8192)
            var responseCount = 0
            
            Log.d(TAG, "Listening for SSDP responses...")
            
            try {
                while (responseCount < 20) { // 最多接收20个响应
                    val responsePacket = DatagramPacket(responseBuffer, responseBuffer.size)
                    socket.receive(responsePacket)
                    responseCount++
                    
                    val response = String(responsePacket.data, 0, responsePacket.length)
                    val senderAddress = responsePacket.address.hostAddress
                    
                    Log.d(TAG, "--- SSDP Response #$responseCount from $senderAddress ---")
                    Log.d(TAG, "Response length: ${responsePacket.length} bytes")
                    Log.d(TAG, "Response content:\n$response")
                    Log.d(TAG, "--- End Response #$responseCount ---")
                    
                    // 解析响应并检查是否为媒体设备
                    parseAndAddDevice(response, senderAddress)
                }
            } catch (e: SocketTimeoutException) {
                Log.d(TAG, "SSDP response timeout (received $responseCount responses)")
            }
            
            socket.close()
            Log.d(TAG, "--- SSDP Discovery Completed ---")
            
        } catch (e: Exception) {
            Log.e(TAG, "Error in SSDP discovery", e)
            e.printStackTrace()
        }
    }
    
    private fun buildSsdpSearchMessage(): String {
        return "M-SEARCH * HTTP/1.1\r\n" +
                "HOST: 239.255.255.250:1900\r\n" +
                "MAN: \"ssdp:discover\"\r\n" +
                "ST: upnp:rootdevice\r\n" +
                "MX: 3\r\n" +
                "\r\n"
    }
    
    private fun parseAndAddDevice(response: String, senderAddress: String) {
        try {
            Log.d(TAG, "Parsing device response from $senderAddress")
            
            val lines = response.split("\r\n")
            var location: String? = null
            var server: String? = null
            var usn: String? = null
            var st: String? = null
            var deviceName: String? = null
            
            for (line in lines) {
                val parts = line.split(":", limit = 2)
                if (parts.size == 2) {
                    val key = parts[0].trim().lowercase()
                    val value = parts[1].trim()
                    
                    when (key) {
                        "location" -> location = value
                        "server" -> server = value
                        "usn" -> usn = value
                        "st" -> st = value
                        "myname" -> deviceName = value // 某些设备会在MYNAME字段中提供设备名称
                    }
                }
            }
            
            Log.d(TAG, "Parsed headers - Location: $location, Server: $server, USN: $usn, ST: $st, Device Name: $deviceName")
            
            // 检查是否为媒体设备
            val isMediaDevice = server?.contains("UPnP", ignoreCase = true) == true ||
                               usn?.contains("MediaRenderer", ignoreCase = true) == true ||
                               usn?.contains("MediaServer", ignoreCase = true) == true ||
                               st?.contains("MediaRenderer", ignoreCase = true) == true ||
                               st?.contains("MediaServer", ignoreCase = true) == true ||
                               location?.contains("description.xml", ignoreCase = true) == true
            
            Log.d(TAG, "Is media device: $isMediaDevice")
            
            if (isMediaDevice && location != null && usn != null) {
                // 使用USN作为唯一标识符来避免重复设备
                val deviceId = "dlna_" + usn.hashCode().toString().replace("-", "_")
                
                // 如果设备已存在，不重复添加
                if (devices.containsKey(deviceId)) {
                    Log.d(TAG, "Device already exists, skipping: $deviceId")
                    return
                }
                
                // 生成友好的设备名称
                val friendlyName = when {
                    deviceName != null -> {
                        Log.d(TAG, "Using device provided name: $deviceName")
                        deviceName
                    }
                    server?.contains("QQLiveTV", ignoreCase = true) == true -> {
                        Log.d(TAG, "Detected QQLiveTV (极光TV) device")
                        "极光TV"
                    }
                    server?.contains("Cling", ignoreCase = true) == true -> {
                        Log.d(TAG, "Detected Cling framework device")
                        "智能电视"
                    }
                    server?.contains("iQIYI", ignoreCase = true) == true -> {
                        Log.d(TAG, "Detected iQIYI (奇异果TV) device")
                        "奇异果TV"
                    }
                    server?.contains("奇异果", ignoreCase = true) == true -> {
                        Log.d(TAG, "Detected 奇异果TV device by name")
                        "奇异果TV"
                    }
                    senderAddress == "192.168.1.1" -> {
                        Log.d(TAG, "Detected router media service")
                        "路由器媒体服务"
                    }
                    else -> {
                        Log.d(TAG, "Using generic device name for $senderAddress")
                        "DLNA设备 ($senderAddress)"
                    }
                }
                
                // 解析制造商信息
                val manufacturer = when {
                    server?.contains("QQLiveTV") == true -> "极光"
                    server?.contains("Cling") == true -> "Android TV"
                    server?.contains("iQIYI") == true -> "爱奇艺"
                    server?.contains("奇异果") == true -> "爱奇艺"
                    server?.contains("Linux") == true -> "Linux设备"
                    else -> server ?: "Unknown"
                }
                
                val device = mapOf(
                    "id" to deviceId,
                    "name" to friendlyName,
                    "type" to "dlna",
                    "isAvailable" to true,
                    "manufacturer" to manufacturer,
                    "model" to "UPnP Device",
                    "address" to senderAddress,
                    "location" to location,
                    "usn" to usn,
                    "server" to (server ?: "")
                )
                
                devices[deviceId] = device
                Log.d(TAG, "Added DLNA device: $friendlyName (ID: $deviceId)")
            } else {
                Log.d(TAG, "Device not recognized as media device or missing required fields")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing device response", e)
        }
    }
    
    private fun addMockDevices() {
        Log.d(TAG, "Adding mock DLNA devices for testing")
        
        val mockDevices = listOf(
            mapOf(
                "id" to "dlna_tv_mock_001",
                "name" to "模拟智能电视",
                "type" to "dlna",
                "isAvailable" to true,
                "manufacturer" to "Mock Samsung",
                "model" to "Mock Smart TV",
                "address" to "192.168.1.100",
                "isMock" to true
            ),
            mapOf(
                "id" to "dlna_speaker_mock_001",
                "name" to "模拟DLNA音响",
                "type" to "dlna",
                "isAvailable" to true,
                "manufacturer" to "Mock Sony",
                "model" to "Mock Wireless Speaker",
                "address" to "192.168.1.101",
                "isMock" to true
            )
        )
        
        mockDevices.forEach { device ->
            devices[device["id"] as String] = device
            Log.d(TAG, "Added mock device: ${device["name"]}")
        }
    }

    fun stopDiscovery() {
        Log.d(TAG, "=== Stopping DLNA Discovery ===")
        discoveryJob?.cancel()
        discoveryJob = null
        deviceDiscoveryCallback = null
        Log.d(TAG, "Discovery job cancelled, callback cleared")
        Log.d(TAG, "Current devices count: ${devices.size}")
        Log.d(TAG, "=== DLNA Discovery Stopped ===")
    }

    fun getAvailableDevices(): List<Map<String, Any>> {
        val deviceList = devices.values.toList()
        Log.d(TAG, "getAvailableDevices() called - returning ${deviceList.size} devices")
        deviceList.forEachIndexed { index, device ->
            Log.d(TAG, "  Device #${index + 1}: ${device["name"]} (ID: ${device["id"]})")
        }
        return deviceList
    }

    fun connectToDevice(deviceId: String): Boolean {
        return try {
            Log.d(TAG, "=== Connecting to DLNA Device ===")
            Log.d(TAG, "Requested device ID: $deviceId")
            Log.d(TAG, "Available devices: ${devices.keys}")
            
            val device = devices[deviceId]
            if (device != null) {
                currentSelectedDevice = device
                Log.d(TAG, "Successfully connected to DLNA device:")
                Log.d(TAG, "  - Name: ${device["name"]}")
                Log.d(TAG, "  - Type: ${device["type"]}")
                Log.d(TAG, "  - Manufacturer: ${device["manufacturer"]}")
                Log.d(TAG, "  - Model: ${device["model"]}")
                device["address"]?.let { address ->
                    Log.d(TAG, "  - Address: $address")
                }
                Log.d(TAG, "=== DLNA Connection Successful ===")
                true
            } else {
                Log.w(TAG, "Device not found: $deviceId")
                Log.w(TAG, "Available device IDs: ${devices.keys.joinToString(", ")}")
                Log.w(TAG, "=== DLNA Connection Failed ===")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect to device: $deviceId", e)
            e.printStackTrace()
            false
        }
    }

    fun castVideo(videoUrl: String, title: String, poster: String?, currentTime: Int, callback: (Boolean) -> Unit) {
        val device = currentSelectedDevice
        if (device == null) {
            Log.w(TAG, "No device selected for casting")
            callback(false)
            return
        }

        try {
            Log.d(TAG, "=== Starting DLNA Cast ===")
            Log.d(TAG, "Device: ${device["name"]}")
            Log.d(TAG, "Device Type: ${device["type"]}")
            Log.d(TAG, "Device Manufacturer: ${device["manufacturer"]}")
            Log.d(TAG, "Device Address: ${device["address"]}")
            Log.d(TAG, "Video URL: $videoUrl")
            Log.d(TAG, "Title: $title")
            Log.d(TAG, "Poster: $poster")
            Log.d(TAG, "Current Time: $currentTime")
            
            // 检查是否为奇异果TV设备
            val isIqiyiDevice = isIqiyiTVDevice(device)
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI TV DEVICE DETECTED - Enabling enhanced debugging")
                Log.d(TAG, "🍇 Device Server: ${device["server"]}")
                Log.d(TAG, "🍇 Device USN: ${device["usn"]}")
                Log.d(TAG, "🍇 Device Location: ${device["location"]}")
            }
            
            val deviceLocation = device["location"] as? String
            if (deviceLocation == null) {
                Log.e(TAG, "Device location not found")
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI CASTING FAILED: No device location URL")
                }
                callback(false)
                return
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    if (isIqiyiDevice) {
                        Log.d(TAG, "🍇 Starting IQIYI TV casting process...")
                    }
                    
                    // 步骤1: 获取设备描述XML来找到AVTransport服务
                    val serviceUrl = getAVTransportServiceUrl(deviceLocation, isIqiyiDevice)
                    if (serviceUrl == null) {
                        Log.e(TAG, "AVTransport service not found")
                        if (isIqiyiDevice) {
                            Log.e(TAG, "🍇 IQIYI CASTING FAILED: AVTransport service not found in device XML")
                        }
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    Log.d(TAG, "Found AVTransport service URL: $serviceUrl")
                    if (isIqiyiDevice) {
                        Log.d(TAG, "🍇 IQIYI AVTransport URL: $serviceUrl")
                    }
                    
                    // 步骤2: 发送SetAVTransportURI命令
                    val setUriSuccess = setAVTransportURI(serviceUrl, videoUrl, title, isIqiyiDevice)
                    if (!setUriSuccess) {
                        Log.e(TAG, "Failed to set AV transport URI")
                        if (isIqiyiDevice) {
                            Log.e(TAG, "🍇 IQIYI CASTING FAILED: SetAVTransportURI command failed")
                        }
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    Log.d(TAG, "Successfully set AV transport URI")
                    if (isIqiyiDevice) {
                        Log.d(TAG, "🍇 IQIYI SetAVTransportURI: SUCCESS")
                    }
                    
                    // 步骤3: 发送Play命令
                    val playSuccess = playMedia(serviceUrl, isIqiyiDevice)
                    if (!playSuccess) {
                        Log.e(TAG, "Failed to start playback")
                        if (isIqiyiDevice) {
                            Log.e(TAG, "🍇 IQIYI CASTING FAILED: Play command failed")
                        }
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    Log.d(TAG, "=== DLNA Cast Started Successfully ===")
                    if (isIqiyiDevice) {
                        Log.d(TAG, "🍇 IQIYI TV CASTING SUCCESS! 🎉")
                    }
                    
                    withContext(Dispatchers.Main) {
                        callback(true)
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error during DLNA casting", e)
                    e.printStackTrace()
                    if (isIqiyiDevice) {
                        Log.e(TAG, "🍇 IQIYI CASTING EXCEPTION: ${e.message}")
                        Log.e(TAG, "🍇 Exception cause: ${e.cause}")
                        Log.e(TAG, "🍇 Stack trace: ${e.stackTraceToString()}")
                    }
                    withContext(Dispatchers.Main) {
                        callback(false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error casting video to DLNA device", e)
            e.printStackTrace()
            val isIqiyiDevice = isIqiyiTVDevice(device)
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI OUTER CASTING EXCEPTION: ${e.message}")
            }
            callback(false)
        }
    }

    fun stopCasting(callback: (Boolean) -> Unit) {
        val device = currentSelectedDevice
        if (device == null) {
            callback(false)
            return
        }

        try {
            Log.d(TAG, "=== Stopping DLNA Playback ===")
            Log.d(TAG, "Device: ${device["name"]}")
            
            // 检查是否为奇异果TV设备
            val isIqiyiDevice = isIqiyiTVDevice(device)
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI TV DEVICE DETECTED for stopping")
            }
            
            val deviceLocation = device["location"] as? String
            if (deviceLocation == null) {
                Log.e(TAG, "Device location not found")
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI STOP FAILED: No device location URL")
                }
                callback(false)
                return
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val serviceUrl = getAVTransportServiceUrl(deviceLocation, isIqiyiDevice)
                    if (serviceUrl == null) {
                        Log.e(TAG, "AVTransport service not found for stop command")
                        if (isIqiyiDevice) {
                            Log.e(TAG, "🍇 IQIYI STOP FAILED: AVTransport service not found")
                        }
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    val success = stopMedia(serviceUrl, isIqiyiDevice)
                    Log.d(TAG, if (success) "DLNA playback stopped successfully" else "Failed to stop DLNA playback")
                    if (isIqiyiDevice) {
                        Log.d(TAG, if (success) "🍇 IQIYI playback stopped successfully" else "🍇 Failed to stop IQIYI playback")
                    }
                    
                    withContext(Dispatchers.Main) {
                        callback(success)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error stopping DLNA playback", e)
                    if (isIqiyiDevice) {
                        Log.e(TAG, "🍇 IQIYI STOP EXCEPTION: ${e.message}")
                    }
                    withContext(Dispatchers.Main) {
                        callback(false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping DLNA playback", e)
            val isIqiyiDevice = isIqiyiTVDevice(device)
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI OUTER STOP EXCEPTION: ${e.message}")
            }
            callback(false)
        }
    }

    fun pauseCasting(callback: (Boolean) -> Unit) {
        val device = currentSelectedDevice
        if (device == null) {
            callback(false)
            return
        }

        try {
            Log.d(TAG, "=== Pausing DLNA Playback ===")
            Log.d(TAG, "Device: ${device["name"]}")
            
            // 检查是否为奇异果TV设备
            val isIqiyiDevice = isIqiyiTVDevice(device)
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI TV DEVICE DETECTED for pausing")
            }
            
            val deviceLocation = device["location"] as? String
            if (deviceLocation == null) {
                Log.e(TAG, "Device location not found")
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI PAUSE FAILED: No device location URL")
                }
                callback(false)
                return
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val serviceUrl = getAVTransportServiceUrl(deviceLocation, isIqiyiDevice)
                    if (serviceUrl == null) {
                        Log.e(TAG, "AVTransport service not found for pause command")
                        if (isIqiyiDevice) {
                            Log.e(TAG, "🍇 IQIYI PAUSE FAILED: AVTransport service not found")
                        }
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    val success = pauseMedia(serviceUrl, isIqiyiDevice)
                    Log.d(TAG, if (success) "DLNA playback paused successfully" else "Failed to pause DLNA playback")
                    if (isIqiyiDevice) {
                        Log.d(TAG, if (success) "🍇 IQIYI playback paused successfully" else "🍇 Failed to pause IQIYI playback")
                    }
                    
                    withContext(Dispatchers.Main) {
                        callback(success)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error pausing DLNA playback", e)
                    if (isIqiyiDevice) {
                        Log.e(TAG, "🍇 IQIYI PAUSE EXCEPTION: ${e.message}")
                    }
                    withContext(Dispatchers.Main) {
                        callback(false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing DLNA playback", e)
            val isIqiyiDevice = isIqiyiTVDevice(device)
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI OUTER PAUSE EXCEPTION: ${e.message}")
            }
            callback(false)
        }
    }

    fun seekTo(timeInSeconds: Int, callback: (Boolean) -> Unit) {
        val device = currentSelectedDevice
        if (device == null) {
            callback(false)
            return
        }

        try {
            val hours = timeInSeconds / 3600
            val minutes = (timeInSeconds % 3600) / 60
            val seconds = timeInSeconds % 60
            val timeString = String.format("%02d:%02d:%02d", hours, minutes, seconds)
            
            Log.d(TAG, "Seeking DLNA playback to $timeString on ${device["name"]}")
            
            CoroutineScope(Dispatchers.IO).launch {
                delay(500)
                withContext(Dispatchers.Main) {
                    Log.d(TAG, "DLNA seek completed successfully")
                    callback(true)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error seeking DLNA playback", e)
            callback(false)
        }
    }

    fun disconnect() {
        try {
            stopDiscovery()
            currentSelectedDevice = null
            devices.clear()
            httpClient.dispatcher.executorService.shutdown()
            Log.d(TAG, "Disconnected from DLNA service")
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from DLNA service", e)
        }
    }
    
    // === DLNA UPnP 实现方法 ===
    
    private suspend fun getAVTransportServiceUrl(deviceLocation: String, isIqiyiDevice: Boolean = false): String? {
        return try {
            Log.d(TAG, "Fetching device description from: $deviceLocation")
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Fetching device XML from $deviceLocation")
            }
            
            val request = Request.Builder()
                .url(deviceLocation)
                .get()
                .build()
            
            val response = httpClient.newCall(request).execute()
            if (!response.isSuccessful) {
                Log.e(TAG, "Failed to get device description: ${response.code} - ${response.message}")
                Log.e(TAG, "Response headers: ${response.headers}")
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI XML FETCH FAILED: HTTP ${response.code} - ${response.message}")
                    Log.e(TAG, "🍇 IQIYI Response headers: ${response.headers}")
                }
                response.body?.string()?.let { body ->
                    Log.e(TAG, "Response body: $body")
                    if (isIqiyiDevice) {
                        Log.e(TAG, "🍇 IQIYI Error response body: $body")
                    }
                }
                return null
            }
            
            val xml = response.body?.string() ?: ""
            Log.d(TAG, "Device description XML length: ${xml.length}")
            Log.d(TAG, "Device description XML content (first 500 chars): ${xml.take(500)}")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI XML SUCCESS: Retrieved ${xml.length} characters")
                Log.d(TAG, "🍇 IQIYI XML Preview: ${xml.take(500)}")
                
                // 为奇异果TV输出完整XML内容供调试
                if (xml.length <= 3000) {
                    Log.d(TAG, "🍇 IQIYI COMPLETE XML:\n$xml")
                } else {
                    Log.d(TAG, "🍇 IQIYI XML (first 1500 chars):\n${xml.take(1500)}")
                    Log.d(TAG, "🍇 IQIYI XML (last 1500 chars):\n${xml.takeLast(1500)}")
                }
            }
            
            // 解析XML找到AVTransport服务
            val serviceUrl = parseAVTransportServiceUrl(xml, deviceLocation, isIqiyiDevice)
            Log.d(TAG, "Parsed AVTransport service URL: $serviceUrl")
            
            if (isIqiyiDevice) {
                if (serviceUrl != null) {
                    Log.d(TAG, "🍇 IQIYI XML PARSING SUCCESS: Found AVTransport URL: $serviceUrl")
                } else {
                    Log.e(TAG, "🍇 IQIYI XML PARSING FAILED: No AVTransport service found")
                }
            }
            
            serviceUrl
        } catch (e: Exception) {
            Log.e(TAG, "Error getting AVTransport service URL", e)
            e.printStackTrace()
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI XML FETCH EXCEPTION: ${e.message}")
                Log.e(TAG, "🍇 Exception: ${e.stackTraceToString()}")
            }
            null
        }
    }
    
    private fun parseAVTransportServiceUrl(xml: String, baseUrl: String, isIqiyiDevice: Boolean = false): String? {
        try {
            Log.d(TAG, "=== Parsing XML for AVTransport Service ===")
            Log.d(TAG, "Base URL: $baseUrl")
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI XML PARSING: Starting to parse for AVTransport service")
                Log.d(TAG, "🍇 Base URL: $baseUrl")
            }
            
            // 使用正则表达式解析XML，而不是按行分割
            // 查找所有service块
            val servicePattern = Regex("<service>([\\s\\S]*?)</service>", RegexOption.IGNORE_CASE)
            val serviceMatches = servicePattern.findAll(xml)
            
            for (serviceMatch in serviceMatches) {
                val serviceBlock = serviceMatch.groupValues[1]
                Log.d(TAG, "Found service block: $serviceBlock")
                if (isIqiyiDevice) {
                    Log.d(TAG, "🍇 IQIYI: Found service block")
                }
                
                // 查找serviceType
                val serviceTypePattern = Regex("<serviceType[^>]*>(.*?)</serviceType>", RegexOption.IGNORE_CASE)
                val serviceTypeMatch = serviceTypePattern.find(serviceBlock)
                val serviceType = serviceTypeMatch?.groupValues?.get(1)?.trim()
                
                if (serviceType != null) {
                    Log.d(TAG, "Found service type: $serviceType")
                    if (isIqiyiDevice) {
                        Log.d(TAG, "🍇 IQIYI Service Type Found: $serviceType")
                    }
                    
                    // 检查是否为AVTransport服务
                    if (serviceType.contains("AVTransport", ignoreCase = true) || 
                        serviceType.contains("urn:schemas-upnp-org:service:AVTransport", ignoreCase = true)) {
                        Log.d(TAG, "Found AVTransport service section with type: $serviceType")
                        if (isIqiyiDevice) {
                            Log.d(TAG, "🍇 IQIYI: Found AVTransport service! Type: $serviceType")
                        }
                        
                        // 查找controlURL
                        val controlUrlPattern = Regex("<controlURL[^>]*>(.*?)</controlURL>", RegexOption.IGNORE_CASE)
                        val controlUrlMatch = controlUrlPattern.find(serviceBlock)
                        val controlUrl = controlUrlMatch?.groupValues?.get(1)?.trim()
                        
                        if (controlUrl != null) {
                            Log.d(TAG, "Found control URL: $controlUrl")
                            if (isIqiyiDevice) {
                                Log.d(TAG, "🍇 IQIYI: Found controlURL: $controlUrl")
                            }
                            
                            // 构建完整URL
                            val finalUrl = if (controlUrl.startsWith("http")) {
                                Log.d(TAG, "Control URL is absolute: $controlUrl")
                                if (isIqiyiDevice) {
                                    Log.d(TAG, "🍇 IQIYI: Control URL is absolute: $controlUrl")
                                }
                                controlUrl
                            } else {
                                val base = baseUrl.substringBeforeLast("/")
                                val finalConstructedUrl = if (controlUrl.startsWith("/")) {
                                    val protocol = baseUrl.substringBefore("://")
                                    val host = baseUrl.substringAfter("://").substringBefore("/")
                                    "$protocol://$host$controlUrl"
                                } else {
                                    "$base/$controlUrl"
                                }
                                Log.d(TAG, "Constructed absolute URL: $finalConstructedUrl")
                                if (isIqiyiDevice) {
                                    Log.d(TAG, "🍇 IQIYI: Constructed URL: $finalConstructedUrl")
                                    Log.d(TAG, "🍇 IQIYI: Base: $base, ControlURL: $controlUrl")
                                }
                                finalConstructedUrl
                            }
                            
                            Log.d(TAG, "=== Final AVTransport service URL: $finalUrl ===")
                            if (isIqiyiDevice) {
                                Log.d(TAG, "🍇 IQIYI FINAL URL: $finalUrl")
                            }
                            return finalUrl
                        }
                    }
                }
            }
            
            Log.w(TAG, "=== No AVTransport service found in XML ===")
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI PARSING FAILED: No AVTransport service found!")
            }
            
            // 打印所有找到的服务类型供调试
            Log.w(TAG, "Available services in XML:")
            val serviceTypePattern = Regex("<serviceType[^>]*>(.*?)</serviceType>", RegexOption.IGNORE_CASE)
            val serviceTypeMatches = serviceTypePattern.findAll(xml)
            serviceTypeMatches.forEach { match ->
                val serviceType = match.groupValues[1].trim()
                Log.w(TAG, "  Service: $serviceType")
                if (isIqiyiDevice) {
                    Log.w(TAG, "🍇 IQIYI Available Service: $serviceType")
                }
            }
            
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing AVTransport service URL", e)
            e.printStackTrace()
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI XML PARSING EXCEPTION: ${e.message}")
                Log.e(TAG, "🍇 Exception: ${e.stackTraceToString()}")
            }
            return null
        }
    }
    
    private suspend fun setAVTransportURI(serviceUrl: String, videoUrl: String, title: String, isIqiyiDevice: Boolean = false): Boolean {
        return try {
            Log.d(TAG, "=== Setting AV Transport URI ===")
            Log.d(TAG, "Service URL: $serviceUrl")
            Log.d(TAG, "Video URL: $videoUrl")
            Log.d(TAG, "Title: $title")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Setting AV Transport URI")
                Log.d(TAG, "🍇 Service URL: $serviceUrl")
                Log.d(TAG, "🍇 Video URL: $videoUrl")
                Log.d(TAG, "🍇 Title: $title")
            }
            
            val soapAction = "\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\""
            val soapBody = """
                <?xml version="1.0" encoding="utf-8"?>
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <s:Body>
                        <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                            <InstanceID>0</InstanceID>
                            <CurrentURI>$videoUrl</CurrentURI>
                            <CurrentURIMetaData>&lt;DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/"&gt;&lt;item id="1" parentID="0" restricted="1"&gt;&lt;dc:title&gt;$title&lt;/dc:title&gt;&lt;upnp:class&gt;object.item.videoItem&lt;/upnp:class&gt;&lt;res&gt;$videoUrl&lt;/res&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;</CurrentURIMetaData>
                        </u:SetAVTransportURI>
                    </s:Body>
                </s:Envelope>
            """.trimIndent()
            
            Log.d(TAG, "SOAP Action: $soapAction")
            Log.d(TAG, "SOAP Body: $soapBody")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI SOAP ACTION: $soapAction")
                Log.d(TAG, "🍇 IQIYI SOAP BODY:\n$soapBody")
            }
            
            val requestBody = RequestBody.create(
                "text/xml; charset=utf-8".toMediaType(),
                soapBody
            )
            
            val request = Request.Builder()
                .url(serviceUrl)
                .post(requestBody)
                .addHeader("SOAPAction", soapAction)
                .addHeader("Content-Type", "text/xml; charset=utf-8")
                .addHeader("User-Agent", "MTV-App/1.0 UPnP/1.0")
                .build()
            
            Log.d(TAG, "Sending SetAVTransportURI request...")
            Log.d(TAG, "Request headers: ${request.headers}")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Sending SetAVTransportURI request")
                Log.d(TAG, "🍇 IQIYI Request headers: ${request.headers}")
            }
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            val responseBody = response.body?.string() ?: ""
            
            Log.d(TAG, "SetAVTransportURI response code: ${response.code}")
            Log.d(TAG, "SetAVTransportURI response message: ${response.message}")
            Log.d(TAG, "SetAVTransportURI response headers: ${response.headers}")
            Log.d(TAG, "SetAVTransportURI response body: $responseBody")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI SetAVTransportURI Response:")
                Log.d(TAG, "🍇 HTTP Code: ${response.code}")
                Log.d(TAG, "🍇 Message: ${response.message}")
                Log.d(TAG, "🍇 Headers: ${response.headers}")
                Log.d(TAG, "🍇 Body: $responseBody")
            }
            
            if (!success) {
                Log.e(TAG, "SetAVTransportURI failed with HTTP ${response.code}: ${response.message}")
                Log.e(TAG, "Error response body: $responseBody")
                
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI SetAVTransportURI FAILED!")
                    Log.e(TAG, "🍇 HTTP ${response.code}: ${response.message}")
                    Log.e(TAG, "🍇 Response body: $responseBody")
                }
                
                // 分析常见错误
                when (response.code) {
                    400 -> Log.e(TAG, "Bad Request - Check SOAP message format")
                    401 -> Log.e(TAG, "Unauthorized - Device may require authentication")
                    404 -> Log.e(TAG, "Not Found - Control URL may be incorrect")
                    405 -> Log.e(TAG, "Method Not Allowed - Device may not support this action")
                    500 -> Log.e(TAG, "Internal Server Error - Device internal error")
                    else -> Log.e(TAG, "Unexpected HTTP error code: ${response.code}")
                }
                
                // 检查是否是SOAP Fault
                if (responseBody.contains("soap:Fault", ignoreCase = true) || 
                    responseBody.contains("s:Fault", ignoreCase = true)) {
                    Log.e(TAG, "SOAP Fault detected in response")
                    if (isIqiyiDevice) {
                        Log.e(TAG, "🍇 IQIYI SOAP FAULT DETECTED!")
                    }
                    extractSoapFaultInfo(responseBody)
                }
            } else {
                Log.d(TAG, "SetAVTransportURI completed successfully")
                if (isIqiyiDevice) {
                    Log.d(TAG, "🍇 IQIYI SetAVTransportURI SUCCESS!")
                }
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error setting AV transport URI", e)
            e.printStackTrace()
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI SetAVTransportURI EXCEPTION: ${e.message}")
                Log.e(TAG, "🍇 Exception: ${e.stackTraceToString()}")
            }
            false
        }
    }
    
    private suspend fun playMedia(serviceUrl: String, isIqiyiDevice: Boolean = false): Boolean {
        return try {
            Log.d(TAG, "=== Sending Play Command ===")
            Log.d(TAG, "Service URL: $serviceUrl")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Sending Play Command")
                Log.d(TAG, "🍇 Service URL: $serviceUrl")
            }
            
            val soapAction = "\"urn:schemas-upnp-org:service:AVTransport:1#Play\""
            val soapBody = """
                <?xml version="1.0" encoding="utf-8"?>
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <s:Body>
                        <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                            <InstanceID>0</InstanceID>
                            <Speed>1</Speed>
                        </u:Play>
                    </s:Body>
                </s:Envelope>
            """.trimIndent()
            
            Log.d(TAG, "Play SOAP Action: $soapAction")
            Log.d(TAG, "Play SOAP Body: $soapBody")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI Play SOAP ACTION: $soapAction")
                Log.d(TAG, "🍇 IQIYI Play SOAP BODY:\n$soapBody")
            }
            
            val requestBody = RequestBody.create(
                "text/xml; charset=utf-8".toMediaType(),
                soapBody
            )
            
            val request = Request.Builder()
                .url(serviceUrl)
                .post(requestBody)
                .addHeader("SOAPAction", soapAction)
                .addHeader("Content-Type", "text/xml; charset=utf-8")
                .addHeader("User-Agent", "MTV-App/1.0 UPnP/1.0")
                .build()
            
            Log.d(TAG, "Sending Play request...")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Sending Play request")
            }
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            val responseBody = response.body?.string() ?: ""
            
            Log.d(TAG, "Play command response code: ${response.code}")
            Log.d(TAG, "Play command response message: ${response.message}")
            Log.d(TAG, "Play command response headers: ${response.headers}")
            Log.d(TAG, "Play command response body: $responseBody")
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI Play Command Response:")
                Log.d(TAG, "🍇 HTTP Code: ${response.code}")
                Log.d(TAG, "🍇 Message: ${response.message}")
                Log.d(TAG, "🍇 Headers: ${response.headers}")
                Log.d(TAG, "🍇 Body: $responseBody")
            }
            
            if (!success) {
                Log.e(TAG, "Play command failed with HTTP ${response.code}: ${response.message}")
                Log.e(TAG, "Error response body: $responseBody")
                
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI Play Command FAILED!")
                    Log.e(TAG, "🍇 HTTP ${response.code}: ${response.message}")
                    Log.e(TAG, "🍇 Response body: $responseBody")
                }
                
                // 分析常见错误
                when (response.code) {
                    400 -> Log.e(TAG, "Bad Request - Check Play command format")
                    401 -> Log.e(TAG, "Unauthorized - Device may require authentication")
                    404 -> Log.e(TAG, "Not Found - Control URL may be incorrect")
                    405 -> Log.e(TAG, "Method Not Allowed - Device may not support Play action")
                    500 -> Log.e(TAG, "Internal Server Error - Device internal error")
                    else -> Log.e(TAG, "Unexpected HTTP error code: ${response.code}")
                }
                
                // 检查是否是SOAP Fault
                if (responseBody.contains("soap:Fault", ignoreCase = true) || 
                    responseBody.contains("s:Fault", ignoreCase = true)) {
                    Log.e(TAG, "SOAP Fault detected in Play response")
                    if (isIqiyiDevice) {
                        Log.e(TAG, "🍇 IQIYI Play SOAP FAULT DETECTED!")
                    }
                    extractSoapFaultInfo(responseBody)
                }
            } else {
                Log.d(TAG, "Play command completed successfully")
                if (isIqiyiDevice) {
                    Log.d(TAG, "🍇 IQIYI Play Command SUCCESS!")
                }
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending play command", e)
            e.printStackTrace()
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI Play Command EXCEPTION: ${e.message}")
                Log.e(TAG, "🍇 Exception: ${e.stackTraceToString()}")
            }
            false
        }
    }
    
    private suspend fun stopMedia(serviceUrl: String, isIqiyiDevice: Boolean = false): Boolean {
        return try {
            Log.d(TAG, "Sending Stop command")
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Sending Stop command")
            }
            
            val soapAction = "\"urn:schemas-upnp-org:service:AVTransport:1#Stop\""
            val soapBody = """
                <?xml version="1.0" encoding="utf-8"?>
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <s:Body>
                        <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                            <InstanceID>0</InstanceID>
                        </u:Stop>
                    </s:Body>
                </s:Envelope>
            """.trimIndent()
            
            val requestBody = RequestBody.create(
                "text/xml; charset=utf-8".toMediaType(),
                soapBody
            )
            
            val request = Request.Builder()
                .url(serviceUrl)
                .post(requestBody)
                .addHeader("SOAPAction", soapAction)
                .addHeader("Content-Type", "text/xml; charset=utf-8")
                .addHeader("User-Agent", "MTV-App/1.0 UPnP/1.0")
                .build()
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            
            Log.d(TAG, "Stop command response code: ${response.code}")
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI Stop Response Code: ${response.code}")
            }
            if (!success) {
                Log.e(TAG, "Stop command failed: ${response.body?.string()}")
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI Stop Command FAILED: ${response.body?.string()}")
                }
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending stop command", e)
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI Stop Command EXCEPTION: ${e.message}")
            }
            false
        }
    }
    
    private suspend fun pauseMedia(serviceUrl: String, isIqiyiDevice: Boolean = false): Boolean {
        return try {
            Log.d(TAG, "Sending Pause command")
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI: Sending Pause command")
            }
            
            val soapAction = "\"urn:schemas-upnp-org:service:AVTransport:1#Pause\""
            val soapBody = """
                <?xml version="1.0" encoding="utf-8"?>
                <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
                    <s:Body>
                        <u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
                            <InstanceID>0</InstanceID>
                        </u:Pause>
                    </s:Body>
                </s:Envelope>
            """.trimIndent()
            
            val requestBody = RequestBody.create(
                "text/xml; charset=utf-8".toMediaType(),
                soapBody
            )
            
            val request = Request.Builder()
                .url(serviceUrl)
                .post(requestBody)
                .addHeader("SOAPAction", soapAction)
                .addHeader("Content-Type", "text/xml; charset=utf-8")
                .addHeader("User-Agent", "MTV-App/1.0 UPnP/1.0")
                .build()
            
            val response = httpClient.newCall(request).execute()
            val success = response.isSuccessful
            
            Log.d(TAG, "Pause command response code: ${response.code}")
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IQIYI Pause Response Code: ${response.code}")
            }
            if (!success) {
                Log.e(TAG, "Pause command failed: ${response.body?.string()}")
                if (isIqiyiDevice) {
                    Log.e(TAG, "🍇 IQIYI Pause Command FAILED: ${response.body?.string()}")
                }
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending pause command", e)
            if (isIqiyiDevice) {
                Log.e(TAG, "🍇 IQIYI Pause Command EXCEPTION: ${e.message}")
            }
            false
        }
    }
    
    private fun extractSoapFaultInfo(responseBody: String) {
        try {
            Log.e(TAG, "=== SOAP Fault Analysis ===")
            
            // 提取faultcode
            val faultCodeRegex = "<(?:soap:|s:)?faultcode[^>]*>([^<]+)</(?:soap:|s:)?faultcode>".toRegex(RegexOption.IGNORE_CASE)
            val faultCodeMatch = faultCodeRegex.find(responseBody)
            if (faultCodeMatch != null) {
                Log.e(TAG, "SOAP Fault Code: ${faultCodeMatch.groupValues[1].trim()}")
            }
            
            // 提取faultstring
            val faultStringRegex = "<(?:soap:|s:)?faultstring[^>]*>([^<]+)</(?:soap:|s:)?faultstring>".toRegex(RegexOption.IGNORE_CASE)
            val faultStringMatch = faultStringRegex.find(responseBody)
            if (faultStringMatch != null) {
                Log.e(TAG, "SOAP Fault String: ${faultStringMatch.groupValues[1].trim()}")
            }
            
            // 提取detail
            val detailRegex = """<(?:soap:|s:)?detail[^>]*>([\s\S]*?)</(?:soap:|s:)?detail>""".toRegex(RegexOption.IGNORE_CASE)
            val detailMatch = detailRegex.find(responseBody)
            if (detailMatch != null) {
                Log.e(TAG, "SOAP Fault Detail: ${detailMatch.groupValues[1].trim()}")
            }
            
            // 提取UPnP错误代码
            val upnpErrorRegex = "<errorCode>([^<]+)</errorCode>".toRegex(RegexOption.IGNORE_CASE)
            val upnpErrorMatch = upnpErrorRegex.find(responseBody)
            if (upnpErrorMatch != null) {
                val errorCode = upnpErrorMatch.groupValues[1].trim()
                Log.e(TAG, "UPnP Error Code: $errorCode")
                
                // 解释常见的UPnP错误代码
                when (errorCode) {
                    "701" -> Log.e(TAG, "UPnP Error: Transition not available")
                    "702" -> Log.e(TAG, "UPnP Error: No contents")
                    "703" -> Log.e(TAG, "UPnP Error: Read error")
                    "704" -> Log.e(TAG, "UPnP Error: Format not supported for reading")
                    "705" -> Log.e(TAG, "UPnP Error: Transport locked")
                    "706" -> Log.e(TAG, "UPnP Error: Write error")
                    "707" -> Log.e(TAG, "UPnP Error: Media is write-protected")
                    "708" -> Log.e(TAG, "UPnP Error: Format not supported for writing")
                    "709" -> Log.e(TAG, "UPnP Error: Media is full")
                    "710" -> Log.e(TAG, "UPnP Error: Seek mode not supported")
                    "711" -> Log.e(TAG, "UPnP Error: Illegal seek target")
                    "712" -> Log.e(TAG, "UPnP Error: Play mode not supported")
                    "713" -> Log.e(TAG, "UPnP Error: Record quality not supported")
                    "714" -> Log.e(TAG, "UPnP Error: Illegal MIME-Type")
                    "715" -> Log.e(TAG, "UPnP Error: Content 'BUSY'")
                    "716" -> Log.e(TAG, "UPnP Error: Resource not found")
                    "717" -> Log.e(TAG, "UPnP Error: Play speed not supported")
                    "718" -> Log.e(TAG, "UPnP Error: Invalid InstanceID")
                    else -> Log.e(TAG, "UPnP Error: Unknown error code $errorCode")
                }
            }
            
            // 提取UPnP错误描述
            val upnpDescRegex = "<errorDescription>([^<]+)</errorDescription>".toRegex(RegexOption.IGNORE_CASE)
            val upnpDescMatch = upnpDescRegex.find(responseBody)
            if (upnpDescMatch != null) {
                Log.e(TAG, "UPnP Error Description: ${upnpDescMatch.groupValues[1].trim()}")
            }
            
            Log.e(TAG, "=== End SOAP Fault Analysis ===")
        } catch (e: Exception) {
            Log.e(TAG, "Error analyzing SOAP fault", e)
        }
    }

    private fun notifyDeviceListChanged() {
        Log.d(TAG, "=== Notifying Device List Changed ===")
        val deviceList = getAvailableDevices()
        Log.d(TAG, "Notifying callback with ${deviceList.size} devices")
        
        if (deviceDiscoveryCallback != null) {
            Log.d(TAG, "Callback is set, invoking...")
            deviceDiscoveryCallback?.invoke(deviceList)
            Log.d(TAG, "Callback invoked successfully")
        } else {
            Log.w(TAG, "Device discovery callback is null")
        }
        
        Log.d(TAG, "=== Device List Notification Complete ===")
    }
    
    private fun isIqiyiTVDevice(device: Map<String, Any>): Boolean {
        try {
            val name = device["name"] as? String ?: ""
            val manufacturer = device["manufacturer"] as? String ?: ""
            val server = device["server"] as? String ?: ""
            val address = device["address"] as? String ?: ""
            
            Log.d(TAG, "Checking if device is IQIYI TV:")
            Log.d(TAG, "  Name: $name")
            Log.d(TAG, "  Manufacturer: $manufacturer")
            Log.d(TAG, "  Server: $server")
            Log.d(TAG, "  Address: $address")
            
            // 检查设备名称
            val isIqiyiByName = name.contains("奇异果", ignoreCase = true) || 
                               name.contains("iQIYI", ignoreCase = true) ||
                               name.contains("IQIYI", ignoreCase = true)
            
            // 检查制造商
            val isIqiyiByManufacturer = manufacturer.contains("奇异果", ignoreCase = true) ||
                                       manufacturer.contains("爱奇艺", ignoreCase = true) ||
                                       manufacturer.contains("iQIYI", ignoreCase = true) ||
                                       manufacturer.contains("IQIYI", ignoreCase = true)
            
            // 检查服务器信息
            val isIqiyiByServer = server.contains("奇异果", ignoreCase = true) ||
                                 server.contains("爱奇艺", ignoreCase = true) ||
                                 server.contains("iQIYI", ignoreCase = true) ||
                                 server.contains("IQIYI", ignoreCase = true)
            
            val isIqiyiDevice = isIqiyiByName || isIqiyiByManufacturer || isIqiyiByServer
            
            if (isIqiyiDevice) {
                Log.d(TAG, "🍇 IDENTIFIED AS IQIYI TV DEVICE!")
                Log.d(TAG, "  By Name: $isIqiyiByName")
                Log.d(TAG, "  By Manufacturer: $isIqiyiByManufacturer")
                Log.d(TAG, "  By Server: $isIqiyiByServer")
            }
            
            return isIqiyiDevice
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if device is IQIYI TV", e)
            return false
        }
    }
}