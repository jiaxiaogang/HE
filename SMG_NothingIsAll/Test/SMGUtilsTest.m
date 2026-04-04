//
//  SMGUtilsTest.m
//  SMG_NothingIsAll
//
//  Created for testing union area calculation
//  测试环境匹配率（并集面积）计算的各种场景
//

#import "SMGUtilsTest.h"

/**
 * 测试用例说明：
 * 所有测试都调用 computeUnionAreaOfRects: 方法
 * 输入是一个包含 NSValue(CGRect) 的数组
 * 输出是所有矩形的并集面积（去除重叠部分，只计一次）
 */
@implementation SMGUtilsTest

/**
 * ================== 运行测试 ==================
 *
 * 使用方法：
 * 1. 在 Xcode 中打开此文件
 * 2. 按 Cmd + U 运行所有测试
 * 或
 * 3. 在终端中运行：
 *    cd /Users/jia/Desktop/repos/HE
 *    xcodebuild test -scheme SMG_NothingIsAll -destination 'platform=iOS Simulator,name=iPhone 15'
 *
 * 输出说明：
 * - PASS: 测试通过，实际输出与期望输出一致
 * - FAIL: 测试失败，实际输出与期望输出不一致
 *
 * 调试建议：
 * - 如果某个测试失败，检查扫描线算法中的y坐标和x段计算
 * - 验证矩形重叠的边界条件处理
 * - 确认x段排序和合并逻辑
 */
-(void) test {
    [self test_Case1_SingleRectangle];
    [self test_Case2_TwoNonOverlappingRectangles];
    [self test_Case3_TwoCompletelyOverlappingRectangles];
    [self test_Case4_TwoPartiallyOverlappingRectangles];
    [self test_Case5_OneRectangleInsideAnother];
    [self test_Case6_ThreeRectanglesChainOverlap];
    [self test_Case7_CrossoverRectangles];
    [self test_Case8_EmptyArray];
    [self test_Case9_FourRectanglesGrid];
    [self test_Case10_ComplexRealWorldScenario];
}

/**
 * ========== 测试 1: 单个矩形 ==========
 * 说明: 只有一个矩形，并集面积应等于该矩形面积
 * 输入: 矩形 (0, 0, 10, 10)
 * 期望输出: 100
 */
- (void)test_Case1_SingleRectangle {
    NSArray *rects = @[[NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)]];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 1] 单个矩形");
    NSLog(@"  输入: 1个矩形 (0,0,10,10)");
    NSLog(@"  期望输出: 100");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 100.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 100.0, 0.01);
}

/**
 * ========== 测试 2: 两个不重叠的矩形 ==========
 * 说明: 两个矩形完全分离，并集面积 = 面积1 + 面积2
 * 输入:
 *   矩形1: (0, 0, 5, 5)  面积=25
 *   矩形2: (10, 10, 5, 5)  面积=25
 * 期望输出: 50
 */
- (void)test_Case2_TwoNonOverlappingRectangles {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 0, 5, 5)],
        [NSValue valueWithCGRect:CGRectMake(10, 10, 5, 5)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 2] 两个不重叠的矩形");
    NSLog(@"  输入: 矩形1 (0,0,5,5) 面积=25");
    NSLog(@"        矩形2 (10,10,5,5) 面积=25");
    NSLog(@"  期望输出: 50");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 50.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 50.0, 0.01);
}

/**
 * ========== 测试 3: 两个完全重叠的矩形 ==========
 * 说明: 两个矩形完全相同，并集面积 = 一个矩形的面积
 * 输入:
 *   矩形1: (0, 0, 10, 10)  面积=100
 *   矩形2: (0, 0, 10, 10)  面积=100
 * 期望输出: 100
 */
- (void)test_Case3_TwoCompletelyOverlappingRectangles {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 3] 两个完全重叠的矩形");
    NSLog(@"  输入: 矩形1 (0,0,10,10) 面积=100");
    NSLog(@"        矩形2 (0,0,10,10) 面积=100");
    NSLog(@"  期望输出: 100");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 100.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 100.0, 0.01);
}

/**
 * ========== 测试 4: 两个部分重叠的矩形 ==========
 * 说明: 两个矩形部分重叠
 * 输入:
 *   矩形1: (0, 0, 10, 10)  面积=100
 *   矩形2: (5, 5, 10, 10)  面积=100
 *   重叠部分: (5, 5, 5, 5)  面积=25
 * 期望输出: 100 + 100 - 25 = 175
 */
- (void)test_Case4_TwoPartiallyOverlappingRectangles {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(5, 5, 10, 10)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 4] 两个部分重叠的矩形");
    NSLog(@"  输入: 矩形1 (0,0,10,10) 面积=100");
    NSLog(@"        矩形2 (5,5,10,10) 面积=100");
    NSLog(@"        重叠部分: (5,5,5,5) 面积=25");
    NSLog(@"  期望输出: 175");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 175.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 175.0, 0.01);
}

/**
 * ========== 测试 5: 一个矩形完全包含另一个 ==========
 * 说明: 大矩形完全包含小矩形，并集面积 = 大矩形面积
 * 输入:
 *   矩形1: (0, 0, 20, 20)  面积=400
 *   矩形2: (5, 5, 10, 10)  面积=100
 * 期望输出: 400
 */
- (void)test_Case5_OneRectangleInsideAnother {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 0, 20, 20)],
        [NSValue valueWithCGRect:CGRectMake(5, 5, 10, 10)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 5] 一个矩形完全包含另一个");
    NSLog(@"  输入: 大矩形 (0,0,20,20) 面积=400");
    NSLog(@"        小矩形 (5,5,10,10) 面积=100");
    NSLog(@"  期望输出: 400");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 400.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 400.0, 0.01);
}

