//
//  AIImvAlgs.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/12/21.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImvAlgsModelBase;
@interface AIImvAlgs : NSObject

/**
 *  MARK:--------------------输入mindValue--------------------
 *  所有值域,转换为0-10;(例如:hunger时0为不饿,10为非常饿)
 */
+(ImvAlgsModelBase*) commitIMV:(MVType)type from:(CGFloat)from to:(CGFloat)to;

/**
 *  MARK:--------------------BadImv迫切度--------------------
 *  @desc 指迫切度与value在"同向"上,比如更饿,越饿迫切度越高;
 */
+(CGFloat) getBadImvUrgentValue:(CGFloat)to;

@end
