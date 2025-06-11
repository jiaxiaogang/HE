//
//  AIFeatureZenTiModels.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------用于记录组特征识别中，所有的组特征--------------------
 */
@interface AIFeatureZenTiModels : NSObject

@property (strong, nonatomic) NSMutableArray *models;

-(AIFeatureZenTiModel*) getModelIfNullCreate:(AIKVPointer*)assT;
-(void) updateItem:(AIPort*)assPort fromItemT:(AIFeatureJvBuModel*)fromItemT protoGTIndex:(NSInteger)protoGTIndex;

/**
 *  MARK:--------------------组特征rectItems重复问题：位置符合度竞争防重（参考35034）--------------------
 */
-(void) run4BestRemoveRepeat:(AIKVPointer*)protoT;

/**
 *  MARK:--------------------跑出位置符合度--------------------
 */
-(void) run4MatchDegree:(AIKVPointer*)protoT;

/**
 *  MARK:--------------------跑出综合匹配度--------------------
 */
-(void) run4MatchValue:(AIKVPointer*)protoT;
-(void) run4MatchValueV2:(AIKVPointer*)protoT;
-(void) run4StrongRatio;

@end
