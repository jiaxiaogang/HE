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
        
        // 前80%，全计为满分：仅末尾淘汰，不然稳定性作用力太大，训练再久也只识别最旧的一些强者恒强的结果，影响到准确性，喧宾夺主（参考38012-BUG1-TODO）。
        if (i < sorts.count * 0.8f) {
            item.averageContentStrongScore = 1;
        }
        // 末尾20%，也正常计算它的小竞争分，参与到最终综合竞争中，自然淘汰（参考38012-BUG1-TODO）。
        else {
            item.averageContentStrongScore = (sorts.count - i) / (CGFloat)sorts.count;
        }
    }
}

@end
