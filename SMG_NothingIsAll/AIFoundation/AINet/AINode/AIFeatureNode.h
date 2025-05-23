//
//  AIFeatureNode.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/18.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AINodeBase.h"

/**
 *  MARK:--------------------特征节点--------------------
 */
@interface AIFeatureNode : AINodeBase

@property (strong, nonatomic) NSArray *rects;

//根据rect找下标，找不到时返-1。
-(NSInteger) indexOfRect:(CGRect)rect;

//MARK:===============================================================
//MARK:             < 特征位置符合度（类似匹配度，持久化）>
//MARK:===============================================================
@property (strong, nonatomic) NSMutableDictionary *absMatchDegreeDic;
@property (strong, nonatomic) NSMutableDictionary *conMatchDegreeDic;
-(void) updateMatchDegree:(AIFeatureNode*)absNode matchDegree:(CGFloat)matchDegree;
-(CGFloat) getConMatchDegree:(AIKVPointer*)con_p;
-(CGFloat) getAbsMatchDegree:(AIKVPointer*)abs_p;

//MARK:===============================================================
//MARK:       < degree组（不进行持久化，仅用于step1识别结果的类比中） >
//MARK:===============================================================
@property (strong, nonatomic) NSMutableDictionary *degreeDDic; // <K=assT.pId, V=<K=assIndex, V=与之映射的位置符合度matchDegree>>
-(void) updateDegreeDic:(NSInteger)assPId degreeDic:(NSDictionary*)degreeDic;
-(NSDictionary*) getDegreeDic:(NSInteger)assPId;

//MARK:===============================================================
//MARK:       < zenTiModel（不进行持久化，仅用于ZenTi识别结果的类比中 >
//MARK:===============================================================
@property (strong, nonatomic) MapModel *jvBuModel;//v1=indexDic v2=protoT
@property (strong, nonatomic) AIFeatureJvBuModel *jvBuModelV2;
@property (strong, nonatomic) AIFeatureZenTiModel *zenTiModel;

-(NSArray*) convert2GVModels:(NSArray*)indexes;

@end
