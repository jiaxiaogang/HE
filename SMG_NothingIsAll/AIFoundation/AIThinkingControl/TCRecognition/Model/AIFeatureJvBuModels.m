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

@end
