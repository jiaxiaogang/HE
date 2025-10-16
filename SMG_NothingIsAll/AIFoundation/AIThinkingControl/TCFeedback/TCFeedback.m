//
//  TCFeedback.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/2.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCFeedback.h"

@implementation TCFeedback

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 决策--------------------
 *  @title 外层输入对In短时记忆的影响处理 (参考22052-2);
 *  @param model : 新帧的model;
 *  @version
 *      2021.01.24: 多时序识别支持,使之更全面的支持每个matchFo的status更新 (参考22073-todo6);
 *      2021.10.17: 支持IRT的理性失效,场景更新时,状态设为OutBackReason (参考24059&24061-方案2);
 *      2021.12.25: 针对理性IRT反省的支持 (判断非末位为理性预测中) (参考25021-②);
 *      2022.03.05: BUG_将仅末位才反馈,改成非末位才反馈 (原来逻辑写反了);
 *      2022.05.02: 用matchAlgs+partAlgs替代mIsC (参考25234-8);
 *      2022.09.05: 将theTC.inModels改成roots.pFos (参考27096-方案2);
 *      2022.09.06: TC流程调整_直接调用TCDemand,将感理性反省预置都后置到Demand中 (参考27096-实践1);
 *      2022.09.18: 反馈匹配时,及时处理反省和任务推进帧 (参考27098-todo2&todo3);
 *      2023.02.09: 反馈不匹配时(只要没调用到匹配,即调用不匹配),也要记录protoAlg到pFo里的实际发生帧 (参考28063-todo1);
 *  @status
 *      xxxx.xx.xx: 非启动状态,因为时序识别中,未涵盖HNGL类型,所以并未对HNGL进行预测;
 *      2021.10.17: 启动,支持对IRT的理性失效 (参考24059&24061-方案2);
 */
