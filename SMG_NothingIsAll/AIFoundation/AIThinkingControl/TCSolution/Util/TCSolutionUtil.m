//
//  TCSolutionUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/6/5.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TCSolutionUtil.h"

@implementation TCSolutionUtil


//MARK:===============================================================
//MARK:                     < 快思考 >
//MARK:===============================================================

/**
 *  MARK:--------------------R快思考--------------------
 *  @desc 习惯 (参考26142);
 *  @version
 *      2022.11.30: 先关掉快思考功能,因为慢思考有了indexDic和相似度复用后并不慢,并且effectDic和SP等效 (参考27205);
 */
+(AICansetModel*) rSolution_Fast:(ReasonDemandModel *)demand except_ps:(NSArray*)except_ps{
    if (!Switch4FastSolution) return nil;
    //1. 数据准备;
    except_ps = ARRTOOK(except_ps);

    //2. 收集所有解决方案候选集;
    NSArray *cansetModels = [SMGUtils convertArr:demand.validPFos convertItemArrBlock:^NSArray *(AIMatchFoModel *pFoM) {
        //a. 取出pFo的effectDic候选集;
        AIFoNodeBase *pFo = [SMGUtils searchNode:pFoM.matchFo];
        NSArray *cansetFos = [pFo getValidEffs:pFo.count];
        if (Log4Solution_Fast && ARRISOK(cansetFos)) NSLog(@"\tF%ld的第%ld帧取: %@",pFo.pointer.pointerId,pFo.count,CLEANSTR(cansetFos));

        //b. 分析analyst结果 & 排除掉不适用当前场景的(为nil) (参考26232-TODO8);
        return [SMGUtils convertArr:cansetFos convertBlock:^id(AIEffectStrong *eff) {
            //c. 分析比对结果;
            NSInteger rAleardayCount = [self getRAleardayCount:demand pFo:pFoM];
            AICansetModel *sModel = [TCCanset convert2CansetModel:eff.solutionFo sceneFo:pFoM.matchFo basePFoOrTargetFoModel:pFoM ptAleardayCount:rAleardayCount isH:true sceneModel:nil];
            return sModel;
        }];
    }];

    //3. 快思考算法;
    return [TCSolutionUtil generalSolution_Fast:demand cansets:cansetModels except_ps:except_ps];
}

/**
 *  MARK:--------------------H快思考--------------------
 *  @desc 习惯 (参考26142);
 *  @version
 *      2022.11.30: 先关掉快思考功能,因为慢思考有了indexDic和相似度复用后并不慢,并且effectDic和SP等效 (参考27205);
 */
+(AICansetModel*) hSolution_Fast:(HDemandModel *)hDemand except_ps:(NSArray*)except_ps{
    if (!Switch4FastSolution) return nil;
    //1. 数据准备;
    TOFoModel *targetFoM = (TOFoModel*)hDemand.baseOrGroup.baseOrGroup;
    AIFoNodeBase *targetFo = [SMGUtils searchNode:targetFoM.content_p];

    //2. 从targetFo取解决方案候选集;
    NSArray *cansetFos = [targetFo.effectDic objectForKey:@(targetFoM.actionIndex)];

    //3. 分析analyst结果 & 排除掉不适用当前场景的(为nil) (参考26232-TODO8);
    NSArray *cansetModels = [SMGUtils convertArr:cansetFos convertBlock:^id(AIEffectStrong *eff) {
        //a. 分析比对结果;
        NSInteger hAleardayCount = [self getHAleardayCount:targetFoM];
        AICansetModel *sModel = [TCCanset convert2CansetModel:eff.solutionFo sceneFo:targetFoM.content_p basePFoOrTargetFoModel:targetFoM ptAleardayCount:hAleardayCount isH:true sceneModel:nil];
        return sModel;
    }];

    //3. 快思考算法;
    return [TCSolutionUtil generalSolution_Fast:hDemand cansets:cansetModels except_ps:except_ps];
}

