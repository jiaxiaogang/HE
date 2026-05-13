//
//  AIScore.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/1/5.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "AIScore.h"

@implementation AIScore

//MARK:===============================================================
//MARK:                     < 下标不急评价 >
//MARK:===============================================================

/**
 *  MARK:--------------------下标不急(弄巧成拙)评价--------------------
 *  @desc
 *          1. 说明: R子任务来的及评价 (后续考虑支持rootR任务) (参考22194 & 22195 & 22198);
 *          2. 决策时序AB 在 任务未发生部分D 中找mIsC (找到AB中index,index及之后需要等待静默成功,之前的可实行行为化) (参考22198);
 *          3. 必要性: ARSTime来的及评价是针对某帧的,而决策中,外界条件会变化,所以必须每帧都单独评价;
 *  @param dsFoModel : 当前正在推进的解决方案,其中actionIndex为当前帧;
 *  @param demand : 当前任务;
 *  @result (参考22194示图 & 22198) (默认为ture);
 *      true    : 提前可预备部分:返回true以进行_hav实时行为化 (比如:在穿越森林前,在遇到老虎前,我们先带枪);
 *      false   : 来的及返回false则ActYes等待静默成功,并继续推进主任务 (比如:枪已取到,现在先穿越森林,等老虎出现时,再吓跑它);
 *  @version
 *      2022.05.19: 废弃 (参考26051);
 */
//+(BOOL) ARS_Time:(TOFoModel*)dsFoModel demand:(ReasonDemandModel*)demand{
//    //1. 找下标;
//    __block NSInteger dsIndex = -1;
//    __block NSInteger demandIndex = -1;
//    [self score4ARSTime:dsFoModel demand:demand finishBlock:^(NSInteger _dsIndex, NSInteger _demandIndex) {
//        dsIndex = _dsIndex;
//        demandIndex = _demandIndex;
//    }];
//
//    //2. 下标有效时,返回ARSTime结果 (参考22194示图 & 22198);
//    if (demandIndex != -1) {
//        //3a. ds下标后的dsFo部分,需要静默等待 (会导致弄巧成拙,评价为否->ActYes);
//        //3b. ds下标前的dsFo部分,可直接行为化 (当dsAlg在demand预测中已发生时,评价为是->立马行为化修正);
//        return dsFoModel.actionIndex < dsIndex;
//    }
//    return true;
//}

/**
 *  MARK:--------------------来的及评分--------------------
 *  @desc 对dsFo的从前到后所有元素,在demand的预测中未发生的部分,找下标返回 (参考22198示图);
 *  @param finishBlock notnull : 根据dsFo的哪个下标,发现了在demand预测fo中的哪个下标,使用说明如下;
 */
//+(void) score4ARSTime:(TOFoModel*)dsFoModel demand:(ReasonDemandModel*)demand finishBlock:(void(^)(NSInteger _dsIndex,NSInteger _demandIndex))finishBlock{
//    //1. 数据检查;
//    if (!dsFoModel || !demand) return;
//    AIFoNodeBase *dsFo = [SMGUtils searchNode:dsFoModel.content_p];
//
//    //2. 找下标 (参考注释@desc);
//    for (NSInteger i = 0; i < dsFo.count; i++) {
//        AIKVPointer *dsAlg_p = ARR_INDEX(dsFo.content_ps, i);
//        AIFoNodeBase *demandMFo = [SMGUtils searchNode:demand.mModel.matchFo];
//        NSInteger demandIndex = [TOUtils indexOfConOrAbsItem:dsAlg_p atContent:demandMFo.content_ps layerDiff:2 startIndex:demand.mModel.cutIndex2 + 1 endIndex:NSUIntegerMax];
//
//        //3. 根据dsIndex发现demandIndex成功 (仅需发现一个下标即可);
//        if (demandIndex != -1) {
//            finishBlock(i,demandIndex);  //根据i发现了result
//            return;
//        }
//    }
//}

//MARK:===============================================================
//MARK:                     < 时间不急评价 >
//MARK:===============================================================