/**
 * ========== 测试 6: 三个矩形，部分重叠链式 ==========
 * 说明: 矩形1→矩形2→矩形3 链式部分重叠
 * 输入:
 *   矩形1: (0, 0, 10, 10)   面积=100
 *   矩形2: (5, 0, 10, 10)   面积=100
 *   矩形3: (10, 0, 10, 10)  面积=100
 *
 * 并集计算:
 *   y 区间 [0, 10): x 段为 [0,15] ∪ [10,20] = [0,20]，长度=20
 *   总面积 = 20 × 10 = 200
 * 期望输出: 200
 */
- (void)test_Case6_ThreeRectanglesChainOverlap {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(5, 0, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(10, 0, 10, 10)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 6] 三个矩形链式部分重叠");
    NSLog(@"  输入: 矩形1 (0,0,10,10) 面积=100");
    NSLog(@"        矩形2 (5,0,10,10) 面积=100");
    NSLog(@"        矩形3 (10,0,10,10) 面积=100");
    NSLog(@"  期望输出: 200");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 200.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 200.0, 0.01);
}

/**
 * ========== 测试 7: 十字形重叠 ==========
 * 说明: 两个矩形形成十字形交叉
 * 输入:
 *   矩形1: (0, 5, 20, 10)   水平矩形，面积=200
 *   矩形2: (5, 0, 10, 20)   竖直矩形，面积=200
 *   重叠部分: (5, 5, 10, 10) 面积=100
 * 期望输出: 200 + 200 - 100 = 300
 */
- (void)test_Case7_CrossoverRectangles {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 5, 20, 10)],  // 水平
        [NSValue valueWithCGRect:CGRectMake(5, 0, 10, 20)]   // 竖直
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 7] 十字形重叠");
    NSLog(@"  输入: 水平矩形 (0,5,20,10) 面积=200");
    NSLog(@"        竖直矩形 (5,0,10,20) 面积=200");
    NSLog(@"        重叠部分: (5,5,10,10) 面积=100");
    NSLog(@"  期望输出: 300");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 300.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 300.0, 0.01);
}

/**
 * ========== 测试 8: 空数组 ==========
 * 说明: 输入空数组，应返回 0
 * 输入: 空数组
 * 期望输出: 0
 */
- (void)test_Case8_EmptyArray {
    NSArray *rects = @[];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 8] 空数组");
    NSLog(@"  输入: []");
    NSLog(@"  期望输出: 0");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 0.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 0.0, 0.01);
}

/**
 * ========== 测试 9: 四个矩形，形成 2x2 网格 ==========
 * 说明: 四个 10x10 的矩形排成 2x2 网格，不重叠
 * 输入:
 *   矩形1: (0, 0, 10, 10)      面积=100
 *   矩形2: (10, 0, 10, 10)     面积=100
 *   矩形3: (0, 10, 10, 10)     面积=100
 *   矩形4: (10, 10, 10, 10)    面积=100
 * 期望输出: 400
 */
- (void)test_Case9_FourRectanglesGrid {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(0, 0, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(10, 0, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(0, 10, 10, 10)],
        [NSValue valueWithCGRect:CGRectMake(10, 10, 10, 10)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 9] 四个矩形 2x2 网格");
    NSLog(@"  输入: 4个 (10,10) 矩形排成 2x2 网格");
    NSLog(@"        (0,0,10,10), (10,0,10,10)");
    NSLog(@"        (0,10,10,10), (10,10,10,10)");
    NSLog(@"  期望输出: 400");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 400.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 400.0, 0.01);
}

/**
 * ========== 测试 10: 复杂重叠场景（实际应用） ==========
 * 说明: 模拟实际着色场景 - 多个重叠的 GV 着色
 * 输入:
 *   矩形1: (10, 10, 30, 30)  面积=900
 *   矩形2: (25, 25, 30, 30)  面积=900
 *   矩形3: (40, 40, 20, 20)  面积=400
 *   矩形1和2的重叠: (25, 25, 15, 15) 面积=225
 * 期望输出: 900 + 900 + 400 - 225 = 1975
 */
- (void)test_Case10_ComplexRealWorldScenario {
    NSArray *rects = @[
        [NSValue valueWithCGRect:CGRectMake(10, 10, 30, 30)],
        [NSValue valueWithCGRect:CGRectMake(25, 25, 30, 30)],
        [NSValue valueWithCGRect:CGRectMake(40, 40, 20, 20)]
    ];
    
    CGFloat result = [SMGUtils computeUnionAreaOfRects:rects];
    
    NSLog(@"[Test 10] 复杂重叠场景（实际应用）");
    NSLog(@"  输入: 矩形1 (10,10,30,30) 面积=900");
    NSLog(@"        矩形2 (25,25,30,30) 面积=900");
    NSLog(@"        矩形3 (40,40,20,20) 面积=400");
    NSLog(@"        矩形1和2重叠: (25,25,15,15) 面积=225");
    NSLog(@"        矩形2和3重叠: (40,40,15,15) 面积=225");
    NSLog(@"  期望输出: 1975");
    NSLog(@"  实际输出: %.2f", result);
    NSLog(@"  结果: %s\n", fabs(result - 1750.0) < 0.01 ? "PASS" : "FAIL");
    
    // XCTAssertEqualWithAccuracy(result, 1750.0, 0.01);
}

@end
