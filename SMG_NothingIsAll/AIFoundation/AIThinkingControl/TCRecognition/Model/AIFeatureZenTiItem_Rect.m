//
//  AIFeatureZenTiItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureZenTiItem_Rect.h"

@implementation AIFeatureZenTiItem_Rect

+(AIFeatureZenTiItem_Rect*) new:(AIKVPointer*)fromItemT itemAtAssRect:(CGRect)itemAtAssRect itemToAssStrong:(NSInteger)itemToAssStrong protoGTIndex:(NSInteger)protoGTIndex {
    AIFeatureZenTiItem_Rect *result = [[AIFeatureZenTiItem_Rect alloc] init];
    result.fromItemT = fromItemT;
    result.itemAtAssRect = itemAtAssRect;
    result.rect = itemAtAssRect;
    result.itemToAssStrong = itemToAssStrong;
    result.protoGTIndex = protoGTIndex;
    return result;
}

@end
