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
        
        // 根据：itemT的原画大小 在 GT的画布大小上 => 进行拉伸平铺显示（参考35044-方案5）。
        CGRect itemTCanvasRect = VALTOOK(ARR_INDEX(self.rects, i)).CGRectValue;
        CGRect itemTPaintRect = [AINetUtils convertAllOfFeatureContent2Rect:itemT];
        CGFloat scaleW = itemTCanvasRect.size.width / itemTPaintRect.size.width;
        CGFloat scaleH = itemTCanvasRect.size.height / itemTPaintRect.size.height;
        
        NSLog(@"aaaa4 GT%ld 布:%@ 画:%@",self.pId,Rect2Str(itemTCanvasRect),Rect2Str(itemTPaintRect));
        for (NSInteger j = 0; j < itemT.count; j++) {
            CGRect itemGVPaintRect = VALTOOK(ARR_INDEX(itemT.rects, j)).CGRectValue;
            if (itemGVPaintRect.size.width != itemGVPaintRect.size.height || itemGVPaintRect.size.width == 0 || itemGVPaintRect.size.height == 0) {
                ELog(@"assRect数据异常: 宽高不一致，或宽高为0");
            }
            
            // 把item原画，拉伸到画布上（参考35044-方案5）。
            CGRect itemGVCanvasRect = CGRectMake(itemGVPaintRect.origin.x * scaleW, itemGVPaintRect.origin.y * scaleH, itemGVPaintRect.size.width * scaleW, itemGVPaintRect.size.height * scaleH);
            
            //TODOTOMORROW20250528: itemT和itemGVs的大小不同问题。
            //1. itemTRect为0,11,24,16
            //2. 五个itemGVRect分别为：
            //NSRect: {{0, 0}, {9, 9}},
            //NSRect: {{9, 0}, {9, 9}},
            //NSRect: {{9, 0}, {3, 3}},
            //NSRect: {{12, 0}, {3, 3}},
            //NSRect: {{15, 0}, {3, 3}}
            //说明：如上五个itemGVRect总大小为0,0,18,9，而itemTRect为24,16，显然二者大小不一致。
            NSLog(@"aaaa5 GT%ld 布:%@ 画:%@",self.pId,Rect2Str(itemGVCanvasRect),Rect2Str(itemGVPaintRect));
            
            // 把item画布的xy：从itemT坐标系 改成 GT坐标系（参考35044-方案5）。
            itemGVCanvasRect.origin.x += itemTCanvasRect.origin.x;
            itemGVCanvasRect.origin.y += itemTCanvasRect.origin.y;
            [gvModels addObject:[InputGroupValueModel new:ARR_INDEX(itemT.content_ps, j) rect:itemGVCanvasRect]];
        }
    }
    return gvModels;
}

@end
