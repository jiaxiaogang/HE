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
        NSLog(@"aaaa4 GT%ld itemTRect:%@",self.pId,Rect2Str(itemTRect));
        for (NSInteger j = 0; j < itemT.count; j++) {
            CGRect itemGVRect = VALTOOK(ARR_INDEX(itemT.rects, j)).CGRectValue;
            if (itemGVRect.size.width != itemGVRect.size.height || itemGVRect.size.width == 0 || itemGVRect.size.height == 0) {
                ELog(@"assRect数据异常: 宽高不一致，或宽高为0");
            }
            
            //TODOTOMORROW20250528: itemT和itemGVs的大小不同问题。
            //1. itemTRect为0,11,24,16
            //2. 五个itemGVRect分别为：
            //NSRect: {{0, 0}, {9, 9}},
            //NSRect: {{9, 0}, {9, 9}},
            //NSRect: {{9, 0}, {3, 3}},
            //NSRect: {{12, 0}, {3, 3}},
            //NSRect: {{15, 0}, {3, 3}}
            //说明：如上五个itemGVRect总大小为0,0,18,9，而itemTRect为24,16，显然二者大小不一致。
            NSLog(@"aaaa5 GT%ld itemGVRect:%@",self.pId,Rect2Str(itemGVRect));
            
            itemGVRect.origin.x += itemTRect.origin.x;
            itemGVRect.origin.y += itemTRect.origin.y;
            [gvModels addObject:[InputGroupValueModel new:ARR_INDEX(itemT.content_ps, j) rect:itemGVRect]];
        }
    }
    return gvModels;
}

@end
