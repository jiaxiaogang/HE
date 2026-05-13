//
//  AIScore.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/1/5.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

//MARK:===============================================================
//MARK:                     < 评价器 >
//MARK: 从最初版本开始,已经支持评价器,只是一直未整理,此类将各评价器整理进来,分以下几种 (参考n22p1):
//MARK: 1. 感性评价 (反思)
//MARK:     > FPS & MPS
//MARK: 2. 理性评价 (反省)
//MARK:     > VRS & ARS & FRS
//MARK:===============================================================
@class AIShortMatchModel,TOFoModel,ReasonDemandModel,DemandModel,AIMatchFoModel;
@interface AIScore : NSObject

//MARK:===============================================================
//MARK:                     < 下标不急评价 >
//MARK:===============================================================
//+(BOOL) ARS_Time:(TOFoModel*)dsFoModel demand:(ReasonDemandModel*)demand;
//+(void) score4ARSTime:(TOFoModel*)dsFoModel demand:(ReasonDemandModel*)demand finishBlock:(void(^)(NSInteger _dsIndex,NSInteger _demandIndex))finishBlock;


//MARK:===============================================================
//MARK:                     < 时间不急评价 >
//MARK:===============================================================
+(BOOL) FRS_Time:(DemandModel*)demand solutionModel:(TOFoModel*)solutionModel;

/**
 *  MARK:--------------------指定ratio的评价重载--------------------
 *  @desc 旧有说明: 获取到cmvNode的评价力;
 *  @desc 对MC的评价时:
 *      1. 理性评价: 由MC匹配方法中,进行类比ms&cs&mcs决定;
 *      2. 感性评价: 由此处进行计算得出;
 *          如: 判断变脏后,不能吃; 参考17202表中示图 (被吃mv为负 (理性是间接的感性) (导致负价值))
 *          如: 判断cpu损坏,会浪费钱;
 *          如: 带皮坚果,不能吃, (根本,不能吃,比如坚果皮 (抽象为:吃皮,导致负mv))
 *
 *  @desc 对ExpOut评价时:
 *      1. 以默认ratio=0.2,进行评价;
 */
+(CGFloat) score4MV:(AIKVPointer*)cmvNode_p ratio:(CGFloat)ratio;
+(CGFloat) score4MV:(NSString*)algsType urgentTo_p:(AIKVPointer*)urgentTo_p delta_p:(AIKVPointer*)delta_p ratio:(CGFloat)ratio;
+(CGFloat) score4MV:(NSString*)algsType urgentTo:(NSInteger)urgentTo delta:(NSInteger)delta ratio:(CGFloat)ratio;
+(CGFloat) score4MV_v2:(AIMatchFoModel*)inModel;
+(CGFloat) score4MV_v2FromCache:(AIMatchFoModel*)inModel;

/**
 *  MARK:--------------------对Demand综合评分--------------------
 *  @param demand : 仅支持PR两种类型
 */
+(CGFloat) score4Demand:(DemandModel*)demand;
+(CGFloat) score4Demand_Out:(DemandModel*)demand;

//返回demand的考虑到进度分的得分 (越在这个任务上推进的多,任务分越严重);
+(CGFloat) progressScore4Demand_Out:(DemandModel*)demand;

/**
 *  MARK:--------------------求pFos的平均价值分--------------------
 */
+(CGFloat) score4PFos:(NSArray*)pFos;

/**
 *  MARK:--------------------获取mv1和mv2是否同向或反向--------------------
 *  @result 默认返回false;
 */
//同区且同向
+(BOOL) sameIdenSameScore:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p;
//同区不同向
+(BOOL) sameIdenNoSameScore:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p;
//同区且同向
+(BOOL) sameIdenSameDelta:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p;
//同区且反向
+(BOOL) sameIdenDiffDelta:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p;

/**
 *  MARK:--------------------归一化得分 转为 末尾淘汰得分--------------------
 *  @param from0_1Score : 归一化得分
 *  @param weight : 权重0-1（输入0.3时，result为0.7-1）。
 *  @desc 前80%，全计为满分：仅末尾淘汰，不然稳定性作用力太大，训练再久也只识别最旧的一些强者恒强的结果，影响到准确性，喧宾夺主（参考38012-BUG1-TODO）。
 *  @desc 末尾20%，也正常计算它的小竞争分，参与到最终综合竞争中，自然淘汰（参考38012-BUG1-TODO）。
 *  @result 权重削弱之后的单项竞争因子分值
 */
+(CGFloat) scoreWeight:(CGFloat)from0_1Score weight:(CGFloat)weight;

@end
