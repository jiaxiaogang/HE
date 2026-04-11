//
//  ZiJvUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/4/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class AIFeatureNode, AIFeatureJvBuItem;

@interface ZiJvUtil : NSObject

/**
 *  MARK:--------------------计算吸附后的assRect--------------------
 *  @param bestGVs           本体bestGVs字典
 *  @param baseT             本体AIFeatureNode
 *  @param curIndex          本体下标
 *  @return                  吸附后的protoRect
 */
+ (CGRect) calcAdsorbAssRect:(NSDictionary*)bestGVs baseT:(AIFeatureNode*)baseT curIndex:(NSInteger)curIndex;

@end
