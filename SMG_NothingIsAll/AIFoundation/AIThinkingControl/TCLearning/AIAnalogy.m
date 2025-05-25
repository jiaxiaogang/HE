//
//  AIAnalogy.m
//  SMG_NothingIsAll
//
//  Created by jia on 2019/3/20.
//  Copyright © 2019年 XiaoGang. All rights reserved.
//

#import "AIAnalogy.h"
#import "AINetAbsCMVUtil.h"

@implementation AIAnalogy

//MARK:===============================================================
//MARK:                     < 外类比时序 >
//MARK:===============================================================

/**
 *  MARK:--------------------fo外类比 (找相同算法)--------------------
 *  @desc                   : orderSames用于构建absFo
 *  @callers
 *      1. analogy_Feedback_Same()  : 同向反馈类比
 *      2. analogyInner()           : 内类比
 *      3. reasonRethink()          : 反省类比
 *
 *  1. 连续信号中,找重复;(连续也是拆分,多事务处理的)
 *  2. 两条信息中,找交集;
 *  3. 在连续信号的处理中,实时将拆分单信号存储到内存区,并提供可检索等,其形态与最终存硬盘是一致的;
 *  4. 类比处理(瓜是瓜)
 *  注: 类比的处理,是足够细化的,对思维每个信号作类比操作;(而将类比到的最基本的结果,输出给thinking,以供为构建网络的依据,最终是以网络为目的的)
 *  注: 随后可以由一个sames改为多个sames并实时使用block抽象 (并消耗energy);
 *  _param noRepeatArea_ps : 类比结果absFo的防重范围 (默认传nil时,会全局防重);
 *
 *  @version
 *      20200215: 有序外类比: 将forin循环fo和assFo改为反序,并记录上次类比位置jMax (因出现了[果,果,吃,吃]这样的异常时序) 参考n18p11;
 *      20200831: 支持反省外类比,得出更确切的ATSub原因,参考:20205-步骤4;
 *      20201203: 修复21175BUG (因createAbsAlgBlock忘记调用,导致absAlg和glAlg间未关联) (参考21115);
 *      20210819: 修复长1和长2类比时,类比出长2的BUG (参考23221-BUG2);
 *      20210926: 修复glFo外类比时非末位alg类比构建absAlg时,也使用了GLType的问题 (参考24022-BUG1);
 *      20221028: 用mIsC判断替代sameValue_ps (参考27153-todo4);
 *      20230322: 打开外类比,支持(根据相近度将主要责任的码抽象掉)共同点抽象 (参考29025-11);
 *      20230327: 支持得出protoFo/assFo 与 absFo的indexDic映射 (参考29032-todo1.2);
 */
+(AINetAbsFoNode*) analogyOutside:(AIFoNodeBase*)protoFo assFo:(AIFoNodeBase*)assFo type:(AnalogyType)type {
    return [self analogyOutside:protoFo assFo:assFo type:type noRepeatArea_ps:nil];
}
+(AINetAbsFoNode*) analogyOutside:(AIFoNodeBase*)protoFo assFo:(AIFoNodeBase*)assFo type:(AnalogyType)type noRepeatArea_ps:(NSArray*)noRepeatArea_ps {
    //1. 类比orders的规律
    if (Log4Ana) NSLog(@"\n----------- 外类比(%@) -----------\nfo:%@ \nassFo:%@",ATType2Str(type),Fo2FStr(protoFo),Fo2FStr(assFo));
    NSMutableArray *orderSames = [[NSMutableArray alloc] init];
    NSMutableDictionary *protoAssIndexDic = [NSMutableDictionary new];//收集proto和ass的映射;
    if (protoFo && assFo) {

        //2. 外类比有序进行 (记录jMax & 反序)
        NSInteger jMax = assFo.count - 1;
        for (NSInteger i = protoFo.count - 1; i >= 0; i--) {
            for (NSInteger j = jMax; j >= 0; j--) {
                AIKVPointer *protoA_p = protoFo.content_ps[i];
                AIKVPointer *assA_p = assFo.content_ps[j];
                
                //3. B源于matchFo,此处只判断B是1层抽象 (参考27161-调试1&调试2);
                //此处proto抽象仅指向刚识别的matchAlgs,所以与contains等效;
                BOOL mIsC = [TOUtils mIsC_1:protoA_p c:assA_p];
                if (Log4Ana) NSLog(@"proto的第%ld: A%ld 类比 ass的第%ld: A%ld (%@)",i,protoA_p.pointerId,j,assA_p.pointerId,mIsC?@"成功":@"失败");
                if (mIsC) {
                    
                    //4. 即使mIsC匹配,也要进行共同点抽象 (参考29025-11);
                    AIAlgNodeBase *absA = [self analogyAlg:protoA_p assA:assA_p];
                    
                    //TODOTOMORROW20240801: 查下此处为什么M1(饥饿)和A3955(皮果)会有mIsC关系? (参考32132);
                    //日志: alg类比 ===> M1{↑饿-16} : A3955(向90,距13,皮果) = A9585()
                    //日志: alg类比 ===> A4467(向92,距12,果) : A3967(飞↑) = A8471()
                    if (Log4Ana) NSLog(@"alg类比 ===> %@ : %@ = %@",Pit2FStr(protoA_p),Pit2FStr(assA_p),Alg2FStr(absA));
                    
                    //5. 收集并更新jMax;
                    [protoAssIndexDic setObject:@(i) forKey:@(j)];
                    [orderSames insertObject:absA.pointer atIndex:0];
                    jMax = j - 1;
                    break;
                }
            }
        }
    }

    //6. 生成protoIndexDic 和 assIndexDic  (参考29032-todo1.2);
    NSDictionary *assAbsIndexDic = [AINetUtils getIndexDic4AnalogyAbsFo:protoAssIndexDic.allKeys];
    NSDictionary *protoAbsIndexDic = [AINetUtils getIndexDic4AnalogyAbsFo:protoAssIndexDic.allValues];
    
    //7. 外类比构建
    return [self analogyOutside_Creater:orderSames protoFo:protoFo assFo:assFo type:type protoIndexDic:protoAbsIndexDic assIndexDic:assAbsIndexDic noRepeatArea_ps:noRepeatArea_ps];
}

