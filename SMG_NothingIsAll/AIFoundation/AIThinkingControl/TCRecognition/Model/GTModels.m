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
 *  MARK:--------------------主因子：符合度--------------------
 */
-(void) run4ModelsMatchDegree {
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
    CGFloat max = [SMGUtils filterBestScore:self.models scoreBlock:^CGFloat(GTModel *model) {
        return model.items.count;
    }];
    for (GTModel *model in self.models) {
        model.modelCountRatio = max == 0 ? 0 : model.items.count / max;
    }
}

@end