/**
 *  MARK:--------------------时间不急评价--------------------
 *  @desc 时间不急评价: 紧急情况 = 解决方案所需时间 > 父任务能给的时间 (参考:24057-方案3,24171-7);
 *  @param demand : 当前任务
 *  @version
 *      2022.01.19: 从action前置到rSolution中,因为三条全紧急,就完蛋了,放到action则不受此限制 (参考25106);
 *      2022.02.22: 将needTime取到mv改为仅取下帧,因为很多solution只需要一帧就改到正确的道路上了 (参考25113-方案2);
 *      2022.05.28: 判断目标向后一帧 (参考26132-方案2);
 *      2022.05.31: 兼容支持H任务 (参考26161-6);
 *      2022.05.31: 中段为0条时,评价直接通过 (参考26161-7);
 *      2024.09.26: 兼容R子任务 (参考33075-TODO4);
 *  @result 返回是否时间不急 (默认为true);
 *      true    : 不急,时间够用,这方案可继续act;
 *      false   : 紧急,这方案来不及执行,直接ActNo掉;
 */
+(BOOL) FRS_Time:(DemandModel*)demand solutionModel:(TOFoModel*)solutionModel{
    //0. 先关掉,现在还没必要用到这些,等以后需要时再打开,顺利迭代下 (迭代思路参考33075-TODO4&重点1&2&结果);
    BOOL isSwitch = false;
    if (!isSwitch) return true;
    
    //1. 中段为0条时,直接返回true,评价通过;
    if (solutionModel.cansetActIndex >= solutionModel.cansetTargetIndex) {
        return true;
    }

    //2. 最近的R任务 (R任务时取自身,H任务时取最近的baseRDemand);
    ReasonDemandModel *nearRDemand = [SMGUtils filterSingleFromArr:[TOUtils getBaseOutModels_AllDeep:demand] checkValid:^BOOL(id item) {
        return ISOK(item, ReasonDemandModel.class);
    }];
    if (!nearRDemand) return false;
    
    //3. 取解决方案所需时间;
    AIFoNodeBase *fCanset = [SMGUtils searchNode:solutionModel.fCanset];
    double needTime = [TOUtils getSumDeltaTime:fCanset startIndex:solutionModel.cansetCutIndex endIndex:solutionModel.cansetActIndex];
    
    //4. 取父任务能给的时间;
    AIMatchFoModel *firstPFo = ARR_INDEX(nearRDemand.validPFos, 0);
    AIFoNodeBase *pFo = [SMGUtils searchNode:firstPFo.matchFo];
    double giveTime = [TOUtils getSumDeltaTime2Mv:pFo cutIndex:firstPFo.cutIndex];
    
    //5. 判断是否时间不急;
    BOOL timeIsEnough = needTime <= giveTime;
    if (Log4Score && timeIsEnough) NSLog(@"> 时间不急%d = 方案T:%.2f <= 任务T:%.2f",timeIsEnough,needTime,giveTime);
    return timeIsEnough;
}

//MARK:===============================================================
//MARK:                     < MPS评分 >
//MARK:===============================================================
/**
 *  MARK:--------------------MPS评分--------------------
 *  @result 负价值返回负分,正价值返回正分;
 */
+(CGFloat) score4MV:(AIKVPointer*)cmvNode_p ratio:(CGFloat)ratio{
    AICMVNodeBase *cmvNode = [SMGUtils searchNode:cmvNode_p];
    if (ISOK(cmvNode, AICMVNodeBase.class)) {
        return [AIScore score4MV:cmvNode.pointer.algsType urgentTo_p:cmvNode.urgentTo_p delta_p:cmvNode.delta_p ratio:ratio];
    }
    return 0;
}
+(CGFloat) score4MV:(NSString*)algsType urgentTo_p:(AIKVPointer*)urgentTo_p delta_p:(AIKVPointer*)delta_p ratio:(CGFloat)ratio{
    //1. 检查absCmvNode是否顺心
    NSInteger delta = [NUMTOOK([AINetIndex getData:delta_p]) integerValue];
    NSInteger urgentTo = [NUMTOOK([AINetIndex getData:urgentTo_p]) integerValue];
    return [self score4MV:algsType urgentTo:urgentTo delta:delta ratio:ratio];
}
+(CGFloat) score4MV:(NSString*)algsType urgentTo:(NSInteger)urgentTo delta:(NSInteger)delta ratio:(CGFloat)ratio{
    //1. 检查absCmvNode是否顺心
    BOOL havDemand = [ThinkingUtils havDemand:algsType delta:delta];
    
    //2. 根据检查到的数据取到score;
    ratio = MIN(1,MAX(ratio,0));
    if (havDemand) {
        return  -urgentTo * ratio;
    }else{
        return urgentTo * ratio;
    }
}

/**
 *  MARK:--------------------对预测价值时序评分V2--------------------
 *  @desc score = spScore * mvScore (即将原匹配度,改为由spScore来替代);
 *  @result 1. 返回评分越低说明越不好,越高越好;
 *          2. 返回正值为正mv,返回负值为负mv;
 */