+(void) feedbackTIR:(AIShortMatchModel*)model{
    //1. 取所有lastWait模型,并与新输入的概念做mIsC判断;
    [theTC updateOperCount:kFILENAME];
    Debug();
    
    //2024.04.21: 改成取matchAlgs_All判断反馈 (参考31134-交层AbsCanset很难反馈匹配的问题);
    IFTitleLog(@"feedbackTIR", @"\n输入ProtoA:%@ (识别matchAlgs数:%ld)",Alg2FStr(model.protoAlg),model.matchAlgs_Si.count);
    NSArray *recognitionAlgs = [SMGUtils convertArr:model.matchAlgs_All convertBlock:^id(AIMatchAlgModel *o) {
        return o.matchAlg;
    }];
    
    //2024.12.05: 每次反馈同F只计一次: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5);
    NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];

    //1. fbTIR对roots进行反馈判断 (参考27096-方案2);
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    for (ReasonDemandModel *root in roots) {
        
        //2. 仅支持ReasonDemandModel类型的反馈,因为PerceptDemandModel已经发生完毕,不需要反馈;
        if (!ISOK(root, ReasonDemandModel.class)) continue;
        
        //3. 对pFos做理性反馈;
        //2025.01.07: isExpired状态的，也要记录proto到realMaskFo中，避免少记导致TOR反馈成立时，更新RealCansetToIndexDic映射时取错realMaskFo的index导致映射错误 (参考：全局搜索RealCansetToIndexDic重复BUG)。
        for (AIMatchFoModel *waitModel in root.pFos) {
            //4. isExpired状态的,不处理 （但也要记录只要没调用到pushFrame,就调用此方法记录protoA）。
            if (waitModel.isExpired) {
                [waitModel feedbackOtherFrame:model.protoAlg.pointer];
                continue;
            }
            //4. 取出等待中的_非wait状态的,不处理;
            NSInteger status = [waitModel getStatusForCutIndex:waitModel.cutIndex];
            if (status != TIModelStatus_LastWait) {
                //调用1: 只要没调用到pushFrame,就调用此方法记录protoA;
                [waitModel feedbackOtherFrame:model.protoAlg.pointer];
                continue;
            }
            AIFoNodeBase *matchFo = [SMGUtils searchNode:waitModel.matchFo];
            if (Log4TIROPushM) NSLog(@"==> checkTIModel=MatchFo: %@",Fo2FStr(matchFo));
            
            //5. 末位跳过,不需要反馈 (参考25031-2 & 25134-方案2);
            NSInteger maxCutIndex = matchFo.count - 1;
            if (waitModel.cutIndex >= maxCutIndex){
                //调用2: 只要没调用到pushFrame,就调用此方法记录protoA;
                [waitModel feedbackOtherFrame:model.protoAlg.pointer];
                continue;
            }
            
            AIKVPointer *waitAlg_p = ARR_INDEX(matchFo.content_ps, waitModel.cutIndex + 1);
            
            //6. 判断protoAlg与waitAlg之间匹配,成立则OutBackYes;
            [AITest test11:model waitAlg_p:waitAlg_p];//测下2523c-此处是否会导致匹配不到;
//            BOOL mIsC = [TOUtils mIsC_1:model.protoAlg.pointer c:waitAlg_p];
            BOOL mIsC = [recognitionAlgs containsObject:waitAlg_p];
            if (mIsC) {
                //6. 有反馈时,进行P反省: 进行理性IRT反省;
                [waitModel checkAndUpdateReasonInRethink:waitModel.cutIndex type:ATPlus except4SP2F:except4SP2F];
                
                //7. pFo任务顺利: 推进帧;
                [waitModel feedbackPushFrame:model.protoAlg.pointer];
                dispatch_async(dispatch_get_main_queue(), ^{//30083回同步
                    [theTV updateFrame];
                });
                NSLog(@"tir_OPushM: waitFo场景更新,原IRT理性失效");
            } else {
                //调用3: 只要没调用到pushFrame,就调用此方法记录protoA;
                [waitModel feedbackOtherFrame:model.protoAlg.pointer];
            }
        }
    }
    
    //7. 传给TOR,做下一步处理: R任务_预测mv价值变化;
    //2021.12.01: R任务(新架构应在forecastIRT之后,调用rForecastBack.rDemand,但旧架构在前面,先不动,等测没影响再改后面);
    //2021.12.05: 将tor移到概念识别后了,此处front和back合并 (参考24171-9);
    DebugE();
}

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 认知--------------------
 *  @title 外层输入对In短时记忆的影响处理 (参考22052-2);
 *  @param cmvNode : 新输入的mv;
 *  @version
 *      2021.01.24: 对多时序识别结果支持,及时全面的改变status为OutBackYes (参考22073-todo5);
 *      2021.02.04: In反省支持虚mv,所以此处也要支持虚mv的OPush判断 (参考22108);
 *      2021.12.25: 废弃虚mv的代码 (因为虚mv早已不在时序识别的结果中,并且整个dsFo都已废弃掉了) (参考Note24);
 *      2021.12.25: 针对感性IRT反省的支持 (判断末位为感性预测中) (参考25022-②);
 *      2022.09.05: 将theTC.inModels改成roots.pFos (参考27096-方案2);
 *      2022.09.18: 有反馈时,及时处理反省和任务失效 (参考27098-todo2);
 *      2023.04.19: 改到TCTransfer迁移后调用canset识别类比 (参考29069-todo12);
 *      2023.09.01: 打开canset失败时调用canset识别类比,并eff-1 (参考30124-todo1&todo2);
 *  @bug
 *      2021.01.25: 修复witMatchFo.cmvNode_p空判断逻辑反了,导致无法执行修改状态为OutBackYes,从而反省类比永远为"逆";
 */
