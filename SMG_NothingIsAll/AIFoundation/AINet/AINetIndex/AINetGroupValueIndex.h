//
//  AINetGroupValueIndex.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/27.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GVIndexTypeOfDataSource -1
#define GVIndexTypeOfDirection 0
#define GVIndexTypeOfDiffNum 1
#define GVIndexTypeOfPinJunNum 2

@interface AINetGroupValueIndex : NSObject

+(NSArray*) gvIndexKeys:(NSString*)ds;

/**
 *  MARK:--------------------根据组节点取 三个索引的数据（参考34082-方案2）--------------------
 */
+(NSDictionary*) convertGVIndexData:(NSArray*)subDots ds:(NSString*)ds;

@end
