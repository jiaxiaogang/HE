//
//  AIFeatureZenTiModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureZenTiModel.h"

@implementation AIFeatureZenTiModel

+(AIFeatureZenTiModel*) new:(AIKVPointer*)assT {
    AIFeatureZenTiModel *result = [[AIFeatureZenTiModel alloc] init];
    result.assT = assT;
    result.rectItems = [NSMutableArray new];
    return result;
}

//MARK:===============================================================
//MARK:                     < 收集数据组 >
//MARK:===============================================================
-(void) updateRectItem:(AIKVPointer*)fromItemT itemAtAssRect:(CGRect)itemAtAssRect itemToAssStrong:(NSInteger)itemToAssStrong protoGTIndex:(NSInteger)protoGTIndex {
    [self.rectItems addObject:[AIFeatureZenTiItem_Rect new:fromItemT itemAtAssRect:itemAtAssRect itemToAssStrong:itemToAssStrong protoGTIndex:protoGTIndex]];
}

-(CGRect) getRectItem:(AIKVPointer*)fromItemT {
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        if ([item.fromItemT isEqual:fromItemT]) return item.rect;
    }
    return CGRectNull;
}

//MARK:===============================================================
//MARK:                     < 位置符合度竞争防重 >
//MARK:===============================================================

/**
 *  MARK:--------------------组特征rectItems重复问题：位置符合度竞争防重（参考35034）--------------------
 *  @desc 方法说明：该方法，用best竞争解决重影问题（参考35034）。
 *  @desc 问题说明：有时protoGT中多个item会指向assGT同一个item，比如protoGT为0时，其左上角(proto2)和右下角(proto5)都是上斜线，可能同时匹配到assGT中的(ass2)左上角。
 *  @desc 方案说明：但这两个匹配只有一个位置符合度更好，本方法即用于通过位置符合度竞争，保留best一条。
 */
-(void) run4BestRemoveRepeat:(AIFeatureZenTiModel*)protoModel {
    //1. 计算符合度。
    [self run4MatchDegree:protoModel];
    
    //2. 多个protoGT.item指向同一个rectItem时，进行防重。
    NSArray *sort = [SMGUtils sortBig2Small:self.rectItems compareBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return obj.itemMatchDegree;
    }];
    NSArray *removeRepeat = [SMGUtils removeRepeat:sort convertBlock:^id(AIFeatureZenTiItem_Rect *obj) {
        return @(obj.itemAtAssRect);
    }];
    
    //3. 保留防重后的结果。
    [self.rectItems removeAllObjects];
    [self.rectItems addObjectsFromArray:removeRepeat];
    
    //4. 恢复原状。
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        item.rect = item.itemAtAssRect;
    }
}