/**
 *  MARK:--------------------外类比的构建器--------------------
 *  1. 构建absFo
 *  2. 构建absCmv
 *  @todo
 *      20200416 - TODO_NEXT_VERSION:方法中absFo是防重的,如果absFo并非新构建,而又为其构建了absMv,则会有多个mv指向同一个fo的问题;
 *  @version
 *      2020.07.22: 在外类比无需构建时 (即具象和抽象一致时),其方向索引强度+1;
 *      2021.08.10: 在RFos的再抽象调用时,有可能将防重的带mvDeltaTime的值重置为0的BUG (参考23212-问题2);
 *      2021.09.23: 构建fo时,新增type参数,废弃原foDS(typeStr)的做法 (参考24019-时序部分);
 *      2021.09.26: 仅构建glFo时才从conNodes取at&ds值,避免SFo也有值的问题 (参考24022-BUG2);
 *      2021.09.28: ATSame和ATDiff两个type是描述是否包含cmv指向的,改为传ATDefault过来 (参考24022-BUG5);
 *      2023.07.28: 把mvDeltaTime改成偏移修正方式 (参考30087-分析1);
 */
+(AINetAbsFoNode*)analogyOutside_Creater:(NSArray*)orderSames protoFo:(AIFoNodeBase*)protoFo assFo:(AIFoNodeBase*)assFo type:(AnalogyType)type protoIndexDic:(NSDictionary*)protoIndexDic assIndexDic:(NSDictionary*)assIndexDic noRepeatArea_ps:(NSArray*)noRepeatArea_ps{
    //2. 数据检查;
    AINetAbsFoNode *result = nil;
    if (ARRISOK(orderSames) && ISOK(protoFo, AIFoNodeBase.class) && ISOK(assFo, AIFoNodeBase.class)) {

        //3. fo和assFo本来就是抽象关系时_直接关联即可;
        BOOL samesEqualAssFo = orderSames.count == assFo.count && [SMGUtils containsSub_ps:orderSames parent_ps:assFo.content_ps];
        BOOL jumpForAbsAlreadyHav = (ISOK(assFo, AINetAbsFoNode.class) && samesEqualAssFo);
        if (jumpForAbsAlreadyHav) {
            result = (AINetAbsFoNode*)assFo;
            [AINetUtils relateFoAbs:result conNodes:@[protoFo] isNew:false];
            [AINetUtils insertRefPorts_AllFoNode:result.pointer order_ps:result.content_ps ps:result.content_ps];
            
            //3. 存储protoFo与matchFo之间的匹配度 (参考33143-方案1);
            [protoFo updateMatchValue:result matchValue:1];
            
            if (result.cmvNode_p) [theNet setMvNodeToDirectionReference:[SMGUtils searchNode:result.cmvNode_p] difStrong:1];
        }else{
            //4. 取foDifStrong
            NSInteger foDifStrong = 1;
            AICMVNodeBase *foMv = [SMGUtils searchNode:protoFo.cmvNode_p];
            AICMVNodeBase *assMv = [SMGUtils searchNode:assFo.cmvNode_p];
            if (foMv && assMv) {
                NSArray *conMvs = [SMGUtils searchNodes:@[protoFo.cmvNode_p,assFo.cmvNode_p]];
                NSInteger absUrgentTo = [AINetAbsCMVUtil getAbsUrgentTo:conMvs];
                foDifStrong = absUrgentTo;
            }
            
            //5. 构建absFoNode (当GL时,传入at&ds);
            HEResult *heResult = [theNet createAbsFo_NoRepeat:orderSames protoFo:protoFo assFo:assFo difStrong:foDifStrong type:type protoIndexDic:protoIndexDic assIndexDic:assIndexDic outConAbsIsRelate:nil noRepeatArea_ps:noRepeatArea_ps];
            result = heResult.data;
            
            //6. 算出具象总强度,其和已经是累计了此次类比的新关联强度 (参考30087-todo6);
            NSArray *conPorts = [AINetUtils conPorts_All:result];
            NSInteger sumStrong = 0;
            for (AIPort *item in conPorts) sumStrong += item.strong.value;
            [AITest test30:sumStrong];
            CGFloat frontMvDeltaTime4Log = result.mvDeltaTime;
            
            //6.1. 将protoFo的mvDeltaTime偏移量计入 (参考30087-todo5&6);
            result.mvDeltaTime += (protoFo.mvDeltaTime - result.mvDeltaTime) / (sumStrong - 1);
            
            //6.2. 将assFo的mvDeltaTime偏移量计入 (参考30087-todo5&6);
            result.mvDeltaTime += (assFo.mvDeltaTime - result.mvDeltaTime) / sumStrong;
            //NSLog(@"偏移mvDeltaTime (从%.2f到%.2f) (总强度:%ld con1:%.2f con2:%.2f) ",frontMvDeltaTime4Log,result.mvDeltaTime,sumStrong,protoFo.mvDeltaTime,assFo.mvDeltaTime);
            
            //6. createAbsCmvNode (当正向类比,且result没有cmv指向时);
            if (protoFo.cmvNode_p && assMv && !result.cmvNode_p) {
                AIAbsCMVNode *resultMv = [theNet createAbsCMVNode_Outside:nil aMv_p:protoFo.cmvNode_p bMv_p:assMv.pointer];
                [AINetUtils relateFo:result mv:resultMv];//cmv模型连接;
            }
        }
    }
    //调试短时序; (先仅打外类比日志);
    NSInteger foStrong = [AINetUtils getStrong:result atConNode:protoFo type:type];
    NSInteger assFoStrong = [AINetUtils getStrong:result atConNode:assFo type:type];
    if (Log4Ana) NSLog(@"1. 新proto: %@\n2. 与ass: %@ \n3. 外类比构建时序: %@->{%@} from: (protoFo(%ld):assFo(%ld))",Fo2FStr(protoFo),Fo2FStr(assFo),Fo2FStr(result),Mvp2Str(result.cmvNode_p),foStrong,assFoStrong);
    return result;
}

/**
 *  MARK:--------------------概念类比--------------------
 *  @desc 概念类比: 将相近度低的(负主要责任的)过滤掉 (参考29025-12);
 *        作用范围: 仅适用于protoA和assA有抽具象关系时的概念类比;
 *  @version
 *      2023.05.10: 修复此处抽具象匹配度未储存,导致复用时取不到的问题 (参考29091);
 *      2024.06.12: 修复M1和M1类比出A13的问题 (因为根据sameValue_ps去进行createAbsAlg_NoRepeat)最终输出的一定是A节点而不是M节点 (参考31187);
 *                  另: M1和M2还是可能生成为Axx,这个是难免的,随后看全部重新训练时: 彻底废弃Mv节点;
 */
