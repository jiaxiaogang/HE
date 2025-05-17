//
//  AIFeatureZenTiModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/11.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------特征识别向具象（从局部到整体）的model--------------------
 *  @desc 说明：
 *          1、每个conPort.target(assT/protoT)对应一到多个absT。
 *          2、把每个assT / protoT 计为一组（本模型表示其中一组）。
 *
 */
@interface AIFeatureZenTiModel : NSObject

+(AIFeatureZenTiModel*) new:(AIKVPointer*)assT;

//每个assT/protoT 各有一到多个absT（表示每个assT/protoT所包含的所有absT）。
@property (strong, nonatomic) NSMutableArray *rectItems;

//记录assT/protoT的地址。
@property (strong, nonatomic) AIKVPointer *assT;

//记录当时识别时的protoT（类比时要用下）。
@property (strong, nonatomic) AIKVPointer *protoT;

//MARK:===============================================================
//MARK:                     < 收集数据组 >
//MARK:===============================================================
-(void) updateRectItem:(AIKVPointer*)fromItemT itemAtAssRect:(CGRect)itemAtAssRect itemToAssStrong:(NSInteger)itemToAssStrong protoGTIndex:(NSInteger)protoGTIndex;
-(CGRect) getRectItem:(AIKVPointer*)fromItemT;

//MARK:===============================================================
//MARK:                     < 位置符合度竞争防重 >
//MARK:===============================================================

/**
 *  MARK:--------------------组特征rectItems重复问题：位置符合度竞争防重（参考35034）--------------------
 */
-(void) run4BestRemoveRepeat:(AIFeatureZenTiModel*)protoModel;

//MARK:===============================================================
//MARK:                     < 计算位置符合度组 >
//MARK:===============================================================
-(void) run4MatchDegree:(AIFeatureZenTiModel*)protoModel;

/**
 *  MARK:--------------------assTModel的位置匹配度 = 所有absTItem的位置符合度的平均值（参考34136-TODO6）--------------------
 */
@property (assign, nonatomic) CGFloat modelMatchDegree;

//MARK:===============================================================
//MARK:                     < 计算所有absT与assT的综合匹配度 >
//MARK:===============================================================
-(void) run4MatchValue:(AIKVPointer*)protoT;
-(void) run4MatchValueV2:(AIKVPointer*)protoT;
@property (assign, nonatomic) CGFloat modelMatchValue;

//MARK:===============================================================
//MARK:                     < 计算assT的显著度 >
//MARK:===============================================================
@property (assign, nonatomic) CGFloat modelMatchConStrongRatio;  //显著度：被抽象强度程度（越高越好，因为它是更显著的特征）(参考34175-公式3）。

@end
