# DLNA投屏功能测试指南

## 新增功能说明

我们已经实现了真正的DLNA投屏功能，不再是模拟操作。新实现包括：

### 真实DLNA投屏流程

1. **设备发现** - 通过SSDP协议发现UPnP设备
2. **设备连接** - 获取设备描述XML，解析AVTransport服务
3. **媒体投屏** - 发送真实的UPnP SOAP命令
4. **播放控制** - 支持播放、暂停、停止操作

### 实现的UPnP命令

1. **SetAVTransportURI** - 设置要播放的媒体URL
2. **Play** - 开始播放媒体
3. **Pause** - 暂停播放
4. **Stop** - 停止播放

## 技术实现详情

### HTTP客户端配置
```kotlin
private val httpClient = OkHttpClient.Builder()
    .connectTimeout(10, java.util.concurrent.TimeUnit.SECONDS)
    .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
    .writeTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
    .build()
```

### SOAP消息示例

#### SetAVTransportURI命令
```xml
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <CurrentURI>[视频URL]</CurrentURI>
            <CurrentURIMetaData>[媒体元数据]</CurrentURIMetaData>
        </u:SetAVTransportURI>
    </s:Body>
</s:Envelope>
```

#### Play命令
```xml
<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    <s:Body>
        <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
            <InstanceID>0</InstanceID>
            <Speed>1</Speed>
        </u:Play>
    </s:Body>
</s:Envelope>
```

## 测试步骤

### 1. 检查调试日志

启动应用后，查看logcat中的DLNA相关日志：

```bash
adb logcat -s DlnaHandler:* CastHandler:*
```

### 2. 触发投屏功能

1. 在应用中进入视频播放页面
2. 点击投屏按钮
3. 选择一个DLNA设备（如极光TV）
4. 观察调试日志中的投屏过程

### 3. 预期的日志输出

**成功的投屏流程应该显示：**

```
DlnaHandler: === Starting DLNA Cast ===
DlnaHandler: Device: 客厅极光TV(dlna)
DlnaHandler: Video URL: [实际视频URL]
DlnaHandler: Fetching device description from: http://192.168.1.234:39520/description.xml
DlnaHandler: Found AVTransport service section
DlnaHandler: Found control URL: /MediaRenderer/AVTransport/Control
DlnaHandler: Found AVTransport service URL: http://192.168.1.234:39520/MediaRenderer/AVTransport/Control
DlnaHandler: Setting AV transport URI: [视频URL]
DlnaHandler: SetAVTransportURI response code: 200
DlnaHandler: Successfully set AV transport URI
DlnaHandler: Sending Play command
DlnaHandler: Play command response code: 200
DlnaHandler: === DLNA Cast Started Successfully ===
```

**失败时可能的错误：**

```
DlnaHandler: Failed to get device description: 404
DlnaHandler: AVTransport service not found
DlnaHandler: SetAVTransportURI failed: [错误详情]
DlnaHandler: Play command failed: [错误详情]
```

## 可能的问题和解决方案

### 1. HTTP 403/404错误
- **原因**: 设备描述URL不正确或设备不支持外部访问
- **解决**: 检查设备是否支持DLNA投屏，确认网络连接

### 2. AVTransport服务未找到
- **原因**: 设备不是MediaRenderer或XML解析失败
- **解决**: 检查设备类型，可能是MediaServer而非MediaRenderer

### 3. SOAP命令失败
- **原因**: 视频格式不支持或网络问题
- **解决**: 
  - 检查视频URL是否可访问
  - 确认视频格式（MP4, M3U8等）是否被设备支持
  - 检查网络连接稳定性

### 4. 设备连接超时
- **原因**: 设备响应慢或网络延迟高
- **解决**: 增加超时时间或检查网络质量

## 设备兼容性

### 已测试的设备类型
1. **极光TV** - 支持QQLiveTV DLNA服务
2. **Android TV盒子** - 支持Cling UPnP框架
3. **路由器UPnP服务** - 基础MediaServer功能

### 支持的视频格式
- MP4 (H.264/H.265)
- M3U8 (HLS流)
- 其他UPnP兼容格式

## 故障排除指南

### 检查清单
- [ ] 设备在同一WiFi网络
- [ ] 设备支持DLNA/UPnP MediaRenderer
- [ ] 视频URL可直接访问
- [ ] 应用有网络权限
- [ ] 防火墙允许UPnP流量

### 高级调试
1. 使用UPnP测试工具验证设备兼容性
2. 抓取网络包分析SOAP通信
3. 检查设备制造商的DLNA实现细节

## 下一步改进

1. **设备能力检测** - 自动检测设备支持的媒体格式
2. **播放状态监控** - 实时获取播放进度和状态
3. **错误恢复机制** - 网络中断后自动重连
4. **媒体转码支持** - 不兼容格式的自动转换