+(AIAlgNodeBase*) analogyAlg:(AIKVPointer*)protoA_p assA:(AIKVPointer*)assA_p {
    //0. 如果本就一致;
    //NSLog(@"==============> 概念类比：protoA%ld assA%ld",protoA_p.pointerId,assA_p.pointerId);
    if ([protoA_p isEqual:assA_p]) return [SMGUtils searchNode:protoA_p];

    //1. 数据准备;
    AIAlgNodeBase *protoA = [SMGUtils searchNode:protoA_p];
    AIAlgNodeBase *assA = [SMGUtils searchNode:assA_p];
    NSMutableArray *sameValue_ps = [[NSMutableArray alloc] init];
    AIMatchAlgModel *protoAbsModel4MatchValue = [[AIMatchAlgModel alloc] init];//此模型仅用于收集proto和abs的相近度,用于计算matchValue;
    if (!assA) return nil;
    
    //2. 数据检查（当前有主责，直接剔除）（时序全含，概念以mIsC来剔除，不做责任计算）。
    CGFloat curMatchValue = [protoA getAbsMatchValue:assA_p];
    //if (![TCLearningUtil noZeRenForCenJi:curMatchValue bigerMatchValue:1]) return nil;//识别时序全含，此处默认匹配度为1。

    //11. 分别对protoA和assA的稀疏码进行对比;
    //2025.04.06: 在概念识别时，不要求全含了，所以有些特征间是没有映射的，它的位置符合字典也是空，所以此处改为只类比有indexDic映射的部分（参考概念识别算法）。
    NSDictionary *indexDic = [protoA getAbsIndexDic:assA_p];
    for (NSNumber *key in indexDic.allKeys) {
        NSInteger assIndex = key.integerValue;
        NSInteger protoIndex = NUMTOOK([indexDic objectForKey:key]).integerValue;
        AIKVPointer *protoV_p = ARR_INDEX(protoA.content_ps, protoIndex);
        AIKVPointer *assV_p = ARR_INDEX(assA.content_ps, assIndex);

        //12. 非同区过滤;
        if (![protoV_p.dataSource isEqualToString:assV_p.dataSource] || ![protoV_p.algsType isEqualToString:assV_p.algsType]) continue;

        //21. ======== 兼容新版组码特征 ========
        if (PitIsFeature(protoV_p) || PitIsFeature(assV_p)) {
            AIFeatureNode *absT = [self analogyFeature:protoV_p ass:assV_p bigerMatchValue:curMatchValue];
            if (!absT) continue;
            CGFloat valueMatchValue = [absT getConMatchValue:protoA_p];
            [sameValue_ps addObject:absT.p];

            //22. 相近度个数nearCount & 相近度sumNear
            protoAbsModel4MatchValue.nearCount++;
            protoAbsModel4MatchValue.sumNear *= valueMatchValue;
            continue;
        }

        //31. ======== 保留旧版单码特征 ========
        //32. 二者相似度较高时 (计算当前码的责任比例: 比如:1*0.8*0.7时,当前码=0.7时,它的责任比例=(1-0.7)/(1-0.8 + 1-0.7)=60%) (参考29025-13);
        MapModel *analogyValueResult = [self analogyValue:protoV_p assV:assV_p bigerMatchValue:curMatchValue];

        //33. 当前码责任<50%时 (次要责任时,免责);
        if (analogyValueResult) {
            AIKVPointer *absV_p = analogyValueResult.v1;
            CGFloat valueMatchValue = NUMTOOK(analogyValueResult.v2).floatValue;
            [sameValue_ps addObject:absV_p];

            //34. 相近度个数nearCount & 相近度sumNear
            protoAbsModel4MatchValue.nearCount++;
            protoAbsModel4MatchValue.sumNear *= valueMatchValue;
        } else {
            if (Log4Ana) NSLog(@"> 当前A%ld<%@>比A%ld<%@>",(long)protoA_p.pointerId,Pit2FStr(protoV_p),(long)assA_p.pointerId,Pit2FStr(assV_p));
        }
        //35. 继续判断proto的下个V码;
    }

    //41. 将相近度善可的构建成抽象概念返回;
    [AITest test29:protoA assA:assA];
    AIAbsAlgNode *absA = [theNet createAbsAlg_NoRepeat:sameValue_ps conAlgs:@[protoA,assA]];
    [absA updateLogDescDic:protoA.logDesc];
    [absA updateLogDescDic:assA.logDesc];

    //42. 将抽象概念与具象的匹配度存下来 (参考29091BUG);
    [protoA updateMatchValue:absA matchValue:protoAbsModel4MatchValue.matchValue];
    [assA updateMatchValue:absA matchValue:1];
    [AITest test25:absA conNodes:@[protoA,assA]];
    return absA;
}

/**
 *  MARK:--------------------特征类比--------------------
 *  @desc 冷启无共同交层时，调用JvBu。
 *  @desc 然后有共同交层后，调用ZenTi。
 *  @version
 *      2025.03.21: 使用mIsC正序双循环来实现特征类比 (参考34062-方案1);
 *      2025.03.21: 改用indexDic映射来实现特征类比 (参考34062-方案2);
 *      2025.03.31: 改为调用组码类比v2。
 */
+(AIFeatureNode*) analogyFeature:(AIKVPointer*)protoT_p ass:(AIKVPointer*)assT_p bigerMatchValue:(CGFloat)bigerMatchValue {
    //1. 数据准备。
    //NSLog(@"==============> 特征类比：protoT%ld assT%ld",protoT_p.pointerId,assT_p.pointerId);
    if ([protoT_p isEqual:assT_p]) return [SMGUtils searchNode:assT_p];
    AIFeatureNode *protoFeature = [SMGUtils searchNode:protoT_p];
    AIFeatureNode *assFeature = [SMGUtils searchNode:assT_p];
    
    //2. 局部冷启 或 整体识别：类比依据不同（参考34139-TODO1）。
    //11. 取共同absT，借助absT进行类比（参考34139-TODO1）。
    //2025.04.19: 必须是当前protoT识别时的zenTiModel才行，如果是往期zenTiModel不能用，会导致类比找protoT对应不上，导致取rect为Null的BUG。
    if (assFeature.zenTiModel && [assFeature.zenTiModel.protoT isEqual:protoT_p]) {
        //12. 借助absT来类比时，复用ZenTi的识别结果model数据，并且用完就清空，防止循环野指针（参考34139-TODO3）。
        AIFeatureZenTiModel *zenTiModel = assFeature.zenTiModel;
        assFeature.zenTiModel = nil;
        return [self analogyFeature_ZenTi:protoFeature ass:assFeature bigerMatchValue:bigerMatchValue zenTiModel:zenTiModel];
    }
    //21. 特征识别step1识别到的结果，复用indexDic进行类比。
    else if(assFeature.jvBuModel && [protoT_p isEqual:assFeature.jvBuModel.v2] ) {
        //22. 用于类比的数据用完就删，避免太占空间（参考34137-TODO2）。
        NSDictionary *indexDic = assFeature.jvBuModel.v1;
        return [self analogyFeature_JvBu:protoFeature ass:assFeature bigerMatchValue:bigerMatchValue indexDic:indexDic];
    }
    return nil;
}