/**
 *  MARK:--------------------快思考--------------------
 *  @desc 习惯 (参考26142);
 *  @version
 *      2022.06.03: 将cansets中hnStrong合并,一直这么设计的,今发现写没实现,补上;
 *      2022.06.03: 排除掉候选方案不适用当前场景的 (参考26192);
 *      2022.06.05: 支持三个阈值 (参考26199);
 *      2022.06.05: 将R快思考和H快思考整理成通用快思考算法;
 *      2022.06.09: 废弃阈值方案和H>5的要求 (参考26222-TODO3);
 *      2022.06.09: 弃用阈值方案,改为综合排名 (参考26222-TODO2);
 *      2022.06.12: 废弃同cansetFo的effStrong累计 (参考26232-TODO8);
 *      2022.06.12: 每个pFo独立做analyst比对,转为cansetModels (参考26232-TODO8);
 *      2022.10.15: 快思考支持反思,不然因为一点点小任务就死循环 (参考27143-问题2);
 */
+(AICansetModel*) generalSolution_Fast:(DemandModel *)demand cansets:(NSArray*)cansets except_ps:(NSArray*)except_ps{
    //1. 数据准备;
    except_ps = ARRTOOK(except_ps);
    BOOL havBack = ISOK(demand, HDemandModel.class); //H有后段,别的没有;
    NSLog(@"1. 快思考protoCansets数:%ld",cansets.count);

    //2. solutionModels过滤器;
    cansets = [SMGUtils filterArr:cansets checkValid:^BOOL(AICansetModel *item) {
        //a. 排除不应期;
        if([except_ps containsObject:item.cansetFo]) return false;

        //b. 时间不急评价: 不急 = 解决方案所需时间 <= 父任务能给的时间 (参考:24057-方案3,24171-7);
        if (![AIScore FRS_Time:demand solutionModel:item]) return false;

        ////2. 后段-目标匹配 (阈值>80%) (参考26199-TODO1);
        //if (item.backMatchValue < 0.8f) return false;
        //
        ////3. 中段-按有效率 (effectScore>0) (参考26199-TODO2);
        //if (item.effectScore <= 0) return false;
        //
        ////4. 前段-场景匹配 (阈值>80%) (参考26199-TODO3);
        //if (item.frontMatchValue < 0.8) return false;

        //5. 闯关成功;
        return true;
    }];
    NSLog(@"2. (不应期 & FRSTime & 后中后段阈值)过滤后:%ld",cansets.count);

    //6. 对候选集排序;
    NSArray *sortCansets = [AIRank solutionFoRankingV3:cansets];
    NSLog(@"3. 有效率排序后:%ld",cansets.count);
    if (Log4Solution_Fast) for (AICansetModel *m in ARR_SUB(sortCansets, 0, 5)) {
        NSLog(@"\t(前%.2f 中%.2f 后%.2f) %@",m.frontMatchValue,m.midEffectScore,m.backMatchValue,Pit2FStr(m.cansetFo));
    }

    //6. 逐条S反思;
    AICansetModel *result = nil;
    for (AICansetModel *item in sortCansets) {
        BOOL score = [TCRefrection refrection:item demand:demand];
        if (score) {
            result = item;
            break;
        }
    }

    //7. 日志及更新强度值等;
    if (result) {
        if (Log4Solution && result) NSLog(@"4. 快思考最佳结果:F%ld (前%.2f 中%.2f 后%.2f",result.cansetFo.pointerId,result.frontMatchValue,result.midEffectScore,result.backMatchValue);

        //8. 更新其前段帧的con和abs抽具象强度 (参考28086-todo2);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.matchFrontIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];

        //16. 更新后段的的具象强度 (参考28092-todo4);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.backIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];
    }

    //8. 将首条最佳方案返回;
    return result;
}


//MARK:===============================================================
//MARK:                     < 慢思考 >
//MARK:===============================================================

/**
 *  MARK:--------------------H慢思考--------------------
 *  @version
 *      2023.09.10: 升级v2,支持TCScene和TCCanset (参考30127);
 */
