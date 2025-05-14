//
//  AIGroupFeatureNode.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/12.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIGroupFeatureNode.h"

@implementation AIGroupFeatureNode

-(NSArray*) convert2GVModels {
    NSMutableArray *gvModels = [NSMutableArray new];
    for (NSInteger i = 0; i < self.count; i++) {
        AIKVPointer *itemT_p = ARR_INDEX(self.content_ps, i);
        AIFeatureNode *itemT = [SMGUtils searchNode:itemT_p];
        CGRect itemTRect = VALTOOK(ARR_INDEX(self.rects, i)).CGRectValue;
        for (NSInteger j = 0; j < itemT.count; j++) {
            CGRect itemGVRect = VALTOOK(ARR_INDEX(itemT.rects, i)).CGRectValue;
            
            //TODOTOMORROW20250514: 这里很多宽高不一致的情况 & 还有很多宽高为0的情况。
            if (itemGVRect.size.width != itemGVRect.size.height) {
                NSLog(@"");
            }
            
            if (itemGVRect.size.width == 0 || itemGVRect.size.height == 0) {
                NSLog(@"");
            }
                
                
            itemGVRect.origin.x += itemTRect.origin.x;
            itemGVRect.origin.y += itemTRect.origin.y;
            [gvModels addObject:[InputGroupValueModel new:ARR_INDEX(self.content_ps, i) rect:itemGVRect]];
        }
    }
    return gvModels;
}

@end
