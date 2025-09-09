import 'package:mtv_app/src/core/utils/title_matcher.dart';

void main() {
  print('=== 标题匹配器测试 ===\n');

  // 测试用例 - 严格匹配版本
  final testCases = [
    // 精确匹配
    {'search': '复仇者联盟', 'result': '复仇者联盟', 'expected': true},
    {'search': '钢铁侠', 'result': '钢铁侠', 'expected': true},
    {'search': '夜班', 'result': '夜班', 'expected': true},
    
    // 包含年份的匹配
    {'search': '复仇者联盟', 'result': '复仇者联盟(2012)', 'expected': true},
    {'search': '阿凡达', 'result': '阿凡达 (2009)', 'expected': true},
    
    // 包含版本信息的匹配
    {'search': '阿凡达', 'result': '阿凡达 HD高清版', 'expected': true},
    {'search': '泰坦尼克号', 'result': '泰坦尼克号 1080p蓝光版', 'expected': true},
    
    // 不匹配的情况 - 系列电影不算匹配
    {'search': '钢铁侠', 'result': '钢铁侠2', 'expected': false},
    {'search': '复仇者联盟', 'result': '复仇者联盟III', 'expected': false},
    
    // 不匹配的情况 - 完全不同的电影
    {'search': '钢铁侠', 'result': '蜘蛛侠', 'expected': false},
    {'search': '复仇者联盟', 'result': '正义联盟', 'expected': false},
    
    // 不匹配的情况 - 这种情况必须过滤掉
    {'search': '夜班', 'result': '夜班医生第四季', 'expected': false},
    {'search': '复仇者联盟', 'result': '复仇者联盟：终局之战', 'expected': false},
    {'search': '变形金刚', 'result': '变形金刚：最后的骑士', 'expected': false},
    {'search': '变形金刚', 'result': '变形金刚4：绝迹重生', 'expected': false},
  ];

  int passedTests = 0;
  int totalTests = testCases.length;

  for (int i = 0; i < testCases.length; i++) {
    final testCase = testCases[i];
    final search = testCase['search'] as String;
    final result = testCase['result'] as String;
    final expected = testCase['expected'] as bool;

    final actual = TitleMatcher.isMatch(search, result);
    final similarity = TitleMatcher.calculateSimilarity(search, result);

    final status = actual == expected ? '✓' : '✗';
    final color = actual == expected ? '\x1B[32m' : '\x1B[31m'; // 绿色或红色
    const reset = '\x1B[0m';

    print('${color}$status${reset} 测试 ${i + 1}: "$search" vs "$result"');
    print('   期望: $expected, 实际: $actual, 相似度: ${similarity.toStringAsFixed(2)}');
    
    if (actual == expected) {
      passedTests++;
    } else {
      print('   ${color}❌ 测试失败${reset}');
      // 打印详细调试信息
      TitleMatcher.debugMatch(search, result);
    }
    print('');
  }

  print('=== 测试结果 ===');
  print('通过: $passedTests/$totalTests');
  print('成功率: ${(passedTests / totalTests * 100).toStringAsFixed(1)}%');

  // 额外的相似度测试
  print('\n=== 相似度测试 ===');
  final similarityTests = [
    ['复仇者联盟', '复仇者联盟'],
    ['复仇者联盟', '复仇者联盟(2012)'],
    ['复仇者联盟', '复仇者联盟：终局之战'],
    ['钢铁侠', '钢铁侠2'],
    ['钢铁侠', '蜘蛛侠'],
    ['变形金刚', '变形金刚4'],
  ];

  for (final test in similarityTests) {
    final sim = TitleMatcher.calculateSimilarity(test[0], test[1]);
    print('${test[0]} vs ${test[1]}: ${sim.toStringAsFixed(3)}');
  }
}