//
//  AIGeneralNodeCreater.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/19.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AIGeneralNodeCreater : NSObject

+(AIGroupValueNode*) createGroupValueNode:(NSArray*)item_ps conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut;
+(AIFeatureNode*) createFeatureNode:(NSArray*)groupModels conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut isJiao:(BOOL)isJiao;
+(AIGroupFeatureNode*) createGroupFeatureNode:(NSArray*)subTModels conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut isJiao:(BOOL)isJiao;

@end