+(AICansetModel*) hSolution_SlowV2:(HDemandModel *)demand except_ps:(NSArray*)except_ps {
    //1. 收集cansetModels候选集;
    NSArray *sceneModels = [TCScene hGetSceneTree:demand];
    TOFoModel *targetFoM = (TOFoModel*)demand.baseOrGroup.baseOrGroup;

    //2. 每个cansetModel转solutionModel;
    NSArray *cansetModels = [SMGUtils convertArr:sceneModels convertItemArrBlock:^NSArray *(AISceneModel *sceneModel) {
        //3. 取出overrideCansets;
        NSArray *cansets = ARRTOOK([TCCanset getOverrideCansets:sceneModel sceneTargetIndex:sceneModel.cutIndex + 1]);//127ms
        NSArray *itemCansetModels = [SMGUtils convertArr:cansets convertBlock:^id(AIKVPointer *canset) {
            //4. 过滤器 & 转cansetModels候选集 (参考26128-第1步 & 26161-1&2&3);
            NSInteger aleardayCount = sceneModel.cutIndex + 1;
            return [TCCanset convert2CansetModel:canset sceneFo:sceneModel.scene basePFoOrTargetFoModel:targetFoM ptAleardayCount:aleardayCount isH:true sceneModel:sceneModel];//245ms
        }];
        
        if (Log4GetCansetResult4H && cansets.count > 0) NSLog(@"\t item场景(%@):%@ 取得候选数:%ld 转成候选模型数:%ld",SceneType2Str(sceneModel.type),Pit2FStr(sceneModel.scene),cansets.count,itemCansetModels.count);
        return itemCansetModels;
    }];
    //TODOTOMORROW20231004:
    //查下,这里hSolution总是输出无计可施,而此时"皮果"已经有了,按道理说,前段条件满足已经满足了;
    //日志: 第1步 H场景树枝点数 I:1 + Father:0 + Brother:0 = 总:1 (这里总是取到hCanset=0条);
    
    
    
    NSLog(@"第2步 转为候选集 总数:%ld",cansetModels.count);

    //5. 慢思考;
    return [self generalSolution_Slow:demand cansetModels:cansetModels except_ps:except_ps];//400ms
}

+(AICansetModel*) hSolution_SlowV3:(HDemandModel *)demand except_ps:(NSArray*)except_ps {
    //1. 数据准备;
    TOFoModel *targetFoM = (TOFoModel*)demand.baseOrGroup.baseOrGroup;
    ReasonDemandModel *baseRDemand = (ReasonDemandModel*)targetFoM.baseOrGroup;//取出rDemand
    
    //2. 再根据rDemand取出场景树;
    NSArray *sceneModels = [TCScene rGetSceneTree:baseRDemand];
    //3. 再根据r场景树,找出cansets;
    
    //2. 每个cansetModel转solutionModel;
    NSArray *cansetModels = [SMGUtils convertArr:sceneModels convertItemArrBlock:^NSArray *(AISceneModel *sceneModel) {
        //3. 取出overrideCansets;
        NSArray *cansets = ARRTOOK([TCCanset getOverrideCansets:sceneModel sceneTargetIndex:sceneModel.cutIndex + 1]);//127ms
        NSArray *itemCansetModels = [SMGUtils convertArr:cansets convertBlock:^id(AIKVPointer *canset) {
            //4. 过滤器 & 转cansetModels候选集 (参考26128-第1步 & 26161-1&2&3);
            NSInteger aleardayCount = sceneModel.cutIndex + 1;
            
            
            //TODOTOMORROW20240106: 测下h任务也从r场景树迁移 (参考31053);
            //1. 从cansets中过滤出与hDemand有抽具象关系的 (用hAlg取抽具象关系的,判断交集即可);
            //问题: 此处再跑一次R的流程有点浪费,并且R流程也不行,得再改代码,往H再深入一层,有点复杂且麻烦;
            
            
            
            return [TCCanset convert2CansetModel:canset sceneFo:sceneModel.scene basePFoOrTargetFoModel:targetFoM ptAleardayCount:aleardayCount isH:true sceneModel:sceneModel];//245ms
        }];
        
        if (Log4GetCansetResult4H && cansets.count > 0) NSLog(@"\t item场景(%@):%@ 取得候选数:%ld 转成候选模型数:%ld",SceneType2Str(sceneModel.type),Pit2FStr(sceneModel.scene),cansets.count,itemCansetModels.count);
        return itemCansetModels;
    }];
    NSLog(@"第2步 转为候选集 总数:%ld",cansetModels.count);

    //5. 慢思考;
    return [self generalSolution_Slow:demand cansetModels:cansetModels except_ps:except_ps];//400ms
}

