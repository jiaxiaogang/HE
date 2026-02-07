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

@property (assign, nonatomic) CGFloat matchValue;
-(void) run4MatchValue;

@property (assign, nonatomic) CGFloat matchCountRatio;
-(void) run4MatchCountRatio:(NSInteger)max;

@property (assign, nonatomic) CGFloat strongRatio;
-(void) run4StrongRatio;

@end