+(AIFeatureNode*) analogyFeature_JvBu:(AIFeatureNode*)protoFeature ass:(AIFeatureNode*)assFeature bigerMatchValue:(CGFloat)bigerMatchValue indexDic:(NSDictionary*)indexDic {
    //NSLog(@"==============> 特征类比Step1：protoT%ld assT%ld",protoFeature.pId,assFeature.pId);
    //1. 类比orders的规律
    CGFloat sumProtoMatchValue = 0;
    CGFloat sumProtoMatchDegree = 0;
    
    //2. 数据检查（当前有主责，直接剔除）。
    //BUG-2025.03.24: 先关掉，不然信息量大的特征，因为能者多错（像HSB里，HS全是躺赢狗，只有B信息量大，同时差异性也大，这里会判B全责）。
    //思路-除非引入信息量，即HSB不同信息量时，各自责任占比也不同，不然很难判准，先注掉吧，后续确实需要修此BUG时再来搞。
    CGFloat curMatchValue = [protoFeature getAbsMatchValue:assFeature.p];
    //BOOL noZeRen = [TCLearningUtil noZeRenForCenJi:curMatchValue bigerMatchValue:bigerMatchValue];
    //if (!noZeRen) return nil;
    NSDictionary *degreeDic = DICTOOK([protoFeature getDegreeDic:assFeature.pId]);
    
    //3. 收集有效的映射：用于后面计算rect用。
    NSMutableDictionary *validIndexDic = [[NSMutableDictionary alloc] init];
    
    //11. 外类比有序进行 (记录jMax & 正序)
    for (NSNumber *key in indexDic.allKeys) {
        NSNumber *value = [indexDic objectForKey:key];
        NSInteger assIndex = key.integerValue;
        NSInteger protoIndex = value.integerValue;
        AIKVPointer *protoG_p = ARR_INDEX(protoFeature.content_ps, protoIndex);
        AIKVPointer *assG_p = ARR_INDEX(assFeature.content_ps, assIndex);
        if (![degreeDic objectForKey:@(assIndex)]) {
            ELog(@"查下为什么没存上符合度，没符合度会导致protoG和assG的匹配度算成0 getDegreeDic %ld %ld %@",protoFeature.p.pointerId,assFeature.p.pointerId,CLEANSTR(degreeDic));
        }
        CGFloat curDegree = NUMTOOK([degreeDic objectForKey:@(assIndex)]).floatValue;
        if (Log4Ana) NSLog(@"proto的第%ld: G%ld 类比 ass的第%ld: G%ld",protoIndex,protoG_p.pointerId,assIndex,assG_p.pointerId);
        
        //12. 调用GV类比V2: 即使mIsC匹配,也要进行共同点抽象 (参考29025-11);
        MapModel *analogyGVResult = [self analogyGroupValueV2:protoG_p assG:assG_p curDegree:curDegree bigerMatchValue:curMatchValue];
        if (!analogyGVResult) continue;
        sumProtoMatchValue += NUMTOOK(analogyGVResult.v2).floatValue;
        sumProtoMatchDegree += curDegree;
        
        //13. 收集有效的映射：用于后面计算rect用。
        [validIndexDic setObject:value forKey:key];
    }
    
    //14. 根据validIndexDic求出newAbsT在protoT和assT中的rect。
    CGRect absAtProtoRect = [AINetUtils convertPartOfFeatureContent2Rect:protoFeature contentIndexes:validIndexDic.allValues];
    CGRect absAtAssRect = [AINetUtils convertPartOfFeatureContent2Rect:assFeature contentIndexes:validIndexDic.allKeys];
    
    //15. 转为List<InputGroupValueModel>模型。
    NSMutableArray *absGVModels = [SMGUtils convertArr:validIndexDic.allKeys convertBlock:^id(NSNumber *key) {
        NSInteger assIndex = key.integerValue;
        AIKVPointer *assGV_p = ARR_INDEX(assFeature.content_ps, assIndex);
        
        //16. 将gvRect在assT的范围，转成在newAbsT中的位置。
        CGRect assRect = VALTOOK(ARR_INDEX(assFeature.rects, assIndex)).CGRectValue;
        assRect.origin.x -= absAtAssRect.origin.x;
        assRect.origin.y -= absAtAssRect.origin.y;
        return [InputGroupValueModel new:assGV_p rect:assRect];
    }];
    if (curMatchValue == 1 && absGVModels.count == 0) {
        ELog(@"如果匹配度为1，会导致所有indexDic的GV全有责，导致最后absGVModels为0条，如果停此处时，查下来源，这个匹配度1是哪来的");
    }
    if (!ARRISOK(absGVModels)) return nil;
    
    //21. 为增加特征content_ps的有序性：对groupModels进行排序（特征的content是有序的，所以要先排下序）。
    NSArray *sortGroupModels = [ThinkingUtils sortInputGroupValueModels:absGVModels];
    
    //31. 外类比构建
    AIFeatureNode *absT = [AIGeneralNodeCreater createFeatureNode:sortGroupModels conNodes:@[protoFeature,assFeature] at:protoFeature.p.algsType ds:protoFeature.p.dataSource isOut:protoFeature.p.isOut isJiao:true];
    [absT updateLogDescDic:protoFeature.logDesc];
    [absT updateLogDescDic:assFeature.logDesc];
    
    //32. 更新匹配度 & 映射;
    //2025.04.12: 先不存特征的indexDic映射了，太占空间（参考34137-TODO2）。
    [protoFeature updateMatchValue:absT matchValue:sumProtoMatchValue / absT.count];
    [assFeature updateMatchValue:absT matchValue:1];
    //[protoFeature updateIndexDic:absT indexDic:protoAbsIndexDic];
    //[assFeature updateIndexDic:absT indexDic:assAbsIndexDic];
    
    //33. 存conPorts的rect（参考34135-TODO1）。
    [AINetUtils updateConPortRect:absT conT:protoFeature.p rect:absAtProtoRect];
    [AINetUtils updateConPortRect:absT conT:assFeature.p rect:absAtAssRect];
    
    //34. 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
    [protoFeature updateMatchDegree:absT matchDegree:sumProtoMatchDegree / absT.count];
    [assFeature updateMatchDegree:absT matchDegree:1];
    
    if (Log4Ana || true) NSLog(@"\n局部特征类比结果(%@) ======================> \n局部Proto特征T%ld（GV数:%ld）%@\n%@局部Ass特征T%ld（GV数:%ld）%@\n%@局部Abs特征T%ld（GV数:%ld）：%@\n%@",protoFeature.p.dataSource,
                               protoFeature.pId,protoFeature.count,CLEANSTR([protoFeature getLogDesc:false]),FeatureDesc(protoFeature.p,1),
                               assFeature.pId,assFeature.count,CLEANSTR([assFeature getLogDesc:false]),FeatureDesc(assFeature.p,1),
                               absT.pId,sortGroupModels.count,CLEANSTR([absT getLogDesc:false]),FeatureDesc(absT.p,1));
    return absT;
}

