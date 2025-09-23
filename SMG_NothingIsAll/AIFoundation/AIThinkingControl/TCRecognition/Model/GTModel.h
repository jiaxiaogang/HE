//
//  GTModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------GT识别模型--------------------
 */
@interface GTModel : NSMutableArray

+(id) new:(AIGroupFeatureNode*)assGT;

@property (strong, nonatomic) AIGroupFeatureNode *assGT;

@end