+(void) feedbackTIP:(AIFoNodeBase*)protoFo cmvNode:(AICMVNode*)cmvNode {
    //1. 数据检查
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"feedbackTIP", @"\n输入MV:%@",Mv2FStr(cmvNode));
    
    //2024.12.05: 每次反馈同F只计一次: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5);
    NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];
    
    //2. 判断最近一次input是否与等待中pFo感性结果相匹配 (匹配,比如吃,确定自己是否真吃了);
    //2. fbTIP对roots进行反馈判断 (参考27096-方案2);
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    for (ReasonDemandModel *root in roots) {
        
        //2. 仅支持ReasonDemandModel类型的反馈,因为PerceptDemandModel已经发生完毕,不需要反馈;
        if (!ISOK(root, ReasonDemandModel.class)) continue;
        
        //2025.01.08. 每条TI输入，必须收集到realMaskFo中，不然TOR反馈成立时，RealCansetToIndexDic就会有重复帧 (参考：全局搜索RealCansetToIndexDic重复BUG)。
        for (AIMatchFoModel *waitModel in root.pFos) {
            [waitModel feedbackOtherFrame:cmvNode.pointer];
        }
        
        //3. 对pFos做理性反馈;
        for (AIMatchFoModel *waitModel in root.validPFos) {
            
            //3. 数据准备;
            AIFoNodeBase *waitMatchFo = [SMGUtils searchNode:waitModel.matchFo];
            NSInteger maxCutIndex = waitMatchFo.count - 1;
            
            //4. 非等待中的跳过;
            NSInteger status = [waitModel getStatusForCutIndex:waitModel.cutIndex];
            if (Log4OPushM) NSLog(@"==> checkTIModel=MatchFo: %@ (%@)",Fo2FStr(waitMatchFo),TIStatus2Str(status));
            if (status != TIModelStatus_LastWait) continue;
            
            //5. 非末位跳过 (参考25031-2);
            if (waitModel.cutIndex < maxCutIndex) continue;
            
            //6. 等待中的inModel_判断hope(wait)和real(new)之间是否相符 (仅标记同区同向反馈);
            if ([AIScore sameIdenSameScore:waitMatchFo.cmvNode_p mv2:cmvNode.pointer]) {
                AIFoNodeBase *waitMatchFo = [SMGUtils searchNode:waitModel.matchFo];
                
                //10. 有反馈;
                CGFloat score = [AIScore score4MV:waitMatchFo.cmvNode_p ratio:1.0f];
                
                //b. 正mv反馈为P(好) 或 负mv反馈为S(坏);
                if (score != 0) {
                    AnalogyType type = score > 0 ? ATPlus : ATSub;
                    
                    //11. 则进行感性IRT反省;
                    [waitModel checkAndUpdatePerceptInRethink:type except4SP2F:except4SP2F];
                    NSLog(@"---//IP反省触发器执行:%p F%ld 状态:%@",waitMatchFo,waitMatchFo.pointer.pointerId,TIStatus2Str(TIModelStatus_OutBackSameDelta));
                    
                    //12. 有mv反馈时,做Canset识别 (参考28185-todo5);
                    //[TCEffect rInEffect:waitMatchFo matchRFos:waitModel.baseFrameModel.matchRFos es:es];
                    //EffectStatus es = score > 0 ? ES_HavEff : ES_NoEff;
                    //[TCRecognitionInvoke recognitionCansetFo:protoFo.pointer sceneFo:waitMatchFo.pointer es:es];
                }
                
                //13. pFo任务失效 (参考27093-条件1 & 27095-1);
                //2024.07.04: pFo发生负价值反馈时: 单发价值=>已不可挽回计为失效 & 持续价值感=>发生后还会再发生不计失效 (参考32041-方案);
                if (![ThinkingUtils isContinuousWithAT:cmvNode.pointer.algsType]) waitModel.isExpired = true;
                dispatch_async(dispatch_get_main_queue(), ^{//30083回同步
                    [theTV updateFrame];
                });
                NSLog(@"tip_OPushM: 实MV 正向反馈");
            }
        }
        
        //2024.07.28: 此处应该对所有pFos反馈TIModelStatus_OutBackSameDelta状态;
        for (AIMatchFoModel *waitModel in root.pFos) {
            AIFoNodeBase *waitMatchFo = [SMGUtils searchNode:waitModel.matchFo];
            //6. 等待中的inModel_判断hope(wait)和real(new)之间是否相符 (仅标记同区同向反馈);
            if ([AIScore sameIdenSameScore:waitMatchFo.cmvNode_p mv2:cmvNode.pointer]) {
                [waitModel setStatus:TIModelStatus_OutBackSameDelta forCutIndex:waitMatchFo.count - 1];
            }
        }
    }
    DebugE();
}


