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
 *  MARK:--------------------ST时的匹配度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchValue;
@property (assign, nonatomic) CGFloat stMatchValue;

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree;
@property (assign, nonatomic) CGFloat stMatchDegree;

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore;

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
-(void) run4GTValidAbsPorts;
@property (strong, nonatomic) NSArray *validAbsPorts;

@end
