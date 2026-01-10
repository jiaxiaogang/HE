//
//  GTModels.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GTModels.h"

@implementation GTModels

-(NSMutableArray*) models {
    if (!_models) _models = [NSMutableArray new];
    return _models;
}

/**
 *  MARK:--------------------主因子：匹配度--------------------
 */
-(void) run4ModelsMatchValue {
    // 1. 计算每个model的匹配度
    for (GTModel *model in self.models) {
        [model run4ModelMatchValue];
    }
    
    // 2. 计算整个gtModels的匹配度。
    self.modelsMatchValue = self.models.count > 0 ? [SMGUtils sumOfArr:self.models convertBlock:^double(GTModel *obj) {
        return obj.modelMatchValue;
    }] / self.models.count : 0;
}

/**
 *  MARK:--------------------主因子：符合度--------------------
 */
-(void) run4ModelsMatchDegree {
    // 末尾淘汰过滤器：根据位置符合度末尾淘汰（参考34135-TODO4）。
    // 2025.09.09: 组特征竞争要只计算了位置符合度，和匹配率（参考35072-TODO3-竞争因子）。
    self.modelsMatchDegree = self.models.count > 0 ? [SMGUtils sumOfArr:self.models convertBlock:^double(GTModel *obj) {
        return obj.modelMatchDegree;
    }] / self.models.count : 0;
}

/**
 *  MARK:--------------------辅因子：计算健全度（防过具：因为只有抽象的匹配数才会高）--------------------
 */
-(void) run4ModelsMatchRatio {
    for (GTModel *model in self.models) {
        [model run4ModelMatchRatio];
    }
}

/**
 *  MARK:--------------------辅因子：元素数归一化值（防过抽：因为只有具象的匹配数count才可能长）--------------------
 */
-(void) run4ModelCountRatio {
    //2025.10.05: 加上obj.assGT.count，避免assGT的长度普遍太短问题。
    //2025.11.14: 防过抽assGTCountRatio支持归一化（归一化处理，避免count权重优势影响：就是先找出max然后全除以这个max）。
    CGFloat max = [SMGUtils filterBestScore:self.models scoreBlock:^CGFloat(GTModel *model) {
        return model.items.count;
    }];
    for (GTModel *model in self.models) {
        model.modelCountRatio = max == 0 ? 0 : model.items.count / max;
    }
}

@end
