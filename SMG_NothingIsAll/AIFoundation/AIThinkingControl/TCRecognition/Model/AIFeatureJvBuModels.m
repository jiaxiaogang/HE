//
//  AIFeatureJvBuModels.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuModels.h"

@implementation AIFeatureJvBuModels

+(id) new:(NSInteger)hash {
    AIFeatureJvBuModels *result = [AIFeatureJvBuModels new];
    result.protoTHash = hash;
    return result;
}

-(NSMutableArray *)stModels {
    if (!_stModels) _stModels = [NSMutableArray new];
    return _stModels;
}

-(NSMutableArray *)gtModels {
    if (!_gtModels) _gtModels = [NSMutableArray new];
    return _gtModels;
}

// 分区竞争匹配度：计算每条item的rankScore和rankRatio。
-(void) run4AreaMatchRatio {
    //1. 无效过滤器1、matchValue=0排到最后。
    NSArray *validModels = [SMGUtils filterArr:self.stModels checkValid:^BOOL(AIFeatureJvBuModel *model) {
        return model.matchValue > 0;
    }];
    
    //2. 计算分区均衡排名分。
    for (AIFeatureJvBuModel *item in validModels) {
        [item run4ItemAreaRankScore:validModels];
    }
    
    //3. 排名。
    NSArray *sorts = [SMGUtils sortSmall2Big:self.stModels compareBlock:^double(AIFeatureJvBuModel *obj) {
        return obj.areaRankScore;
    }];
    
    //4. 归一化区域排名分（参考35082-方案4）。
    for (NSInteger i = 0; i < sorts.count; i++) {
        AIFeatureJvBuModel *item = ARR_INDEX(sorts, i);
        item.areaMatchRatio = 1 - ((float)i / sorts.count);
    }
}

// item.bestGVs.count防止过度抽象，归一化计算。
-(void) run4BestGVsCountRatio {
    // 找出最长item的bestGVs.count。
    NSInteger maxCount = 0;
    for (AIFeatureJvBuModel *item in self.stModels) {
        maxCount = MAX(maxCount, item.bestGVs.count);
    }
    
    // 归一化每一条：越多的越好，越少的越孬（参考35082-方案4）。
    for (AIFeatureJvBuModel *item in self.stModels) {
        item.bestGVsCountRatio = (float)item.bestGVs.count / maxCount;
    }
}

// item.assT.absLevel抽象度，归一化计算（用于在稳定层里优先抽象层）。
-(void) run4AbsLevelRatio {
    // 找出最高抽象级。
    NSInteger maxLevel = 0;
    for (AIFeatureJvBuModel *item in self.stModels) {
        maxLevel = MAX(maxLevel, item.assT.absLevel);
    }
    
    // 归一化每一条：越抽象的越好，越具象的越孬（参考35082-方案4）。
    for (AIFeatureJvBuModel *item in self.stModels) {
        item.absLevelRatio = (float)item.assT.absLevel / maxLevel;
    }
}

@end
