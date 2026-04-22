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
            // TODO: 等这里再次测试时，把这儿改一下，alg类比，不应该调用gt类比。这里先临时这么写着。。。
            AIFeatureNode *absT = [AIAnalogy analogyGroupFeatureV10:nil at:nil isOut:false logDesc:nil gtModel:nil prefixIndex:0];
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
+(AIFeatureNode*) analogyFeatureV2:(AIFeatureJvBuModel*)jvBuModel protoTLogDesc:(NSString*)protoTLogDesc prefixIndex:(NSInteger)prefixIndex {
    AIFeatureNode *absST = [self analogyFeatureV3:jvBuModel.bestGVs baseST:jvBuModel.assT stMatchValue:jvBuModel.matchValue protoTLogDesc:protoTLogDesc prefixIndex:prefixIndex finishBlock:^(NSArray *validBestGVs, NSValue *bestGVs_AssT) {
        // 1. 把后面会用到的一些数据存下来。
        jvBuModel.bestGVs4NoZeRen = validBestGVs;
    } debug:true];
    
    // 2. 完成后数据处理（现在并不排除主责，所以不需要重新计算竞争因子）。
    //if (![absST.p isEqual:jvBuModel.assT.p]) {
    //    [jvBuModel run4MatchValueAndMatchDegreeAndMatchAssProtoRatio];
    //}
    
    // 3. 把后面会用到的一些数据存下来。
    jvBuModel.abs_p = absST.p;
    return absST;
}

