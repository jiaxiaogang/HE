//
//  AIFeatureZenTiItem.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:-------------------- 记录每一条abs在当前 assT/protoT 下的rect--------------------
 */
@interface AIFeatureZenTiItem_Rect : NSObject

+(AIFeatureZenTiItem_Rect*) new:(AIKVPointer*)absT itemAtAssRect:(CGRect)itemAtAssRect itemToAssStrong:(NSInteger)itemToAssStrong protoGTIndex:(NSInteger)protoGTIndex;

//absT.pId
@property (strong, nonatomic) AIKVPointer *fromItemT;

//一直存absAtConRect不变（表示当前itemAbsT在assT中的rect）。
@property (assign, nonatomic) CGRect itemAtAssRect;

//conPort.rect（表示absT在assT/protoT中的位置）
//输入时=absAtConRect
//缩放对齐后=(x/pinJunScale, y/pinJunScale, w/pinJunScale, h/pinJunScale)
//Delta对齐后=(x - deltaX, y - deltaY, w, h)
@property (assign, nonatomic) CGRect rect;

//每个item激活ass的强度。
@property (assign, nonatomic) NSInteger itemToAssStrong;
//每个self对应的是从哪个protoGTIndex对应过来的（用于类比抽象时，找到在protoGT中的rect）。
@property (assign, nonatomic) NSInteger protoGTIndex;

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
@property (assign, nonatomic) CGFloat itemMatchValue;

@end