//MARK:===============================================================
//MARK:                     < TO部分 >
//MARK:===============================================================

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 决策--------------------
 *  @title 外层输入对Out短时记忆的影响处理:
 *  @实例1: 原本我要上战场,预测危险不去,结果突然看到一辆坦克,为什么我会想到驾驶坦克上战场?
 *          a. 发现坦克前: 短时记忆的父子枝结构为: 物体去战场 -> 我做为物体去战场;
 *          b. 发现坦克后: 短时记忆的父子枝结构为: 坦克去战场 -> 我开着坦克去战场 (feedback后重组反思_坦克替代物体);
 *          说明: 通过feedback,已经重刷新了记忆树的一大部分;
 *          问题: 此处如何把坦克替换到人的?因为物体在更抽象父中,而上战场在更子中 (物体和战场可能不在同一时序中);
 *  @callers : 所有的ActYes都会使用此处来收集外循环反馈;
 *      1. HNGL
 *      2. Demand
 *      3. 静默成功说明 (例:穿越森林,出门前备好枪,老虎冲出来时,开枪吓跑它):
 *          a. 备好枪后,等待老虎 (进入来的及,actYes状态);
 *          b. 当静默成功返回outBack时,会在isNormal代码处判断到mIsC成立 (如老虎冲出来了);
 *          c. 并在此方法最后提交到PM流程中 (判断这只老虎的特征是否符合被吓跑的可能);
 *          d. 流程控制自行继续推进dsFo,使之阻止R预测发生 (如在老虎咬人前,我们开枪吓跑它);
 //因为dsFo的继续推进,未必需要PM,而此处PM的推进,能否流程控制自己递归到dsFo推进?需要明天查下此代码;
 *  @desc
 *      1. 最新一帧,与上轮循环做匹配 (对单帧匹配到任务Finish的,要推动决策跳转下帧);
 *      2. 未输出行为,等待中的,也要进行下轮匹配,比如等开饭,等来开饭了; (等待的status是ActNo还是Runing?)
 *      3. 流程说明: OPushM成功时,调用PM继续推进流程;
 *      4. 流程说明: OPushM失败时,待生物钟触发器触发反省类比,再推进流程;
 *  @desc 外循环回来,把各自实际输入的概念,存入到TOAlgModel.realAlg中;
 *      1. 三种ActYes方式: (HNGL,isOut输出,demand完成);
 *      2. 其中,"isOut输出"和"demand完成"和"HNGL.H"时的ActYes直接根据mIsC判断外循环输入是否符合即可;
 *      3. 而HNGL.GL需要根据输入的稀疏码变化是否符合GL来判断 (base.base可找到期望稀疏码,参考:20204);
 *  @todo
 *      1. 此处在for循环中,所以有可能推进多条,比如我有了一只狗,可以拉雪撬,或者送给爷爷陪爷爷 (涉及多任务间的价值自由竞争),暂仅支持一条,后再支持;
 *      2020.08.23: 在inputMv时,支持当前actYes的fo进行抵消 (或设置为Finish) (T 由demandManager完成);
 *      2020.08.23: 在waitModel为ActYes且为HNGL时,仅判定其是否符合HNGL变化; T
 *      2020.08.23: 对realAlg进行收集,收集到waitTOAlgModel.feedbackAlg下; T
 *      2020.08.26: 在GL时,需要判断其"期望"与"真实"概念间是否是同一物体 (参考20204-示例);
 *  @version
 *      xxxx.xx.xx: 返回pushMiddle是否成功,如果推进成功,则不再执行TOP四模式;
 *      2020.08.05: waitModel.pm_Score的赋值改为取demand.score取负 (因为demand一般为负,而解决任务为正);
 *                  而此处,从waitModel的base中找fo较麻烦,所以省事儿,就直接取-demand.score得了;
 *      2020.08.24: 从tor_OPushM中独立出来,独立调用,处理realAlg和HNGL的变化相符判断;
 *      2020.12.21: 重新将commitFromOuterInputReason与OuterPushMiddleLoop()合并 (参考21185);
 *      2020.12.22: 在以往isNormal之外,再支持对isH,isGL的节点进行PM理性评价;
 *      2020.12.22: 将所有waitModel有效的返回都赋值OuterBack,而仅将首个focusModel进行PM理性评价;
 *      2020.12.28: waitModels仅对ActYes响应,将Runing去掉,因为Running应该到任务推进中自行进行PM匹配mModel,而非此处 (参考21208);
 *      2021.01.02: 无论GL变化type是否与waitType符合,都对新的变化进行保留到feedbackAlg (参考2120B-BUG1);
 *      2021.01.02: GL中mIsC对matchAlgs的全面支持,因为有时洽逢C不是matchAlgs首个,而致mIsC失败;
 *      2021.03.17: 将latestAlg和waitAlg之间的mIsC判断由1层改为2层 (因为在22173BUG时,发现此处输入了隔层mIsC);
 *      2021.05.09: 对OPushM反馈的GL触发ORT反省 (参考23071-方案2);
 *      2021.05.12: 整理tor_OPushM的代码易读性;
 *      2021.05.12: GL返回时,直接调用focus.base(即C).begin() (参考23075-方案);
 *      2021.05.14: 将reModel.content由matchA改成protoA后,此处GL时mIsC判断仅判断pIsM即可 (参考23076);
 *      2021.05.18: 将GL返回时,更新baseGLFo和basebaseValue的status,以使ORT中可以判断其finish状态 (参考23065-474示图);
 *      2021.05.20: 在waitModels收集中,将任何层的actNo之下都切断收集,避免距21飞错又飞回来,重复相符判断 (参考23073-假想2);
 *      2021.05.20: 当GL相符判断有结果后,targetModel(replaceAlg)也设为finish或actNo,以便_GL()中做不应期判断 (参考23079);
 *      2021.12.05: 将feedbackTOR前置到概念识别后,所以推进成功,才执行TOP四模式的逻辑作废 (参考24171-9);
 *      2021.12.23: feedback时,将root设回runing状态 (参考24212-8);
 *      2021.12.26: 废弃HN后,类型判断处理 & 兼容hActYes输出 (参考25032-6);
 *      2021.12.26: waitModels由currentDemand改为支持所有rootDemands (新螺旋架构迭代了短时记忆树,全树更新);
 *      2021.12.27: 当H反馈成功时,把hDemand设为finish;
 *      2022.01.08: HDemand时,非actYes状态也处理反馈 (参考25054);
 *      2022.03.13: 将mIsC改成proto或matchAlgs中任一条mIsC成立即可 (参考25146-转疑3-方案);
 *      2022.05.02: 用matchAlgs+partAlgs替代mIsC (参考25234-8);
 *      2022.05.22: H任务有效性反馈状态更新 (参考26095-6);
 *      2022.06.01: 有反馈时,不改root的runing状态 (参考26185-TODO1);
 *      2022.06.01: H反馈中段和末帧改的状态不同处理;
 *      2022.06.01: 有反馈时,继续调用TCScore (参考26185-TODO2);
 *      2022.06.01: HDemand.targetAlg提前反馈时,HDemand设为finish状态 (参考26185-TODO6);
 *      2022.11.27: H任务完成时,H当前正执行的S提前完成,并进行外类比 (参考27206c-H任务);
 *      2022.11.27: H解决方案再类比时,为其生成indexDic (参考27206d-方案2);
 *      2023.10.27: 用共同抽象判断cansetAlg反馈: 取出targetAlg的abs层,并与识别的matchAlgs判断交集 (参考3014c-todo1);
 *      2023.12.09: 预想与实际类比构建absCanset以场景内防重 (参考3101b-todo6);
 *      2024.01.10: 改为在feedbackTOR有反馈"RCansetA有效"时,直接生成newHCanset,避免原本在OR反省时后面会有无关帧排到后段的问题 (参考31061-todo1);
 *      2024.01.11: H支持持续反馈 (参考31063-todo1);
 *  @bug
 *      2020.09.22: 加上cutStopStatus,避免同一waitModel被多次触发,导致BUG (参考21042);
 *      2020.12.26: GL时,waitType的判断改为bFo,因为只有bFo才携带了waitTypeDS (参考21204);
 *      2020.12.26: GL时,在21204BUG修复后训练时,发现mIsC有时是cIsM,所以都判断下;
 *      2020.12.26: 在OPushM继续PM前,replaceAlg时,重新赋值JustPValues=P-C (参考21206);
 *      2023.11.07: 预想与实际类比,实际hCanset采用pFo.maskRealFo来生成 (参考30154-todo2);
 */
