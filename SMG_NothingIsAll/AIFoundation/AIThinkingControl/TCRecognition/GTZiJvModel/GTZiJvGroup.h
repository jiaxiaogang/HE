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

@property (strong, nonatomic) NSMutableDictionary *stMatchDegreeDic; // GT收集每个best时，把对应的匹配度收集下来。

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;

// GT时为baseST_Proto（要根据bests计算出bestGVs_Proto，然后再推算出整个baseST_Proto）
// ST时用jvBuItem.bestGVAtProtoTRect即可，用不着这个。
@property (assign, nonatomic) CGRect baseST_Proto;

// GT时，这个在GT.bests中的元素下，表示当前baseST所在的下标。
// ST时，GV的下标在jvBuItem.baseIndex，用不着这个。
@property (assign, nonatomic) NSInteger baseSTIndex;

/**
 *  MARK:--------------------主因子：匹配度--------------------
 */
-(void) run4GTMatchValue;
@property (assign, nonatomic) CGFloat gtMatchValue;

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4GTMatchDegree;
@property (assign, nonatomic) CGFloat gtMatchDegree;

/**
 *  MARK:--------------------ST时的匹配度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchValue;
@property (assign, nonatomic) CGFloat stMatchValue;

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree;
@property (assign, nonatomic) CGFloat stMatchDegree;

@end
