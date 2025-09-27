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

/**
 *  MARK:--------------------重新计算PinJun、Min、Max、Span存到以下WHXYModel中--------------------
 */
@property (strong, nonatomic) MapModel *wModel;
@property (strong, nonatomic) MapModel *hModel;
@property (strong, nonatomic) MapModel *xModel;
@property (strong, nonatomic) MapModel *yModel;
-(void) run4WHXYModelMatchDegree;

/**
 *  MARK:--------------------重新计算whxyModel、itemMatchDegree、modelMatchDegree值--------------------
 */
@property (assign, nonatomic) CGFloat modelMatchDegree;
-(void) run4ModelMatchDegree;

/**
 *  MARK:--------------------计算健全度--------------------
 */
@property (assign, nonatomic) CGFloat modelMatchRatio;
-(void) run4ModelMatchRatio;

@end
