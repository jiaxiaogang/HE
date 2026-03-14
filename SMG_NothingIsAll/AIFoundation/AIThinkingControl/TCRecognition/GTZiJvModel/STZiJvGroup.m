//
//  STZiJvGroup.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/14.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "STZiJvGroup.h"

@implementation STZiJvGroup

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex {
    // bests在baseT中的Rect
    CGRect bests_BaseT = [SMGUtils convertArr2Rect:self.bestGVs itemRectBlock:^CGRect(AIFeatureJvBuItem *item) {
        return [self.baseST rectByIndex:item.baseIndex];
    }];
    
    // bests在Proto中的Rect
    CGRect bests_Proto = [SMGUtils convertArr2Rect:self.bestGVs itemRectBlock:^CGRect(AIFeatureJvBuItem *item) {
        return item.bestGVAtProtoTRect;
    }];
    
    // index的GV在ST中的Rect
    CGRect newBest_BaseT = [self.baseST rectByIndex:newBestIndex];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect newBest_Proto = [SMGUtils convertNewAAtCWithAAtB:bests_BaseT aAtC:bests_Proto newAAtB:newBest_BaseT];
    
    // 即为：预计newGV的protoRect。
    return newBest_Proto;
}

@end