+(void) feedbackTOR:(AIShortMatchModel*)model{
    //1. 将新一帧数据报告给TOR,以进行短时记忆的更新,比如我输出行为"打",短时记忆由此知道输出"打"成功 (外循环入->推进->中循环出);
    [theTC updateOperCount:kFILENAME];
    Debug();
    
    //2024.04.21: 改成取matchAlgs_All判断反馈 (参考31134-交层AbsCanset很难反馈匹配的问题);
    NSArray *recognitionAlgs = [SMGUtils convertArr:model.matchAlgs_All convertBlock:^id(AIMatchAlgModel *o) {
        return o.matchAlg;
    }];
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    IFTitleLog(@"feedbackTOR", @"\n输入ProtoA:%@ 识别matchAlgs数:%ld",Alg2FStr(model.protoAlg),recognitionAlgs.count);
    
    //2. ============== 对Demand.cansetModels的反馈判断 (参考31073-TODO2: Cansets实时竞争) ==============
    NSMutableArray *allDemands = [SMGUtils convertArr:roots convertItemArrBlock:^NSArray *(DemandModel *root) {
        return [SMGUtils filterArr:[TOUtils getSubOutModels_AllDeep:root validStatus:nil] checkValid:^BOOL(TOModelBase *item) {
            return ISOK(item, DemandModel.class);
        }];
    }];
    
    NSLog(@"反馈来了:protoA:%@ recognitionAlgs:%@",ShortDesc4Node(model.protoAlg),CLEANSTR([SMGUtils convertArr:recognitionAlgs convertBlock:^id(AIKVPointer *obj) {
        return STRFORMAT(@"A%ld",obj.pointerId);
    }]));
    
    NSLog(@"工作记忆root数:%ld 含任务数:%ld",roots.count,allDemands.count);
    
    //3. 每个Canset都支持持续反馈: 反馈有效时,构建或类比抽象HCanset,并推进到下一帧;
    NSArray *allCanset = [TOUtils getSubCansets_AllDeep_AllRoots];
    
    //2024.12.05: 每次反馈同F只计一次: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5);
    NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];
    int feedbackValidNum = 0, rewakeNum = 0;
    for (TOFoModel *cansetModel in allCanset) {
        BOOL feedbackValid = [cansetModel commit4FeedbackTOR:recognitionAlgs protoAlg:model.protoAlg.p except4SP2F:except4SP2F];
        
        //4. feedbackTOR有反馈有效时,被传染的支持整个工作记忆树唤醒 (参考31178-TODO2);
        feedbackValidNum += feedbackValid ? 1 : 0;
        if (feedbackValid && cansetModel.isInfected) {
            rewakeNum++;
            cansetModel.isInfected = false;
        }
    }
    if (rewakeNum > 0) NSLog(@"feedbackTOR反馈:%@ 反馈有效数:%d 因此中间帧传染唤醒数:%d",Alg2FStr(model.protoAlg),feedbackValidNum,rewakeNum);
    DebugE();
}