+(CGFloat) score4MV_v2:(AIMatchFoModel*)inModel{
    AIFoNodeBase *mFo = [SMGUtils searchNode:inModel.matchFo];
    BOOL isBadMv = [ThinkingUtils havDemand:mFo.cmvNode_p];
    CGFloat spScore = [TOUtils getSPScore:mFo startSPIndex:inModel.cutIndex + 1 endSPIndex:mFo.count];
    CGFloat ratio = isBadMv ? (1 - spScore) : spScore;
    return [AIScore score4MV:mFo.cmvNode_p ratio:ratio];//价值迫切度 * 匹配度
}

/**
 *  MARK:--------------------对预测价值时序评分v2 from cache--------------------
 *  @version
 *      2022.08.19: 性能优化缓存版 (参考27065);
 */
+(CGFloat) score4MV_v2FromCache:(AIMatchFoModel*)inModel {
    if (inModel.scoreCache == defaultScore) {
        inModel.scoreCache = [self score4MV_v2:inModel];
    }
    [AITest test12:inModel.scoreCache];
    return inModel.scoreCache;
}

/**
 *  MARK:--------------------对Demand综合评分--------------------
 *  @param demand : 仅支持PR两种类型
 *  @version
 *      2022.05.19: demand的评分,继承firstPFo的评分 (参考26042-TODO4);
 *      2022.05.21: demand的评分,改为综合sumPFoScore评分 (参考26076);
 *      2022.06.08: demand的评分,改为综合sumMvScore / pFos.count (参考2619j-TODO6);
 */
+(CGFloat) score4Demand:(DemandModel*)demand{
    if (ISOK(demand, ReasonDemandModel.class) ) {
        ReasonDemandModel *rDemand = (ReasonDemandModel*)demand;
        return [self score4PFos:rDemand.validPFos];
    }else if (ISOK(demand, PerceptDemandModel.class) ) {
        PerceptDemandModel *pDemand = (PerceptDemandModel*)demand;
        return [AIScore score4MV:pDemand.algsType urgentTo:pDemand.urgentTo delta:pDemand.delta ratio:1.0f];
    }
    return 0;
}

/**
 *  MARK:--------------------在决策流程,对Demand综合评分--------------------
 *  @version
 *      2024.06.30: 既然激活了,那么在决策流程中,即使失效的pFos也计入任务评分中,因为它虽然失效了,但只要此任务还在执行,那么它的重要性评分就依旧 (如果只计有效,如果全失效了,任务会返回0分);
 */
+(CGFloat) score4Demand_Out:(DemandModel*)demand {
    if (ISOK(demand, ReasonDemandModel.class) ) {
        ReasonDemandModel *rDemand = (ReasonDemandModel*)demand;
        return [self score4PFos:rDemand.pFos];
    }else if (ISOK(demand, PerceptDemandModel.class) ) {
        PerceptDemandModel *pDemand = (PerceptDemandModel*)demand;
        return [AIScore score4MV:pDemand.algsType urgentTo:pDemand.urgentTo delta:pDemand.delta ratio:1.0f];
    }
    return 0;
}

//返回demand的考虑到进度分的得分 (越在这个任务上推进的多,任务分越严重);
+(CGFloat) progressScore4Demand_Out:(DemandModel*)demand {
    //1. 计算任务分;
    CGFloat demandScore = [AIScore score4Demand_Out:demand];
    
    //2. 取出最大进度值;
    CGFloat maxProgress = 0;
    for (TOFoModel *actionFo in demand.bestCansets) {
        //2024.08.25: 即使被传染,或者没在执行中,也计算进度分 (参考33019-方案2-TODO1);
        //BOOL statusOK = actionFo.status == TOModelStatus_Runing || actionFo.status == TOModelStatus_ActYes;
        //BOOL infectedOK = !actionFo.isInfected;
        //if (!statusOK || !infectedOK) continue;
        //if (Log4Score) NSLog(@"Demand:F%ld Canset:F%ld 状态:%@ 传染:%d (%ld/%ld=%.2f)",Demand2Pit(demand).pointerId,actionFo.cansetFrom.pointerId,TOStatus2Str(actionFo.status),actionFo.isInfected,actionFo.cansetActIndex,actionFo.cansetTargetIndex + 1,(float)(actionFo.cansetCutIndex + 1) / (actionFo.cansetTargetIndex + 1));
        
        CGFloat progress = (float)(actionFo.cansetCutIndex + 1) / (actionFo.cansetTargetIndex + 1);//参考31052-公式1
        //NSLog(@"cansetFo: F%ld %@ (%ld/%ld)",actionFo.content_p.pointerId,TOStatus2Str(actionFo.status),actionFo.actionIndex+1,actionFo.targetIndex);
        //NSLog(@"进度:%.2f 热度:%.2f 进度分:%.2f",progress,hot,progressScore);
        //NSLog(@"检查下actionFo状态是否有资格被评进度分: %@ %@ %@",TOStatus2Str(actionFo.status),CansetStatus2Str(actionFo.cansetStatus),actionFo.isInfected ? @"传染" : @"唤醒");
        maxProgress = MAX(maxProgress, progress);
    }
    
    //3. 计算最大的进度分 (参考31052-todo1);
    CGFloat hot = 1 - [MathUtils getCooledValue_28:maxProgress];//参考31052-公式2
    CGFloat progressScore = demandScore * hot;//参考31052-公式3
    
    //3. 求出总分 (参考31052-todo2);
    CGFloat totalScore = progressScore + demandScore;
    if (Log4Score) NSLog(@"任务分:%.2f + 最终进度分:%.2f = 总分:%.2f \t 任务:%@",demandScore,progressScore,totalScore,Pit2FStr(Demand2Pit(demand)));
    return totalScore;
}

