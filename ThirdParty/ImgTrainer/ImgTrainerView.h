//
//  ImgTrainerView.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/25.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AIFeatureNode,AIFeatureJvBuModel;
@interface ImgTrainerView : UIView

-(void) open;

/**
 *  MARK:--------------------setData--------------------
 *  @param mode 1custom模式 2imageNet模式 3Mnist模式（暂不需要，但也用过人家图库，挂个名）。
 */
-(void) setData:(int)mode;

/**
 *  MARK:--------------------局部特征识别结果可视化（参考34176）--------------------
 */
-(void) setDataForJvBuModelV2:(AIFeatureJvBuModel*)jvBuModel lab:(NSString*)lab;
-(void) setDataForAlgs:(NSArray*)models;

-(void) setDataForFeature:(AIFeatureNode*)tNode lab:(NSString*)lab;
-(void) setDataForAlg:(AINodeBase*)algNode lab:(NSString*)lab;

@end