+(AIFeatureNode*) analogyFeature_JvBu_V2:(AIFeatureJvBuModel*)jvBuModel {
    //NSLog(@"==============> 特征类比Step1：protoT%ld assT%ld",protoFeature.pId,assFeature.pId);
    //3. 收集有效的映射：用于后面计算rect用。
    NSMutableArray *validItems = [[NSMutableArray alloc] init];
    
    //11. 外类比有序进行 (记录jMax & 正序)
    for (AIFeatureJvBuItem *item in jvBuModel.bestGVs) {
        //12. 当前有主责，直接剔除: GV类比: 进行共同点抽象 (参考29025-11);
        CGFloat curDegree = item.matchDegree;
        CGFloat curMatchValue = item.matchValue;
        BOOL noZeRen = [TCLearningUtil noZeRenForPingJun:curMatchValue * curDegree bigerMatchValue:jvBuModel.matchValue * jvBuModel.matchDegree];
        if (!noZeRen) continue;
        
        //13. 当前码责任<50%时 (次要责任时,免责): 收集有效的映射：用于后面计算rect用。
        [validItems addObject:item];
    }
    
    //14. 根据validIndexDic求出newAbsT在protoT和assT中的rect。
    NSArray *sortValidItems = [SMGUtils sortSmall2Big:validItems compareBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.assIndex;
    }];
    NSArray *assContentIndexes = [SMGUtils convertArr:sortValidItems convertBlock:^id(AIFeatureJvBuItem *obj) {
        return @(obj.assIndex);
    }];
    CGRect absAtAssRect = [AINetUtils convertPartOfFeatureContent2Rect:jvBuModel.assT contentIndexes:assContentIndexes];
    
    
    
    
    //TODOTOMORROW20250525: 这里absAtAssR就是absAtProto了，查下此处absAtAssRect是不是应该把xy归0？assT有多大，似乎与protoT占了同样大的画布？
    
    
    
    //15. 转为List<InputGroupValueModel>模型。
    NSMutableArray *absGVModels = [SMGUtils convertArr:sortValidItems convertBlock:^id(AIFeatureJvBuItem *obj) {
        AIKVPointer *assGV_p = ARR_INDEX(jvBuModel.assT.content_ps, obj.assIndex);
        
        //16. 将gvRect在assT的范围，转成在newAbsT中的位置。
        CGRect assRect = VALTOOK(ARR_INDEX(jvBuModel.assT.rects, obj.assIndex)).CGRectValue;
        assRect.origin.x -= absAtAssRect.origin.x;
        assRect.origin.y -= absAtAssRect.origin.y;
        if (assRect.size.width != assRect.size.height || assRect.size.width == 0 || assRect.size.height == 0) {
            ELog(@"assRect数据异常: 宽高不一致，或宽高为0");
        }
        return [InputGroupValueModel new:assGV_p rect:assRect];
    }];
    if (jvBuModel.matchValue == 1 && absGVModels.count == 0) {
        ELog(@"如果匹配度为1，会导致所有indexDic的GV全有责，导致最后absGVModels为0条，如果停此处时，查下来源，这个匹配度1是哪来的");
    }
    if (!ARRISOK(absGVModels)) return nil;
    
    //21. 为增加特征content_ps的有序性：对groupModels进行排序（特征的content是有序的，所以要先排下序）。
    NSArray *sortGroupModels = [ThinkingUtils sortInputGroupValueModels:absGVModels];
    
    //31. 外类比构建
    AIFeatureNode *absT = [AIGeneralNodeCreater createFeatureNode:sortGroupModels conNodes:@[jvBuModel.assT] at:jvBuModel.assT.at ds:jvBuModel.assT.ds isOut:jvBuModel.assT.isOut isJiao:true];
    [absT updateLogDescDic:jvBuModel.assT.logDesc];
    
    //32. 更新匹配度;
    //TODO: 考虑下，此处abs是从ass抽象来的，那这里的匹配度，符合度，是不是应该直接=1。
    CGFloat absMatchValue = validItems.count == 0 ? 0 : [SMGUtils sumOfArr:validItems convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.matchValue;
    }] / validItems.count;
    [jvBuModel.assT updateMatchValue:absT matchValue:absMatchValue];
    
    //33. 存conPorts的rect（参考34135-TODO1）。
    [AINetUtils updateConPortRect:absT conT:jvBuModel.assT.p rect:absAtAssRect];
    
    //34. 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
    CGFloat absMatchDegree = validItems.count == 0 ? 0 : [SMGUtils sumOfArr:validItems convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.matchDegree;
    }] / validItems.count;
    [jvBuModel.assT updateMatchDegree:absT matchDegree:absMatchDegree];
    
    //41. debugLog
    NSLog(@"局部识别类比结果absT长度：%ld",absT.count);
    [SMGUtils runByMainQueue:^{
        //[theApp.imgTrainerView setDataForJvBuModelV2:jvBuModel lab:STRFORMAT(@"assT%ld(GV%ld/%ld)",jvBuModel.assT.pId,jvBuModel.bestGVs.count,jvBuModel.assT.count)];
        //[theApp.imgTrainerView setDataForFeature:absT lab:STRFORMAT(@"类比absT%ld",absT.pId)];
    }];
    if (Log4Ana || true) NSLog(@"\n局部特征类比结果(%@) ======================> \n局部Ass特征T%ld（GV数:%ld）%@\n%@局部Abs特征T%ld（GV数:%ld）：%@\n%@",jvBuModel.assT.ds,
                               jvBuModel.assT.pId,jvBuModel.assT.count,CLEANSTR([jvBuModel.assT getLogDesc:false]),FeatureDesc(jvBuModel.assT.p,1),
                               absT.pId,sortGroupModels.count,CLEANSTR([absT getLogDesc:false]),FeatureDesc(absT.p,1));
    return absT;
}