+(AIFeatureNode*) analogyFeatureV3:(NSDictionary*)bestGVs baseST:(AIFeatureNode*)baseST stMatchValue:(CGFloat)stMatchValue protoTLogDesc:(NSString*)protoTLogDesc prefixIndex:(NSInteger)prefixIndex finishBlock:(void(^)(NSArray *validBestGVs, NSValue *bestGVs_AssT))finishBlock debug:(BOOL)debug {
    
    //14. 根据validIndexDic求出newAbsT在protoT和assT中的rect。
    NSArray *assContentIndexes = [SMGUtils sortSmall2Big:bestGVs.allKeys compareBlock:^double(NSNumber *key) {
        return key.integerValue;
    }];
    CGRect bestGVs_AssT = [AINetUtils convertPartOfFeatureContent2Rect:baseST contentIndexes:assContentIndexes];
    
    // 收集indexDic。
    NSMutableDictionary *indexDic0 = [NSMutableDictionary new]; // 需要先收集每个abs的元素对应的con的下标。
    NSMutableDictionary *indexDic = [NSMutableDictionary new]; // 然后再把这个转成absIndex对应conIndex的字典。
    
    //15. 转为List<InputGroupValueModel>模型。
    NSMutableArray *absGVModels = [NSMutableArray new];
    for (NSNumber *assIndex in assContentIndexes) {
        AIKVPointer *assGV_p = ARR_INDEX(baseST.content_ps, assIndex.integerValue);
        
        //16A. 方案1、采用bestGV at assT的位置，做absT的元素位置分布：将gvRect在assT的范围，转成在newAbsT中的位置。
        CGRect assGVRect = VALTOOK(ARR_INDEX(baseST.rects, assIndex.integerValue)).CGRectValue;
        CGRect bestGV_assT = CGRectMake(assGVRect.origin.x - bestGVs_AssT.origin.x, assGVRect.origin.y - bestGVs_AssT.origin.y, assGVRect.size.width, assGVRect.size.height);
        if (bestGV_assT.size.width != bestGV_assT.size.height || bestGV_assT.size.width == 0 || bestGV_assT.size.height == 0) ELog(@"assRect数据异常: 宽高不一致，或宽高为0");
        //16B. 方案2、采用bestGV at protoT的位置，做absT的元素位置分布：此方案优点在于构建protoGT时，尺寸及位置可以更准确，缺点是类比这里本来就应该以assT为准，不关protoT的事，所以先采用方案1。
        //CGRect bestGV_protoT = CGRectMake(obj.bestGVAtProtoTRect.origin.x - jvBuModel.bestGVsAtProtoTRect.origin.x,obj.bestGVAtProtoTRect.origin.y - jvBuModel.bestGVsAtProtoTRect.origin.y,obj.bestGVAtProtoTRect.size.width, obj.bestGVAtProtoTRect.size.height);
        //NSLog(@"bestGV的Rect：atAss=%@ atProto=%@",Rect2Str(bestGV_assT),Rect2Str(bestGV_protoT));
        
        InputGroupValueModel *newGVModel = [InputGroupValueModel new:assGV_p rect:bestGV_assT];
        [absGVModels addObject:newGVModel];
        
        // indexDic第1步：先收集每个abs元素对应的conIndex。
        [indexDic0 setObject:newGVModel forKey:assIndex];
    }
    if (stMatchValue == 1 && absGVModels.count == 0) {
        ELog(@"如果匹配度为1，会导致所有indexDic的GV全有责，导致最后absGVModels为0条，如果停此处时，查下来源，这个匹配度1是哪来的");
    }
    if (!ARRISOK(absGVModels)) return nil;
    
    //21. 为增加特征content_ps的有序性：对groupModels进行排序（特征的content是有序的，所以要先排下序）。
    NSArray *sortGroupModels = [ThinkingUtils sortInputGroupValueModels:absGVModels];
    
    // indexDic第2步：再转成每个absIndex对应conIndex的正式映射。
    for (NSInteger absIndex = 0; absIndex < sortGroupModels.count; absIndex++) {
        InputGroupValueModel *itemGVModel = ARR_INDEX(sortGroupModels, absIndex);
        NSNumber *assIndex = ARR_INDEX([indexDic0 allKeysForObject:itemGVModel], 0);
        [indexDic setObject:assIndex forKey:@(absIndex)];
    }
    
    //31. 外类比构建
    AIFeatureNode *absT = [AIGeneralNodeCreater createFeatureNode:sortGroupModels conNodes:@[baseST] at:baseST.at ds:baseST.ds isOut:baseST.isOut isJiao:true isGT:false];
    
    // 如果abs的抽象层数少于当前proto或ass加1，则赋新抽象层数值（未达到abs本来就有的层级，则不变）。
    absT.absLevel = MAX(baseST.absLevel + 1, absT.absLevel);
    
    //2025.08.24: protoT为空时，也要记录protoLogDesc+1，避免一些抽象特征明明很广泛了，还是只记录着最初的那个logDesc（比如通过识别1触发的多次抽象，仅因最具象时是0，最后还只认为它是0是不对的）。
    [absT updateLogDescDic:baseST.logDesc];
    [absT updateLogDescItem:protoTLogDesc rate:stMatchValue];
    
    // 只有不同时，才存各种匹配度等。
    if (![absT.p isEqual:baseST.p]) {
        //35. 存protoT与absT的匹配度 & 存conPorts的rect（参考34135-TODO1）& 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
        //36. 类比竞争完后，重新计算然后再存assT与absT的：匹配度 & 存conPorts的rect（参考34135-TODO1）& 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
        [baseST updateMatchValue:absT matchValue:1]; // ass与abs的匹配度必为1。
        [AINetUtils updateConPortRect:absT conT:baseST.p rect:bestGVs_AssT];
        [baseST updateMatchDegree:absT matchDegree:1];
        [baseST updateIndexDic:absT indexDic:indexDic];
    }
    
    // 参与了抽象的GV元素更新其内容强度（参考36022）。
    [AINetUtils updateContentStrongByIndexes:assContentIndexes toNode:baseST];
    
    //41. debugLog
    if (debug) {
        CGRect bestGVs_Proto = [SMGUtils convertArr2Rect:bestGVs.allValues itemRectBlock:^CGRect(AIFeatureJvBuItem *item) {
            return item.bestGVAtProtoTRect;
        }];
        [SMGUtils runByMainQueue:^{
            [theApp.imgTrainerView setDataForFeatureV2:absT lab:STRFORMAT(@"%ld-T%ld->抽%ld(%ld)",prefixIndex,baseST.pId,absT.pId,absT.count) canvasRect:bestGVs_Proto tvId:2];
            // [theApp.imgTrainerView setDataForFeature:absT lab:STRFORMAT(@"%ld-T%ld->抽%ld(%ld)",prefixIndex,baseST.pId,absT.pId,absT.count) left:bestGVs_AssT.origin.x top:bestGVs_AssT.origin.y tvId:2];
        }];
    }
    
    // NSLog(@"单特征识别类比结果absT长度：%ld 匹配度:%.2f 符合度:%.2f",absT.count,jvBuModel.matchValue,jvBuModel.matchDegree);
    if (Log4Ana) NSLog(@"\n单特征类比结果(%@) ======================> \nAssT%ld（GV数:%ld）%@\n%@AbsT%ld（GV数:%ld）：%@\n%@",baseST.ds,
                               baseST.pId,baseST.count,CLEANSTR([baseST getLogDesc:false]),FeatureDesc(baseST.p,1),
                               absT.pId,sortGroupModels.count,CLEANSTR([absT getLogDesc:false]),FeatureDesc(absT.p,1));
    if (finishBlock) finishBlock(bestGVs.allValues,@(bestGVs_AssT));
    return absT;
}

