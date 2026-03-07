//
//  GTModelV2.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/2/1.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTModelV2 : NSObject

+(id) new:(AIGroupFeatureNode*)assGT;

@property (strong, nonatomic) NSMutableDictionary *bestSTDic;
@property (strong, nonatomic) AIGroupFeatureNode *assGT;

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
@property (strong, nonatomic) NSArray *validAbsPorts;
-(void) run4ValidAbsPorts;

@property (assign, nonatomic) CGFloat matchValue;
-(void) run4MatchValue;

@property (assign, nonatomic) CGFloat matchCountRatio;
-(void) run4MatchCountRatio:(NSInteger)max;

@property (assign, nonatomic) CGFloat strongRatio;
-(void) run4StrongRatio;

@property (assign, nonatomic) CGFloat strongRatioByContent;
-(void) run4StrongRatioByContent;

@property (assign, nonatomic) CGFloat matchDegree;
-(void) run4MatchDegree;

@property (assign, nonatomic) CGFloat zonHeSTScore;
-(void) run4ZonHeSTScore;

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore;

@end
