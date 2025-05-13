//
//  AIFeatureZenTiModels.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------用于记录整体特征识别中，所有的整体特征--------------------
 */
@interface AIFeatureZenTiModels : NSObject

@property (strong, nonatomic) NSMutableArray *models;

-(AIFeatureZenTiModel*) getModelIfNullCreate:(AIKVPointer*)assT;
-(void) updateItem:(AIPort*)assPort fromItemT:(AIKVPointer*)fromItemT;

/**
 *  MARK:--------------------跑出位置符合度--------------------
 */
-(void) run4MatchDegree:(AIKVPointer*)protoT;

/**
 *  MARK:--------------------跑出综合匹配度--------------------
 */
-(void) run4MatchValue:(AIKVPointer*)protoT;
-(void) run4MatchValueV2:(AIKVPointer*)protoT;

@end
