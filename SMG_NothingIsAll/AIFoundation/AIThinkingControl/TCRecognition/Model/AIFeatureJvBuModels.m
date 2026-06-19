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

-(PRJSModel *)stModels {
    if (!_stModels) _stModels = [PRJSModel new];
    return _stModels;
}

-(NSMutableArray *)gtModels {
    if (!_gtModels) _gtModels = [NSMutableArray new];
    return _gtModels;
}

// stModels的psArr+rsArr合并视图（用于不需要区分P/R的下游消费方）。
-(NSArray*) stModelsAll {
    return [SMGUtils collectArrA:self.stModels.psArr arrB:self.stModels.rsArr];
}

// 分区竞争匹配度：计算每条item的rankScore和rankRatio（P/R两组各自竞争，参考38065-TODO1）。
-(void) run4AreaRankRatioV2 {
    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        // 计算分区均衡排名分。
        for (AIFeatureJvBuModel *item in group) {
            [item run4ItemAreaRankScore:group];
        }

        // 找出均分最好的。
        CGFloat max = [SMGUtils filterBestScore:group scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
            return item.areaRankScore;
        }];

        // 归一化每一条：越多的越好，越少的越孬（参考35082-方案4）。
        for (AIFeatureJvBuModel *item in group) {
            item.areaRankRatio = max > 0 ? (float)item.areaRankScore / max : 0.0f;
        }
    }
}

// item.bestGVs.count防止过度抽象，归一化计算（P/R两组各自归一化）。
-(void) run4BestGVsCountRatio {
    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        // 找出最长item的bestGVs.count。
        NSInteger maxCount = [SMGUtils filterBestScore:group scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
            return item.bestGVs.count;
        }];

        // 归一化每一条：越多的越好，越少的越孬（参考35082-方案4）。
        for (AIFeatureJvBuModel *item in group) {
            item.bestGVsCountRatio = (float)item.bestGVs.count / maxCount;
        }
    }
}

// 匹配数，归一化防过抽（参考35141-方案1）（P/R两组各自归一化）。
-(void) run4ModelMatchCountScore {
    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        // 找出最高抽象级。
        NSInteger max = [SMGUtils filterBestScore:group scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
            return item.bestGVs.count;
        }];

        // 归一化每一条：越抽象的越好，越具象的越孬（参考35082-方案4）。
        for (AIFeatureJvBuModel *item in group) {
            item.modelMatchCountScore = (float)item.bestGVs.count / max;
        }
    }
}

// 匹配率（健全度），归一化防过具竞争力（参考35141-方案3）（P/R两组各自归一化）。
-(void) run4ModelMatchRatioScore {
    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        // 找出最高抽象级。
        NSInteger max = [SMGUtils filterBestScore:group scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
            return (float)item.bestGVs.count / item.assT.count;
        }];
        NSLog(@"最高匹配率：%ld",max);

        // 归一化每一条：强度越大越好，越小越孬（参考35082-方案4）。
        for (AIFeatureJvBuModel *item in group) {
            float itemMatchRatio = (float)item.bestGVs.count / item.assT.count;
            item.modelMatchRatioScore = (float)itemMatchRatio / max;
        }
    }
}

// 计算stModel的抽象强度得分（P/R两组各自归一化）。
-(void) run4AbsPortStrongScore {
    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        NSInteger max = [SMGUtils filterBestScore:group scoreBlock:^CGFloat(AIFeatureJvBuModel *item) {
            return [SMGUtils sumOfArr:item.validAbsSTPorts convertBlock:^double(AIPort *obj) {
                return obj.strong.value;
            }];
        }];
        for (AIFeatureJvBuModel *item in group) {
            NSInteger cur = [SMGUtils sumOfArr:item.validAbsSTPorts convertBlock:^double(AIPort *obj) {
                return obj.strong.value;
            }];
            item.absPortStrongScore = max > 0 ? (float)cur / max : 0;
        }
    }
}

