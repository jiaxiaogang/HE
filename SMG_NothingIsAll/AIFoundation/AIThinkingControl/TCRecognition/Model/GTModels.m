//
//  GTModels.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GTModels.h"

@implementation GTModels

-(void) run4ModelsMatchDegree {
    self.modelsMatchDegree = self.count > 0 ? [SMGUtils sumOfArr:self convertBlock:^double(GTModel *obj) {
        return obj.modelMatchDegree;
    }] / self.count : 0;
}

-(void) run4ModelsMatchRatio {
    for (GTModel *model in self) {
        [model run4ModelMatchDegree];
    }
}

@end
