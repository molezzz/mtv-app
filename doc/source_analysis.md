# MoonTV 播放源分析机制详解

本文档将详细解释 MoonTV 项目是如何实现**提取播放源分辨率**和**播放源测速**这两个核心功能的。

## 核心摘要

这两个功能主要由位于 `src/lib/utils.ts` 文件中的 `getVideoResolutionFromM3u8` 函数统一实现。该函数通过创建一个临时的 `<video>` 元素并结合 `hls.js` 库，在一次异步操作中同时获取视频的分辨率、下载速度和网络延迟（Ping）。

在Flutter版本中，这些功能由位于 `lib/src/core/utils/video_resolution_detector.dart` 文件中的 `VideoResolutionDetector` 类实现。该类通过解析M3U8文件内容和发送网络请求来获取视频的分辨率、下载速度和网络延迟。

整个流程大致如下：

1.  **发起检测**：在播放页面 (`play/page.tsx`) 进行播放源优选时，或在选集组件 (`EpisodeSelector.tsx`) 展示换源列表时，会调用 `getVideoResolutionFromM3u8` 函数。
2.  **创建播放环境**：函数在内存中创建一个 `<video>` 标签，并初始化 `hls.js` 来加载传入的 M3U8 URL。
3.  **并行测量**：
    *   **测延迟 (Ping)**：通过向 M3U8 URL 发送一个 `HEAD` 请求来测量网络延迟。
    *   **测下载速度**：监听 `hls.js` 的 `FRAG_LOADED` 事件，获取第一个视频切片（fragment）的大小和加载时间，从而计算出下载速度。
    *   **提取消耗**：监听 `<video>` 元素的 `onloadedmetadata` 事件，当视频元数据加载完成后，读取 `video.videoWidth` 属性获得视频宽度，进而推算出分辨率。
4.  **返回结果**：函数将分辨率、下载速度和延迟时间作为一个对象返回。
5.  **应用结果**：
    *   在播放源优选时，根据这三个指标计算出一个综合评分，选择评分最高的源进行播放。
    *   在换源列表中，将这些信息直观地展示给用户，以便用户根据网络情况自行选择。

在Flutter版本中，这些信息会在播放源选择界面中显示，包括分辨率标签（如4K、1080p、720p等）、下载速度和网络延迟。

---

## 1. 播放源分辨率提取

分辨率的提取依赖于浏览器对视频元数据的解析能力。

### 实现原理

1.  **加载视频**：使用 `hls.js` 将 M3U8 播放列表加载到内存中的 `<video>` 元素中。
2.  **读取元数据**：当视频的元数据加载完成时（触发 `onloadedmetadata` 事件），`<video>` 元素会包含视频的各种信息，包括尺寸。
3.  **获取宽度**：通过读取 `video.videoWidth` 属性，可以得到视频的实际像素宽度。
4.  **推算分辨率等级**：根据常见的视频宽度标准（如 3840, 1920, 1280 等），将像素宽度映射为用户熟悉的分辨率等级（如 "4K", "1080p", "720p"）。

在Flutter版本中，我们通过解析M3U8文件中的RESOLUTION标签来获取视频宽度信息。

### 关键代码 (`src/lib/utils.ts`)

```typescript
// ...

// 监听视频元数据加载完成
video.onloadedmetadata = () => {
  hasMetadataLoaded = true;
  checkAndResolve(); // 尝试返回结果
};

// 在 checkAndResolve 函数内部
const checkAndResolve = () => {
  if (hasMetadataLoaded && hasSpeedCalculated) {
    clearTimeout(timeout);
    const width = video.videoWidth;
    if (width && width > 0) {
      hls.destroy();
      video.remove();

      // 根据视频宽度判断视频质量等级
      const quality =
        width >= 3840
          ? '4K' // 4K: 3840x2160
          : width >= 2560
          ? '2K' // 2K: 2560x1440
          : width >= 1920
          ? '1080p' // 1080p: 1920x1080
          : width >= 1280
          ? '720p' // 720p: 1280x720
          : width >= 854
          ? '480p'
          : 'SD';

      resolve({
        quality,
        loadSpeed: actualLoadSpeed,
        pingTime: Math.round(pingTime),
      });
    }
    // ...
  }
};
```

