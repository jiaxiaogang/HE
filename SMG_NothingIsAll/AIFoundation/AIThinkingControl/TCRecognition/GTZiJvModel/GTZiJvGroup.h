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
@property (strong, nonatomic) NSMutableArray *bests; // ST时为List<AIFeatureJvBuItem> GT时为List<AIFeatureJvBuModel>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;

// GT时为st_Proto ST时为gv_Proto
//TODOTOMORROW20260311: ST时，把JvBuItem.gv_Proto存到此处 GT时，把JvBuModel.validAbsST在ProtoRect算出来存在此处。
@property (assign, nonatomic) CGRect bestAtProtoTRect;

@end
