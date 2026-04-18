//
//  GVIndexTest.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/17.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GVIndexTest.h"
#import "MapModel.h"

@implementation GVIndexTest

// MARK: 测试分隔点
// 正确输出结果：
//┌──────────────┬─────────┬─────────┐
//│   测试用例     │ 期望sep │ 实际sep  │
//├──────────────┼─────────┼─────────┤
//│ 纯色          │ 0.0     │ 0.0 ✓   │
//├──────────────┼─────────┼─────────┤
//│ 左上亮右下暗   │ ~0.222   │ ~0.222 ✓│
//├──────────────┼─────────┼─────────┤
//│ 左亮右暗       │ ~0.333  │ ~0.333 ✓│
//├──────────────┼─────────┼─────────┤
//│ 上亮下暗       │ ~0.333  │ ~0.333 ✓│
//└──────────────┴─────────┴─────────┘
//========== 测试分隔点 ==========
//[纯色] 输入3x3:
//0.5 0.5 0.5
//0.5 0.5 0.5
//0.5 0.5 0.5
//[纯色] 结果: direction=0.000, diff=0.000, jun=0.500, sep=0.000
//[左上亮右下暗] 输入3x3:
//0.9 0.5 0.1
//0.5 0.5 0.5
//0.1 0.5 0.9
//[左上亮右下暗] 结果: direction=0.500, diff=0.500, jun=0.500, sep=0.222
//[左亮右暗] 输入3x3:
//0.9 0.9 0.1
//0.9 0.9 0.1
//0.9 0.9 0.1
//[左亮右暗] 结果: direction=0.500, diff=0.833, jun=0.667, sep=0.333
//[上亮下暗] 输入3x3:
//0.9 0.9 0.9
//0.9 0.9 0.9
//0.1 0.1 0.1
//[上亮下暗] 结果: direction=0.750, diff=0.833, jun=0.667, sep=0.333
//========== 测试结束 ==========






















+ (void)testGVIndexSeparator {
    NSLog(@"\n========== 测试分隔点 ==========");

    // 测试用例1: 纯色（应该返回sep=0.5）
    NSArray *test1 = @[
        @{@"v1": @(0.5), @"v2": @(0), @"v3": @(0)},
        @{@"v1": @(0.5), @"v2": @(1), @"v3": @(0)},
        @{@"v1": @(0.5), @"v2": @(2), @"v3": @(0)},
        @{@"v1": @(0.5), @"v2": @(0), @"v3": @(1)},
        @{@"v1": @(0.5), @"v2": @(1), @"v3": @(1)},
        @{@"v1": @(0.5), @"v2": @(2), @"v3": @(1)},
        @{@"v1": @(0.5), @"v2": @(0), @"v3": @(2)},
        @{@"v1": @(0.5), @"v2": @(1), @"v3": @(2)},
        @{@"v1": @(0.5), @"v2": @(2), @"v3": @(2)},
    ];

    // 测试用例2: 左上角亮，右下角暗（方向从左上到右下）
    // x=0,y=0 是左上角
    NSArray *test2 = @[
        @{@"v1": @(0.9), @"v2": @(0), @"v3": @(0)}, // 左上-亮
        @{@"v1": @(0.5), @"v2": @(1), @"v3": @(0)},
        @{@"v1": @(0.1), @"v2": @(2), @"v3": @(0)},
        @{@"v1": @(0.5), @"v2": @(0), @"v3": @(1)},
        @{@"v1": @(0.5), @"v2": @(1), @"v3": @(1)}, // 中间
        @{@"v1": @(0.5), @"v2": @(2), @"v3": @(1)},
        @{@"v1": @(0.1), @"v2": @(0), @"v3": @(2)}, // 左下-暗
        @{@"v1": @(0.5), @"v2": @(1), @"v3": @(2)},
        @{@"v1": @(0.9), @"v2": @(2), @"v3": @(2)}, // 右下-亮
    ];

    // 测试用例3: 左半边亮，右半边暗
    NSArray *test3 = @[
        @{@"v1": @(0.9), @"v2": @(0), @"v3": @(0)},
        @{@"v1": @(0.9), @"v2": @(1), @"v3": @(0)},
        @{@"v1": @(0.1), @"v2": @(2), @"v3": @(0)},
        @{@"v1": @(0.9), @"v2": @(0), @"v3": @(1)},
        @{@"v1": @(0.9), @"v2": @(1), @"v3": @(1)},
        @{@"v1": @(0.1), @"v2": @(2), @"v3": @(1)},
        @{@"v1": @(0.9), @"v2": @(0), @"v3": @(2)},
        @{@"v1": @(0.9), @"v2": @(1), @"v3": @(2)},
        @{@"v1": @(0.1), @"v2": @(2), @"v3": @(2)},
    ];

    // 测试用例4: 上半边亮，下半边暗
    NSArray *test4 = @[
        @{@"v1": @(0.9), @"v2": @(0), @"v3": @(0)},
        @{@"v1": @(0.9), @"v2": @(1), @"v3": @(0)},
        @{@"v1": @(0.9), @"v2": @(2), @"v3": @(0)},
        @{@"v1": @(0.9), @"v2": @(0), @"v3": @(1)},
        @{@"v1": @(0.9), @"v2": @(1), @"v3": @(1)},
        @{@"v1": @(0.9), @"v2": @(2), @"v3": @(1)},
        @{@"v1": @(0.1), @"v2": @(0), @"v3": @(2)},
        @{@"v1": @(0.1), @"v2": @(1), @"v3": @(2)},
        @{@"v1": @(0.1), @"v2": @(2), @"v3": @(2)},
    ];

    // 转换测试数据
    NSArray *(^convertTestData)(NSArray*) = ^NSArray*(NSArray *arr) {
        NSMutableArray *result = [NSMutableArray array];
        for (NSDictionary *d in arr) {
            MapModel *m = [[MapModel alloc] init];
            m.v1 = d[@"v1"];
            m.v2 = d[@"v2"];
            m.v3 = d[@"v3"];
            [result addObject:m];
        }
        return result;
    };

    NSArray *tests = @[
        @{@"name": @"纯色", @"data": convertTestData(test1)},
        @{@"name": @"左上亮右下暗", @"data": convertTestData(test2)},
        @{@"name": @"左亮右暗", @"data": convertTestData(test3)},
        @{@"name": @"上亮下暗", @"data": convertTestData(test4)},
    ];

    for (NSDictionary *test in tests) {
        NSString *name = test[@"name"];
        NSArray *subDots = test[@"data"];

        // 打印输入数据
        NSMutableString *inputStr = [NSMutableString stringWithFormat:@"[%@] 输入3x3:\n", name];
        for (NSInteger i = 0; i < 3; i++) {
            for (NSInteger j = 0; j < 3; j++) {
                NSInteger idx = i * 3 + j;
                MapModel *m = subDots[idx];
                NSNumber *v1 = m.v1;
                [inputStr appendFormat:@"%.1f ", v1.floatValue];
            }
            [inputStr appendString:@"\n"];
        }
        NSLog(@"%@", inputStr);

        NSDictionary *result = [AINetGroupValueIndex convertGVIndexData:subDots ds:@"bColors"];
        NSLog(@"[%@] 结果: direction=%.3f, diff=%.3f, jun=%.3f, sep=%.3f",
              name,
              [result[@"bColors_direction"] floatValue],
              [result[@"bColors_diff"] floatValue],
              [result[@"bColors_jun"] floatValue],
              [result[@"bColors_sep"] floatValue]);
    }

    NSLog(@"========== 测试结束 ==========\n");
}

@end
