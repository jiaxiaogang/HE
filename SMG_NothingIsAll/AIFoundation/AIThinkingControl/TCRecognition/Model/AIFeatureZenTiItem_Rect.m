//
//  AIFeatureZenTiItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureZenTiItem_Rect.h"

@implementation AIFeatureZenTiItem_Rect

+(AIFeatureZenTiItem_Rect*) new:(AIFeatureJvBuModel*)fromItemT itemAtAssRect:(CGRect)itemAtAssRect itemToAssStrong:(NSInteger)itemToAssStrong protoGTIndex:(NSInteger)protoGTIndex {
    AIFeatureZenTiItem_Rect *result = [[AIFeatureZenTiItem_Rect alloc] init];
    result.fromItemT = fromItemT;
    result.itemAtAssRect = itemAtAssRect;
    result.rect = itemAtAssRect;
    result.itemToAssStrong = itemToAssStrong;
    result.protoGTIndex = protoGTIndex;
    return result;
}

-(AIKVPointer*) fromItemT_p {
    //生成protoT的是absT就传absT，是assT就传assT，因为：一来要用它们的抽具象关联，二来要和fromItemT.bestGVs相对应（后面的类比等操作都要依赖这个bestGVs）。
    //改为assT,absT准备废弃掉，因为识别时，不再依赖类比后，统一直接改成原来的assT方式。
    return self.fromItemT.assT.p;
}

@end
