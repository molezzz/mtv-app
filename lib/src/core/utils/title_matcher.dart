/// 影片标题匹配工具类 - 严格精确匹配版本
/// 只有标题完全相同或仅忽略年份/版本信息的情况下才算匹配
class TitleMatcher {
  /// 严格精确匹配影片标题
  /// 只有完全相同的标题才算匹配成功
  static bool isMatch(String searchTitle, String resultTitle) {
    if (searchTitle.isEmpty || resultTitle.isEmpty) {
      return false;
    }

    final normalizedSearch = _normalize(searchTitle);
    final normalizedResult = _normalize(resultTitle);

    // 策略1: 完全匹配（严格）
    if (normalizedSearch == normalizedResult) {
      return true;
    }

    // 策略2: 忽略年份和版本信息后完全匹配
    final cleanSearch = _removeYearAndVersionInfo(normalizedSearch);
    final cleanResult = _removeYearAndVersionInfo(normalizedResult);
    
    if (cleanSearch == cleanResult && cleanSearch.isNotEmpty) {
      return true;
    }

    return false;
  }

  /// 标准化标题：统一大小写、移除特殊字符和空格
  static String _normalize(String title) {
    return title
        .toLowerCase()
        .trim()
        // 移除各种空格和分隔符
        .replaceAll(RegExp(r'[\s\-_·•\u00a0\u2000-\u200a\u202f\u205f\u3000]'), '')
        // 移除常见标点符号
        .replaceAll(RegExp(r'[：:，,。.！!？?；;（）()［］\[\]【】〈〉<>《》""''""\u201c\u201d\u2018\u2019]'), '')
        // 移除其他特殊字符
        .replaceAll(RegExp(r'[~`@#\$%\^&\*\+\=\|\\/]'), '');
  }

  /// 移除年份和版本信息
  static String _removeYearAndVersionInfo(String title) {
    return title
        // 移除年份 (YYYY)
        .replaceAll(RegExp(r'\(?(?:19|20)\d{2}\)?'), '')
        // 移除版本信息
        .replaceAll(RegExp(r'(蓝光|高清|超清|4k|1080p|720p|hd|bd|dvd|ts|cam|版)', caseSensitive: false), '')
        // 移除语言信息
        .replaceAll(RegExp(r'(中字|英语|国语|粤语|日语|韩语|法语|德语|西班牙语)'), '')
        .trim();
  }

  /// 计算标题相似度 (0.0 - 1.0)
  static double calculateSimilarity(String title1, String title2) {
    if (title1.isEmpty || title2.isEmpty) {
      return 0.0;
    }

    final normalized1 = _normalize(title1);
    final normalized2 = _normalize(title2);

    if (normalized1 == normalized2) {
      return 1.0;
    }

    // 使用编辑距离计算相似度
    final distance = _levenshteinDistance(normalized1, normalized2);
    final maxLength = normalized1.length > normalized2.length ? normalized1.length : normalized2.length;
    
    if (maxLength == 0) {
      return 0.0;
    }

    return 1.0 - (distance / maxLength);
  }

  /// 计算编辑距离
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // 删除
          matrix[i][j - 1] + 1,      // 插入
          matrix[i - 1][j - 1] + cost, // 替换
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// 调试方法：打印匹配详情
  static void debugMatch(String searchTitle, String resultTitle) {
    print('=== 标题匹配调试 ===');
    print('搜索标题: "$searchTitle"');
    print('结果标题: "$resultTitle"');
    print('标准化搜索: "${_normalize(searchTitle)}"');
    print('标准化结果: "${_normalize(resultTitle)}"');
    print('清理后搜索: "${_removeYearAndVersionInfo(_normalize(searchTitle))}"');
    print('清理后结果: "${_removeYearAndVersionInfo(_normalize(resultTitle))}"');
    print('是否匹配: ${isMatch(searchTitle, resultTitle)}');
    print('相似度: ${calculateSimilarity(searchTitle, resultTitle).toStringAsFixed(2)}');
    print('==================');
  }
}