/**
 *  MARK:--------------------"外层输入" 推进 "中层循环" 决策--------------------
 *  @title 外层输入对Out短时记忆的ReasonDemandModel影响处理 (参考22061-8);
 *  @version
 *      2021.02.04: 将R同区同向(会导致永远为false因为虚mv得分为0)判断,改为同区反向判断 (参考22115BUG & 22108虚mv反馈判断方法);
 *      2021.12.23: feedback时,将root设回runing状态 (参考24212-8);
 *      2021.12.24: 应对整个工作记忆树进行支持,而不是仅rootDemands (参考25032-6);
 *      2021.12.26: 针对rSolution的感性反馈 (参考25031-11 & 25032-6);
 *      2022.05.22: R任务有效性反馈状态更新 (参考26095-3);
 *      2022.05.29: 反馈与demand.mv对比匹配,而不是solutionFo (参考26141-BUG1);
 *      2022.06.03: 将roots浅复制,避免强训过程中因loopCache变化而闪退;
 *      2022.09.06: TC流程调整_直接调用TCDemand (参考27096-实践1);
 *      2022.11.23: 记录feedbackMv (参考27204-2);
 *      2024.05.23: feedbackTOP: 末帧且反馈到负mv,则被传染 (参考31179-TODO1);
 */
+(void) feedbackTOP:(AICMVNodeBase*)cmvNode{
    //1. 数据检查
    NSInteger delta = [NUMTOOK([AINetIndex getData:cmvNode.delta_p]) integerValue];
    if (delta == 0) return;
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"feedbackTOP", @"\n输入MV:%@",Mv2FStr(cmvNode));
    
    //2. ============== 对所有等待中的任务尝试处理 (R-任务); ==============
    int newInfectedNum = 0;
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    
    //2024.12.05: 每次反馈同F只计一次: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5);
    NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];
    for (ReasonDemandModel *root in roots) {
        NSArray *waitModels = [TOUtils getSubOutModels_AllDeep:root validStatus:nil];
        for (TOFoModel *waitModel in waitModels) {
            
            //3. wait不为fo解决方案时不处理;
            if (!ISOK(waitModel, TOFoModel.class)) continue;
            
            //4. 非R也非P任务时,不处理;
            if (!ISOK(waitModel.baseOrGroup, ReasonDemandModel.class) && !ISOK(waitModel.baseOrGroup, PerceptDemandModel.class)) continue;
            
            //5. 非actYes状态不处理 (canset池的none,best状态都可以传染和唤醒 参考31179-TODO1);
            //if (waitModel.status != TOModelStatus_ActYes) continue;
            
            //7. waitFo是为了解决任务,所以要取出原任务的mv标识来比较;
            //7. 判断hope(wait)和real(new)之间是否相符 (当反馈了"同区反向"时,即表明任务失败,为S);
            DemandModel *demand = (DemandModel*)waitModel.baseOrGroup;
            BOOL sameIden = [cmvNode.pointer.algsType isEqualToString:demand.algsType];
            if (!sameIden) continue;
                
            //8. 同向匹配 (比如撞疼,确定疼了);
            CGFloat score = [AIScore score4MV:cmvNode.pointer ratio:1.0f];
            if (score < 0) {
                
                //11. 未到末尾,不处理;
                if (waitModel.cansetActIndex < waitModel.transferXvModel.cansetToOrders.count) continue;
                
                //12. 记录feedbackMv (参考27204-2);
                waitModel.feedbackMv = cmvNode.pointer;
                
                waitModel.status = TOModelStatus_OuterBack;
                
                //13. SP计数之二A(P负):末帧反馈负价值的,计SP- (参考32012-TODO7);
                //2024.09.08: 非bested/besting状态的,没在推进中,不接受反馈; if (waitModel.cansetStatus != CS_None) {}
                //2024.09.21: 去掉best过状态要求 (参考33065-TODO3);
                [waitModel checkAndUpdateOutSPStrong_Percept:1 type:ATSub debugMode:true caller:@"末帧负mv反馈" except4SP2F:except4SP2F];
                
                //14. 末帧且反馈到负mv,则被传染 (参考31179-TODO1);
                waitModel.isInfected = true;
                newInfectedNum++;
                
                //15. root设回runing;
                //demand.status = TOModelStatus_Runing;//后面又设为ActNo了,此处无意义
                root.status = TOModelStatus_Runing;
                
                //16. 明确无效
                demand.status = TOModelStatus_ActNo;
            }else{
                //21. solutionFo反馈好时,baseDemand为完成状态;
                waitModel.baseOrGroup.status = TOModelStatus_Finish;
                
                //22. 记录feedbackMv (参考27204-2);
                waitModel.feedbackMv = cmvNode.pointer;
                
                //23. SP计数之二B(P正):任意帧反馈正价值的,计SP+ (参考33031b-TODO5);
                //2024.09.10: 必须有贡献,才计提前mv反馈 (参考33031c-方案3B);
                //2024.09.21: 去掉best过状态要求 (参考33065-TODO3);
                BOOL tiaoJian2 = waitModel.cansetCutIndex > waitModel.initCansetCutIndex;
                if (tiaoJian2) {
                    [waitModel checkAndUpdateOutSPStrong_Percept:1 type:ATPlus debugMode:true caller:@"提前正mv反馈" except4SP2F:except4SP2F];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{//30083回同步
                [theTV updateFrame];
            });
        }
    }
    NSLog(@"feedbackTOP: 有负mv反馈导致canset末帧无效 传染数:%d",newInfectedNum);
    
    //31. ============== expired4PInput: 把at标识的root全移除掉 ==============
    //> 2024.07.22: 如果输入为正价值,目前不做太深入操作,直接简单的将DemandManager中一样标识的任务对冲移除掉即可;
    //> 起因: 因为饥饿最近改成了连续任务,更饿也要继续求解,直至好久后解决后,得有个触发,使之停下吃 (不然它完成后,还一直在尝试求解);
    //用expired4PInput的原因: 如果直接remove,好像工作记忆停的太快,导致会有一些执行不到? (比如吃的识别是否还没完成,如果识别完成,发现feedback时root已经没了,那就反馈不到了);
    for (ReasonDemandModel *root in roots) {
        BOOL sameIden = [cmvNode.pointer.algsType isEqualToString:root.algsType];
        CGFloat score = [AIScore score4MV:cmvNode.pointer ratio:1.0f];
        if (sameIden && score > 0) {
            root.expired4PInput = true;
            NSLog(@"因持续任务反馈了正mv设expired4PInput=true (F%ld)",Demand2Pit(root).pointerId);
        }
    }
    
    //3. p任务;
    DebugE();
    [TCDemand pDemand:cmvNode];
}

@end
