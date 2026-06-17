//
//  PRJSModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/6/18.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "PRJSModel.h"

@implementation PRJSModel

- (NSMutableArray *)psArr {
    if (!_psArr) {
        _psArr = [NSMutableArray new];
    }
    return _psArr;
}

- (NSMutableArray *)rsArr {
    if (!_rsArr) {
        _rsArr = [NSMutableArray new];
    }
    return _rsArr;
}

- (NSMutableArray *)pjArr {
    if (!_pjArr) {
        _pjArr = [NSMutableArray new];
    }
    return _pjArr;
}

- (NSMutableArray *)rjArr {
    if (!_rjArr) {
        _rjArr = [NSMutableArray new];
    }
    return _rjArr;
}

- (NSArray *)pArr {
    return [self.psArr arrayByAddingObjectsFromArray:self.pjArr];
}

- (NSArray *)rArr {
    return [self.rsArr arrayByAddingObjectsFromArray:self.rjArr];
}

@end
