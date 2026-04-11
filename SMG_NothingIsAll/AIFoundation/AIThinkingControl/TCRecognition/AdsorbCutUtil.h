//
//  WeightedSumCutUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------加权求和切图法（又称：吸附切图算法）--------------------
 */
@interface WeightedSumCutUtil : NSObject

/**
 *  MARK:--------------------获取切图候选范围（返回十条）--------------------
 *  @desc 锚点交由权重求和来计算：根据锚点，求出十种newST_Proto。
 *  @param baseT_Proto : baseT给的总空间非常重要，对每个bestGV最终能切到多少有决定性作用（并且baseST也往往是吸附锚点算出来的，所以必须得传过来）。
 */
+ (NSArray*) calcAdsorbProtoRects:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex baseT_Proto:(CGRect)baseT_Proto;

@end
