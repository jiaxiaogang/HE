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

-(void) run4ModelMatchDegree {
    // ========= 计算WHXY的平均值，最小值，最大值，SPAN值 =========
    MapModel *wModel = [self run4PinJunMinMax:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.wRate);
    }]];
    MapModel *hModel = [self run4PinJunMinMax:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.hRate);
    }]];
    MapModel *xModel = [self run4PinJunMinMax:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.xDelta);
    }]];
    MapModel *yModel = [self run4PinJunMinMax:[SMGUtils convertArr:self convertBlock:^id(GTItem *obj) {
        return @(obj.yDelta);
    }]];
    
    //=============== step4: 求三个相近度（参考34136-TODO4）===============
    
    //32. 根据item与proto的差距 / 最大差距 = 得出相近度。
    for (GTItem *item in self) {
        item.scaleMatchValue = 1 - (scaleSpan == 0 ? 0 : fabs(itemScale - 1) / scaleSpan);
        item.deltaXMatchValue = 1 - (deltaXSpan == 0 ? 0 : fabs(itemDeltaX) / deltaXSpan);
        item.deltaYMatchValue = 1 - (deltaYSpan == 0 ? 0 : fabs(itemDeltaY) / deltaYSpan);
    }
    
    //=============== step5: 该assT与protoT的这一块单特征的“位置符合度” = 三个要素乘积（参考34136-TODO5）===============
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        item.itemMatchDegree = item.scaleMatchValue * item.deltaXMatchValue * item.deltaYMatchValue;
    }
    
    //=============== step6: 求当前assModel的综合位置符合度（参考34136-TODO6）===============
    self.modelMatchDegree = self.rectItems.count == 0 ? 0 : [SMGUtils sumOfArr:self.rectItems convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return obj.itemMatchDegree;
    }] / self.rectItems.count;
}

-(MapModel*) run4PinJunMinMax:(NSArray*)numbers {
    NSArray *sort = [SMGUtils sortBig2Small:self compareBlock:^double(NSNumber *obj) { return obj.floatValue; }];// 排序
    sort = sort.count > 3 ? ARR_SUB(sort, sort.count * 0.1, sort.count * 0.8) : sort;// 掐头去尾。
    CGFloat pinJun = sort.count == 0 ? 0 : [SMGUtils sumOfArr:sort convertBlock:^double(NSNumber *obj) { return obj.floatValue; }] / sort.count;// 求平均。
    CGFloat min = NUMTOOK(ARR_INDEX_REVERSE(sort, 0)).floatValue;
    CGFloat max = NUMTOOK(ARR_INDEX(sort, 0)).floatValue;
    return [MapModel newWithV1:@(pinJun) v2:@(min) v3:@(max) v4:@(max - min)];
}

@end
