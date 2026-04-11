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
 *  MARK:--------------------计算吸附后的assRect--------------------
 *  @param bestGVs           本体bestGVs字典
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @param force             吸附强度调整参数 (0~1)，越大吸附越强烈（为1时最近的100%匹配则完全吸附，为0.5时最近的100%匹配也只吸一半）
 *  @return                  吸附后的protoRect
 */
+ (CGRect) calcAdsorbAssRect:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex force:(CGFloat)force;

@end
