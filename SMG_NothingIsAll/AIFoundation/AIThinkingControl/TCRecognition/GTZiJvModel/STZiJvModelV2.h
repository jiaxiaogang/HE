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
-(CGRect) hopeProtoRectByAll;
@property (assign, nonatomic) CGRect hopeProtoRectByAllCache; // 复用结果，但每次best有更新时，手动将此值清空，使之可以重算。

-(CGRect) bestGVs_ST;
-(CGRect) bestGVs_Proto;

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
