//
//  GTZiJvGroup.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/11.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTZiJvGroup : NSObject

@property (strong, nonatomic) AIFeatureNode *baseGT;
@property (strong, nonatomic) NSMutableDictionary *bestSTs; // GT时为Dic<stIndex, STGroup>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;

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
 *  MARK:--------------------辅因子：元素数归一化值（防过抽：因为只有具象的匹配数count才可能长）--------------------
 */
-(void) run4GTMatchCountRatio:(NSInteger)max;
@property (assign, nonatomic) CGFloat gtMatchCountRatio;

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree;
@property (assign, nonatomic) CGFloat stMatchDegree;

/**
 *  MARK:--------------------ST时的匹配率：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchCountRatio;
@property (assign, nonatomic) CGFloat stMatchCountRatio;

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore;

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
-(void) run4GTValidAbs_ps;
@property (strong, nonatomic) NSArray *validAbs_ps;

@end
