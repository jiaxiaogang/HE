//
//  ZiJvUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZiJvUtil : NSObject

/**
 *  MARK:--------------------获取切图候选范围（返回十条）--------------------
 *  @desc 锚点交由权重求和来计算：根据锚点，求出十种newST_Proto。
 */
+ (NSArray*) calcAdsorbProtoRects:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex;

@end
