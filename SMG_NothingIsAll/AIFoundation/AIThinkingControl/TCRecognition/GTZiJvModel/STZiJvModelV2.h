//
//  STZiJvGroup.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/14.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STZiJvModelV2 : NSObject

@property (strong, nonatomic) AIFeatureNode *baseST;
@property (strong, nonatomic) NSMutableDictionary *bestGVs; // Dic<gvIndex, AIFeatureJvBuItem>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;
-(CGRect) bestGVs_ST;
-(CGRect) bestGVs_Proto;

// GT时为baseST_Proto（要根据bests计算出bestGVs_Proto，然后再推算出整个baseST_Proto）
// ST时用jvBuItem.bestGVAtProtoTRect即可，用不着这个。
@property (assign, nonatomic) CGRect baseST_Proto;

-(CGFloat) stMatchValue;
-(CGFloat) stMatchDegree;
-(CGFloat) stMatchCountRatio;

/**
 *  MARK:--------------------st位置符合度--------------------
 *  @param hopeRect 传所属GT期望当前st在Proto中的位置。
 */
-(CGFloat) stMatchDegree:(CGRect)hopeRect;

@property (strong, nonatomic) AIFeatureNode *absST; // 类比gtGroup时，先把stGroup中的bestGVs抽象成absST。
@property (assign, nonatomic) CGRect absST_BaseST; // 类比后，取得absST_BaseST

@end
