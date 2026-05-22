//
//  ImgTrainerPreview.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/27.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>


#define cPreviewCellWidth 70

@interface ImgTrainerPreview : UIView

// 这一个cell显示部分，来自哪个模型，比如AIFeatureJvBuModel / AIFeatureNode / GTZiJvModelV2 / GTModelV2 / AIMatchModel
@property (strong, nonatomic) id fromObj;

// cell指定显示的画布大小
@property (assign, nonatomic) CGRect fromCanvas;

@property (strong, nonatomic) UILabel *lab;
@property (strong, nonatomic) NSMutableDictionary *lightDic;
@property (strong, nonatomic) NSMutableDictionary *hsbDic;
@property (strong, nonatomic) UIView *lightGroupView;

-(void) setData:(AIFeatureNode*)tNode indexes:(NSArray*)indexes lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top;
-(void) setData:(AIFeatureNode*)tNode gvModels:(NSArray*)gvModels lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top;
-(void) setData_GVIndex:(NSDictionary*)gvIndex canvasRect:(CGRect)canvasRect ds:(NSString*)ds lab:(NSString*)lab;

@end
