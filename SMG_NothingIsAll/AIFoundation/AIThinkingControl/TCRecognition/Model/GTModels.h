//
//  GTModels.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTModels : NSObject

@property (strong, nonatomic) NSMutableArray *models;

@property (assign, nonatomic) CGFloat modelsMatchDegree;

/**
 *  MARK:--------------------主因子：符合度--------------------
 */
-(void) run4ModelsMatchDegree;

/**
 *  MARK:--------------------辅因子：计算健全度（防过具：因为只有抽象的匹配数才会高）--------------------
 */
-(void) run4ModelsMatchRatio;

/**
 *  MARK:--------------------辅因子：元素数归一化值（防过抽：因为只有具象的匹配数count才可能长）--------------------
 */
-(void) run4ModelCountRatio;

@end
