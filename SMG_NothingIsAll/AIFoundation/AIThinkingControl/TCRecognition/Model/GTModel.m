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
    result.items = [NSMutableArray new];
    return result;
}

/**
 *  MARK:--------------------重新计算PinJun、Min、Max、Span存到以下WHXYModel中--------------------
 */
-(void) run4WHXYModelMatchDegree {
    // ========= 计算WHXY的平均值，最小值，最大值，SPAN值 =========
    self.wModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self.items convertBlock:^id(GTItem *obj) {
        return @(obj.wRate);
    }]];
    self.hModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self.items convertBlock:^id(GTItem *obj) {
        return @(obj.hRate);
    }]];
    self.xModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self.items convertBlock:^id(GTItem *obj) {
        return @(obj.xDelta);
    }]];
    self.yModel = [self run4PinJunMinMaxSpan:[SMGUtils convertArr:self.items convertBlock:^id(GTItem *obj) {
        return @(obj.yDelta);
    }]];
    
    
    
    // TODOTOMORROW20251013:
    NSLog(@"1. 查下为什么符合度全是0和1，没中间值？GT%ld %.3f %.3f %.3f %.3f",self.assGT.pId,NUMTOOK(self.wModel.v1).floatValue,NUMTOOK(self.wModel.v2).floatValue,NUMTOOK(self.wModel.v3).floatValue,NUMTOOK(self.wModel.v4).floatValue);
    
}

/**
 *  MARK:--------------------重新计算itemMatchDegree、modelMatchDegree值（执行前需保证whxyModel已计算）--------------------
 */
-(void) run4ModelMatchDegree {
    //2. 算itemMatchDegree
    for (GTItem *item in self.items) {
        [item run4ItemMatchDegree:self];
    }
    
    //3. 求modelMatchDegree综合位置符合度（参考34136-TODO6）。
    self.modelMatchDegree = self.items.count == 0 ? 0 : [SMGUtils sumOfArr:self.items convertBlock:^double(GTItem *obj) {
        return obj.itemMatchDegree;
    }] / self.items.count;
}

-(void) run4ModelMatchRatio {
    self.modelMatchRatio = self.assGT.count > 0 ? self.items.count / (float)self.assGT.count : 0;
}

//MARK:===============================================================
//MARK:                     < PrivateMethod >
//MARK:===============================================================
-(MapModel*) run4PinJunMinMaxSpan:(NSArray*)numbers {
    NSArray *sort = [SMGUtils sortBig2Small:numbers compareBlock:^double(NSNumber *obj) { return obj.floatValue; }];// 排序
    sort = sort.count > 3 ? ARR_SUB(sort, sort.count * 0.1, sort.count * 0.8) : sort;// 掐头去尾。
    CGFloat pinJun = sort.count == 0 ? 0 : [SMGUtils sumOfArr:sort convertBlock:^double(NSNumber *obj) { return obj.floatValue; }] / sort.count;// 求平均。
    CGFloat min = NUMTOOK(ARR_INDEX_REVERSE(sort, 0)).floatValue;
    CGFloat max = NUMTOOK(ARR_INDEX(sort, 0)).floatValue;
    return [MapModel newWithV1:@(pinJun) v2:@(min) v3:@(max) v4:@(max - min)];
}

@end