//MARK:===============================================================
//MARK:                     < 计算位置符合度组 >
//MARK:===============================================================
-(void) run4MatchDegree:(AIFeatureZenTiModel*)protoModel {
    //0. 存下protoT来，类比时要用下。
    self.protoT = protoModel.assT;
    
    //=============== step1: 缩放对齐（参考34136-TODO1）===============
    //1. 比例排序。
    NSArray *scaleSort = [SMGUtils sortSmall2Big:self.rectItems compareBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return [self scale4RectItemAtProto:protoModel rectItem:obj];
    }];
    
    //2. 掐头去尾。
    NSArray *scaleValid = scaleSort.count > 3 ? ARR_SUB(scaleSort, scaleSort.count * 0.1, scaleSort.count * 0.8) : scaleSort;
    
    //3. 求平均scale。
    CGFloat pinJunScale = scaleValid.count == 0 ? 0 : [SMGUtils sumOfArr:scaleValid convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return [self scale4RectItemAtProto:protoModel rectItem:obj];
    }] / scaleValid.count;
    
    //4. 缩放对齐。
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        item.rect = CGRectMake(item.rect.origin.x / pinJunScale,item.rect.origin.y / pinJunScale,item.rect.size.width / pinJunScale, item.rect.size.height / pinJunScale);
    }
    
    //=============== step2: DeltaX对齐（参考34136-TODO2）===============
    //11. 缩放对齐后，然后根据deltaX排序。
    NSArray *deltaXSort = [SMGUtils sortSmall2Big:self.rectItems compareBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return [self deltaX4RectItemAtProto:protoModel rectItem:obj];
    }];
    
    //12. 掐头去尾。
    NSArray *deltaXValid = deltaXSort.count > 3 ? ARR_SUB(deltaXSort, deltaXSort.count * 0.1, deltaXSort.count * 0.8) : deltaXSort;
    
    //13. 求平均deltaX。
    CGFloat pinJunDelteX = deltaXValid.count == 0 ? 0 : [SMGUtils sumOfArr:deltaXValid convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return [self deltaX4RectItemAtProto:protoModel rectItem:obj];
    }] / deltaXValid.count;
    
    //14. deltaX对齐。
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        item.rect = CGRectMake(item.rect.origin.x - pinJunDelteX, item.rect.origin.y,item.rect.size.width, item.rect.size.height);
    }
    
    //=============== step3: DeltaY对齐（参考34136-TODO3）===============
    //21. 缩放对齐后，然后根据deltaX排序。
    NSArray *deltaYSort = [SMGUtils sortSmall2Big:self.rectItems compareBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return [self deltaY4RectItemAtProto:protoModel rectItem:obj];
    }];
    
    //22. 掐头去尾。
    NSArray *deltaYValid = deltaYSort.count > 3 ? ARR_SUB(deltaYSort, deltaYSort.count * 0.1, deltaYSort.count * 0.8) : deltaYSort;
    
    //23. 求平均deltaY。
    CGFloat pinJunDelteY = deltaYValid.count == 0 ? 0 : [SMGUtils sumOfArr:deltaYValid convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return [self deltaY4RectItemAtProto:protoModel rectItem:obj];
    }] / deltaYValid.count;
    
    //24. deltaY对齐。
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        item.rect = CGRectMake(item.rect.origin.x, item.rect.origin.y - pinJunDelteY,item.rect.size.width, item.rect.size.height);
    }
    
    //=============== step4: 求三个相近度（参考34136-TODO4）===============
    //31. 找出与proto最大的差距(span)值。
    CGFloat scaleMin = 99999999,scaleMax = -99999999;
    CGFloat deltaXMin = 99999999,deltaXMax = -99999999;
    CGFloat deltaYMin = 99999999,deltaYMax = -99999999;
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        CGFloat itemScale = [self scale4RectItemAtProto:protoModel rectItem:item];
        CGFloat itemDeltaX = [self deltaX4RectItemAtProto:protoModel rectItem:item];
        CGFloat itemDeltaY = [self deltaY4RectItemAtProto:protoModel rectItem:item];
        if (scaleMin > itemScale) scaleMin = itemScale;
        if (scaleMax < itemScale) scaleMax = itemScale;
        if (deltaXMin > itemDeltaX) deltaXMin = itemDeltaX;
        if (deltaXMax < itemDeltaX) deltaXMax = itemDeltaX;
        if (deltaYMin > itemDeltaY) deltaYMin = itemDeltaY;
        if (deltaYMax < itemDeltaY) deltaYMax = itemDeltaY;
    }
    CGFloat scaleSpan = scaleMax - scaleMin;
    CGFloat deltaXSpan = deltaXMax - deltaXMin;
    CGFloat deltaYSpan = deltaYMax - deltaYMin;
    
    //32. 根据item与proto的差距 / 最大差距 = 得出相近度。
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        CGFloat itemScale = [self scale4RectItemAtProto:protoModel rectItem:item];
        CGFloat itemDeltaX = [self deltaX4RectItemAtProto:protoModel rectItem:item];
        CGFloat itemDeltaY = [self deltaY4RectItemAtProto:protoModel rectItem:item];
        item.scaleMatchValue = 1 - (scaleSpan == 0 ? 0 : fabs(itemScale - 1) / scaleSpan);
        item.deltaXMatchValue = 1 - (deltaXSpan == 0 ? 0 : fabs(itemDeltaX) / deltaXSpan);
        item.deltaYMatchValue = 1 - (deltaYSpan == 0 ? 0 : fabs(itemDeltaY) / deltaYSpan);
    }
    
    //=============== step5: 该assT与protoT的这一块局部特征的“位置符合度” = 三个要素乘积（参考34136-TODO5）===============
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        item.itemMatchDegree = item.scaleMatchValue * item.deltaXMatchValue * item.deltaYMatchValue;
    }
    
    //=============== step6: 求当前assModel的综合位置符合度（参考34136-TODO6）===============
    self.modelMatchDegree = self.rectItems.count == 0 ? 0 : [SMGUtils sumOfArr:self.rectItems convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return obj.itemMatchDegree;
    }] / self.rectItems.count;
}