+(AIFeatureNode*) analogyFeature_ZenTi:(AIFeatureNode*)protoT ass:(AIFeatureNode*)assT bigerMatchValue:(CGFloat)bigerMatchValue zenTiModel:(AIFeatureZenTiModel*)zenTiModel {
    //NSLog(@"==============> 特征类比Step2：protoT%ld assT%ld",protoT.pId,assT.pId);
    //1. 借助每个absT来实现整体T的类比：类比orders的规律: 类比rectItems，把责任超过50%的去掉，别的保留（参考34139）。
    NSArray *sameItems = [SMGUtils filterArr:zenTiModel.rectItems checkValid:^BOOL(AIFeatureZenTiItem_Rect *obj) {
        return [TCLearningUtil noZeRenForPingJun:obj.itemMatchValue * obj.itemMatchDegree bigerMatchValue:zenTiModel.modelMatchValue * zenTiModel.modelMatchDegree];
    }];
    
    //11. 将每个absT指向具象整体特征的rect求并集，得出加一块儿的绝对rect范围（参考3413a-示图2）。
    CGRect newAbsAtAssRect = CGRectNull;
    for (AIFeatureZenTiItem_Rect *item in sameItems) {
        //12. 取并每个itemAbsT在assT的范围。
        newAbsAtAssRect = CGRectUnion(newAbsAtAssRect, item.itemAtAssRect);
    }
    
    //20. 根据protoT和itemAbsT的映射来实现类比抽象（参考34164-方案2）。
    //2025.04.23: 修复收集到的absGVModels数竟然有达到1000的情况，改为通过protoT和itemAbsT的映射，收集protoT的gv元素做抽象。
    NSMutableArray *protoIndexes = [SMGUtils convertArr:sameItems convertItemArrBlock:^NSArray *(AIFeatureZenTiItem_Rect *item) {
        AIFeatureNode *itemAbsT = [SMGUtils searchNode:item.fromItemT];
        MapModel *jvBuModel = itemAbsT.jvBuModel;
        if (!jvBuModel || ![protoT.p isEqual:jvBuModel.v2]) {
            ELog(@"Step2借助JvBuModel来找映射，找类比抽象gv元素，这里的jvBuModel都不为空才对，因为itemAbsT都是由局部特征识别来的，如果为空查下原因。");
            return nil;
        }
        NSDictionary *protoItemAbsTIndexDic = jvBuModel.v1;
        return protoItemAbsTIndexDic.allValues;
    }];
    protoIndexes = [SMGUtils removeRepeat:protoIndexes];
    
    //21. 取newAbs在protoT的rect，可以用protoIndexes来算，也可以用itemAbsT的具象conPort中来收集，效果是一样的（参考34135-TODO1）。
    CGRect newAbsAtProtoRect = [AINetUtils convertPartOfFeatureContent2Rect:protoT contentIndexes:protoIndexes];
    
    //22. 取出每个itemAbsT中的gv，转换成newAbsT的元素：@[InputGroupValueModel]格式（参考3413a-示图1）。
    NSMutableArray *absGVModels = [SMGUtils convertArr:protoIndexes convertBlock:^id(NSNumber *protoIndex) {
        
        //23. 从protoT中收集元素（参考34164-方案2）。
        AIKVPointer *protoGV_p = ARR_INDEX(protoT.content_ps, protoIndex.integerValue);
        
        //24. 将gvRect在protoT的范围，转成在newAbsT中的位置。
        CGRect gvRect = VALTOOK(ARR_INDEX(protoT.rects, protoIndex.integerValue)).CGRectValue;
        gvRect.origin.x -= newAbsAtProtoRect.origin.x;
        gvRect.origin.y -= newAbsAtProtoRect.origin.y;
        return [InputGroupValueModel new:protoGV_p rect:gvRect];
    }];
    
    //31. 为增加特征content_ps的有序性：对groupModels进行排序（特征的content是有序的，所以要先排下序）。
    NSArray *sortGroupModels = [ThinkingUtils sortInputGroupValueModels:absGVModels];
    
    //33. 保留下来的生成为absT。
    AIFeatureNode *absT = [AIGeneralNodeCreater createFeatureNode:sortGroupModels conNodes:@[protoT,assT] at:protoT.p.algsType ds:protoT.p.dataSource isOut:protoT.p.isOut isJiao:true];
    
    //41. 更新logDesc。
    [absT updateLogDescDic:protoT.logDesc];
    [absT updateLogDescDic:assT.logDesc];
    
    //2025.04.23: 改为由protoT来收集absGVModels了，所以与protoT的匹配度符合度全是1，与assT的匹配度符合度直接重用zenTiModel的。
    //42. 记录匹配度：根据每个匹配itemAbsT，来计算平均匹配度。
    [protoT updateMatchValue:absT matchValue:1];
    [assT updateMatchValue:absT matchValue:zenTiModel.modelMatchValue];
    
    //43. 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
    [protoT updateMatchDegree:absT matchDegree:1];
    [assT updateMatchDegree:absT matchDegree:zenTiModel.modelMatchDegree];
    
    //44. 记录整体absT.conPort到protoT和assT的rect。
    [AINetUtils updateConPortRect:absT conT:protoT.p rect:newAbsAtProtoRect];
    [AINetUtils updateConPortRect:absT conT:assT.p rect:newAbsAtAssRect];
    
    //51. debug
    if (Log4Ana || true) NSLog(@"\n整体特征类比结果(%@) ======================> \n整体Proto特征T%ld（局部特征数:%ld GV数:%ld）%@\n%@整体Ass特征T%ld（局部特征数:%ld GV数:%ld）%@\n%@整体Abs特征T%ld（局部特征数:%ld GV数:%ld）：%@\n%@",protoT.p.dataSource,
                               protoT.pId,sameItems.count,protoT.count,CLEANSTR([protoT getLogDesc:false]),FeatureDesc(protoT.p,1),
                               assT.pId,sameItems.count,assT.count,CLEANSTR([assT getLogDesc:false]),FeatureDesc(assT.p,1),
                               absT.pId,sameItems.count,absGVModels.count,CLEANSTR([absT getLogDesc:false]),FeatureDesc(absT.p,1));
    return absT;
}

