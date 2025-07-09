//
//  GroupDebug.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/7/9.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------分组Debug工具--------------------
 *  @desc   1. 每个stepX下，都会pId/100分组，存一个计数字典，以此知道哪一组执行了多少次。
 *          2. 所以主要用于调试那些执行循环数巨多的性能问题。
 *  @示例    1. GroupDebug *debug = [GroupDebug new];
 *          2. for { [debug.updateLogDic:1 assPId:125] }
 *          3. [debug printLogDic];
 */
@interface GroupDebug : NSObject

@property (strong, nonatomic) NSMutableDictionary *logDics;
-(void) updateLogDic:(NSInteger)stepX assPId:(NSInteger)assPId;
-(void) printLogDic;

@end