// 计算强度归一化得分（P/R两组各自按排名归一化）。
-(void) run4AverageContentStrongScore {
    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        NSArray *sorts = [SMGUtils sortBig2Small:group compareBlock:^double(AIFeatureJvBuModel *obj) {
            return obj.averageContentStrong;
        }];
        for (NSInteger i = 0; i < sorts.count; i++) {
            AIFeatureJvBuModel *item = ARR_INDEX(sorts, i);
            item.averageContentStrongScore = (float)(sorts.count - i) / sorts.count;
        }
    }
}

// 匹配数归一化得分：依据排名（P/R两组各自计分）。
-(void) run4BestsCountScore:(NSInteger)protoCount {
    // 越大越好。
    for (AIFeatureJvBuModel *stModel in self.stModels.psArr) {
        stModel.bestsCountScore = (float)stModel.bestGVs.count / protoCount;
    }
    for (AIFeatureJvBuModel *stModel in self.stModels.rsArr) {
        stModel.bestsCountScore = (float)stModel.bestGVs.count / protoCount;
    }
}

-(void) run4TotalCountScore:(NSInteger)protoCount {
    // 越大越好。
    for (AIFeatureJvBuModel *stModel in self.stModels.psArr) {
        stModel.totalCountScore = (float)stModel.assT.count / protoCount;
    }
    for (AIFeatureJvBuModel *stModel in self.stModels.rsArr) {
        stModel.totalCountScore = (float)stModel.assT.count / protoCount;
    }
}

/**
 *  MARK:--------------------ST定责末尾淘汰（参考35138-TODO1）。--------------------
 *  @status 关掉：这个五项分别淘汰的太狠，200条只剩没几条。如果综合淘汰，与st识别后的竞争因子综合竞争就一模一样重复了。
 */
-(void) filter4ZonHe {
    
    // =================== 方式2、根据五项分别定责淘汰 ===================
    
    //CGFloat outerJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
    //    return model.outerShapeMatchValue;
    //}] / self.stModels.count;
    //CGFloat innerJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
    //    return model.innerEigenMatchValue;
    //}] / self.stModels.count;
    //CGFloat bestCountJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
    //    return model.bestGVs.count;
    //}] / self.stModels.count;
    //CGFloat matchRatioJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
    //    return model.modelMatchRatio;
    //}] / self.stModels.count;
    //CGFloat averageContentJun = self.stModels.count == 0 ? 0 : [SMGUtils sumOfArr:self.stModels convertBlock:^double(AIFeatureJvBuModel *model) {
    //    return model.averageContentStrong;
    //}] / self.stModels.count;
    //
    //self.stModels = [SMGUtils filterArr:self.stModels checkValid:^BOOL(AIFeatureJvBuModel *model) {
    //    if (![TCLearningUtil noZeRenForPingJun:model.outerShapeMatchValue bigerMatchValue:outerJun]) return false;
    //    if (![TCLearningUtil noZeRenForPingJun:model.innerEigenMatchValue bigerMatchValue:innerJun]) return false;
    //    if (![TCLearningUtil noZeRenForPingJun:model.bestGVs.count bigerMatchValue:bestCountJun]) return false;
    //    if (![TCLearningUtil noZeRenForPingJun:model.modelMatchRatio bigerMatchValue:matchRatioJun]) return false;
    //    if (![TCLearningUtil noZeRenForPingJun:model.averageContentStrong bigerMatchValue:averageContentJun]) return false;
    //    return true;
    //}];
    
    // =================== 方式2、根据综合定责淘汰（P/R两组各自淘汰） ===================

    for (NSMutableArray *group in @[self.stModels.psArr, self.stModels.rsArr]) {
        CGFloat modelScore = group.count == 0 ? 0 : [SMGUtils sumOfArr:group convertBlock:^double(AIFeatureJvBuModel *model) {
            return model.matchValue * model.bestGVs.count * model.modelMatchRatio * model.averageContentStrongScore;
        }] / group.count;

        NSArray *filtered = [SMGUtils filterArr:group checkValid:^BOOL(AIFeatureJvBuModel *model) {
            CGFloat itemScore = model.matchValue * model.bestGVs.count * model.modelMatchRatio * model.averageContentStrongScore;
            return [TCLearningUtil noZeRenForPingJun:itemScore bigerMatchValue:modelScore];
        }];
        [group removeAllObjects];
        [group addObjectsFromArray:filtered];
    }
}

@end
