//
//  DemandManager.m
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/8/4.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "DemandManager.h"

@interface DemandManager()

/**
 *  MARK:--------------------实时序列--------------------
 *  元素 : <DemandModel.class>
 *  思维因子_当前cmv序列(注:所有cmv只与cacheImv中作匹配)(正序,order越大,排越前)
 */
@property (strong,nonatomic) AsyncMutableArray *loopCache;

@end

@implementation DemandManager

-(id) init{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

-(void) initData{
    self.loopCache = [[AsyncMutableArray alloc] init];
}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================

/**
 *  MARK:--------------------生成P任务--------------------
 *  1. 添加新的cmv到cache,并且自动撤消掉相对较弱的同类同向mv;
 *  2. 在assData等(内心活动,不抵消cmvCache中旧任务)
 *  3. 在dataIn时,抵消旧任务,并生成新任务;
 *  @version
 *      2020.08.24: 在inputMv时,当前demand进行抵消时,其状态设置为Finish;
 *      2021.09.04: 当R任务的 (R部分发生完毕 & P部分也发生完毕 & R任务又没在ActYes/OutBack状态),则销毁这一任务 (参考23224-方案-代码2);
 *      2022.05.18: 废弃抵消功能 (反馈功能早已由TCFeedback来做,不需要这里弄);
 *      2022.09.20: 加PDemand开关功能,先继续开着,其实现在P任务已经不怎么用了,逐步关掉;
 *  @todo
 *      2022.xx.xx: 废弃P模式 (参考xx);
 */
-(void) updateCMVCache_PMV:(NSString*)algsType urgentTo:(NSInteger)urgentTo delta:(NSInteger)delta{
    //1. 数据检查
    if (delta == 0 || !Switch4PDemand) {
        return;
    }
    
    //2. 去重_同向撤弱,反向抵消;
    BOOL canNeed = true;
    NSInteger limit = self.loopCache.count;
    for (NSInteger i = 0; i < limit; i++) {
        DemandModel *checkItem = [self.loopCache objectAtIndex:i];
        if ([STRTOOK(algsType) isEqualToString:checkItem.algsType]) {
            if (ISOK(checkItem, PerceptDemandModel.class)) {
                if ((delta > 0 == checkItem.delta > 0)) {
                    //1) 同向较弱的撤消
                    if (labs(urgentTo) > labs(checkItem.urgentTo)) {
                        [self.loopCache removeObjectAtIndex:i];
                        NSLog(@"demandManager >> PMV移除P任务: 同向较弱撤消 %@,%ld",checkItem.algsType,(long)checkItem.delta);
                        limit--;
                        i--;
                    }else{
                        canNeed = false;
                    }
                }else{
                    //2) 反向抵消
                    [self.loopCache removeObjectAtIndex:i];
                    checkItem.status = TOModelStatus_Finish;
                    NSLog(@"demandManager >> PMV移除P任务: 反向抵消 %@,%ld",checkItem.algsType,(long)checkItem.delta);
                    limit--;
                    i--;
                }
            }
        }
    }
    
    //3. 有需求时且可加入时_加入新的
    //TODO:>>>>判断需求;(如饿,主动取当前状态,是否饿)
    MVDirection direction = [ThinkingUtils getDemandDirection:algsType delta:delta];
    if (canNeed && (direction != MVDirection_None)) {
        PerceptDemandModel *newItem = [[PerceptDemandModel alloc] init];
        newItem.algsType = algsType;
        newItem.delta = delta;
        newItem.urgentTo = urgentTo;
        [self.loopCache addObject:newItem];
        
        //2. 新需求时,加上活跃度;
        [theTC updateEnergyDelta:urgentTo];
        NSLog(@"demandManager-PMV >> 新需求 %lu",(unsigned long)self.loopCache.count);
    }
}

/**
 *  MARK:--------------------生成R任务--------------------
 *  @desc RMV输入更新任务管理器 (理性思维预测mv加入)
 *  @todo
 *      2021.01.21: 抵销: 当汽车冲过来,突然又转向了,任务消除 (理性抵消 (仅能通过matchFo已发生的部分进行比对)) (参考22074-BUG2) T;
 *      2021.01.21: 抵销: 当另一辆更大的车又冲过来,两条matchFo都导致疼不能抵消 (理性抵消不以mv.algsType为准) (参考22074-BUG2) T;
 *      2021.01.21: 抵销&增强: 进度更新后,根据matchFo进行"理性抵消" 或者 "理性增强(进度更新)" 判断 (参考22074-BUG2) T;
 *  @version
 *      2021.01.25: RMV仅对ReasonDemandModel进行抵消防重 (否则会导致R-与P-需求冲突);
 *      2021.01.27: RMV仅对matchFoModel进行抵消防重 (否则会导致inModel预测处理不充分) (参考22074-BUG2);
 *      2021.02.05: 新增任务时,仅将"与旧有同区最大迫切度的差值"累增至活跃度 (参考22116);
 *      2021.03.01: 修复RMV一直在行为输出和被识别间重复死循环BUG (参考22142);
 *      2021.03.28: 此处algsType由urgentTo.at改成cmv.at,从mvNodeManager看这俩一致,如果出现bug再说;
 *      2021.07.14: 循环matchPFos时,采用反序,因为优先级和任务池优先级上弄反了 (参考23172);
 *      2021.11.11: 迭代RMV的生成机制,此代码其实啥也没改 (参考24107-1);
 *      2022.03.10: 为使鸟躲避及时停下,将迫切度再改回受评分迫切度等影响 (参考25142-改进);
 *      2022.05.02: 未形成新需求时,也更新energy (参考2523a-方案1);
 *      2022.05.18: 多pFos形成单个任务 (参考26042-TODO1);
 *      2022.05.18: 废弃抵消和防重功能,现在root各自工作,共用R和P反馈即可各自工作;
 *      2023.08.15: 传入protoFo,因为在pInput时和rInput时的protoFo是不同的,这个protoFo到决策时还要用 (参考30095代码段2);
 *      2023.12.20: 写同质新旧Root合并 (参考31024);
 *      2024.05.24: 废弃同质合并,因为有了传染机制后,此处不再需要,相反传染机制需要新旧任务都存在时,工作起来才更简单且顺利 (参考31178&31179);
 *  @result 将新增的root任务收集返回;
 */
-(NSArray*) updateCMVCache_RMV:(AIShortMatchModel*)inModel protoFo:(AIFoNodeBase*)protoFo{
    //1. 数据检查;
    NSMutableArray *newRootsResult = [[NSMutableArray alloc] init];
    if (!inModel || !protoFo || !Switch4RS) return newRootsResult;
    NSDictionary *fos4Demand = inModel.fos4Demand;
    
    //2. 防止刚解决过饥饿,又立马预测到了一个新的饥饿 (参考33031-BUG4);
    NSArray *validFosDemandKeys = [SMGUtils filterArr:fos4Demand.allKeys checkValid:^BOOL(NSString *atKey) {
        return ![SMGUtils filterSingleFromArr:self.loopCache.array checkValid:^BOOL(ReasonDemandModel *oldRoot) {
            return [oldRoot.algsType isEqualToString:atKey] && oldRoot.expired4PInput;//旧root有同质的且已经解决掉,则直接不构建为新root;
        }];
    }];
    
    //2. 多时序识别预测分别进行处理;
    for (NSString *atKey in validFosDemandKeys) {
        
        //3. 数据准备
        NSMutableArray *pFosValue = [fos4Demand objectForKey:atKey];
        CGFloat score = [AIScore score4PFos:pFosValue];
        
        //5. 取迫切度评分: 判断matchingFo.mv有值才加入demandManager,同台竞争,执行顺应mv;
        if (score < 0) {
            NSLog(@"RMV新需求: %@ (第%ld条 评分:%@)",ClassName2Str(atKey),self.loopCache.count+1,Double2Str_NDZ(score));
            for (AIMatchFoModel *pFo in pFosValue) {
                AIFoNodeBase *matchFo = [SMGUtils searchNode:pFo.matchFo];
                if (Log4NewDemand) NSLog(@"\t pFo:%@->{%.2f} SP:%@ indexDic:%@",Pit2FStr(pFo.matchFo),[AIScore score4MV_v2FromCache:pFo],CLEANSTR(matchFo.spDic),CLEANSTR(pFo.indexDic2));
            }
            
            //6. 当新旧Root的pFos有交集时,即为同质ROOT: 将oldRoot.pFos合并到newRoot中 (参考31024-todo1);
            //2024.05.24: 关掉同质合并: 因为在alg和mv支持传染后,此处同质合并不再必要,合并后旧的删除掉,反而导致旧任务下的已传染的被删,新任务初始不到传染状态了;
            //for (ReasonDemandModel *oldRRoot in self.loopCache.array) {
            //    NSInteger oldIndex = [self.loopCache indexOfObject:oldRRoot];
            //    7. 判断新旧Root有交集 (参考31024-todo1);
            //    2024.05.13: 取出新的,只占一部分,则说明有旧的交集 (简化下算法);
            //    NSArray *samePFos = [SMGUtils filterArr:pFosValue arrB:oldRRoot.pFos convertBlock:^id(AIMatchFoModel *item) {return item.matchFo;}];
            //    NSArray *newPFosValue = [SMGUtils removeArr:oldRRoot.pFos parentArr:pFosValue convertBlock:^id(AIMatchFoModel *item) { return item.matchFo; }];
            //    if (newPFosValue.count < pFosValue.count) {
            //        NSLog(@"发现同质Root: (交集数:%ld) 旧位置:%ld/%ld 旧枝叶数:%ld pFos数:(旧%ld + 新%ld = %ld)",pFosValue.count - newPFosValue.count,oldIndex+1,self.loopCache.count,[TOUtils getSubOutModels_AllDeep:oldRRoot validStatus:nil].count,oldRRoot.pFos.count,newPFosValue.count,oldRRoot.pFos.count + newPFosValue.count);
            //
            //        //8. 新旧pFos全保留 (参考31024-todo1);
            //        pFosValue = [SMGUtils collectArrA:oldRRoot.pFos arrB:newPFosValue];
            //
            //        //9. 删掉旧的root (参考31024-todo2);
            //        [self.loopCache removeObject:oldRRoot];
            //        break;
            //    }
            //}
            
            //7. 有需求时,则加到需求序列中;
            ReasonDemandModel *newItem = [ReasonDemandModel newWithAlgsType:atKey pFos:pFosValue shortModel:inModel baseFo:nil protoFo:protoFo];
            [self.loopCache addObject:newItem];
            [newRootsResult addObject:newItem];
            
            //8. 设活跃度_将最大的任务x2取负值,为当前活跃度 (参考25142-改进);
            //2021.05.27: 为方便测试,所有imv都给20迫切度 (因为迫切度太低话,还没怎么思考就停了);
            //2022.03.10: 为使鸟躲避及时停下,将迫切度再改回受评分迫切度等影响;
            [theTC updateEnergyValue:-score * 20];
            
            //9. 新非连续R任务未输入负mv反馈时 (参考32118-TODO2);
            [self notInputForNotContinueAndBadMv:newItem];
        }else{
            [theTC updateEnergyValue:-score * 20];
            NSLog(@"当前,预测mv未形成需求:%@ 评分:%f",atKey,score);
        }
    }
    NSLog(@"生成NewRoot数:%ld from:%@",newRootsResult.count,Fo2FStr(protoFo));
    return newRootsResult;
}

/**
 *  MARK:--------------------重排序cmvCache--------------------
 *  1. 懒排序,什么时候assLoop,什么时候排序;
 *  @version
 *      2021.01.02: loopCache排序后未被接收,所以一直是未生效的BUG;
 *      2021.01.27: 支持第二级排序:initTime (参考22074-BUG2);
 *      2021.11.13: R任务排序根据 "迫切度*匹配度" 得出 (参考24107-2);
 *      2022.03.15: 将排序方式更新为用score4Demand (参考25142);
 *      2023.03.01: 修复排序反了的BUG: 评分越低越应该优先 (参考28136-修复);
 *      2024.01.04: 避免徒劳,已经付出努力的价值,计为进度分 (参考31052);
 *      2024.07.03: 改为调用score4Demand_Out避免它超时后,直接为0分,导致激活不了,影响Root的持续性 (参考32017);
 */
-(void) refreshCmvCacheSort {
    //1. 为了性能好,先算出排序任务分;
    NSArray *roots = [self.loopCache.array copy];
    
    //2. 先把每个root都求出含进度的总分,并用于排序 (参考31052-todo2);
    NSArray *mapArr = [SMGUtils convertArr:roots convertBlock:^id(ReasonDemandModel *obj) {
        CGFloat totalScore = -[AIScore progressScore4Demand_Out:obj];
        return [MapModel newWithV1:obj v2:@(totalScore) v3:@(obj.initTime)];
    }];
    
    //2. 排序 (第一因子得分,第二因子更新任务);
    NSArray *sort = [SMGUtils sortBig2Small:mapArr compareBlock1:^double(MapModel *obj) {
        return NUMTOOK(obj.v2).doubleValue;
    } compareBlock2:^double(MapModel *obj) {
        return NUMTOOK(obj.v3).doubleValue;
    }];
    
    //3. log
    for (MapModel *item in sort) {
        ReasonDemandModel *root = item.v1;
        if (Log4CanDecisionDemand) NSLog(@"root(%ld/%ld):%@ 评分:%.2f",[sort indexOfObject:item],sort.count,Pit2FStr(root.protoFo),NUMTOOK(item.v2).doubleValue);
    }
    sort = [SMGUtils convertArr:sort convertBlock:^id(MapModel *obj) {
        return obj.v1;
    }];
    
    [self.loopCache removeAllObjects];
    [self.loopCache addObjectsFromArray:sort];
}

/**
 *  MARK:--------------------获取任务 (决策部分: 可继续决策的部分)--------------------
 *  @version
 *      xxxx.xx.xx: (未完成 & 非等待反馈ActYes);
 *      2021.12.23: root非WithOut状态的 (参考24212-6);
 *      2021.12.23: 最优末枝处在actYes状态时,继续secondRoot (参考24212-7);
 *      2022.06.01: 末端actYes时,root不应期,因为actYes是向上传染不向下 (参考26185-TODO3);
 *      2022.09.24: 失效处理: 根任务失效时,不进行决策 (参考27123-问题2-todo2);
 *      2024.07.11: 把能决策的root全返回,而不是只返bestRoot一条,因为到TCPlan中可能还要一条条依次淘汰呢 (参考32071-分析2);
 *  @todo
 *      2024.01.31: 以后可以考虑把root的sort也改到TCScore中处理竞争 (但注意一点: 要把refreshCmvCacheSort()中的进度分等也集成过去);
 */
-(NSArray*) getCanDecisionDemandV3 {
    //1. 重排序 & 然后直接返回;
    [self refreshCmvCacheSort];
    return [self.loopCache.array copy];
}

/**
 *  MARK:--------------------获取任务 (全部返回: 用于反馈和可视化等)--------------------
 *  @desc 排序方式: 从大到小;
 */
-(NSArray*) getAllDemand{
    return self.loopCache.array;
}

/**
 *  MARK:--------------------移除某任务--------------------
 */
-(void) removeDemand:(DemandModel*)demand{
    if (ISOK(demand, ReasonDemandModel.class)) NSLog(@"demandManager >> 移除R任务:%@",((ReasonDemandModel*)demand).algsType);
    if (demand) [self.loopCache removeObject:demand];
}

-(void) clear{
    [self.loopCache removeAllObjects];
}

/**
 *  MARK:--------------------当输入持续mv的正向mv时 (参考32118-TODO1)--------------------
 *  @version
 *      2024.09.03: BUG-因为构建RCanset太慢,导致半天expired4PInput改不成true,导致它又跑了几轮TOQueue才停 (所以改成两个for,先把expired4PInput生效了再执行构建RCanset);
 */
-(void) inputForContinueAndGoodMv:(AICMVNodeBase*)mv {
    //1. 数据准备,取出标识同区的roots;
    NSArray *roots = [self.getAllDemand copy];
    roots = [SMGUtils filterArr:roots checkValid:^BOOL(ReasonDemandModel *root) {
        return [root.algsType isEqualToString:mv.pointer.algsType];
    }];
    
    //2024.12.05: 每次反馈同F只计一次: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5);
    NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];
    
    //3. 为这些roots构建RCanset;
    for (ReasonDemandModel *root in roots) {
        //2. 对于持续R任务: 比如饥饿R任务现在是连续饥饿状态,所以只能以饥饿状态的减弱为判断 (即正mv输入) (参考32118-TODO1);
        NSLog(@"%@因持续任务反馈了正mv (ROOT:F%ld) (pFos数:%ld) => 触发构建RCanset",FltLog4CreateRCanset(2),Demand2Pit(root).pointerId,root.pFos.count);
        for (AIMatchFoModel *pFo in root.pFos) {
            [pFo pushFrameFinish:@"持续任务反馈正mv" except4SP2F:except4SP2F];
        }
    }
}

