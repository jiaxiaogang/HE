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
#define GVIndexTypeOfSepNum 3

@interface AINetGroupValueIndex : NSObject

+(NSArray*) gvIndexKeys:(NSString*)ds;
+(NSString*) directionKey:(NSString*)ds;
+(NSString*) diffKey:(NSString*)ds;
+(NSString*) junKey:(NSString*)ds;
+(NSString*) sepKey:(NSString*)ds;

// 是否外形 (dataSource是否用于外形判断)
+(BOOL) isOuterShape:(NSString*)ds;

// 是否内征 (dataSource是否用于内征判断)
+(BOOL) isInnerEigen:(NSString*)ds;

/**
 *  MARK:--------------------根据组节点取 四个索引的数据（均值、差值、方向、分隔点）--------------------
 */
+(NSDictionary*) convertGVIndexData:(NSArray*)subDots ds:(NSString*)ds;

@end
