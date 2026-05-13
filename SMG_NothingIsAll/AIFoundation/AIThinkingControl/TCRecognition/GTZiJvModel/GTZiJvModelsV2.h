//
//  GTZiJvModelsV2.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/13.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTZiJvModelsV2 : NSObject

// 强度归一化得分。
+(void) computeAverageContentStrongScoreWithGTModels:(NSArray*)gtModels;

@end
