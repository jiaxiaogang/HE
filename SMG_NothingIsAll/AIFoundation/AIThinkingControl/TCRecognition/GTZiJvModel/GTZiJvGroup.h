//
//  GTZiJvGroup.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/11.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTZiJvGroup : NSObject

@property (strong, nonatomic) AIFeatureNode *baseT; // ST时为baseST GT时为baseGT
@property (strong, nonatomic) NSMutableArray *bests; // ST时为List<AIFeatureJvBuItem> GT时为List<STGroup>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;

// GT时为targetST_Proto（要根据bests计算出bests_Proto，然后再推算出整个targetST_Proto）
// ST时为gv_Proto（此时bests的元素是JvBuItem，它本身就有gv_Proto）
@property (assign, nonatomic) CGRect targetST_Proto;

@end
