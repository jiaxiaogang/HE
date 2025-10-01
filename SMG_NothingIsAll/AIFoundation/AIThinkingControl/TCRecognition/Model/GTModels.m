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

-(void) run4ModelsMatchDegree {
    self.modelsMatchDegree = self.models.count > 0 ? [SMGUtils sumOfArr:self.models convertBlock:^double(GTModel *obj) {
        return obj.modelMatchDegree;
    }] / self.models.count : 0;
}

-(void) run4ModelsMatchRatio {
    for (GTModel *model in self.models) {
        [model run4ModelMatchRatio];
    }
}

@end
