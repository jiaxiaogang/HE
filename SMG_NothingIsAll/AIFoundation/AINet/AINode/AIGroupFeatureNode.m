//
//  AIGroupFeatureNode.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/12.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIGroupFeatureNode.h"

@implementation AIGroupFeatureNode

-(NSArray*) convert2GVModels:(NSArray*)indexes {
    // 数据检查。
    if (!ARRISOK(indexes)) indexes = self.indexes;
    
    // 转为gvModels返回。
    NSMutableArray *gvModels = [NSMutableArray new];
    for (NSNumber *index in indexes) {
        NSInteger i = index.integerValue;
        
        // 每一条都单独取下面所有的gvs。
        AIKVPointer *itemT_p = ARR_INDEX(self.content_ps, i);
        AIFeatureNode *itemT = [SMGUtils searchNode:itemT_p];
        CGRect itemTRect = VALTOOK(ARR_INDEX(self.rects, i)).CGRectValue;
        for (NSInteger j = 0; j < itemT.count; j++) {
            CGRect itemGVRect = VALTOOK(ARR_INDEX(itemT.rects, j)).CGRectValue;
            if (itemGVRect.size.width != itemGVRect.size.height || itemGVRect.size.width == 0 || itemGVRect.size.height == 0) {
                ELog(@"assRect数据异常: 宽高不一致，或宽高为0");
            }
            itemGVRect.origin.x += itemTRect.origin.x;
            itemGVRect.origin.y += itemTRect.origin.y;
            [gvModels addObject:[InputGroupValueModel new:ARR_INDEX(itemT.content_ps, j) rect:itemGVRect]];
        }
    }
    return gvModels;
}

@end
