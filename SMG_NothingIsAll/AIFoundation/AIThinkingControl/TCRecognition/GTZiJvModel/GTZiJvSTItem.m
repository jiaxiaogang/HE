//
//  GTZiJvSTItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTZiJvSTItem.h"

@implementation GTZiJvSTItem

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newGVIndex {    
    // gvs在ST中的Rect
    CGRect gvs_ST = [SMGUtils convertArr2Rect:self.gvs itemRectBlock:^CGRect(AIFeatureJvBuItem *item) { return [self.baseST rectByIndex:item.baseIndex]; }];
    
    // gvs在Proto中的Rect
    CGRect gvs_Proto = [SMGUtils convertArr2Rect:self.gvs itemRectBlock:^CGRect(AIFeatureJvBuItem *item) { return item.bestGVAtProtoTRect; }];
    
    // index的GV在ST中的Rect
    CGRect newGV_ST = [self.baseST rectByIndex:newGVIndex];
    
    // 用newGV_ST、以及已知gvs_Proto、已知gvs_ST，预计出newGV_Proto。
    CGRect newGV_Proto = [SMGUtils convertNewAAtCWithAAtB:gvs_ST aAtC:gvs_Proto newAAtB:newGV_ST];
    
    // 即为：预计newGV的protoRect。
    return newGV_Proto;
}

@end