/**
 *  MARK:--------------------未输入非持续mv的负向mv时 (参考32118-TODO2)--------------------
 */
-(void) notInputForNotContinueAndBadMv:(ReasonDemandModel*)root {
    //0. 数据检查 (本方法仅针对非持续任务);
    if ([ThinkingUtils isContinuousWithAT:root.algsType]) return;
    
    //1. 对于非持续R任务: 当它的所有pFo全没反馈负mv时,再为其触发New&AbsRCanset (即所有pFo没有负mv输入) (参考32118-TODO2);
    double maxDeltaTime = 0;
    for (AIMatchFoModel *pFo in root.pFos) {
        AIFoNodeBase *baseFo = [SMGUtils searchNode:pFo.matchFo];
        double deltaTime = [TOUtils getSumDeltaTime2Mv:baseFo cutIndex:pFo.cutIndex];
        maxDeltaTime = MAX(maxDeltaTime, deltaTime);
    }
    
    //2. 触发器;
    double triggerTime = maxDeltaTime * 1.2f;
    [AITime setTimeTrigger:triggerTime trigger:^{
        
        //3. 判断pFos是否阻止负mv成功了 (只要有一条失败了,就是全盘失败,阻止负mv没成功);
        BOOL success = true;
        for (AIMatchFoModel *pFo in root.pFos) {
            AIFoNodeBase *baseFo = [SMGUtils searchNode:pFo.matchFo];
            TIModelStatus status = [pFo getStatusForCutIndex:baseFo.count - 1];
            if (status == TIModelStatus_OutBackSameDelta) {
                success = false;
            }
        }
        
        //4. 如果阻止pFos负mv全成功: 则记录新的NewAbsRCanset;
        if (success) {
            
            //2024.12.05: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5TODO2);
            NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];
            NSLog(@"%@非持续任务未反馈负mv (pFos数:%ld)",FltLog4CreateRCanset(2),root.pFos.count);
            for (AIMatchFoModel *pFo in root.pFos) {
                [pFo pushFrameFinish:@"非持续任务未反馈负mv" except4SP2F:except4SP2F];
            }
        }
    }];
}

@end