-(void) run4MatchValue:(AIKVPointer*)protoT {
    //0. 存下protoT来，类比时要用下。
    self.protoT = protoT;
    
    //1. self就是protoT时，直接设为匹配度1。
    if ([self.assT isEqual:protoT]) {
        self.modelMatchValue = 1;
        return;
    }
    
    //2. 别的assT则计算综合平均匹配度。
    for (AIFeatureZenTiItem_Rect *item in self.rectItems) {
        AIFeatureNode *fromItemT = [SMGUtils searchNode:item.fromItemT];
        
        //3. assT与absT的匹配度 * assT与protoT的匹配度 = assT与protoT的匹配度。
        item.itemMatchValue = [fromItemT getConMatchValue:self.assT] * [fromItemT getConMatchValue:protoT];
    }
    
    //4. 求出整体特征：assT 与 protoT 的综合匹配度。
    self.modelMatchValue = self.rectItems.count == 0 ? 0 : [SMGUtils sumOfArr:self.rectItems convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return obj.itemMatchValue;
    }] / self.rectItems.count;
}

-(void) run4MatchValueV2:(AIKVPointer*)protoT {
    //0. 存下protoT来，类比时要用下。
    self.protoT = protoT;
    
    //4. 求出整体特征：assT 与 protoT 的综合匹配度。
    AIGroupFeatureNode *assGT = [SMGUtils searchNode:self.assT];
    self.modelMatchValue = assGT.count == 0 ? 0 : self.rectItems.count / (float)assGT.count;
}

-(void) run4StrongRatio {
    AIFeatureNode *assT = [SMGUtils searchNode:self.assT];
    //24. 显著度公式（参考34175-公式3）。
    //2025.05.13: contentPorts没有存强度，所以此处改为用assT.count做分母，实测下应该没问题（这应该会容易激活抽象组特征，后续看边测再边调整这些参数竞争公式）。
    NSInteger validStrong = [SMGUtils sumOfArr:self.rectItems convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return obj.itemToAssStrong;
    }];
    self.modelMatchConStrongRatio = assT.count > 0 ? validStrong / (float)assT.count : 0;
}

//MARK:===============================================================
//MARK:                     < PrivateMethod >
//MARK:===============================================================

//返回 rectItem 在 conAssT 与 protoT 的缩放比例。
-(CGFloat) scale4RectItemAtProto:(AIFeatureZenTiModel*)protoModel rectItem:(AIFeatureZenTiItem_Rect*)rectItem {
    //1. 取出abs在proto和ass中的范围。
    CGRect protoRect = [protoModel getRectItem:rectItem.fromItemT];
    CGRect conAssRect = rectItem.rect;
    
    //2. 计算缩放scale。
    return protoRect.size.width == 0 ? : conAssRect.size.width / (float)protoRect.size.width;
}

//返回 rectItem 在 conAssT 与 protoT 的deltaX偏移量。
-(CGFloat) deltaX4RectItemAtProto:(AIFeatureZenTiModel*)protoModel rectItem:(AIFeatureZenTiItem_Rect*)rectItem {
    //1. 取出abs在proto和ass中的范围。
    CGRect protoRect = [protoModel getRectItem:rectItem.fromItemT];
    
    //2. 计算result。
    return rectItem.rect.origin.x - protoRect.origin.x;
}

//返回 rectItem 在 conAssT 与 protoT 的deltaY偏移量。
-(CGFloat) deltaY4RectItemAtProto:(AIFeatureZenTiModel*)protoModel rectItem:(AIFeatureZenTiItem_Rect*)rectItem {
    //1. 取出abs在proto和ass中的范围。
    CGRect protoRect = [protoModel getRectItem:rectItem.fromItemT];
    
    //2. 计算result。
    return rectItem.rect.origin.y - protoRect.origin.y;
}

@end