/**
 *  MARK:--------------------求pFos的平均价值分--------------------
 */
+(CGFloat) score4PFos:(NSArray*)pFos {
    pFos = ARRTOOK(pFos);
    CGFloat sumScore = 0;
    for (AIMatchFoModel *pFo in pFos) {
        sumScore += [AIScore score4MV_v2FromCache:pFo];
    }
    return pFos.count > 0 ? sumScore / pFos.count : 0;
}

//MARK:===============================================================
//MARK:                     < MPS评价 >
//MARK:===============================================================

//同区且同向
+(BOOL) sameIdenSameScore:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p{
    if ([self sameIdentifierOfMV1:mv1_p mv2:mv2_p]) {
        CGFloat mScore = [AIScore score4MV:mv1_p ratio:1.0f];
        CGFloat sScore = [AIScore score4MV:mv2_p ratio:1.0f];
        return [self sameDire:mScore v2:sScore];
    }
    return false;
}

//同区不同向
+(BOOL) sameIdenNoSameScore:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p{
    CGFloat ratio = 1.0f;
    return [self sameIdentifierOfMV1:mv1_p mv2:mv2_p] && ![self sameDire:Mvp2Score(mv1_p, ratio) v2:Mvp2Score(mv2_p, ratio)];
}

//同区且同向
+(BOOL) sameIdenSameDelta:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p{
    return [self sameIdentifierOfMV1:mv1_p mv2:mv2_p] && [self sameDire:Mvp2Delta(mv1_p) v2:Mvp2Delta(mv2_p)];
    return false;
}

//同区且反向
+(BOOL) sameIdenDiffDelta:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p{
    return [self sameIdentifierOfMV1:mv1_p mv2:mv2_p] && [self diffDire:Mvp2Delta(mv1_p) v2:Mvp2Delta(mv2_p)];
}

//MARK:===============================================================
//MARK:                     < 单纯同区同向判断 >
//MARK:===============================================================
//同区
+(BOOL) sameIdentifierOfMV1:(AIKVPointer*)mv1_p mv2:(AIKVPointer*)mv2_p{
    return mv1_p && mv2_p && [mv1_p.identifier isEqualToString:mv2_p.identifier];
}
//同向
+(BOOL) sameDire:(NSInteger)v1 v2:(NSInteger)v2{
    return (v1 > 0 && v2 > 0) || (v1 < 0 && v2 < 0);
}
//反向
+(BOOL) diffDire:(NSInteger)v1 v2:(NSInteger)v2{
    return (v1 > 0 && v2 < 0) || (v1 < 0 && v2 > 0);
}

/**
 *  MARK:--------------------归一化得分 转为 末尾淘汰得分--------------------
 *  @param from0_1Score : 归一化得分
 *  @desc 前80%，全计为满分：仅末尾淘汰，不然稳定性作用力太大，训练再久也只识别最旧的一些强者恒强的结果，影响到准确性，喧宾夺主（参考38012-BUG1-TODO）。
 *  @desc 末尾20%，也正常计算它的小竞争分，参与到最终综合竞争中，自然淘汰（参考38012-BUG1-TODO）。
 *  @result 末尾淘汰得分
 */
+(CGFloat) tailScore:(CGFloat)from0_1Score {
    return MIN(1, from0_1Score + 0.8f);
}

@end
