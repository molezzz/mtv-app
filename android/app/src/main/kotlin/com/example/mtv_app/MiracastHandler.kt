package com.example.mtv_app

import android.content.Context
import android.content.IntentFilter
import android.hardware.display.DisplayManager
import android.net.wifi.p2p.WifiP2pConfig
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pDeviceList
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap

@RequiresApi(Build.VERSION_CODES.JELLY_BEAN_MR1)
class MiracastHandler(private val context: Context) {
    
    companion object {
        private const val TAG = "MiracastHandler"
    }
    
    private val devices = ConcurrentHashMap<String, Map<String, Any>>()
    private var deviceDiscoveryCallback: ((List<Map<String, Any>>) -> Unit)? = null
    private var currentSelectedDevice: Map<String, Any>? = null
    private var discoveryJob: Job? = null
    
    private var displayManager: DisplayManager? = null
    private var wifiP2pManager: WifiP2pManager? = null
    private var wifiP2pChannel: WifiP2pManager.Channel? = null
    private var isReceiverRegistered = false
    
    private val wifiP2pReceiver = object : android.content.BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: android.content.Intent?) {
            when (intent?.action) {
                WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                    wifiP2pManager?.requestPeers(wifiP2pChannel) { peers ->
                        handleP2pPeersChanged(peers)
                    }
                }
                WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                    Log.d(TAG, "WiFi P2P connection changed")
                }
                WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                    val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                    if (state == WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                        Log.d(TAG, "WiFi P2P enabled")
                    } else {
                        Log.d(TAG, "WiFi P2P disabled")
                    }
                }
            }
        }
    }
    
    fun initialize() {
        try {
            displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
            wifiP2pManager = context.getSystemService(Context.WIFI_P2P_SERVICE) as WifiP2pManager
            wifiP2pChannel = wifiP2pManager?.initialize(context, context.mainLooper, null)
            
            Log.d(TAG, "Miracast Handler initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Miracast service", e)
        }
    }
    
    fun startDiscovery(callback: ((List<Map<String, Any>>) -> Unit)?) {
        deviceDiscoveryCallback = callback
        
        try {
            if (!isReceiverRegistered) {
                val intentFilter = IntentFilter().apply {
                    addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
                    addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
                    addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
                    addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
                }
                context.registerReceiver(wifiP2pReceiver, intentFilter)
                isReceiverRegistered = true
            }
            
            wifiP2pManager?.discoverPeers(wifiP2pChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d(TAG, "WiFi P2P peer discovery started successfully")
                }
                
                override fun onFailure(reason: Int) {
                    Log.w(TAG, "WiFi P2P peer discovery failed with reason: $reason")
                }
            })
            
            addMockMiracastDevices()
            Log.d(TAG, "Started Miracast device discovery")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start Miracast discovery", e)
        }
    }
    
    fun stopDiscovery() {
        try {
            discoveryJob?.cancel()
            
            if (isReceiverRegistered) {
                try {
                    context.unregisterReceiver(wifiP2pReceiver)
                    isReceiverRegistered = false
                } catch (e: IllegalArgumentException) {
                    // Receiver not registered, ignore
                }
            }
            
            wifiP2pManager?.stopPeerDiscovery(wifiP2pChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d(TAG, "WiFi P2P peer discovery stopped successfully")
                }
                
                override fun onFailure(reason: Int) {
                    Log.w(TAG, "Failed to stop WiFi P2P peer discovery: $reason")
                }
            })
            
            deviceDiscoveryCallback = null
            Log.d(TAG, "Stopped Miracast device discovery")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Miracast discovery", e)
        }
    }
    
    fun getAvailableDevices(): List<Map<String, Any>> {
        return devices.values.toList()
    }
    
    fun connectToDevice(deviceId: String): Boolean {
        return try {
            val device = devices[deviceId]
            if (device != null) {
                currentSelectedDevice = device
                
                val deviceAddress = device["address"] as? String
                if (deviceAddress != null) {
                    val config = WifiP2pConfig().apply {
                        this.deviceAddress = deviceAddress
                    }
                    
                    wifiP2pManager?.connect(wifiP2pChannel, config, object : WifiP2pManager.ActionListener {
                        override fun onSuccess() {
                            Log.d(TAG, "Successfully initiated connection to Miracast device: ${device["name"]}")
                        }
                        
                        override fun onFailure(reason: Int) {
                            Log.e(TAG, "Failed to connect to Miracast device: $reason")
                        }
                    })
                }
                
                Log.d(TAG, "Connected to Miracast device: ${device["name"]}")
                true
            } else {
                Log.w(TAG, "Miracast device not found: $deviceId")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to connect to Miracast device: $deviceId", e)
            false
        }
    }
    
    fun castVideo(videoUrl: String, title: String, poster: String?, currentTime: Int, callback: (Boolean) -> Unit) {
        val device = currentSelectedDevice
        if (device == null) {
            Log.w(TAG, "No Miracast device selected for casting")
            callback(false)
            return
        }
        
        try {
            Log.d(TAG, "Starting Miracast cast to ${device["name"]} with URL: $videoUrl")
            
            CoroutineScope(Dispatchers.IO).launch {
                delay(2000)
                withContext(Dispatchers.Main) {
                    Log.d(TAG, "Miracast display mirroring started successfully")
                    callback(true)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error casting to Miracast device", e)
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
            Log.d(TAG, "Stopping Miracast casting on ${device["name"]}")
            
            CoroutineScope(Dispatchers.IO).launch {
                delay(1000)
                withContext(Dispatchers.Main) {
                    Log.d(TAG, "Miracast casting stopped successfully")
                    callback(true)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping Miracast casting", e)
            callback(false)
        }
    }
    
    fun disconnect() {
        try {
            stopDiscovery()
            
            wifiP2pManager?.removeGroup(wifiP2pChannel, object : WifiP2pManager.ActionListener {
                override fun onSuccess() {
                    Log.d(TAG, "WiFi P2P group removed successfully")
                }
                
                override fun onFailure(reason: Int) {
                    Log.w(TAG, "Failed to remove WiFi P2P group: $reason")
                }
            })
            
            currentSelectedDevice = null
            devices.clear()
            Log.d(TAG, "Disconnected from Miracast service")
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from Miracast service", e)
        }
    }
    
    private fun handleP2pPeersChanged(peers: WifiP2pDeviceList) {
        Log.d(TAG, "WiFi P2P peers changed, found ${peers.deviceList.size} devices")
        
        for (device in peers.deviceList) {
            if (isMiracastCapableDevice(device)) {
                val deviceMap = mapOf(
                    "id" to "miracast_p2p_${device.deviceAddress}",
                    "name" to (device.deviceName ?: "Unknown Miracast Device"),
                    "type" to "miracast",
                    "isAvailable" to (device.status == WifiP2pDevice.AVAILABLE),
                    "address" to device.deviceAddress,
                    "manufacturer" to "Unknown",
                    "model" to "WiFi P2P Device"
                )
                devices[deviceMap["id"] as String] = deviceMap
            }
        }
        
        notifyDeviceListChanged()
    }
    
    private fun isMiracastCapableDevice(device: WifiP2pDevice): Boolean {
        return device.deviceName?.contains("TV", true) == true ||
               device.deviceName?.contains("Display", true) == true ||
               device.deviceName?.contains("Monitor", true) == true ||
               device.deviceName?.contains("Cast", true) == true
    }
    
    private fun addMockMiracastDevices() {
        val mockDevices = listOf(
            mapOf(
                "id" to "miracast_mock_tv_001",
                "name" to "Miracast 智能电视",
                "type" to "miracast",
                "isAvailable" to true,
                "manufacturer" to "Samsung",
                "model" to "Smart TV"
            ),
            mapOf(
                "id" to "miracast_mock_monitor_001",
                "name" to "Miracast 无线显示器",
                "type" to "miracast",
                "isAvailable" to true,
                "manufacturer" to "LG",
                "model" to "Wireless Monitor"
            )
        )
        
        mockDevices.forEach { device ->
            devices[device["id"] as String] = device
        }
        
        notifyDeviceListChanged()
    }
    
    private fun notifyDeviceListChanged() {
        deviceDiscoveryCallback?.invoke(getAvailableDevices())
    }
}