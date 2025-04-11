//
//  AIFeatureStep2Item.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:-------------------- 记录每一条abs在当前 assT/protoT 下的rect--------------------
 */
@interface AIFeatureStep2Item_Rect : NSObject

+(AIFeatureStep2Item_Rect*) new:(NSInteger)absPId absAtConRect:(CGRect)absAtConRect;

//absT.pId
@property (assign, nonatomic) NSInteger absPId;

//conPort.rect（表示absT在assT/protoT中的位置）
//输入时=absAtConRect
//缩放对齐后=(x/pinJunScale, y/pinJunScale, w/pinJunScale, h/pinJunScale)
//Delta对齐后=(x - deltaX, y - deltaY, w, h)
@property (assign, nonatomic) CGRect rect;

/**
 *  MARK:--------------------三个要素与proto的相近度（参考34136-TODO4）--------------------
 */
@property (assign, nonatomic) CGFloat scaleMatchValue;
@property (assign, nonatomic) CGFloat deltaXMatchValue;
@property (assign, nonatomic) CGFloat deltaYMatchValue;

/**
 *  MARK:--------------------该assT与protoT的这一块局部特征的“位置符合度” = 三个要素乘积（参考34136-TODO5）--------------------
 */
@property (assign, nonatomic) CGFloat itemMatchDegree;

@end
