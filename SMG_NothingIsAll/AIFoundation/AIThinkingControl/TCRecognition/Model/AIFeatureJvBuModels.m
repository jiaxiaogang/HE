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
-(void) run4AreaRankRatioV2 {
    // 计算分区均衡排名分。
    for (AIFeatureJvBuModel *item in self.stModels) {
        [item run4ItemAreaRankScore:self.stModels];
    }
    
    // 找出均分最好的。
    CGFloat max = [SMGUtils filterBestScore:self.stModels scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
        return item.areaRankScore;
    }];
    
    // 归一化每一条：越多的越好，越少的越孬（参考35082-方案4）。
    for (AIFeatureJvBuModel *item in self.stModels) {
        item.areaRankRatio = max > 0 ? (float)item.areaRankScore / max : 0.0f;
    }
}

// item.bestGVs.count防止过度抽象，归一化计算。
-(void) run4BestGVsCountRatio {
    // 找出最长item的bestGVs.count。
    NSInteger maxCount = [SMGUtils filterBestScore:self.stModels scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
        return item.bestGVs.count;
    }];
    
    // 归一化每一条：越多的越好，越少的越孬（参考35082-方案4）。
    for (AIFeatureJvBuModel *item in self.stModels) {
        item.bestGVsCountRatio = (float)item.bestGVs.count / maxCount;
    }
}

// 匹配数，归一化防过抽（参考35141-方案1）。
-(void) run4ModelMatchCountScore {
    // 找出最高抽象级。
    NSInteger max = [SMGUtils filterBestScore:self.stModels scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
        return item.bestGVs.count;
    }];
    
    // 归一化每一条：越抽象的越好，越具象的越孬（参考35082-方案4）。
    for (AIFeatureJvBuModel *item in self.stModels) {
        item.modelMatchCountScore = (float)item.bestGVs.count / max;
    }
}

// 匹配率（健全度），归一化防过具竞争力（参考35141-方案3）。
-(void) run4ModelMatchRatioScore {
    // 找出最高抽象级。
    NSInteger max = [SMGUtils filterBestScore:self.stModels scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
        return (float)item.bestGVs.count / item.assT.count;
    }];
    NSLog(@"最高匹配率：%ld",max);
    
    // 归一化每一条：强度越大越好，越小越孬（参考35082-方案4）。
    for (AIFeatureJvBuModel *item in self.stModels) {
        float itemMatchRatio = (float)item.bestGVs.count / item.assT.count;
        item.modelMatchRatioScore = (float)itemMatchRatio / max;
    }
}

// 计算stModel的抽象强度得分。
-(void) run4AbsPortStrongScore {
    NSInteger max = [SMGUtils filterBestScore:self.stModels scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
        return [SMGUtils sumOfArr:item.validAbsSTPorts convertBlock:^double(AIPort *obj) {
            return obj.strong.value;
        }];
    }];
    for (AIFeatureJvBuModel *item in self.stModels) {
        NSInteger cur = [SMGUtils sumOfArr:item.validAbsSTPorts convertBlock:^double(AIPort *obj) {
            return obj.strong.value;
        }];
        item.absPortStrongScore = max > 0 ? (float)cur / max : 0;
    }
}

// 计算强度归一化得分。
-(void) run4AverageContentStrongScore {
    NSArray *sorts = [SMGUtils sortBig2Small:self.stModels compareBlock:^double(AIFeatureJvBuModel *obj) {
        return obj.averageContentStrong;
    }];
    for (NSInteger i = 0; i < sorts.count; i++) {
        AIFeatureJvBuModel *item = ARR_INDEX(sorts, i);
        item.averageContentStrongScore = (float)(sorts.count - i) / sorts.count;
    }
}

// 每个条件都末尾淘汰20%（参考35138-TODO1）。
-(void) filter4ZonHe {
    CGFloat outerJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
        return model.outerShapeMatchValue;
    }] / self.stModels.count;
    CGFloat innerJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
        return model.innerEigenMatchValue;
    }] / self.stModels.count;
    CGFloat bestCountJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
        return model.bestGVs.count;
    }] / self.stModels.count;
    CGFloat matchRatioJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
        return model.modelMatchRatio;
    }] / self.stModels.count;
    CGFloat averageContentJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
        return model.averageContentStrong;
    }] / self.stModels.count;
    
    self.stModels = [SMGUtils filterArr:self.stModels checkValid:^BOOL(AIFeatureJvBuModel *model) {
        if (![TCLearningUtil noZeRenForPingJun:model.outerShapeMatchValue bigerMatchValue:outerJun]) return false;
        if (![TCLearningUtil noZeRenForPingJun:model.innerEigenMatchValue bigerMatchValue:innerJun]) return false;
        if (![TCLearningUtil noZeRenForPingJun:model.bestGVs.count bigerMatchValue:bestCountJun]) return false;
        if (![TCLearningUtil noZeRenForPingJun:model.modelMatchRatio bigerMatchValue:matchRatioJun]) return false;
        if (![TCLearningUtil noZeRenForPingJun:model.averageContentStrong bigerMatchValue:averageContentJun]) return false;
        return true;
    }];
}

@end