在Flutter版本中，对应的实现在 `lib/src/core/utils/video_resolution_detector.dart` 文件中：

```dart
/// 根据视频宽度判断视频质量等级
static String _getQualityFromWidth(int width) {
  if (width >= 3840) {
    return '4K'; // 4K: 3840x2160
  } else if (width >= 2560) {
    return '2K'; // 2K: 2560x1440
  } else if (width >= 1920) {
    return '1080p'; // 1080p: 1920x1080
  } else if (width >= 1280) {
    return '720p'; // 720p: 1280x720
  } else if (width >= 854) {
    return '480p';
  } else {
    return 'SD';
  }
}
```

---

## 2. 播放源测速

测速分为**网络延迟（Ping）**和**下载速度**两部分，它们在同一个函数内并行执行。

### 实现原理

#### a. 延迟 (Ping)

1.  **记录开始时间**：在发起请求前，使用 `performance.now()` 记录当前时间戳 `pingStart`。
2.  **发送轻量请求**：使用 `fetch` API 向 M3U8 地址发送一个 `HEAD` 请求。`HEAD` 请求只获取响应头，不下载响应体，非常轻量，适合用来测量服务器的响应延迟。
3.  **计算耗时**：请求结束后，再次调用 `performance.now()`，与 `pingStart` 相减，得到的时间差即为 Ping 值。

#### b. 下载速度

1.  **监听切片加载**：`hls.js` 在播放视频时，会先下载 M3U8 文件，然后根据文件内容去下载一个个的视频切片（`.ts` 文件）。
2.  **记录加载始末**：
    *   监听 `Hls.Events.FRAG_LOADING` 事件，记录切片开始加载的时间 `fragmentStartTime`。
    *   监听 `Hls.Events.FRAG_LOADED` 事件，此时切片已下载完成。
3.  **计算速度**：
    *   通过 `performance.now() - fragmentStartTime` 得到加载耗时。
    *   从事件的 `data.payload.byteLength` 中获取切片的大小（字节）。
    *   **速度 = 大小 / 时间**。函数仅使用第一个成功加载的切片来计算速度，这足以代表当前网络的瞬时速度。
    *   最后将单位从 `bytes/ms` 转换为用户友好的 `KB/s` 或 `MB/s`。

在Flutter版本中，我们通过发送HTTP请求来测量延迟和下载速度。

### 关键代码 (`src/lib/utils.ts`)

```typescript
export async function getVideoResolutionFromM3u8(m3u8Url: string): Promise<{
  quality: string;
  loadSpeed: string;
  pingTime: number;
}> {
  return new Promise((resolve, reject) => {
    // ...
    // 测量网络延迟（ping时间）
    const pingStart = performance.now();
    let pingTime = 0;

    fetch(m3u8Url, { method: 'HEAD', mode: 'no-cors' })
      .then(() => {
        pingTime = performance.now() - pingStart;
      })
      .catch(() => {
        pingTime = performance.now() - pingStart;
      });

    const hls = new Hls();
    // ...
    let fragmentStartTime = 0;

    // 监听片段加载开始
    hls.on(Hls.Events.FRAG_LOADING, () => {
      fragmentStartTime = performance.now();
    });

    // 监听片段加载完成，只需首个分片即可计算速度
    hls.on(Hls.Events.FRAG_LOADED, (event: any, data: any) => {
      if (fragmentStartTime > 0 && data && data.payload && !hasSpeedCalculated) {
        const loadTime = performance.now() - fragmentStartTime;
        const size = data.payload.byteLength || 0;

        if (loadTime > 0 && size > 0) {
          const speedKBps = size / 1024 / (loadTime / 1000);
          
          if (speedKBps >= 1024) {
            actualLoadSpeed = `${(speedKBps / 1024).toFixed(1)} MB/s`;
          } else {
            actualLoadSpeed = `${speedKBps.toFixed(1)} KB/s`;
          }
          hasSpeedCalculated = true;
          checkAndResolve(); // 尝试返回结果
        }
      }
    });
    // ...
  });
}
```

