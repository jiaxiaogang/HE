//
//  AIMatchModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/19.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIMatchModel.h"

@implementation AIMatchModel

-(id) init {
    self = [super init];
    if (self != nil) {
        self.matchValue = 1;
    }
    return self;
}


-(id) initWithMatch_p:(AIKVPointer*)match_p {
    self = [super init];
    if (self) {
        self.matchValue = 1;
        self.match_p = match_p;
    }
    return self;
}

@end
