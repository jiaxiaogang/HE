//
//  ImgTrainerView.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/25.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AIFeatureNode,AIFeatureJvBuModel,AIFeatureZenTiModel;
@interface ImgTrainerView : UIView

-(void) open;

/**
 *  MARK:--------------------setData--------------------
 *  @param mode 1custom模式 2imageNet模式 3Mnist模式（暂不需要，但也用过人家图库，挂个名）。
 */
-(void) setData:(int)mode;

/**
 *  MARK:--------------------单特征识别结果可视化（参考34176）--------------------
 */
-(void) setDataForJvBuModelV2:(AIFeatureJvBuModel*)jvBuModel lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top;
-(void) setDataForZenTiModel:(AIFeatureZenTiModel*)zenTiModel lab:(NSString*)lab;
-(void) setDataForJvBuModelsV2:(NSArray*)jvBuModels lab:(NSString*)lab;//单特征识别结果数组，应该一个个元素显示，而不是一下把所有的显示到一个画布上。
-(void) setDataForJvBuModelsV3:(NSArray*)jvBuModels lab:(NSString*)lab;//有BUG，可视化像一块块分裂着。
-(void) setDataForAlgs:(NSArray*)models;

-(void) setDataForFeature:(AIFeatureNode*)tNode lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top;
-(void) setDataForAlg:(AINodeBase*)algNode lab:(NSString*)lab;

@end
