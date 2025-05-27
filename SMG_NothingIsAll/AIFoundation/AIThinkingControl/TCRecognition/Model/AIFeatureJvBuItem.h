//
//  AIFeatureJvBuItem.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------局部特征识别V2算法模型：三级--------------------
 */
@interface AIFeatureJvBuItem : NSObject

+(id) new:(CGRect)bestGVAtProtoTRect matchValue:(CGFloat)matchValue matchDegree:(CGFloat)matchDegree assIndex:(NSInteger)assIndex;

//记录当前gv是assT的哪个下标。
@property (assign, nonatomic) NSInteger assIndex;
//每一条bestGV都可以把rect存下来（可用于计算bestGVsAtProtoTRect）。
@property (assign, nonatomic) CGRect bestGVAtProtoTRect;
//每个bestGV的匹配度。
@property (assign, nonatomic) CGFloat matchValue;
//每个bestGV的符合度。
@property (assign, nonatomic) CGFloat matchDegree;

@end