+(AIFeatureNode*) analogyFeature_ZenTi_V2:(AIGroupFeatureNode*)protoGT assModel:(AIFeatureZenTiModel*)assModel {
    AIGroupFeatureNode *assGT = [SMGUtils searchNode:assModel.assT];
    //NSLog(@"==============> 特征类比Step2：protoT%ld assT%ld",protoT.pId,assT.pId);
    //1. 借助每个absT来实现整体T的类比：类比orders的规律: 类比rectItems，把责任超过50%的去掉，别的保留（参考34139）。
    NSArray *sameItems = [SMGUtils filterArr:assModel.rectItems checkValid:^BOOL(AIFeatureZenTiItem_Rect *obj) {
        return [TCLearningUtil noZeRenForPingJun:obj.itemMatchDegree bigerMatchValue:assModel.modelMatchDegree];
    }];
    if (!ARRISOK(sameItems)) return nil;
    
    //11. 将每个absT指向具象整体特征的rect求并集，得出加一块儿的绝对rect范围（参考3413a-示图2）。
    CGRect newAbsAtAssRect = CGRectNull;
    for (AIFeatureZenTiItem_Rect *item in sameItems) {
        //取并每个itemAbsT在assT的范围。
        newAbsAtAssRect = CGRectUnion(newAbsAtAssRect, item.itemAtAssRect);
    }
    
    //12. 取newAbs在protoT的rect，可以用局部特征识别结果中的itemAbsTAtProtoRect来求并集（目前不需要，因为没有protoT，也用不着这个AtProtoTRect）。
    NSArray *protoGTIndexes = [SMGUtils convertArr:sameItems convertBlock:^id(AIFeatureZenTiItem_Rect *obj) {
        return @(obj.protoGTIndex);
    }];
    CGRect newAbsAtProtoRect = [AINetUtils convertPartOfFeatureContent2Rect:protoGT contentIndexes:protoGTIndexes];
    
    //20. 根据protoT和itemAbsT的映射来实现类比抽象（参考34164-方案2）。
    //2025.05.08: 注意-我们无法从protoT来抽象gvs了，也没法从整体特征assT来抽象gvs（因为它与itemAbsT没有映射，我们无法对应到该取哪个下标）。
    //2025.05.08: 说明-所以我们只能从itemAbsT中取gvs，那么这里就有一个要求：itemAbsT中的元素必须来自自身具象，不允许抽象t时，gv有变化，不然每个itemAbsT中的对应gv不同，会重复收集。
    //2025.05.08: 举例-说白了：从乔峰抽象的胳膊腿特征必须是乔峰的，不能是别人的。
    //21. 取出每个itemAbsT中的gv，转换成newAbsT的元素：@[InputGroupValueModel]格式（参考3413a-示图1）。
    NSMutableArray *absTModels = [SMGUtils convertArr:sameItems convertBlock:^id(AIFeatureZenTiItem_Rect *zenTiItem) {
        return [InputGroupFeatureModel new:zenTiItem.fromItemT rect:zenTiItem.itemAtAssRect];
    }];
    
    //33. 构建：保留下来的生成为absT。
    AIGroupFeatureNode *absGT = [AIGeneralNodeCreater createGroupFeatureNode:absTModels conNodes:@[protoGT,assGT] at:assGT.at ds:assGT.ds isOut:assGT.isOut isJiao:true];
    
    //34. debugRect
    //for (NSInteger i = 0; i < absGT.count; i++) {
    //    AIKVPointer *item = ARR_INDEX(absGT.content_ps, i);
    //    NSValue *itemRect = ARR_INDEX(absGT.rects, i);
    //    AIPort *refPort = [AINetUtils getRefPort:item biger:absGT.p refRect:itemRect.CGRectValue];
    //    NSLog(@"2025.05.27后可删aaaaa1 %ld:%ld > %@ : %@",item.pointerId,absGT.pId,itemRect,@(refPort.rect));
    //}
    
    //41. 更新logDesc。
    [absGT updateLogDescDic:assGT.logDesc];
    [absGT updateLogDescDic:protoGT.logDesc];
    
    //2025.04.23: 改为由protoT来收集absGVModels了，所以与protoT的匹配度符合度全是1，与assT的匹配度符合度直接重用zenTiModel的。
    //42. 记录匹配度：根据每个匹配itemAbsT，来计算平均匹配度。
    [assGT updateMatchValue:absGT matchValue:1];//此处abs是从ass抽象来的，那这里的匹配度直接=1。
    [protoGT updateMatchValue:absGT matchValue:1];//此处protoGT是从sameItems这些局部特征构建成的，所以匹配也直接=1。
    
    //43. 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
    [assGT updateMatchDegree:absGT matchDegree:1];
    [protoGT updateMatchDegree:absGT matchDegree:[SMGUtils sumOfArr:sameItems convertBlock:^double(AIFeatureZenTiItem_Rect *obj) {
        return obj.itemMatchDegree;
    }] / sameItems.count];
    
    //44. 记录整体absT.conPort到protoT和assT的rect。
    [AINetUtils updateConPortRect:absGT conT:assGT.p rect:newAbsAtAssRect];
    [AINetUtils updateConPortRect:absGT conT:protoGT.p rect:newAbsAtProtoRect];
    //[SMGUtils runByMainQueue:^{
    //    [theApp.imgTrainerView setDataForFeature:assGT lab:STRFORMAT(@"assGT%ld",assGT.pId)];
    //    [theApp.imgTrainerView setDataForFeature:absGT lab:STRFORMAT(@"absGT%ld",absGT.pId)];
    //}];
    
    //51. debug
    if (Log4Ana || true) NSLog(@"\n整体特征类比结果(%@) ======================> \n整体Ass特征T%ld（局部特征数:%ld GV数:%ld）%@\n%@整体Abs特征T%ld（局部特征数:%ld GV数:%ld）：%@\n%@",assGT.ds,
                               assGT.pId,sameItems.count,assGT.count,CLEANSTR([assGT getLogDesc:false]),FeatureDesc(assGT.p,1),
                               absGT.pId,sameItems.count,absTModels.count,CLEANSTR([absGT getLogDesc:false]),FeatureDesc(absGT.p,1));
    return absGT;
}