+(AICansetModel*) hSolution_SlowV4:(HDemandModel *)demand except_ps:(NSArray*)except_ps {
    return [self hSolution_SlowV2:demand except_ps:except_ps];
    
    //1. 取出rSolution的成果,在它的基础上继续做hSolution;
    ReasonDemandModel *rDemand = (ReasonDemandModel*)demand.baseOrGroup.baseOrGroup.baseOrGroup;
    NSArray *rCansetModels = rDemand.rCansetModels;
    NSLog(@"第1步 rCansetModels数: %ld",rCansetModels.count);
    
    //2. 根据当前hAlg取抽具象树;
    TOAlgModel *hAlgModel = (TOAlgModel*)demand.baseOrGroup;
    AIFoNodeBase *hAlg = [SMGUtils searchNode:hAlgModel.content_p];
    NSArray *absHAlgs = Ports2Pits([AINetUtils absPorts_All:hAlg]);
    NSArray *conHAlgs = [SMGUtils convertArr:absHAlgs convertItemArrBlock:^NSArray *(AIKVPointer *obj) {
        AIAlgNodeBase *absHAlg = [SMGUtils searchNode:obj];
        return Ports2Pits([AINetUtils conPorts_All:absHAlg]);
    }];
    
    NSMutableArray *allHAlgs = [[NSMutableArray alloc] init];
    [allHAlgs addObject:hAlg.pointer];
    [allHAlgs addObjectsFromArray:absHAlgs];
    [allHAlgs addObjectsFromArray:conHAlgs];
    NSLog(@"第2步 absHAlg数:%ld conHAlg数:%ld HAlg树总数:%ld",absHAlgs.count,conHAlgs.count,allHAlgs.count);
//    NSLog(@"=====> %@",CLEANSTR([SMGUtils convertArr:allHAlgs convertBlock:^id(AIKVPointer *obj) {
//        return STRFORMAT(@"F%ld",obj.pointerId);
//    }]));
    
    NSString *hAlgStr = Alg2FStr(hAlg);
    NSMutableArray *havHCansetOfRCanset = [[NSMutableArray alloc] init];
    if ([hAlgStr containsString:@"皮果"]) {
        NSLog(@"直接调试以下,rCanset中就没有包含 果 的...");
        //1. 可是不对啊,都生成皮果hDemand了,怎么可能rCanset里没一个有"果"的呢?
        //2. 即使就真的全没果,那么只好再多训练一些newHCanset出来了...
        //3. 可是下面havHAlgRCansetModelsCount又显示计数5,就奇怪了...,既然没有"果",又哪里计到5呢?
        
        
        NSInteger step1 = 0,step2 = 0;
        for (AICansetModel *item in rCansetModels) {
            AIFoNodeBase *rCanset = [SMGUtils searchNode:item.cansetFo];
            for (NSInteger i = 0; i < rCanset.count; i++) {
                AIKVPointer *rCansetAlg = ARR_INDEX(rCanset.content_ps, i);
                NSString *rCansetAlgStr = Pit2FStr(rCansetAlg);
                if (![rCansetAlgStr containsString:@"皮果"]) {
                    step1++;
                    continue;
                }
                
                NSArray *hCansets = [rCanset getConCansets:i];
                if (!ARRISOK(hCansets)) {
                    step2++;
                    continue;
                }
                
                [havHCansetOfRCanset addObject:item];
                NSLog(@"挂载有hCanset Success");
            }
        }
        NSLog(@"==============>>> %ld %ld",step1,step2);//包含有皮果的rCanset共192条,但它们全部都没有挂截hCanset;
    }
    
    
    //3. 从所有rCanset中,筛选出包含hAlg抽具象树的;
    __block NSMutableArray *havHAlgRCansetModels = [[NSMutableArray alloc] init];
    NSArray *hCansets = [SMGUtils convertArr:rCansetModels convertItemArrBlock:^NSArray *(AICansetModel *item) {
        //a. 从每条rCanset中,找是否包含hAlg树的任何一个枝叶;
        AIFoNodeBase *rCansetFo = [SMGUtils searchNode:item.cansetFo];
        NSInteger findIndex = -1;
        for (NSInteger i = 0; i < rCansetFo.count; i++) {
            AIKVPointer *rCansetAlg = ARR_INDEX(rCansetFo.content_ps, i);
            if ([allHAlgs containsObject:rCansetAlg]) {
                findIndex = i;
                break;
            }
        }
        if (findIndex == -1) return nil;//找hAlg树枝叶失败: 则此rCanset不具备迁移给hScene.hAlg帧的条件;
        [havHAlgRCansetModels addObject:item];
        
        //b. 从所有rCanset中,筛选出有hAlg的hCanset解的部分;
        NSArray *hCansets = [rCansetFo getConCansets:findIndex];
        if (!ARRISOK(hCansets)) return nil;//rCanset这帧无H解: 则它没任何hCanset可迁移给hScene.hAlg;
        return hCansets;
    }];
    NSLog(@"第3步 包含HAlg树的rCansetModels数:%ld \n%@",havHAlgRCansetModels.count,CLEANSTR([SMGUtils convertArr:havHAlgRCansetModels convertBlock:^id(AICansetModel *obj) {
        return STRFORMAT(@"F%ld",obj.cansetFo.pointerId);
    }]));
    NSLog(@"第4步 找到hCansets数:%ld",hCansets.count);
    
    //5. 对有解的部分进行竞争;
    
    //6. 将最好的hCanset解返回 (改写H版本的generalSolution_Slow());
    return nil;
    
    //7. 返回后,将hCanset打包成foModel,并迁移;
}

