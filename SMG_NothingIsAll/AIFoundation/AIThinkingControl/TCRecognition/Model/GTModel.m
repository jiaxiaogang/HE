//
//  GTModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GTModel.h"

@implementation GTModel

+(id) new:(AIGroupFeatureNode*)assGT {
    GTModel *result = [GTModel new];
    result.assGT = assGT;
    return result;
}

/**
 *  MARK:--------------------重新计算whxyModel、itemMatchDegree、modelMatchDegree值--------------------
 */
-(void) run4WHXYModelMatchDegree {
    // ========= 计算WHXY的平均值，最小值，最大值，SPAN值 =========
    self.wModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.wRate);
    }]];
    self.hModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.hRate);
    }]];
    self.xModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.xDelta);
    }]];
    self.yModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.yDelta);
    }]];
}

-(void) run4ModelMatchDegree {
    //1. 算WHXYModel
    [self run4WHXYModelMatchDegree];
    
    //2. 算itemMatchDegree
    for (GTItem *item in self) {
        [item run4ItemMatchDegree:self];
    }
    
    //3. 求modelMatchDegree综合位置符合度（参考34136-TODO6）。
    self.modelMatchDegree = self.count == 0 ? 0 : [SMGUtils sumOfArr:self convertBlock:^double(GTItem *obj) {
        return obj.itemMatchDegree;
    }] / self.count;
}

-(void) run4ModelMatchRatio {
    self.modelMatchRatio = self.assGT.count > 0 ? self.count / (float)self.assGT.count : 0;
}

//MARK:===============================================================
//MARK:                     < PrivateMethod >
//MARK:===============================================================
-(MapModel*) run4PinJunMinMaxSpan:(NSArray*)numbers {
    NSArray *sort = [SMGUtils sortBig2Small:self compareBlock:^double(NSNumber *obj) { return obj.floatValue; }];// 排序
    sort = sort.count > 3 ? ARR_SUB(sort, sort.count * 0.1, sort.count * 0.8) : sort;// 掐头去尾。
    CGFloat pinJun = sort.count == 0 ? 0 : [SMGUtils sumOfArr:sort convertBlock:^double(NSNumber *obj) { return obj.floatValue; }] / sort.count;// 求平均。
    CGFloat min = NUMTOOK(ARR_INDEX_REVERSE(sort, 0)).floatValue;
    CGFloat max = NUMTOOK(ARR_INDEX(sort, 0)).floatValue;
    return [MapModel newWithV1:@(pinJun) v2:@(min) v3:@(max) v4:@(max - min)];
}

@end
