//
//  GTItem.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------GT识别模型--------------------
 */
@interface GTItem : NSObject

+(id) new:(NSInteger)assIndex stModel:(AIFeatureJvBuModel*)stModel curST_AssGT:(CGRect)curST_AssGT itemMatchValue:(CGFloat)itemMatchValue itemMatchRatio:(CGFloat)itemMatchRatio;
@property (assign, nonatomic) NSInteger assIndex;
@property (strong, nonatomic) AIFeatureJvBuModel *stModel; // 对应的stModel
@property (assign, nonatomic) CGRect curST_AssGT;
-(CGRect) curST_ProtoGT;

-(CGFloat) wRate;
-(CGFloat) hRate;
-(CGFloat) xDelta;
-(CGFloat) yDelta;

@property (assign, nonatomic) CGFloat itemMatchValue;
@property (assign, nonatomic) CGFloat itemMatchDegree;
-(void) run4ItemMatchDegree:(GTModel*)baseGTModel;

@property (assign, nonatomic) CGFloat itemMatchRatio; //item匹配率（就是ST的匹配率）。

@end
