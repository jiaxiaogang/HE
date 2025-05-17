//
//  AIFeatureZenTiModels.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureZenTiModels.h"

@implementation AIFeatureZenTiModels

-(NSMutableArray *)models {
    if (!_models) _models = [NSMutableArray new];
    return _models;
}

-(AIFeatureZenTiModel*) getModelIfNullCreate:(AIKVPointer*)assT {
    //1. 优先找旧的。
    for (AIFeatureZenTiModel *model in self.models) {
        if ([model.assT isEqual:assT]) return model;
    }
    
    //2. 找不到则新建。
    AIFeatureZenTiModel *newModel = [AIFeatureZenTiModel new:assT];
    [self.models addObject:newModel];
    return newModel;
}

-(void) updateItem:(AIPort*)assPort fromItemT:(AIKVPointer*)fromItemT protoGTIndex:(NSInteger)protoGTIndex {
    AIFeatureZenTiModel *model = [self getModelIfNullCreate:assPort.target_p];
    [model updateRectItem:fromItemT itemAtAssRect:assPort.rect itemToAssStrong:assPort.strong.value protoGTIndex:protoGTIndex];
}

/**
 *  MARK:--------------------组特征rectItems重复问题：位置符合度竞争防重（参考35034）--------------------
 */
-(void) run4BestRemoveRepeat:(AIKVPointer*)protoT {
    AIFeatureZenTiModel *protoModel = [self getModelIfNullCreate:protoT];
    for (AIFeatureZenTiModel *assModel in self.models) {
        if ([assModel.assT isEqual:protoT]) continue;
        [assModel run4BestRemoveRepeat:protoModel];
    }
}

/**
 *  MARK:--------------------跑出位置符合度--------------------
 */
-(void) run4MatchDegree:(AIKVPointer*)protoT {
    //1. 求出比例。
    AIFeatureZenTiModel *protoModel = [self getModelIfNullCreate:protoT];
    for (AIFeatureZenTiModel *assModel in self.models) {
        if ([assModel.assT isEqual:protoT]) continue;
        //3. 计算assModel的位置符合度。
        [assModel run4MatchDegree:protoModel];
    }
}

/**
 *  MARK:--------------------跑出综合匹配度--------------------
 */
-(void) run4MatchValue:(AIKVPointer*)protoT {
    for (AIFeatureZenTiModel *conModel in self.models) {
        [conModel run4MatchValue:protoT];
    }
}

-(void) run4MatchValueV2:(AIKVPointer*)protoT {
    //1. 求出比例。
    for (AIFeatureZenTiModel *assModel in self.models) {
        if ([assModel.assT isEqual:protoT]) continue;
        //3. 计算assModel的匹配度。
        [assModel run4MatchValueV2:protoT];
    }
}

@end
