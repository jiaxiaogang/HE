//
//  GTModels.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GTModels.h"

@implementation GTModels

-(void) run4PinJunMatchDegree {
    [SMGUtils sumOfArr:self.allValues convertBlock:^double(GTModel *obj) {
        return obj.modelMatchDegree;
    }]
}

@end