/**
 *  MARK:--------------------R慢思考--------------------
 *  @version
 *      2023.12.26: 提前在for之前取scene所在的pFo,以优化其性能 (参考31025-代码段-问题1) //共三处优化,此乃其一;
 */
+(AICansetModel*) rSolution_Slow:(ReasonDemandModel *)demand except_ps:(NSArray*)except_ps {
    //1. 收集cansetModels候选集;
    NSArray *sceneModels = [TCScene rGetSceneTree:demand];//600ms
    
    //2. 每个cansetModel转solutionModel;
    NSArray *cansetModels = [SMGUtils convertArr:sceneModels convertItemArrBlock:^NSArray *(AISceneModel *sceneModel) {
        //3. 取出overrideCansets;
        AIFoNodeBase *sceneFo = [SMGUtils searchNode:sceneModel.scene];
        NSArray *cansets = ARRTOOK([TCCanset getOverrideCansets:sceneModel sceneTargetIndex:sceneFo.count]);//127ms
        AIMatchFoModel *pFo = [SMGUtils filterSingleFromArr:demand.validPFos checkValid:^BOOL(AIMatchFoModel *item) {
            return [item.matchFo isEqual:sceneModel.getRoot.scene];
        }];
        NSArray *itemCansetModels = [SMGUtils convertArr:cansets convertBlock:^id(AIKVPointer *canset) {
            //4. cansetModel转换器参数准备;
            NSInteger aleardayCount = sceneModel.cutIndex + 1;
            
            //4. 过滤器 & 转cansetModels候选集 (参考26128-第1步 & 26161-1&2&3);
            return [TCCanset convert2CansetModel:canset sceneFo:sceneModel.scene basePFoOrTargetFoModel:pFo ptAleardayCount:aleardayCount isH:false sceneModel:sceneModel];//1200ms/600次执行
        }];
        
        if (Log4GetCansetResult4R && cansets.count > 0) NSLog(@"\t item场景(%@):%@ 取得候选数:%ld 转成候选模型数:%ld",SceneType2Str(sceneModel.type),Pit2FStr(sceneModel.scene),cansets.count,itemCansetModels.count);
        return itemCansetModels;
    }];
    NSLog(@"第2步 转为候选集 总数:%ld",cansetModels.count);

    //5. 慢思考;
    return [self generalSolution_Slow:demand cansetModels:cansetModels except_ps:except_ps];//400ms
}

/**
 *  MARK:--------------------慢思考--------------------
 *  @desc 思考求解: 前段匹配,中段加工,后段静默 (参考26127);
 *  @version
 *      2022.06.04: 修复结果与当前场景相差甚远BUG: 分三级排序窄出 (参考26194 & 26195);
 *      2022.06.09: 将R和H的慢思考封装成同一方法,方便调用和迭代;
 *      2022.06.09: 弃用阈值方案,改为综合排名 (参考26222-TODO2);
 *      2022.06.12: 每个pFo独立做analyst比对,转为cansetModels (参考26232-TODO8);
 *      2023.02.19: 最终激活后,将match和canset的前段抽具象强度+1 (参考28086-todo2);
 */