+(AIFeatureNode*) analogyGroupFeatureV10:(NSString*)ds at:(NSString*)at isOut:(BOOL)isOut logDesc:(NSString*)logDesc gtModel:(GTZiJvModelV2*)gtModel prefixIndex:(NSInteger)prefixIndex {
    
    //1. 借助每个absT来实现整体T的类比：类比orders的规律: 类比rectItems，把责任超过50%的去掉，别的保留（参考34139）。
    // 2026.03.xx: 关闭过滤（识别已竞争过，不必画蛇添足）。
    // NSDictionary *sameItems = [SMGUtils filterDic:gtModel.bestSTs checkValid:^BOOL(NSNumber *key, STZiJvModelV2 *stGroup) {
    //    CGRect hopeItemST_Proto = [gtModel hopeProtoRectByIndex:key.integerValue];
    //    CGFloat stMatchDegree = [stGroup stMatchDegree:hopeItemST_Proto];
    //    return [TCLearningUtil noZeRenForPingJun:stGroup.stMatchValue * stMatchDegree * stGroup.stMatchCountRatio
    //                             bigerMatchValue:gtModel.gtMatchValue * gtModel.gtMatchDegree * gtModel.stMatchCountRatio];
    //}];
    
    // STEP1 ===== 先抽象其stGroup：把每个bestSTs里的stGroup.bestGVs先抽象出来（这样才更准确，不然明明bestST中只有一部分bestGVs到了，却要全抽象到absGT中？）。
    for (NSNumber *key in gtModel.bestSTs.allKeys) {
        STZiJvModelV2 *stGroup = [gtModel.bestSTs objectForKey:key];
        CGRect baseST_BaseGT = [gtModel.baseGT rectByIndex:key.integerValue];
        
        stGroup.absST = [AIAnalogy analogyFeatureV3:stGroup.bestGVs baseST:stGroup.baseST stMatchValue:stGroup.stMatchValue protoTLogDesc:logDesc prefixIndex:prefixIndex finishBlock:^(NSArray *validBestGVs, NSValue *bestGVs_AssT) {
            stGroup.absST_BaseST = bestGVs_AssT.CGRectValue;
            
            // 再根据absST_BaseST + baseST_BaseGT = 得出absST_BaseGT。
            stGroup.absST_BaseGT = [SMGUtils convertAAtCWithAAtB:stGroup.absST_BaseST bAtC:baseST_BaseGT protoBSize:stGroup.baseST.rect.size];
        } debug:false];
    }
    
    // STEP2 ===== 再抽象GT。
    //11. 将每个absT指向具象组特征的rect求并集，得出加一块儿的绝对rect范围（参考3413a-示图2）。
    CGRect absSTs_AssGT = [SMGUtils convertArr2Rect:gtModel.bestSTs.allValues itemRectBlock:^CGRect(STZiJvModelV2 *stGroup) {
        return stGroup.absST_BaseGT;
    }];
    
    // STEP3 ===== 转成orders
    NSArray *orders = [SMGUtils convertDic:gtModel.bestSTs kvBlock:^NSArray *(NSNumber *protoK, STZiJvModelV2 *protoV) {
        // 再根据整个absSTs_AssGT，减掉xy偏移值，计算出最终absST_AbsGT。
        // 计算itemST在absGT中的位置，其实就是ST在assGT中的位置，减掉margin左上角的留白（参考上面的方案2-TODO2）。
        CGRect absST_AbsGT = protoV.absST_BaseGT;
        absST_AbsGT.origin.x -= absSTs_AssGT.origin.x;//- marginLeft
        absST_AbsGT.origin.y -= absSTs_AssGT.origin.y;//- marginTop
        InputGroupFeatureModel *result = [InputGroupFeatureModel new:protoV.absST.p rect:absST_AbsGT];
        result.assIndex = protoK.integerValue;
        return @[protoK, result];
    }].allValues;
    
    // 有序：为增加特征content_ps的有序性：对orders按rect进行排序（特征的content是有序的，所以要先排下序）。
    orders = [ThinkingUtils sortInputGroupFeatureModels:orders];
    
    // 防重：orders（经实测：上面的ST抽象，有两个stGroup，分别是baseST910和baseST911，但抽象成了同一个absST963，然后其rect也全是<x0 y0 w18 h18>，所以要防重下先）。
    orders = [SMGUtils removeRepeat:orders convertBlock:^id(InputGroupFeatureModel *obj) {
        return STRFORMAT(@"%ld_%@",obj.feature_p.pointerId,@(obj.rect));
    }];
    
    // 构建absGT
    AIGroupFeatureNode *absGT = [AIGeneralNodeCreater createGroupFeatureNode:orders conNodes:@[gtModel.baseGT] at:at ds:ds isOut:isOut isJiao:true];
    
    //41. 更新logDesc。
    [absGT updateLogDescItem:logDesc rate:gtModel.gtMatchValue];
    [absGT updateLogDescDic:gtModel.baseGT.logDesc];
    
    //2025.04.23: 改为由protoT来收集absGVModels了，所以与protoT的匹配度符合度全是1，与assT的匹配度符合度直接重用zenTiModel的。
    //2025.09.11: 不记录protoGT与absGT的匹配度，位置符合度，范围rect（参考上面方案2-TODO3）。
    //42. 记录匹配度：根据每个匹配itemAbsT，来计算平均匹配度。
    [gtModel.baseGT updateMatchValue:absGT matchValue:1];//gtModel.modelSTMatch;
    
    //43. 记录符合度：根据每个符合itemAbsT，来计算平均符合度。
    [gtModel.baseGT updateMatchDegree:absGT matchDegree:gtModel.gtMatchDegree];
    
    //44. 记录整体absT.conPort到protoT和assT的rect（参考上面的方案2-TODO1）。
    [AINetUtils updateConPortRect:absGT conT:gtModel.baseGT.p rect:absSTs_AssGT];
    
    // 存indexDic。
    // 用途1、TODO：取显著度的时候需要它，现在不取absGT的content显著度，所以暂时用不到，后需要的时候加上。
    // 用途2、assGT识别结果，取有效抽象时，要用indexDic来判断抽象absGT是否全映射匹配。
    NSDictionary *indexDic = [SMGUtils convertArr2Dic:orders kvBlock:^NSArray *(InputGroupFeatureModel *obj) {
        NSNumber *absKey = @([orders indexOfObject:obj]);
        NSNumber *conValue = @(obj.assIndex);
        return @[absKey, conValue];
    }];
    [gtModel.baseGT updateIndexDic:absGT indexDic:indexDic];
    
    // 参与了抽象的ST元素更新其内容强度（参考36022）。
    NSArray *assGTIndexes = [SMGUtils convertArr:gtModel.bestSTs.allKeys convertBlock:^id(NSNumber *obj) { return @(obj.integerValue); }];
    [AINetUtils updateContentStrongByIndexes:assGTIndexes toNode:gtModel.baseGT];
    
    //51. debug
    [SMGUtils runByMainQueue:^{
        [theApp.imgTrainerView setDataForFeature:absGT lab:STRFORMAT(@"%ld-GT%ld_Abs%ld(%ld)",prefixIndex,gtModel.baseGT.pId,absGT.pId,absGT.count) left:0 top:0 tvId:4];
    }];
    if (Log4Ana) NSLog(@"\n组特征类比结果(%@) ======================> \%@ \nassGT%ld（长:%ld）%@\n%@absGT%ld（长:%ld）：%@\n%@",ds,logDesc,
                               gtModel.baseGT.pId,gtModel.baseGT.count,CLEANSTR([gtModel.baseGT getLogDesc:false]),FeatureDesc(gtModel.baseGT.p,1),
                               absGT.pId,absGT.count,CLEANSTR([absGT getLogDesc:false]),FeatureDesc(absGT.p,1));
    return absGT;
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
