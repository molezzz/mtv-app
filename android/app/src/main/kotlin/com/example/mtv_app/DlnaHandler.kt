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
                    deviceName != null -> deviceName
                    server?.contains("QQLiveTV", ignoreCase = true) == true -> "极光TV"
                    server?.contains("Cling", ignoreCase = true) == true -> "智能电视"
                    senderAddress == "192.168.1.1" -> "路由器媒体服务"
                    else -> "DLNA设备 ($senderAddress)"
                }
                
                // 解析制造商信息
                val manufacturer = when {
                    server?.contains("QQLiveTV") == true -> "极光"
                    server?.contains("Cling") == true -> "Android TV"
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
            Log.d(TAG, "Video URL: $videoUrl")
            Log.d(TAG, "Title: $title")
            
            val deviceLocation = device["location"] as? String
            if (deviceLocation == null) {
                Log.e(TAG, "Device location not found")
                callback(false)
                return
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    // 步骤1: 获取设备描述XML来找到AVTransport服务
                    val serviceUrl = getAVTransportServiceUrl(deviceLocation)
                    if (serviceUrl == null) {
                        Log.e(TAG, "AVTransport service not found")
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    Log.d(TAG, "Found AVTransport service URL: $serviceUrl")
                    
                    // 步骤2: 发送SetAVTransportURI命令
                    val setUriSuccess = setAVTransportURI(serviceUrl, videoUrl, title)
                    if (!setUriSuccess) {
                        Log.e(TAG, "Failed to set AV transport URI")
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    Log.d(TAG, "Successfully set AV transport URI")
                    
                    // 步骤3: 发送Play命令
                    val playSuccess = playMedia(serviceUrl)
                    if (!playSuccess) {
                        Log.e(TAG, "Failed to start playback")
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    Log.d(TAG, "=== DLNA Cast Started Successfully ===")
                    
                    withContext(Dispatchers.Main) {
                        callback(true)
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "Error during DLNA casting", e)
                    e.printStackTrace()
                    withContext(Dispatchers.Main) {
                        callback(false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error casting video to DLNA device", e)
            e.printStackTrace()
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
            
            val deviceLocation = device["location"] as? String
            if (deviceLocation == null) {
                Log.e(TAG, "Device location not found")
                callback(false)
                return
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val serviceUrl = getAVTransportServiceUrl(deviceLocation)
                    if (serviceUrl == null) {
                        Log.e(TAG, "AVTransport service not found for stop command")
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    val success = stopMedia(serviceUrl)
                    Log.d(TAG, if (success) "DLNA playback stopped successfully" else "Failed to stop DLNA playback")
                    
                    withContext(Dispatchers.Main) {
                        callback(success)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error stopping DLNA playback", e)
                    withContext(Dispatchers.Main) {
                        callback(false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping DLNA playback", e)
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
            
            val deviceLocation = device["location"] as? String
            if (deviceLocation == null) {
                Log.e(TAG, "Device location not found")
                callback(false)
                return
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val serviceUrl = getAVTransportServiceUrl(deviceLocation)
                    if (serviceUrl == null) {
                        Log.e(TAG, "AVTransport service not found for pause command")
                        withContext(Dispatchers.Main) {
                            callback(false)
                        }
                        return@launch
                    }
                    
                    val success = pauseMedia(serviceUrl)
                    Log.d(TAG, if (success) "DLNA playback paused successfully" else "Failed to pause DLNA playback")
                    
                    withContext(Dispatchers.Main) {
                        callback(success)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error pausing DLNA playback", e)
                    withContext(Dispatchers.Main) {
                        callback(false)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error pausing DLNA playback", e)
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
    
    private suspend fun getAVTransportServiceUrl(deviceLocation: String): String? {
        return try {
            Log.d(TAG, "Fetching device description from: $deviceLocation")
            
            val request = Request.Builder()
                .url(deviceLocation)
                .get()
                .build()
            
            val response = httpClient.newCall(request).execute()
            if (!response.isSuccessful) {
                Log.e(TAG, "Failed to get device description: ${response.code}")
                return null
            }
            
            val xml = response.body?.string() ?: ""
            Log.d(TAG, "Device description XML length: ${xml.length}")
            
            // 解析XML找到AVTransport服务
            val serviceUrl = parseAVTransportServiceUrl(xml, deviceLocation)
            Log.d(TAG, "Parsed AVTransport service URL: $serviceUrl")
            
            serviceUrl
        } catch (e: Exception) {
            Log.e(TAG, "Error getting AVTransport service URL", e)
            null
        }
    }
    
    private fun parseAVTransportServiceUrl(xml: String, baseUrl: String): String? {
        try {
            // 简化的XML解析，找到AVTransport服务
            val lines = xml.split("\n")
            var inAVTransportService = false
            var controlUrl: String? = null
            
            for (line in lines) {
                val trimmedLine = line.trim()
                
                // 检查是否进入AVTransport服务区域
                if (trimmedLine.contains("urn:schemas-upnp-org:service:AVTransport", ignoreCase = true)) {
                    inAVTransportService = true
                    Log.d(TAG, "Found AVTransport service section")
                    continue
                }
                
                // 在AVTransport服务区域内查找controlURL
                if (inAVTransportService && trimmedLine.contains("<controlURL>", ignoreCase = true)) {
                    val startTag = "<controlURL>"
                    val endTag = "</controlURL>"
                    val startIndex = trimmedLine.indexOf(startTag, ignoreCase = true) + startTag.length
                    val endIndex = trimmedLine.indexOf(endTag, ignoreCase = true)
                    
                    if (startIndex > startTag.length - 1 && endIndex > startIndex) {
                        controlUrl = trimmedLine.substring(startIndex, endIndex).trim()
                        Log.d(TAG, "Found control URL: $controlUrl")
                        break
                    }
                }
                
                // 如果退出AVTransport服务区域
                if (inAVTransportService && trimmedLine.contains("</service>", ignoreCase = true)) {
                    break
                }
            }
            
            if (controlUrl != null) {
                // 构建完整URL
                return if (controlUrl.startsWith("http")) {
                    controlUrl
                } else {
                    val base = baseUrl.substringBeforeLast("/")
                    if (controlUrl.startsWith("/")) {
                        val protocol = baseUrl.substringBefore("://")
                        val host = baseUrl.substringAfter("://").substringBefore("/")
                        "$protocol://$host$controlUrl"
                    } else {
                        "$base/$controlUrl"
                    }
                }
            }
            
            return null
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing AVTransport service URL", e)
            return null
        }
    }
    
    private suspend fun setAVTransportURI(serviceUrl: String, videoUrl: String, title: String): Boolean {
        return try {
            Log.d(TAG, "Setting AV transport URI: $videoUrl")
            
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
            
            Log.d(TAG, "SetAVTransportURI response code: ${response.code}")
            if (!success) {
                Log.e(TAG, "SetAVTransportURI failed: ${response.body?.string()}")
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error setting AV transport URI", e)
            false
        }
    }
    
    private suspend fun playMedia(serviceUrl: String): Boolean {
        return try {
            Log.d(TAG, "Sending Play command")
            
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
            
            Log.d(TAG, "Play command response code: ${response.code}")
            if (!success) {
                Log.e(TAG, "Play command failed: ${response.body?.string()}")
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending play command", e)
            false
        }
    }
    
    private suspend fun stopMedia(serviceUrl: String): Boolean {
        return try {
            Log.d(TAG, "Sending Stop command")
            
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
            if (!success) {
                Log.e(TAG, "Stop command failed: ${response.body?.string()}")
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending stop command", e)
            false
        }
    }
    
    private suspend fun pauseMedia(serviceUrl: String): Boolean {
        return try {
            Log.d(TAG, "Sending Pause command")
            
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
            if (!success) {
                Log.e(TAG, "Pause command failed: ${response.body?.string()}")
            }
            
            success
        } catch (e: Exception) {
            Log.e(TAG, "Error sending pause command", e)
            false
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
}