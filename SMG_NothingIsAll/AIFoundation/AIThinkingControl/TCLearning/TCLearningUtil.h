//
//  TCLearningUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/24.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCLearningUtil : NSObject

/**
 *  MARK:--------------------乘积匹配度中的单码对整体的责任占比（整体责任为1，个体责任为0-1）--------------------
 *  @result true无责 false有责
 */
+(BOOL) noZeRenForCenJi:(CGFloat)curMatchValue bigerMatchValue:(CGFloat)bigerMatchValue;


/**
 *  MARK:--------------------平均匹配度中的单码责任占比（个体责任 > 平均责任 x 2则突显其有责任）--------------------
 *  @result true无责 false有责
 */
+(BOOL) noZeRenForPingJun:(CGFloat)curMatchValue bigerMatchValue:(CGFloat)bigerMatchValue;
+(BOOL) noZeRenForPingJun:(CGFloat)curMatchValue bigerMatchValue:(CGFloat)bigerMatchValue fanForce:(CGFloat)fanForce;

@end