在Flutter版本中，对应的实现在 `lib/src/core/utils/video_resolution_detector.dart` 文件中：

```dart
/// 测量网络延迟(Ping)
static Future<int> _measurePing(String url) async {
  try {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    await _dio.head(url);
    final endTime = DateTime.now().millisecondsSinceEpoch;
    return endTime - startTime;
  } catch (e) {
    // 如果HEAD请求失败，尝试GET请求
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;
      await _dio.get(url, options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 5)));
      final endTime = DateTime.now().millisecondsSinceEpoch;
      return endTime - startTime;
    } catch (e2) {
      // 如果都失败了，返回一个较大的默认值
      return 500;
    }
  }
}

/// 测量下载速度
static Future<String> _measureDownloadSpeed(String url) async {
  try {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final response = await _dio.get(url, options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(seconds: 10)));
    final endTime = DateTime.now().millisecondsSinceEpoch;
    
    if (response.data is List<int>) {
      final sizeInBytes = response.data.length;
      final durationInMillis = endTime - startTime;
      
      if (durationInMillis > 0) {
        final speedInKBps = sizeInBytes / 1024 / (durationInMillis / 1000);
        
        if (speedInKBps >= 1024) {
          return '${(speedInKBps / 1024).toStringAsFixed(1)} MB/s';
        } else {
          return '${speedInKBps.toStringAsFixed(1)} KB/s';
        }
      }
    }
    return 'N/A';
  } catch (e) {
    return 'N/A';
  }
}
```

---

## 3. 整体工作流程

测速和分辨率提取的结果被用于两个地方：**播放源自动优选**和**换源列表展示**。

1.  **播放源优选 (`play/page.tsx`)**
    *   当用户进入播放页时，如果开启了优选功能，`preferBestSource` 函数会并发地为所有可用的播放源执行 `getVideoResolutionFromM3u8`。
    *   获取到所有源的 `quality`, `loadSpeed`, `pingTime` 后，`calculateSourceScore` 函数会根据预设的权重（分辨率占40%，速度占40%，延迟占20%）为每个源计算一个综合得分。
    *   系统会自动选择得分最高的源进行播放。

    ```typescript
    // src/app/play/page.tsx -> calculateSourceScore

    // 分辨率评分 (40% 权重)
    const qualityScore = (() => { ... })();
    score += qualityScore * 0.4;

    // 下载速度评分 (40% 权重)
    const speedScore = (() => { ... })();
    score += speedScore * 0.4;

    // 网络延迟评分 (20% 权重)
    const pingScore = (() => { ... })();
    score += pingScore * 0.2;
    ```

2.  **换源列表展示 (`EpisodeSelector.tsx`)**
    *   在播放器加载时预先计算的测速结果 (`precomputedVideoInfo`) 会被传递给 `EpisodeSelector` 组件。
    *   当用户点击"换源"标签时，组件会立即展示这些已经测好的信息（分辨率、速度、延迟）。
    *   如果某些源没有预先测速，组件会按需调用 `getVideoInfo` -> `getVideoResolutionFromM3u8` 来动态获取，并将结果展示在列表中，为用户手动选择提供了清晰的数据参考。

在Flutter版本中，这些信息会在播放源选择界面中显示，包括分辨率标签（如4K、1080p、720p等）、下载速度和网络延迟。

这个设计兼顾了自动化（智能优选）和用户自主选择（清晰的换源信息），极大地提升了用户体验。