/**
 *  MARK:--------------------组码类比V2--------------------
 *  @version
 *      2025.03.31: v2-因组码索引迭代为三个索引后，这里也改下，不再向单码探进了，直接参考单码类比，在组码类比这儿把assG返回就行了。
 */
+(MapModel*) analogyGroupValueV2:(AIKVPointer*)protoG_p assG:(AIKVPointer*)assG_p curDegree:(CGFloat)curDegree bigerMatchValue:(CGFloat)bigerMatchValue {
    //1. 数据准备;
    AIGroupValueNode *protoG = [SMGUtils searchNode:protoG_p];
    if (!protoG || !assG_p) return nil;
    
    //2. 数据检查（当前有主责，直接剔除）。
    CGFloat curMatchValue = [protoG getAbsMatchValue:assG_p];
    BOOL noZeRen = [TCLearningUtil noZeRenForPingJun:curMatchValue * curDegree bigerMatchValue:bigerMatchValue];
    if (!noZeRen) return nil;
    
    //3. 当前码责任<50%时 (次要责任时,免责);
    return [MapModel newWithV1:assG_p v2:@(curMatchValue) v3:@(curDegree)];
}

/**
 *  MARK:--------------------单码类比--------------------
 */
+(MapModel*) analogyValue:(AIKVPointer*)protoV_p assV:(AIKVPointer*)assV_p bigerMatchValue:(CGFloat)bigerMatchValue {
    //31. 二者相似度较高时 (计算当前码的责任比例: 比如:1*0.8*0.7时,当前码=0.7时,它的责任比例=(1-0.7)/(1-0.8 + 1-0.7)=60%) (参考29025-13);
    CGFloat valueMatchValue = [AIAnalyst compareCansetValue:protoV_p protoValue:assV_p vInfo:nil];
    BOOL noZeRen = [TCLearningUtil noZeRenForCenJi:valueMatchValue bigerMatchValue:bigerMatchValue];
    
    //32. 当前码责任<50%时 (次要责任时,免责);
    if (noZeRen) {
        return [MapModel newWithV1:assV_p v2:@(valueMatchValue)];
    }
    return nil;
}

/**
 *  MARK:--------------------Canset类比 --------------------
 *  @noRepeatArea_ps 防重(一般取sceneTo以前的cansets);
 *  @version
 *      xxxx.xx.xx: 初版 (参考29025-24 & 29027-方案3);
 *      2023.03.27: 支持得出newCansetFo/oldCansetFo 与 absCansetFo的indexDic映射 (参考29032-todo1.1);
 *      2023.04.07: 关闭Canset类比 (参考29059-改动);
 *      2023.04.10: 场景包含帧的类比用mIsC判断成立后,直接采用absAlg (参考29067-todo1.1);
 *      2023.04.19: 取消EFF+1,因为迁移完成不表示已正向发生 (参考29069-todo12.1);
 *      2023.04.29: 得出absCanset和scene的indexDic (参考29076-todo2);
 *      2023.09.01: 迁移完成时EFF不变(参数传ES_Default),但newCanset有用时+1,无用时-1 (参考30124-todo2 & todo3);
 *      2023.09.03: 修复dic.keys无序会导致此处生成的absFo序列也错乱的问题;
 *      2023.10.26: 废弃canset类比 (参考3014c-todo2);
 *      2024.09.13: 启用canset类比: 直接用反馈映射realCansetToIndexDic,来生成Canset类比结果 (参考33052-TODO1);
 *      2025.03.13: 迭代V3：用new和old两个orders得出absOrders（参考33174-TODO1）。
 */
+(HEResult*) analogyCansetFoV3:(NSArray*)newCansetOrders oldCansetOrders:(NSArray*)oldCansetOrders oldCansetISceneIndexDic:(NSDictionary*)oldCansetISceneIndexDic {
    //1. 类比orders的规律
    NSMutableArray *absCansetOrders = [[NSMutableArray alloc] init];
    NSMutableDictionary *absCansetOldCansetIndexDic = [NSMutableDictionary new];//收集abs和old的映射;

    //2. 外类比有序进行 (记录jMax & 反序)
    NSInteger jStart = 0;
    for (NSInteger i = 0; i < newCansetOrders.count; i++) {
        for (NSInteger j = jStart; j < oldCansetOrders.count; j++) {
            AIShortMatchModel_Simple *newItem = ARR_INDEX(newCansetOrders, i);
            AIShortMatchModel_Simple *oldItem = ARR_INDEX(oldCansetOrders, j);
            
            //3. B源于matchFo,此处只判断B是1层抽象 (参考27161-调试1&调试2);
            //此处proto抽象仅指向刚识别的matchAlgs,所以与contains等效;
            BOOL mIsC = [TOUtils mIsC_1:newItem.alg_p c:oldItem.alg_p];
            if (mIsC) {
                //4. 收集并更新j进度;
                [absCansetOrders addObject:oldItem];
                [absCansetOldCansetIndexDic setObject:@(j) forKey:@(absCansetOrders.count - 1)];
                jStart = j + 1;
                break;
            }
        }
    }
    
    //5. 计算出absCansetFo的和iScene之间的indexDic (参考27207-7至11 & 33174-TODO2);
    //2024.04.16: 此处简化了下,把用convertOldIndexDic2NewIndexDic()取映射,改成用zonHeDic来计算;
    //2025.03.xx: 从iScene -> iCanset -> iAbsCanset
    NSDictionary *iAbsCansetISceneIndexDic = [TOUtils zonHeIndexDic:@[[DirectIndexDic newNoToAbs:oldCansetISceneIndexDic],[DirectIndexDic newOkToAbs:absCansetOldCansetIndexDic]]];
    if (Log4OutCansetAna) NSLog(@"\n----------- Canset类比 -----------\nold:%@\nnew:%@ absOldIndexDic:%@\nabs:%@",Pits2FStr(Simples2Pits(oldCansetOrders)),Pits2FStr(Simples2Pits(newCansetOrders)),CLEANSTR(iAbsCansetISceneIndexDic),Pits2FStr(Simples2Pits(absCansetOrders)));
    return [[[[HEResult newSuccess] mkData:absCansetOrders] mk:@"absISceneDic" v:iAbsCansetISceneIndexDic] mk:@"absOldDic" v:absCansetOldCansetIndexDic];
}

@end