+(AICansetModel*) generalSolution_Slow:(DemandModel *)demand cansetModels:(NSArray*)cansetModels except_ps:(NSArray*)except_ps {
    //1. 数据准备;
    [AITest test13:cansetModels];
    except_ps = ARRTOOK(except_ps);
    AICansetModel *result = nil;
    NSLog(@"第5步 Anaylst匹配成功:%ld",cansetModels.count);//测时94条

    //8. 排除不应期;
    cansetModels = [SMGUtils filterArr:cansetModels checkValid:^BOOL(AICansetModel *item) {
        return ![except_ps containsObject:item.cansetFo];
    }];
    NSLog(@"第6步 排除不应期:%ld",cansetModels.count);//测时xx条

    //9. 对下一帧做时间不急评价: 不急 = 解决方案所需时间 <= 父任务能给的时间 (参考:24057-方案3,24171-7);
    cansetModels = [SMGUtils filterArr:cansetModels checkValid:^BOOL(AICansetModel *item) {
        return [AIScore FRS_Time:demand solutionModel:item];
    }];
    NSLog(@"第7步 排除FRSTime来不及的:%ld",cansetModels.count);//测时xx条

    //10. 计算衰后stableScore并筛掉为0的 (参考26128-2-1 & 26161-5);
    //NSArray *outOfFos = [SMGUtils convertArr:cansetModels convertBlock:^id(AICansetModel *obj) {
    //    return obj.cansetFo;
    //}];
    //for (AICansetModel *model in cansetModels) {
    //    AIFoNodeBase *cansetFo = [SMGUtils searchNode:model.cansetFo];
    //    model.stableScore = [TOUtils getColStableScore:cansetFo outOfFos:outOfFos startSPIndex:model.cutIndex + 1 endSPIndex:model.targetIndex];
    //}
    //cansetModels = [SMGUtils filterArr:cansetModels checkValid:^BOOL(AICansetModel *item) {
    //    return item.stableScore > 0;
    //}];
    //NSLog(@"第8步 排序中段稳定性<=0的:%ld",cansetModels.count);//测时xx条

    //TODOTOMORROW20240119: 这里确定能响应到feedback和cutIndex变化后,看能否对排序评分,带来分值变化 (参考31073-TODO2);
    
    
    
    //11. 根据候选集综合分排序 (参考26128-2-2 & 26161-4);
    NSArray *sortModels = [AIRank solutionFoRankingV3:cansetModels];
    demand.rCansetModels = sortModels;

    //13. 取通过S反思的最佳S;
    for (AICansetModel *item in sortModels) {
        BOOL score = [TCRefrection refrection:item demand:demand];
        if (!score) continue;

        //14. 闯关成功,取出最佳,跳出循环;
        result = item;
        break;
    }
    
    //13. 输出前: 可行性检查;
    result = [TCRealact checkRealactAndReplaceIfNeed:result fromCansets:sortModels];

    //14. 返回最佳解决方案;
    if (result) {
        AIFoNodeBase *resultFo = [SMGUtils searchNode:result.cansetFo];
        NSLog(@"慢思考最佳结果:F%ld (前%.2f 中%.2f 后%.2f) %@",result.cansetFo.pointerId,result.frontMatchValue,result.midStableScore,result.backMatchValue,CLEANSTR(resultFo.spDic));

        //15. 更新其前段帧的con和abs抽具象强度 (参考28086-todo2);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.matchFrontIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];

        //16. 更新后段的的具象强度 (参考28092-todo4);
        [AINetUtils updateConAndAbsStrongByIndexDic:result.backIndexDic matchFo:result.sceneFo cansetFo:result.cansetFo];

        //17. 更新其前段alg引用value的强度;
        [AINetUtils updateAlgRefStrongByIndexDic:result.protoFrontIndexDic matchFo:result.cansetFo];
    }
    return result;
}


//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
+(NSInteger) getRAleardayCount:(ReasonDemandModel*)rDemand pFo:(AIMatchFoModel*)pFo{
    //1. 数据准备;
    BOOL isRoot = !rDemand.baseOrGroup;
    TOFoModel *demandBaseFo = (TOFoModel*)rDemand.baseOrGroup;

    //3. 取pFo已发生个数 (参考26232-TODO3);
    NSInteger pFoAleardayCount = 0;
    if (isRoot) {
        //a. 根R任务时 (参考26232-TODO5);
        pFoAleardayCount = pFo.cutIndex + 1;
    }else{
        //b. 子R任务时 (参考26232-TODO6);
        pFoAleardayCount = [SMGUtils filterArr:pFo.indexDic2.allValues checkValid:^BOOL(NSNumber *item) {
            int maskIndex = item.intValue;
            return maskIndex <= demandBaseFo.actionIndex;
        }].count;
    }
    return pFoAleardayCount;
}

+(NSInteger) getHAleardayCount:(TOFoModel*)targetFoM {
    //1. 已发生个数 (targetFo已行为化部分即已发生) (参考26161-模型);
    NSInteger targetFoAleardayCount = targetFoM.actionIndex;
    return targetFoAleardayCount;
}

@end
