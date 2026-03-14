//
//  STZiJvGroup.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/14.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STZiJvGroup : NSObject

@property (strong, nonatomic) AIFeatureNode *baseST;
@property (strong, nonatomic) NSMutableArray *bestGVs; // List<AIFeatureJvBuItem>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;

// GT时为baseST_Proto（要根据bests计算出bestGVs_Proto，然后再推算出整个baseST_Proto）
// ST时用jvBuItem.bestGVAtProtoTRect即可，用不着这个。
@property (assign, nonatomic) CGRect baseST_Proto;

// GT时，这个在GT.bests中的元素下，表示当前baseST所在的下标。
// ST时，GV的下标在jvBuItem.baseIndex，用不着这个。
@property (assign, nonatomic) NSInteger baseSTIndex;

@end
