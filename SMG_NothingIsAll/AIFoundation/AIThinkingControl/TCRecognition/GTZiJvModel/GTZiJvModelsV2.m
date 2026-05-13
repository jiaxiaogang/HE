//
//  GTZiJvModelsV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/13.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTZiJvModelsV2.h"

@implementation GTZiJvModelsV2

// 强度归一化得分。
+(void) computeAverageContentStrongScoreWithGTModels:(NSArray*)gtModels {
    // 强度归一化得分。
    NSArray *sorts = [SMGUtils sortBig2Small:gtModels compareBlock:^double(GTZiJvModelV2 *obj) {
        return obj.averageContentStrong;
    }];
    for (NSInteger i = 0; i < sorts.count; i++) {
        GTZiJvModelV2 *item = ARR_INDEX(sorts, i);
        item.averageContentStrongScore = (sorts.count - i) / (CGFloat)sorts.count;
    }
}

// 匹配数归一化得分：依据排名。
+(void) computeBestsCountScoreWithGTModelsByRank:(NSArray*)gtModels {
    NSArray *sorts = [SMGUtils sortBig2Small:gtModels compareBlock:^double(GTZiJvModelV2 *obj) {
        return obj.allBestCount; // obj.bestSTs.count;
    }];
    for (NSInteger i = 0; i < sorts.count; i++) {
        GTZiJvModelV2 *item = ARR_INDEX(sorts, i);
        item.bestsCountScoreByRank = (sorts.count - i) / (CGFloat)sorts.count;
    }
}

@end
