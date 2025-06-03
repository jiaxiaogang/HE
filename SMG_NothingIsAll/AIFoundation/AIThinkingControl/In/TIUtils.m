//
//  TIUtils.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/27.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TIUtils.h"

#define cDebugMode false

@implementation TIUtils

//MARK:===============================================================
//MARK:                     < 稀疏码识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------稀疏码识别--------------------
 *  @version
 *      xxxx.xx.xx: 返回limit不能太小,不然概念识别时,没交集了 (参考26075);
 *      2022.05.23: 初版,排序和限制limit条数放到此处,原来getIndex_ps()方法里并没有相近度排序 (参考26096-BUG5);
 *      2022.05.23: 废弃掉不超过10%的条件,因为它会导致过窄问题 (参考26096-BUG3-方案1);
 *      2023.01.31: 返回limit改成20%条目 (参考28042-思路2-1);
 *      2023.02.25: 返回limit改成80%条目 (参考28108-todo1);
 *      2023.03.16: 支持首尾循环的情况 (参考28174-todo4);
 *      2023.03.16: 修复首尾差值算错的BUG (因为测得360左右度和180左右度相近度是0.9以上);
 *      2023.06.03: 性能优化_复用cacheDataDic到循环外 (参考29109-测得3);
 *      2025.03.25: 新版组码识别时激活10% & 旧有单码特征仍保持80%（因为组码太宽导致性能不好，还影响识别准确性）。
 *  @result 返回当前码识别的相近序列;
 */
+(NSArray*) recognitionValue:(AIKVPointer*)protoV_p rate:(CGFloat)rate minLimit:(NSInteger)minLimit {
    //1. 取当前稀疏码值;
    double protoData = [NUMTOOK([AINetIndex getData:protoV_p]) doubleValue];
    return [self recognitionValue:rate minLimit:minLimit at:protoV_p.algsType ds:protoV_p.dataSource isOut:protoV_p.isOut protoData:protoData];
}

+(NSArray*) recognitionValue:(CGFloat)rate minLimit:(NSInteger)minLimit at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoData:(NSInteger)protoData {
    //1. 取索引序列 & 当前稀疏码值;
    NSDictionary *cacheDataDic = [AINetIndexUtils searchDataDic:at ds:ds isOut:isOut];
    NSArray *index_ps = [AINetIndex getIndex_ps:at ds:ds isOut:isOut];
    double max = [CortexAlgorithmsUtil maxOfLoopValue:at ds:ds itemIndex:GVIndexTypeOfDataSource];
    AIValueInfo *vInfo = [AINetIndex getValueInfo:at ds:ds isOut:isOut];
    
    //2. 按照相近度排序;
    NSArray *near_ps = [SMGUtils sortSmall2Big:index_ps compareBlock:^double(AIKVPointer *obj) {
        double objData = [NUMTOOK([AINetIndex getData:obj fromDataDic:cacheDataDic]) doubleValue];
        return [CortexAlgorithmsUtil nearDeltaOfValue:protoData assNum:objData max:max];
    }];
    
    //3. 窄出,仅返回前NarrowLimit条 (最多narrowLimit条,最少1条);
    NSInteger limit = MAX(near_ps.count * rate, minLimit);
    near_ps = ARR_SUB(near_ps, 0, limit);
    
    //4. 转matchModel模型并返回，取上相近度。
    return [SMGUtils convertArr:near_ps convertBlock:^id(AIKVPointer *near_p) {
        
        //5. 第1_计算出nearV (参考25082-公式1) (性能:400次计算,耗100ms很正常);
        //2024.04.27: BUG_这里有nearV为0的,导致后面可能激活一些完全不准确的结果 (修复: 加上末尾淘汰: 相似度为0的就不收集了先,看下应该也不影响别的什么);
        double nearData = [NUMTOOK([AINetIndex getData:near_p fromDataDic:cacheDataDic]) doubleValue];
        CGFloat matchValue = [AIAnalyst compareCansetValue:nearData protoV:protoData at:near_p.algsType ds:near_p.dataSource isOut:near_p.isOut vInfo:vInfo];
        if (matchValue == 0) return nil;//把相近度为0的过滤掉。
        
        //6. 构建model
        AIMatchModel *model = [[AIMatchModel alloc] init];
        model.match_p = near_p;
        model.matchValue = matchValue;
        return model;
    }];
}

//MARK:===============================================================
//MARK:                     < 组码识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------组码识别--------------------
 */
+(NSArray*) recognitionGroupValueV3:(AIKVPointer*)groupValue_p rate:(CGFloat)rate minLimit:(NSInteger)minLimit {
    AIGroupValueNode *protoGroupValue = [SMGUtils searchNode:groupValue_p];
    NSArray *vModels = [SMGUtils convertArr:protoGroupValue.content_ps convertBlock:^id(AIKVPointer *item_p) {
        double protoData = [NUMTOOK([AINetIndex getData:item_p]) doubleValue];
        return [MapModel newWithV1:item_p.dataSource v2:@(protoData)];
    }];
    
    //gv的at和isOut和v的一样，直接复用，ds不一样，用vModels传过去。
    return [self recognitionGroupValueV4:vModels at:groupValue_p.algsType isOut:groupValue_p.isOut rate:rate minLimit:minLimit forProtoGV:groupValue_p];
}
+(NSArray*) recognitionGroupValueV4:(NSArray*)vModels at:(NSString*)at isOut:(BOOL)isOut rate:(CGFloat)rate minLimit:(NSInteger)minLimit forProtoGV:(AIKVPointer*)forProtoGV {
    //1. 数据准备
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"31");
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"32");
    
    //2. 先把protoGV解读成索引值。
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"33");
    for (NSInteger itemIndex = 0; itemIndex < vModels.count; itemIndex++) {
        
        //3. 取所有当前组码的itemIndex下的索引序列 & 当前码的索引值 & 当前码的最大值。
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"34");
        MapModel *item = ARR_INDEX(vModels, itemIndex);
        NSString *ds = item.v1;
        CGFloat itemData = NUMTOOK(item.v2).floatValue;
        NSArray *vMatchModels = [AIRecognitionCache getCache:STRFORMAT(@"%@_%.2f",item.v1,itemData) cacheBlock:^id{
            return [self recognitionValue:0.2 minLimit:10 at:at ds:ds isOut:isOut protoData:itemData];//v1单码特征
        }];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"37");
        
        //4. 每一个vMatchModel都向refPorts找结果。
        //重复性说明：此处每个vMatchModel都不同，所以它refPort.target也各不同，不会重复。
        for (AIMatchModel *vMatchModel in vMatchModels) {
            NSArray *refPorts = [AINetUtils refPorts_All:vMatchModel.match_p];
            //7. 每个refPort做两件事: (性能: 以下for循环耗150ms很正常);
            for (AIPort *refPort in refPorts) {
                //2025.04.22: 性能注意!!! 此处尽量别加任何复杂代码，除了加减乘除和objectForKey外，最好contains和AddDebugCodeBlock_Key也别加，不然几万次循环足以卡慢。
                //注意：此循环内执行一次识别可能在数万次，所以这里不可再添加别的逻辑，如果要加过滤，到最后识别完后再在此循环外进行补充过滤。
                //9. 找model (无则新建) (性能: 此处在循环中,所以防重耗60ms正常,收集耗100ms正常);
                AIMatchModel *model = itemIndex == 0 ? [AIMatchModel new] : [resultDic objectForKey:@(refPort.target_p.pointerId)];
                if (!model || model.matchCount < itemIndex) continue;
                [resultDic setObject:model forKey:@(refPort.target_p.pointerId)];
                model.match_p = refPort.target_p;
                model.matchCount++;
                model.matchValue *= vMatchModel.matchValue;
                model.sumRefStrong += (int)refPort.strong.value;
            }
        }
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3d");
    }
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3e");
    
    //11. 过滤掉匹配度为0的 & 非全含的 & 不识别protoG自己。
    NSArray *gMatchModels = [SMGUtils filterArr:resultDic.allValues checkValid:^BOOL(AIMatchModel *item) {
        return item.matchValue > 0 && item.matchCount == vModels.count && (!forProtoGV || ![item.match_p isEqual:forProtoGV]);
    }];
    
    //21. 按匹配度排序。
    gMatchModels = [SMGUtils sortBig2Small:gMatchModels compareBlock:^double(AIMatchModel *obj) {
        return obj.matchValue;
    }];
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3f");//循环圈:1 代码块:3e 计数:51 均耗:27.96 = 总耗:1426 读:481 写:0
    
    //24. 过滤不准确的结果。
    gMatchModels = ARR_SUB(gMatchModels, 0, MIN(30, MAX(5, gMatchModels.count * 0.2)));
    
    //25. 更新: ref强度 & 相似度 & 抽具象;
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3g1");
    for (AIMatchModel *matchModel in gMatchModels) {
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3g2");
        AIGroupValueNode *assNode = [SMGUtils searchNode:matchModel.match_p];//性能：起初需要IO时1ms/条，后面有缓存后均耗0.05ms 总22ms。
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3g3");
        //2025.03.30: 这儿性能不太好，经查现在组码识别不需要单码索引强度做竞争，先关掉。
        //[AINetUtils insertRefPorts_General:assNode.p content_ps:assNode.content_ps difStrong:1 header:assNode.header];
        if (forProtoGV) {
            AIGroupValueNode *protoGroupValue = [SMGUtils searchNode:forProtoGV];
            [protoGroupValue updateMatchValue:assNode matchValue:matchModel.matchValue];//性能均耗0.15ms 总65ms
            if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3g4");
            [AINetUtils relateGeneralAbs:assNode absConPorts:assNode.conPorts conNodes:@[protoGroupValue] isNew:false difStrong:1];//性能均耗0.25ms 总97ms
        }
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3g5");
        //NSLog(@"组码识别结果(%ld/%ld) GV%ld 匹配数:%ld 匹配度:%.2f",[gMatchModels indexOfObject:matchModel],gMatchModels.count,matchModel.match_p.pointerId,matchModel.matchCount,matchModel.matchValue);
    }
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3g6");
    return gMatchModels;
}

//MARK:===============================================================
//MARK:                     < 特征识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------特征识别--------------------
 *  @desc 识别抽象的局部特征：通过组码向refPorts找特征结果（起初似层结果较多，但后期随着抽象，会慢慢变成结果中几乎都是交层）。
 */
+(NSArray*) recognitionFeature_JvBu:(AIKVPointer*)protoFeature_p {
    //1. 数据准备
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"1");
    AIFeatureNode *protoFeature = [SMGUtils searchNode:protoFeature_p];
    NSLog(@"\n=========== 特征识别 protoT%ld（%@）===========",protoFeature_p.pointerId,protoFeature_p.dataSource);
    AIFeatureAllBestGVModel *gvBestModel = [[AIFeatureAllBestGVModel alloc] init];
    if (protoFeature.count == 0) return @[[[AIMatchModel alloc] initWithMatch_p:protoFeature_p]];
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"2");
    
    //2. 循环分别识别：特征里的组码。
    for (NSInteger i = 0; i < protoFeature.count; i++) {
        AIKVPointer *protoGroupValue_p = ARR_INDEX(protoFeature.content_ps, i);
        CGRect protoRect = VALTOOK(ARR_INDEX(protoFeature.rects, i)).CGRectValue;
        NSInteger protoLevel = VisionMaxLevel - [SMGUtils convertDotSize2Level:protoRect.size.width];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"3");
        
        //4. 组码识别。
        NSArray *gMatchModels = [AIRecognitionCache getCache:protoGroupValue_p cacheBlock:^id{
            return ARRTOOK([self recognitionGroupValueV3:protoGroupValue_p rate:0.3 minLimit:3]);
        }];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"4");
        
        //6. 对所有gv识别结果的，所有refPorts，依次判断位置符合度。
        for (AIMatchModel *gModel in gMatchModels) {
            if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"5");
            NSArray *refPorts = [AINetUtils refPorts_All:gModel.match_p];
            if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"6");
            
            //11. 每个refPort转为model并计匹配度和匹配数;
            for (AIPort *refPort in refPorts) {
                
                //12. 根据level分别记录不同deltaLevel结果（把deltaLevel做为key的一部分，记录到识别结果字典里）。
                NSInteger refLevel = VisionMaxLevel - [SMGUtils convertDotSize2Level:refPort.rect.size.width];
                NSString *assKey = STRFORMAT(@"%ld_%ld",protoLevel - refLevel,refPort.target_p.pointerId);
                
                //13. 取出已经收集到的assGVModels,判断下一个refPort收集进去的话,是否符合位置;
                NSArray *assGVItems = [gvBestModel getAssGVModelsForKey:assKey];
                //BOOL debugMode = [feature_p.dataSource isEqual:@"hColors"] && [refPort.target_p isEqual:protoFeature.p] && assLevel == protoLevel && [gModel.match_p isEqual:protoGroupValue_p];
                CGFloat matchDegree = [ThinkingUtils checkAssToMatchDegree:protoFeature protoIndex:i assGVModels:assGVItems checkRefPort:refPort debugMode:false];
                
                //14. 判断新一条refPort是否更好，更好的话存下来（存refPort，assKey，gModel.matchValue，matchDegree）。
                [gvBestModel updateStep1:assKey refPort:refPort gMatchValue:gModel.matchValue gMatchDegree:matchDegree matchOfProtoIndex:i];
            }
            if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"11");
        }
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"12");
        
        //21. STEP2：每个protoIndex内防重，竞争只保留protoIndex下最好一条。
        [gvBestModel invokeRankStep2];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"13");
        
        //22. STEP3：跨protoIndex防重，将best结果存下来
        [gvBestModel updateStep3];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"14");
    }
    //31. 用明细生成总账（bestModel -> resultDic）。
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"14B");//均耗:546ms 优化至40ms
    NSDictionary *resultDic = [gvBestModel convert2AIMatchModelsStep4:protoFeature];// <K=deltaLevel_assPId, V=识别的特征AIMatchModel>
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"15");
    
    //32. debug
    for (NSString *assKey in resultDic.allKeys) {
        AIMatchModel *model = [resultDic objectForKey:assKey];
        if (Log4RecogDesc) NSLog(@"%@\t匹配条数 %ld/%ld \t特征识别综合匹配度计算:T%ld \t匹配度:%.2f / %ld \t= %.2f 总强度：%ld",assKey,model.matchCount,protoFeature.count,model.match_p.pointerId,model.sumMatchValue,model.matchCount,model.matchValue,model.sumRefStrong);
    }
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"16");
    
    //33. 生成ass_T在proto_T中的rect。
    for (AIMatchModel *matchModel in resultDic.allValues) {
        matchModel.rect = [AINetUtils convertPartOfFeatureContent2Rect:protoFeature contentIndexes:matchModel.indexDic.allValues];
    }
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"17");
    
    //41. 无效过滤器1、matchValue=0排除掉 & 是protoT自身过滤掉。
    NSArray *resultModels = [SMGUtils filterArr:resultDic.allValues checkValid:^BOOL(AIMatchModel *item) {
        return item.matchValue > 0 || [item.match_p isEqual:protoFeature_p];
    }];
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"18");
    
    //42. 防重过滤器2、此处每个特征的不同层级，可能识别到同一个特征，可以按匹配度防下重。
    resultModels = [SMGUtils removeRepeat:[SMGUtils sortBig2Small:resultModels compareBlock:^double(AIMatchModel *obj) {
        return obj.matchCount;
    }] convertBlock:^id(AIMatchModel *obj) {
        return obj.match_p;
    }];
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"19");
    
    //43. 末尾淘汰20%被引用强度最低的。
    //resultModels = ARR_SUB([SMGUtils sortBig2Small:resultModels compareBlock:^double(AIMatchModel *obj) {
    //    return obj.strongValue;
    //}], 0, MAX(resultModels.count * 0.9f, 10));
    
    //44. 末尾淘汰仅保留匹配数大于xx%的：全含判断=>特征应该不需要全含，因为很难看到局部都相似的两个图像。
    //resultModels = [SMGUtils filterArr:resultModels checkValid:^BOOL(AIMatchModel *item) {
    //    AIFeatureNode *tNode = [SMGUtils searchNode:item.match_p];
    //    return item.matchCount > tNode.count * 0.05;
    //}];
    
    //45. 末尾淘汰匹配数小于3条的、组码太少，形不成什么显著的特征。
    //2025.04.07: 由绝对3条淘汰改成末尾淘汰：匹配数低的占比偏多，所以改成按匹配数排序尾部淘汰。
    //2025.04.08: 由末尾淘汰改成平均匹配数淘汰：BUG-修复最后很多1号坚果都是GV匹配数=2的，但H通道很重要，改成以matchCount的和来判断匹配数（经实测已OK)。
    //TODO: 这个应该没啥用了，匹配数已经用到竞争里了，这个再末尾淘汰30%有点画蛇添足（随后明确测下此处意义不大，去掉也没啥影响的话，就去掉）。
    NSInteger pinJunMatchCount = [SMGUtils sumOfArr:resultModels convertBlock:^double(AIMatchModel *obj) {
        return obj.matchCount;
    }] / (float)resultModels.count;
    resultModels = [SMGUtils filterArr:resultModels checkValid:^BOOL(AIMatchModel *item) {
        return item.matchCount >= pinJunMatchCount * 0.3f;
    }];
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"20");
    
    //46. 末尾淘汰xx%匹配度低的、匹配度强度过滤器 (参考28109-todo2 & 34091-5提升准确)。
    //2025.04.23: 加上健全度：matchAssProtoRatio（参考34165-方案）。
    resultModels = ARR_SUB([SMGUtils sortBig2Small:resultModels compareBlock:^double(AIMatchModel *obj) {
        return obj.matchValue * obj.matchDegree * obj.matchAssProtoRatio;
    }], 0, MIN(MAX(resultModels.count * 0.5f, 10), 20));
    
    //51. 更新: ref强度 & 相似度 & 抽具象 & 映射 & conPort.rect;
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"21");
    for (AIMatchModel *matchModel in resultModels) {
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22");
        AIFeatureNode *assFeature = [SMGUtils searchNode:matchModel.match_p];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22b");//循环圈:10 代码块:22b 计数:20 均耗:17.13 = 总耗:343 读:0 写:0
        //2025.04.22: 这儿性能不太好，经查现在特征识别不需要组码索引强度做竞争，先关掉。
        //[AINetUtils insertRefPorts_General:assFeature.p content_ps:assFeature.content_ps difStrong:1 header:assFeature.header];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22c");
        [protoFeature updateMatchValue:assFeature matchValue:matchModel.matchValue];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22d");
        [protoFeature updateMatchDegree:assFeature matchDegree:matchModel.matchDegree];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22e");
        [AINetUtils relateGeneralAbs:assFeature absConPorts:assFeature.conPorts conNodes:@[protoFeature] isNew:false difStrong:1];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22f");
        assFeature.jvBuModel = [MapModel newWithV1:matchModel.indexDic v2:protoFeature_p];
        //[protoFeature updateIndexDic:assFeature indexDic:matchModel.indexDic];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22g");
        [protoFeature updateDegreeDic:assFeature.pId degreeDic:matchModel.degreeDic];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"22h");
        [AINetUtils updateConPortRect:assFeature conT:protoFeature_p rect:matchModel.rect];
        if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"23");
        
        //52. debug
        if (Log4RecogDesc || resultModels.count > 0) NSLog(@"局部特征识别结果:T%ld%@\t 匹配条数:%ld/(proto%ld ass%ld)\t匹配度:%.2f\t符合度:%.1f",
                                         matchModel.match_p.pointerId,CLEANSTR([assFeature getLogDesc:true]),matchModel.matchCount,protoFeature.count,assFeature.count,matchModel.matchValue,matchModel.matchDegree);
    }
    if (cDebugMode) AddDebugCodeBlock_Key(@"rfs1", @"24");
    PrintDebugCodeBlock_Key(@"rfs1");
    
    //53. 局部特征识别结果可视化（参考34176）。
    //[SMGUtils runByMainQueue:^{
    //    [theApp.imgTrainerView setDataForJvBuModels:resultModels protoT:protoFeature];
    //}];
    
    //53. step1Result仅保留似层（参考34135-TODO5）。
    //2025.04.16: 为了有更为抽象的特征，先似交层都保留。
    //NSArray *step1Si = [SMGUtils filterArr:step1Result checkValid:^BOOL(AIMatchModel *item) {
    //    return !item.match_p.isJiao;
    //}];
    return resultModels;
}

/**
 *  MARK:--------------------局部特征识别--------------------
 *  @param beginRectExcept 切入点防重（相近的地方切入识别的gv避免重复进行识别循环）。
 *  @param assRectExcept 成功识别过的区域防重（如果此处已经被别的assT扫描并成功识别过了，则记录下，它不再做切入点进行别的识别了）。
 */
+(void) recognitionFeature_JvBu_V2_Step1:(NSDictionary*)gvIndex at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoRect:(CGRect)protoRect protoColorDic:(NSDictionary*)protoColorDic decoratorJvBuModel:(AIFeatureJvBuModels*)decoratorJvBuModel excepts:(DDic*)excepts gvRectExcept:(NSMutableDictionary*)gvRectExcept beginRectExcept:(NSMutableArray*)beginRectExcept assRectExcept:(NSMutableArray*)assRectExcept {
    //1. 过滤器：被成功识别过的区域，防重不再做为切入识别。
    //2025.05.20：改为>0就行，所有区域都给机会，但所有区域都不能太占注意力，只分配一些之后，就触发防重，不然循环就太多性能差。
    if ([SMGUtils filterSingleFromArr:assRectExcept checkValid:^BOOL(NSValue *item) {
        return [ThinkingUtils matchOfRect:item.CGRectValue newRect:protoRect] > 0.0f;
    }]) return;
    
    //2. 过滤器2：被切入点成功识别过的相近区域，防重不再做为切入识别。
    if ([SMGUtils filterSingleFromArr:beginRectExcept checkValid:^BOOL(NSValue *item) {
        return [ThinkingUtils matchOfRect:item.CGRectValue newRect:protoRect] > 0.0f;
    }]) return;
    
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    AIFeatureJvBuModels *resultModel = decoratorJvBuModel;
    //1. 单码排序。
    NSArray *sortDS = [gvIndex.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [XGRedisUtil compareStrA:obj1 strB:obj2];
    }];
    //2. 并将单码转为MapModels格式。
    NSArray *vModels = [SMGUtils convertArr:sortDS convertBlock:^id(NSString *ds) {
        return [MapModel newWithV1:ds v2:[gvIndex objectForKey:ds]];
    }];
    //3. 组码cacheKey。
    NSString *gvKey = CLEANSTR([SMGUtils convertArr:vModels convertBlock:^id(MapModel *obj) {
        CGFloat value = NUMTOOK(obj.v2).floatValue;
        return STRFORMAT(@"%@_%.2f",obj.v1,value);
    }]);
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    //4. 组码识别
    NSArray *gMatchModels = [AIRecognitionCache getCache:gvKey cacheBlock:^id{
        return [self recognitionGroupValueV4:vModels at:at isOut:isOut rate:0.15 minLimit:3 forProtoGV:nil];
    }];
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    
    //5. beginRectExcept防重 & 更新（参考35041-TODO4）。
    //2025.05.21: 关掉，前面的beginRectExcept和assRectExcept已经把重复区的全过滤掉了，这里压根收集不到exceptGVs，并且防重exceptGVs反而会让那些原处边缘地带没什么竞争力的gvs有机会进行识别，这也不利于准确性。
    //NSArray *exceptGVs = [ThinkingUtils getGVRectExceptGV_ps:protoRect gvRectExcept:gvRectExcept];
    //gMatchModels = [SMGUtils filterArr:gMatchModels checkValid:^BOOL(AIMatchModel *item) {
    //    return ![exceptGVs containsObject:item.match_p];
    //}];
    //if (gMatchModels.count <= 0) return;
    //[gvRectExcept setObject:[SMGUtils convertArr:gMatchModels convertBlock:^id(AIMatchModel *obj) {
    //    return obj.match_p;
    //}] forKey:@(protoRect)];
    //
    //6. 把exceptGVs防重下。
    //gMatchModels = [SMGUtils removeArr:gMatchModels checkValid:^BOOL(AIMatchModel *item) {
    //    return [exceptGVs containsObject:item.match_p];
    //}];
    //AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    
    //6. 提前加载好vInfo缓存，后面复用。
    NSDictionary *vInfoCache = [SMGUtils convertDic:gvIndex kvBlock:^NSArray *(NSString *protoK, id protoV) {
        AIValueInfo *vInfo = [AINetIndex getValueInfo:at ds:protoK isOut:isOut];
        return @[protoK,vInfo];
    }];
    
    //7. 提前加载好dataDic缓存，后面复用。
    NSDictionary *dataDicCache = [SMGUtils convertDic:gvIndex kvBlock:^NSArray *(NSString *protoK, id protoV) {
        NSDictionary *dataDic = [AINetIndexUtils searchDataDic:at ds:protoK isOut:isOut];
        return @[protoK,dataDic];
    }];
    
    //11. 对所有gv识别结果的，所有refPorts，依次判断位置符合度。
    for (AIMatchModel *gModel in gMatchModels) {
        //12. 切入点相近度太低（比如横线对竖线完全没有必要切入识别），直接pass掉。
        if (gModel.matchValue < 0.6) continue;
        NSArray *refPorts = [AINetUtils refPorts_All:gModel.match_p];
        //NSLog(@"GV%ld.refPorts: %@",gModel.match_p.pointerId,CLEANSTR([SMGUtils convertArr:refPorts convertBlock:^id(AIPort *obj) { return @(obj.target_p.pointerId); }]));
        //refPorts = ARR_SUB(refPorts, 0, 3);
        
        //12. 每个refPort自举，到proto对应下相关区域的匹配度符合度等;
        AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
        for (AIPort *refPort in refPorts) {
            
            // 先把细节处（比如图像中有个小小的3）识别关掉，以方便调试自适应粒度版本的BUG（后面没什么BUG了，再放开）。
            CGFloat sizeRatio = refPort.rect.size.width / protoRect.size.width;
            if (sizeRatio > 1.3f || sizeRatio < 0.8f) continue;
            
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            AIFeatureNode *assT = [SMGUtils searchNode:refPort.target_p];
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            if (!assT) continue;
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            NSInteger beginAssIndex = [assT indexOfRect:refPort.rect];//[assT.content_ps indexOfObject:gModel.match_p];
            if (beginAssIndex == -1) continue;
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            CGRect lastAtAssRect = refPort.rect;//ARR_INDEX(assT.rects, beginAssIndex).CGRectValue;
            CGRect lastProtoRect = protoRect;
            
            //13. 防重（同一个assT也可能有多个assIndex切入点，比如“8有四处下划线”的例子，可以让它多切入点分别自举）。
            //2025.05.12: 防重程度说明如下：
            //说明1：同一个assT有多处局部，protoRect也有多处可能调用它，它俩识别匹配时，必然是多对多的关系。
            //说明2：而防重很难应对这种多对多的情况，最多是邻近防重，即相邻protoRect与相邻assRect只做一次有效匹配，总之这里切不可轻易过度防重。
            //说明3：也可能这里的防重，是一个博弈平衡，过于放开性能就不佳，过于防重识别结果就片面。
            //2025.05.21: 去掉，如果一张图里有多个3呢，不能暴力的全过滤掉。
            //if ([excepts objectV2ForKey1:refPort.target_p k2:@(beginAssIndex)]) continue;
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            
            //13. 把tMatchModel收集起来。
            AIFeatureJvBuModel *model = [AIFeatureJvBuModel new:assT];
            [model.bestGVs addObject:[AIFeatureJvBuItem new:lastProtoRect matchValue:gModel.matchValue matchDegree:1 assIndex:beginAssIndex]];
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            
            //21. 自举：每个assT一条条自举自身的gv。
            for (NSInteger i = 1; i < assT.count; i++) {
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                NSInteger curIndex = (beginAssIndex + i) % assT.count;
                AIKVPointer *curAssGV_p = ARR_INDEX(assT.content_ps, curIndex);
                AIGroupValueNode *curAssGV = [SMGUtils searchNode:curAssGV_p];
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                NSValue *curAtAssRectValue = ARR_INDEX(assT.rects, curIndex);
                CGRect curAtAssRect = curAtAssRectValue.CGRectValue;
                
                //22. 根据比例估算下一条protoGV的取值范围。
                //2025.05.09: bugfix-原来计算错误有NaN的情况，改为明确按缩放+平移来完成（ass和proto缩放量一致，平移量成正例）。
                CGFloat wRate = lastProtoRect.size.width / lastAtAssRect.size.width;            //ass&proto缩放量（如lastP宽6，lastA宽9，则比例为2/3）
                CGFloat hRate = lastProtoRect.size.height / lastAtAssRect.size.height;          //ass&proto缩放量
                CGFloat assDeltaX = curAtAssRect.origin.x - lastAtAssRect.origin.x;             //ass平移量（如lastA.x=9，curA.x=0，则平移为-9）
                CGFloat assDeltaY = curAtAssRect.origin.y - lastAtAssRect.origin.y;             //ass平移量
                CGFloat protoDeltaX = assDeltaX * wRate;                                        //proto平移量（如ass平移=-9，则proto平移=-9*2/3=-6）
                CGFloat protoDeltaY = assDeltaY * hRate;                                        //proto平移量
                CGRect defaultCurProtoRect = CGRectMake(lastProtoRect.origin.x + protoDeltaX,   //如lastP.x=0，平移-6后，得curP.x=-6。
                                                        lastProtoRect.origin.y + protoDeltaY,
                                                        curAtAssRect.size.width * wRate,        //如curA宽27，比例为2/3，得curP宽18。
                                                        curAtAssRect.size.height * hRate);
                
                //23. 找出锚点。
                CGFloat anchorX = (CGRectGetMidX(lastProtoRect) + CGRectGetMidX(defaultCurProtoRect)) / 2;
                CGFloat anchorY = (CGRectGetMidY(lastProtoRect) + CGRectGetMidY(defaultCurProtoRect)) / 2;
                
                //31. 根据估算，到proto色值字典中，找匹配度最高的新切gv粒度比例（从缩小2倍，到增大2倍，中间每层1.3倍，一个个尝试，哪个最相近）。
                //NSArray *scales = @[@(1),@(1.2),@(0.8),@(1.56),@(0.62),@(2.0),@(0.5)];
                NSArray *scales = @[@(1)];
                MapModel *best = nil;
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                for (NSNumber *item in scales) {
                    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                    CGFloat scale = item.floatValue;
                    //32. 锚点不变，求出各比例下的protoRect（缩放时，锚点与中心点的xy偏移量与之正相关）。
                    //x = anchorX + (CGRectGetMidX(curProtoRect) - anchorX) * scale - curProtoRect.size.width * scale * 0.5;
                    CGRect checkCurProtoRect = CGRectMake((1 - scale) * anchorX + defaultCurProtoRect.origin.x * scale,
                                                          (1 - scale) * anchorY + defaultCurProtoRect.origin.y * scale,
                                                          defaultCurProtoRect.size.width * scale,
                                                          defaultCurProtoRect.size.height * scale);
                    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);//计数:138677 均耗:0.05 = 总耗:6847 读:0 写:0
                    
                    //33. 切出当前gv：九宫。
                    //2025.05.10: 出界处理：如checkCurProtoRect出界到视角之外，比如<0或者>max（采用方案2，直接continue）。
                    //  方案1、用assT的解析来填充，不然就没对局部显示的进行识别了。
                    //  方案2、可以出界的不做判断，最后计算匹配度时是要除掉bestGVs.count，所以不做判断并不会影响匹配度。
                    NSArray *subDots = [ThinkingUtils getSubDots:protoColorDic gvRect:checkCurProtoRect];
                    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                    if (!ARRISOK(subDots)) continue;
                    NSDictionary *protoGVIndex = [AINetGroupValueIndex convertGVIndexData:subDots ds:ds];
                    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);//计数:80651 均耗:0.31 = 总耗:25330 读:0 写:0
                    
                    //34. 求切出的curProtoGV九宫与curAssGV的匹配度。
                    CGFloat curGMatchValue = 1;
                    for (AIKVPointer *assV in curAssGV.content_ps) {
                        CGFloat protoData = NUMTOOK([protoGVIndex objectForKey:assV.dataSource]).floatValue;
                        NSDictionary *dataDic = [dataDicCache objectForKey:assV.dataSource];
                        double assData = [NUMTOOK([AINetIndex getData:assV fromDataDic:dataDic]) doubleValue];
                        AIValueInfo *vInfo = [vInfoCache objectForKey:assV.dataSource];
                        CGFloat vMatchValue = [AIAnalyst compareCansetValue:assData protoV:protoData at:assV.algsType ds:assV.dataSource isOut:assV.isOut vInfo:vInfo];
                        curGMatchValue *= vMatchValue;
                    }
                    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                    
                    //35. 保留最匹配的一条。
                    if (!best || NUMTOOK(best.v1).floatValue < curGMatchValue) {
                        best = [MapModel newWithV1:@(curGMatchValue) v2:@(checkCurProtoRect) v3:@(scale)];
                    }
                    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                }
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                //41. 有中断匹配不上的gv，直接计为自举审核失败。
                //2025.05.10: 这里要注意冷启，如果有条中断立马就停，那像虚线画的图就没法识别到了，还是先去掉>0.1的判断。
                //2025.05.10: gv太多了，如果中断还继续，性能极大浪费，也会导致真正后来者准确时，却失去自举的机会（虚线画的图也是在宏观一级层面识别它，而非虚线层面）。
                //1. 即输入和谁都不完全相似时
                //2. 或现在还没抽象特征时，从具象中竞争出匹配度高的。
                //3. 卡的太严这里就断了，看下是否改成（全跑完再竞争匹配度，或一条条ref.target跑下一条gv，边跑边竞争末尾淘汰）。
                if (!best) break;
                CGFloat gMatchValue = NUMTOOK(best.v1).floatValue;
                if (gMatchValue < 0.1f) break;
                
                //42. 把best的情况记下来，继续下一个gv。
                lastProtoRect = VALTOOK(best.v2).CGRectValue;
                lastAtAssRect = curAtAssRect;
                
                //43. 记录curIndex，以使bestGVs知道与assT哪帧映射且用于排序等。
                //2025.05.12: 自适应粒度局部特征识别的位置符合度本来就是自举位置来判断匹配度的，位置不符合时匹配度就无法达标，所以：要么用scale与1的距离来表示，要么直接不判断它。
                CGFloat scale = NUMTOOK(best.v3).floatValue;
                CGFloat matchDegree = MIN(1, scale) / MAX(1, scale);
                [model.bestGVs addObject:[AIFeatureJvBuItem new:lastProtoRect matchValue:gMatchValue matchDegree:matchDegree assIndex:curIndex]];
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            }
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            
            //44. 局部特征最少gv数：如果收集bestGVs太少，则直接判定失败（太少gv达不到局部特征最低标准）。
            if (model.bestGVs.count <= 4) continue;
            
            //51. 全通过了，才收集它（因为同一个assT可能因入protoRect位置不同，导致有时能识别成功有时不能，因为gv是可以重复的，只是位置不同罢了，比如：8有四处下划线，除了第1处下滑切入可以自举全匹配到，别的都不行）。
            [resultModel.models addObject:model];
            
            //52. 有效局部特征条目后，才计为防重（关掉，如果一张图有多个3也得能识别）。
            //[excepts setObjectV2:@"" k1:refPort.target_p k2:@(beginAssIndex)];
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            
            //53. 有效局部特征条目后，计为assRectExcept防重（参考35042-TODO4）。
            [assRectExcept addObjectsFromArray:[SMGUtils convertArr:model.bestGVs convertBlock:^id(AIFeatureJvBuItem *obj) {
                return @(obj.bestGVAtProtoTRect);
            }]];
            
            //54. 有效局部特征条目后，该切入点beginRectExcept防重（参考35042-TODO4）。
            [beginRectExcept addObject:@(protoRect)];
        }
        AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    }
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
}

+(void) recognitionFeature_JvBu_V2_Step2:(AIFeatureJvBuModels*)resultModel dotSize:(CGFloat)dotSize {
    //43. 处理匹配度，符合度
    for (AIFeatureJvBuModel *model in resultModel.models) {
        [model run4MatchValueAndMatchDegreeAndMatchAssProtoRatio];
    }
    
    //51. 过滤非全含。
    //2025.05.10: 冷启时，可能全部不全，并且下面已经有健全度竞争了，此处全含过滤器先去掉。
    //resultModel.models = [SMGUtils filterArr:resultModel.models checkValid:^BOOL(AIFeatureJvBuModel *model) {
    //    return model.bestGVs.count >= model.assT.count;
    //}];
    
    //52. 无效过滤器1、matchValue=0排除掉。
    NSArray *validModels = [SMGUtils filterArr:resultModel.models checkValid:^BOOL(AIFeatureJvBuModel *model) {
        return model.matchValue > 0;
    }];
    
    //53. 排序
    validModels = [SMGUtils sortBig2Small:validModels compareBlock:^double(AIFeatureJvBuModel *obj) {
        return obj.matchValue * obj.matchDegree * obj.matchAssProtoRatio;
    }];
    
    //54. 防重（同一个assT可能在多个错位时都识别到，导致其实是重影的，比如0的内圈和外圈就是两个0，所以要防重下）（参考35043-重影BUG）。
    validModels = [SMGUtils removeRepeat:validModels convertBlock:^id(AIFeatureJvBuModel *obj) {
        return obj.assT.p;
    }];
    
    //55. 末尾淘汰xx%匹配度低的、匹配度强度过滤器 (参考28109-todo2 & 34091-5提升准确)。
    //2025.04.23: 加上健全度：matchAssProtoRatio（参考34165-方案）。
    validModels = ARR_SUB(validModels, 0, MIN(MAX(resultModel.models.count * 0.5f, 10), 20));
    
    //60. 更新赋值回去。
    resultModel.models = [[NSMutableArray alloc] initWithArray:validModels];
    
    //61. 更新: ref强度 & 相似度 & 抽具象 & 映射 & conPort.rect;
    for (AIFeatureJvBuModel *model in resultModel.models) {
        //2025.04.22: 这儿性能不太好，经查现在特征识别不需要组码索引强度做竞争，先关掉。
        //[AINetUtils insertRefPorts_General:assFeature.p content_ps:assFeature.content_ps difStrong:1 header:assFeature.header];
        //[protoFeature updateMatchValue:assFeature matchValue:matchModel.matchValue];
        //[protoFeature updateMatchDegree:assFeature matchDegree:matchModel.matchDegree];
        //[AINetUtils relateGeneralAbs:assFeature absConPorts:assFeature.conPorts conNodes:@[protoFeature] isNew:false difStrong:1];
        //model.assT.jvBuModelV2 = model;
        //[protoFeature updateIndexDic:assFeature indexDic:matchModel.indexDic];
        //[protoFeature updateDegreeDic:assFeature.pId degreeDic:matchModel.degreeDic];
        //[AINetUtils updateConPortRect:assFeature conT:protoFeature_p rect:matchModel.rect];
        
        //52. debug
        if (Log4RecogDesc || resultModel.models.count > 0) NSLog(@"局部特征识别结果:T%ld%@\t 匹配条数:%ld/ass%ld\t匹配度:%.2f\t符合度:%.1f\t健全度:%.1f",
                                         model.assT.pId,CLEANSTR([model.assT getLogDesc:true]),model.bestGVs.count,model.assT.count,model.matchValue,model.matchDegree,model.matchAssProtoRatio);
        [SMGUtils runByMainQueue:^{
            //[theApp.imgTrainerView setDataForJvBuModelV2:model lab:STRFORMAT(@"单T%ld(%ld/%ld)(%.1f)",model.assT.pId,model.bestGVs.count,model.assT.count,dotSize)];
        }];
    }
    
    //61. debugLog
    [TIUtils printLogDescRate:[SMGUtils convertArr:resultModel.models convertBlock:^id(AIFeatureJvBuModel *obj) {
        return obj.assT.p;
    }] protoLogDesc:nil prefix:@"局部特征"];
}

/**
 *  MARK:--------------------特征识别--------------------
 *  @desc Step2 尽可能照顾特征的整体性，通过交层向下找似层结果（参考34135-TODO2）。
 */
+(NSArray*) recognitionFeature_ZenTi:(AIKVPointer*)protoFeature_p matchModels:(NSArray*)matchModels {
    //1. 数据准备
    AIFeatureNode *protoFeature = [SMGUtils searchNode:protoFeature_p];
    AIFeatureZenTiModels *zenTiModel = [AIFeatureZenTiModels new];
    
    //11. 收集：每个absT分别向整体取conPorts。
    for (AIMatchModel *matchModel in matchModels) {
        AIFeatureNode *absT = [SMGUtils searchNode:matchModel.match_p];
        NSArray *conPorts = [AINetUtils conPorts_All:absT];
        
        //12. 将每个conPort先收集到zenTiModel。
        for (AIPort *conPort in conPorts) {
            
            //13. protoFeature单独收集。
            //if ([conPort.target_p isEqual:protoFeature_p]) continue;
            
            //13. 只要似层结果（参考34135-TODO6）。
            if (conPort.target_p.isJiao) continue;
            
            //14. 收集原始item数据（参考34136）(v1版本没有protoGTIndex，在类比时也不会用，直接传-1）。
            [zenTiModel updateItem:conPort fromItemT:absT.p protoGTIndex:-1];
        }
        
        //16. protoFeature单独收集（step1结束时才会存rectDic中，此时还在matchModel.rect中）。
        //2025.05.13: 改回在上面的for循环中收集proto，因为我看在局部识别中，已经把rect存到conPort中了，不需要这里单独处理了。
        //CGRect rect = [AINetUtils convertPartOfFeatureContent2Rect:protoFeature contentIndexes:matchModel.indexDic.allValues];
        //[zenTiModel updateItem:protoFeature_p fromItemT:absT.p itemAtAssRect:rect];
    }
    
    //21. 计算：位置符合度: 根据每个整体特征与局部特征的rect来计算。
    [zenTiModel run4MatchDegree:protoFeature_p];
    
    //22. 计算：每个assT和protoT的综合匹配度。
    [zenTiModel run4MatchValue:protoFeature_p];
    
    //23. 计算：每个model的显著度。
    for (AIFeatureZenTiModel *model in zenTiModel.models) {
        AIFeatureNode *assT = [SMGUtils searchNode:model.assT];
        NSArray *absPorts = [AINetUtils absPorts_All:assT];
        NSInteger allStrong = 0, validStrong = 0;
        
        //24. 显著度公式（参考34175-公式3）。
        for (AIPort *absPort in absPorts) {
            allStrong += absPort.strong.value;
            if ([SMGUtils filterSingleFromArr:matchModels checkValid:^BOOL(AIMatchModel *itemAbsT) {
                return [itemAbsT.match_p isEqual:absPort.target_p];
            }]) {
                validStrong += absPort.strong.value;
            }
        }
        model.modelMatchConStrongRatio = allStrong > 0 ? validStrong / (float)allStrong : 0;
    }
    
    //31. 无效过滤器1、位置符合度=0排除掉。
    NSArray *resultModels = [SMGUtils filterArr:zenTiModel.models checkValid:^BOOL(AIFeatureZenTiModel *item) {
        return item.modelMatchDegree > 0 && item.modelMatchValue > 0;
    }];
    
    //32. 末尾淘汰过滤器：根据位置符合度末尾淘汰（参考34135-TODO4）。
    //2025.04.26: 加上显著度：matchConStrongRatio（参考34175-方案3）。
    resultModels = ARR_SUB([SMGUtils sortBig2Small:resultModels compareBlock:^double(AIFeatureZenTiModel *obj) {
        return obj.modelMatchDegree * obj.modelMatchValue * obj.modelMatchConStrongRatio;
    }], 0, resultModels.count * 0.5);
    
    //33. 防重过滤器2、此处每个特征的不同层级，可能识别到同一个特征，可以按匹配度防下重。
    resultModels = [SMGUtils removeRepeat:resultModels convertBlock:^id(AIFeatureZenTiModel *obj) {
        return obj.assT;
    }];
    
    //34. 末尾淘汰20%被引用强度最低的。
    //TODO: 应该可以去掉了，因为显著度已经做为竞争因子了，此处不再有什么意义（随后测下明确没用就删掉）。
    resultModels = ARR_SUB([SMGUtils sortBig2Small:resultModels compareBlock:^double(AIFeatureZenTiModel *obj) {
        return obj.rectItems.count;
    }], 0, MAX(resultModels.count * 0.9f, 10));
    
    //41. 更新: ref强度 & 相似度 & 抽具象 & 映射;
    for (AIFeatureZenTiModel *matchModel in resultModels) {
        AIFeatureNode *assFeature = [SMGUtils searchNode:matchModel.assT];
        //2025.04.22: 这儿性能不太好，经查现在特征识别不需要组码索引强度做竞争，先关掉。
        //[AINetUtils insertRefPorts_General:assFeature.p content_ps:assFeature.content_ps difStrong:1 header:assFeature.header];
        [protoFeature updateMatchValue:assFeature matchValue:matchModel.modelMatchValue];
        [protoFeature updateMatchDegree:assFeature matchDegree:matchModel.modelMatchDegree];
        
        //42. 存下来zenTiModel用于类比时用一下（参考34139-TODO3）。
        assFeature.zenTiModel = matchModel;
        
        //43. debug
        if (Log4RecogDesc || resultModels.count > 0) NSLog(@"整体特征识别结果:T%ld%@\t（局部特征数:%ld assGV数:%ld protoGV数:%ld）\t匹配度:%.2f\t符合度:%.1f\t显著度:%.2f",
                                                           matchModel.assT.pointerId,CLEANSTR([assFeature getLogDesc:true]),
                                                           matchModel.rectItems.count,assFeature.count,protoFeature.count,
                                                           matchModel.modelMatchValue,matchModel.modelMatchDegree,matchModel.modelMatchConStrongRatio);
        
        //44. 综合求rect: 方案1-通过absT找出综合indexDic然后精确计算出rect，方案2-通过rectItems的每个rect来估算，方案3-这种整体对整体特征没必要存rect，也没必要存抽具象关联。
        //> 抉择：暂选定方案3，因为看了下代码，确实也用不着，像类比analogyFeature_ZenTi()算法，都是通过zenTiModel来的。
        //[AINetUtils relateGeneralAbs:assFeature absConPorts:assFeature.conPorts conNodes:@[protoFeature] isNew:false difStrong:1];
        //[AINetUtils updateConPortRect:assFeature conT:protoFeature_p rect:matchModel.rectItems];
        
        //45. 整体特征识别结果可视化（参考34176）。
        [SMGUtils runByMainQueue:^{
            [theApp.imgTrainerView setDataForFeature:assFeature lab:STRFORMAT(@"整体特征识别T%ld",assFeature.pId) left:0 top:0];
        }];
    }
    
    //51. 转成AIMatchModel格式返回（识别后就用match_p,matchCount,matchValue这三个值）。
    return [SMGUtils convertArr:resultModels convertBlock:^id(AIFeatureZenTiModel *obj) {
        AIMatchModel *model = [[AIMatchModel alloc] initWithMatch_p:obj.assT];
        model.matchCount = obj.rectItems.count;
        model.matchValue = obj.modelMatchValue;
        return model;
    }];
}

/**
 *  MARK:--------------------特征识别--------------------
 *  @desc Step2 尽可能照顾特征的整体性，通过交层向下找似层结果（参考34135-TODO2）。
 *  @version
 *      2025.05.07: v2-支持自适应粒度。
 */
+(NSArray*) recognitionFeature_ZenTi_V2:(AIGroupFeatureNode*)protoGT {
    //1. 数据准备
    AIFeatureZenTiModels *zenTiModel = [AIFeatureZenTiModels new];
    
    //11. 收集：每个absT分别向整体取conPorts。
    for (NSInteger i = 0; i < protoGT.count; i++) {
        AIKVPointer *item_p = ARR_INDEX(protoGT.content_ps, i);
        NSValue *itemRect = ARR_INDEX(protoGT.rects, i);
        NSArray *refPorts = [AINetUtils refPorts_All:item_p];
        
        //12. 将每个conPort先收集到zenTiModel。
        for (AIPort *refPort in refPorts) {
            //if ([refPort.target_p isEqual:protoGT.p]) continue;
            
            //13. 只要似层结果（参考34135-TODO6）。
            //2025.05.13: 只有预测时，才只保留似层，反馈等还是需要交层的，在特征识别时当然就应该打开交层。
            //if (refPort.target_p.isJiao) continue;
            
            //14. 收集原始item数据（参考34136）。
            [zenTiModel updateItem:refPort fromItemT:item_p protoGTIndex:i];
            //NSLog(@"protoGT%ld.protoIndex:%ld=T%ld 在ProtoGT范围%@ 在assGT:%ld的范围:%@",protoGT.pId,i,item_p.pointerId,itemRect,refPort.target_p.pointerId,@(refPort.rect));
        }
    }
    
    //20. 防重：protoGT有多条元素，指向同一条assT的同一个元素时，此方法用于防重。
    [zenTiModel run4BestRemoveRepeat:protoGT.p];
    //for (AIFeatureZenTiModel *model in zenTiModel.models) {
    //    AIFeatureNode *assT = [SMGUtils searchNode:model.assT];
    //    NSLog(@"rectItem数:%ld assT数:%ld protoGT数:%ld",model.rectItems.count,assT.count,protoGT.count);
    //}
    
    //21. 计算：位置符合度: 根据每个整体特征与局部特征的rect来计算。
    [zenTiModel run4MatchDegree:protoGT.p];
    
    //22. 计算：每个assT和protoT的综合匹配度。
    [zenTiModel run4MatchValueV2:protoGT.p];
    
    //23. 计算：每个model的显著度，显著度公式（参考34175-公式3）。
    [zenTiModel run4StrongRatio];
    
    //31. 无效过滤器1、位置符合度=0排除掉。
    NSArray *resultModels = [SMGUtils filterArr:zenTiModel.models checkValid:^BOOL(AIFeatureZenTiModel *item) {
        return item.modelMatchDegree > 0 && item.modelMatchValue > 0;
    }];
    
    //32. 末尾淘汰过滤器：根据位置符合度末尾淘汰（参考34135-TODO4）。
    //2025.04.26: 加上显著度：matchConStrongRatio（参考34175-方案3）。
    resultModels = ARR_SUB([SMGUtils sortBig2Small:resultModels compareBlock:^double(AIFeatureZenTiModel *obj) {
        return obj.modelMatchDegree * obj.modelMatchValue * obj.modelMatchConStrongRatio;
    }], 0, MAX(3, resultModels.count * 0.5));
    
    //33. 防重过滤器2、此处每个特征的不同层级，可能识别到同一个特征，可以按匹配度防下重。
    resultModels = [SMGUtils removeRepeat:resultModels convertBlock:^id(AIFeatureZenTiModel *obj) {
        return obj.assT;
    }];
    
    //34. 末尾淘汰20%被引用强度最低的。
    //TODO: 应该可以去掉了，因为显著度已经做为竞争因子了，此处不再有什么意义（随后测下明确没用就删掉）。
    resultModels = ARR_SUB([SMGUtils sortBig2Small:resultModels compareBlock:^double(AIFeatureZenTiModel *obj) {
        return obj.rectItems.count;
    }], 0, MAX(resultModels.count * 0.9f, 3));
    
    //41. 更新: ref强度 & 相似度 & 抽具象 & 映射;
    for (AIFeatureZenTiModel *matchModel in resultModels) {
        AIFeatureNode *assFeature = [SMGUtils searchNode:matchModel.assT];
        //2025.05.13: 组特征识别需要refStrong做竞争。
        [AINetUtils insertRefPorts_General:assFeature.p content_ps:assFeature.content_ps difStrong:1 header:assFeature.header];
        //[protoFeature updateMatchValue:assFeature matchValue:matchModel.modelMatchValue];
        //[protoFeature updateMatchDegree:assFeature matchDegree:matchModel.modelMatchDegree];
        
        //42. 存下来zenTiModel用于类比时用一下（参考34139-TODO3）。
        //assFeature.zenTiModel = matchModel;
        
        //43. debug
        if (Log4RecogDesc || resultModels.count > 0) NSLog(@"整体特征识别结果:T%ld%@\t（局部特征数:%ld assGV数:%ld）\t匹配度:%.2f\t符合度:%.1f\t显著度:%.2f",
                                                           matchModel.assT.pointerId,CLEANSTR([assFeature getLogDesc:true]),
                                                           matchModel.rectItems.count,assFeature.count,
                                                           matchModel.modelMatchValue,matchModel.modelMatchDegree,matchModel.modelMatchConStrongRatio);
        
        //44. 综合求rect: 方案1-通过absT找出综合indexDic然后精确计算出rect，方案2-通过rectItems的每个rect来估算，方案3-这种整体对整体特征没必要存rect，也没必要存抽具象关联。
        //> 抉择：暂选定方案3，因为看了下代码，确实也用不着，像类比analogyFeature_ZenTi()算法，都是通过zenTiModel来的。
        //[AINetUtils relateGeneralAbs:assFeature absConPorts:assFeature.conPorts conNodes:@[protoFeature] isNew:false difStrong:1];
        //[AINetUtils updateConPortRect:assFeature conT:protoFeature_p rect:matchModel.rectItems];
        
        //45. 整体特征识别结果可视化（参考34176）。
        //for (AIKVPointer *item_p in assFeature.content_ps) {
        //    AIFeatureNode *item = [SMGUtils searchNode:item_p];
        //    [SMGUtils runByMainQueue:^{
        //        [theApp.imgTrainerView setDataForFeature:item lab:STRFORMAT(@"GT.itemT%ld",item.pId)];
        //    }];
        //}
        [SMGUtils runByMainQueue:^{
            //[theApp.imgTrainerView setDataForFeature:assFeature lab:STRFORMAT(@"assGT%ld",assFeature.pId)];
        }];
    }
    
    //46. debugLog
    [TIUtils printLogDescRate:[SMGUtils convertArr:resultModels convertBlock:^id(AIFeatureZenTiModel *obj) {
        return obj.assT;
    }] protoLogDesc:nil prefix:@"整体特征"];
    
    //51. 直接返回：zenTiModel在类比时还要用。
    return resultModels;
}

//MARK:===============================================================
//MARK:                     < 概念识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------概念识别--------------------
 *  @param except_ps : 排除_ps; (如:同一批次输入的概念组,不可用来识别自己)
 *  注: 无条件 & 目前无能量消耗 (以后有基础思维活力值后可energy-1)
 *  注: 局部匹配_后面通过调整参数,来达到99%以上的识别率;
 *
 *  Q1: 老问题,看到的algNode与识别到的,未必是正确的,但我们应该保持使用protoAlgNode而不是recognitionAlgNode;
 *  A1: 190910在理性思维完善后,识别result和protoAlg都有用;
 *
 *  Q2: 概念的嵌套,有可能会导致识别上的一些问题; (我们需要支持结构化识别,而不仅是绝对识别和模糊识别)
 *  A2: 190910概念嵌套已取消,正在做结构化识别,此次改动是为了完善ThinkReason细节;
 *  @version 迭代记录:
 *      20190910: 识别"概念与时序",并构建纵向关联; (190910概念识别,添加了抽象关联)
 *      20191223: 局部匹配支持全含: 对assAlg和protoAlg直接做抽象关联,而不是新构建抽象;
 *      20200307: 迭代支持模糊匹配fuzzy
 *      20200413: 无全含时,支持最相似的seemAlg返回;
 *      20200416: 废除绝对匹配 (因概念全局去重了,绝对匹配匹配没有意义);
 *      20200703: 废弃fuzzy模糊匹配功能,因为识别期要广入 (参考20062);
 *      20201022: 同时支持matchAlg和seemAlg结果 (参考21091);
 *      20201022: 将seem的抽象搬过来,且支持三种关联处理 (参考21091-蓝绿黄三种线);
 *      20220115: 识别结果可为自身,参考recognitionAlg_Run(),所以不需要此处再add(self)了;
 *      20220116: 全含可能也只是相似,由直接构建抽具象关联,改成概念外类比 (参考25105);
 *      20220528: 把概念外类比关掉 (参考26129-方案2-1);
 *      20221018: 对proto直接抽象指向matchAlg (参考27153-todo3);
 *      20221024: 将抽具象相似度存至algNode中 (参考27153-todo2);
 *      2022.01.16: 改为直接传入inModel模型,识别后赋值到inModel中即可;
 *      2021.09.27: 仅识别ATDefault类型 (参考24022-BUG4);
 *      2019.12.23 - 迭代支持全含,参考17215 (代码中由判断相似度,改为判断全含)
 *      2020.04.13 - 将结果通过complete返回,支持全含 或 仅相似 (因为正向反馈类比的死循环切入问题,参考:n19p6);
 *      2020.07.21 - 当Seem结果时,对seem和proto进行类比抽象,并将抽象概念返回 (参考:20142);
 *      2020.07.21 - 当Seem结果时,虽然构建了absAlg,但还是将seemAlg返回 (参考20142-Q1);
 *      2020.10.22 - 支持matchAlg和seemAlg二者都返回 (参考21091);
 *      2020.11.18 - 支持多全含识别 (将所有全含matchAlgs返回) (参考21145方案1);
 *      2020.11.18 - partAlgs将matchAlgs移除掉,仅保留非全含的部分;
 *      2022.01.13 - 迭代支持相近匹配 (参考25082 & 25083);
 *      2022.01.15 - 识别结果可为自身: 比如(飞↑)如果不识别自身,又全局防重,就识别不到最全含最相近匹配结果了;
 *      2022.05.11 - 全含不要求必须是抽象节点,因为相近匹配时,可能最具象也会全含 (且现在全是absNode类型);
 *      2022.05.12 - 仅识别有mv指向的结果 (参考26022-3);
 *      2022.05.13 - 弃用partAlgs (参考26024);
 *      2022.05.20 - 1. 窄出,仅返回前NarrowLimit条 (参考26073-TODO2);
 *      2022.05.20 - 2. 改匹配度公式: matchCount改成protoCount (参考26073-TODO3);
 *      2022.05.20 - 3. 所有结果全放到matchAlgs中 (参考26073-TODO4);
 *      2022.05.20 - 4. 废弃仅识别有mv指向的 (参考26073-TODO5);
 *      2022.05.23 - 将匹配度<90%的过滤掉 (参考26096-BUG3);
 *      2022.05.24 - 排序公式改为sumNear / matchCount (参考26103-代码);
 *      2022.05.25 - 排序公式改为sumNear / proto.count (参考26114-1);
 *      2022.05.28 - 优化性能 (参考26129-方案2);
 *      2022.06.07 - 为了打开抽象结果(确定,轻易别改了),排序公式改为sumNear / matchCount (参考2619j-TODO2);
 *      2022.06.07 - 排序公式改为sumNear / nearCount (参考2619j-TODO5);
 *      2022.06.13 - 修复因matchCount<result.count导致概念识别有错误结果的BUG (参考26236);
 *      2022.10.20 - 删掉早已废弃的partAlgs代码 & 将返回List<AlgNode>类型改成List<AIMatchAlgModel> (参考27153);
 *      2022.12.19 - 迭代概念识别结果的竞争机制 (参考2722d-方案2);
 *      2023.01.18 - 相似度用相乘 (参考28035-todo1);
 *      2023.01.24 - BUG修复: 修复相似度相乘后,相似度阈值相应调低 (参考28041-BUG1);
 *      2023.02.01 - 不限制相似度,让其自然竞争越来越准确 (参考28042-思路2-4);
 *      2023.02.21 - 识别结果保留20% (参考28102-方案1);
 *      2023.02.25 - 集成概念识别过滤器 (参考28111-todo1) & 取消识别后过滤20% (参考28111-todo2);
 *      2023.04.09 - 仅识别似层 (参考29064-todo1);
 *      2023.06.01 - 将识别结果拆分成pAlgs和rAlgs两个部分 (参考29108-2.1);
 *      2023.06.02 - 性能优化_复用vInfo (在识别二次过滤器中测得,这个vInfo在循环中时性能影响挺大的);
 *      2023.06.03 - 性能优化_复用cacheDataDic到循环外 & cacheProtoData到循环外 & proto收集防重用dic (参考29109-测得3);
 *      2025.03.20 - 兼容多码特征（参考n34p04）。
 */
+(void) recognitionAlgStep1:(NSArray*)except_ps inModel:(AIShortMatchModel*)inModel {
    //0. 数据准备;
    AIAlgNodeBase *protoAlg = inModel.protoAlg;
    if (!ISOK(protoAlg, AIAlgNodeBase.class)) return;
    except_ps = ARRTOOK(except_ps);
    IFTitleLog(@"概念识别",@"\n%@\tlogDesc:%@",Alg2FStr(protoAlg),CLEANSTR([protoAlg getLogDesc:false].allKeys));
    
    //1. 收集prAlgs <K:pid,V:AIMatchAlgModel> (注: 现在alg的atds全是空,用pid就能判断唯一);
    NSMutableDictionary *protoPDic = [NSMutableDictionary new], *protoRDic = [NSMutableDictionary new];
    
    //2. 广入: 对每个元素,分别取索引序列 (参考25083-1);
    for (NSInteger i = 0; i < protoAlg.count; i++) {
        AIKVPointer *item_p = ARR_INDEX(protoAlg.content_ps, i);
        
        //3. 取相近度序列 (按相近程度排序);
        NSArray *subMatchModels = nil;
        if (PitIsValue(item_p)) {
            subMatchModels = [AIRecognitionCache getCache:item_p cacheBlock:^id{
                return [self recognitionValue:item_p rate:0.8 minLimit:20];//v1单码特征
            }];
        } else {
            subMatchModels = [AIRecognitionCache getCache:item_p cacheBlock:^id{
                //a. 通过组码做局部特征识别。
                NSArray *jvBuResult = ARRTOOK([self recognitionFeature_JvBu:item_p]);
                //b. 通过抽象特征做整体特征识别，把JvBu的结果传给ZenTi继续向似层识别（参考34135-TODO5）。
                NSArray *zenTiResult = [self recognitionFeature_ZenTi:item_p matchModels:jvBuResult];
                return [SMGUtils collectArrA:jvBuResult arrB:zenTiResult];
            }];
        }
        
        //4. 每个near_p做两件事:
        for (AIMatchModel *subMatchModel in subMatchModels) {
            
            //2024.04.27: BUG_这里有nearV为0的,导致后面可能激活一些完全不准确的结果 (修复: 加上末尾淘汰: 相似度为0的就不收集了先,看下应该也不影响别的什么);
            if (subMatchModel.matchValue == 0) continue;
            
            //6. 第2_取near_p的refPorts (参考25083-1) (性能: 无缓存时读266耗240,有缓存时很快);
            NSArray *refPorts = [AINetUtils refPorts_All:subMatchModel.match_p];
            
            //2024.04.27: BUG_把此处强度淘汰取消掉,不然淘汰70%也太多了,新的概念即使再准也没机会 (比如: 向90跑10左右的有皮果,因为是后期特定训练步骤里才经历的,在这里老是识别不到);
            //refPorts = ARR_SUB(refPorts, 0, cPartMatchingCheckRefPortsLimit_Alg(refPorts.count));
            
            //6. 第3_仅保留有mv指向的部分 (参考26022-3);
            //refPorts = [SMGUtils filterArr:refPorts checkValid:^BOOL(AIPort *item) {
            //    return item.targetHavMv;
            //}];
            //if (Log4MAlg) NSLog(@"当前near_p:%@ --ref数量:%lu",[NVHeUtil getLightStr:near_p],(unsigned long)refPorts.count);
            
            //7. 每个refPort做两件事: (性能: 以下for循环耗150ms很正常);
            for (AIPort *refPort in refPorts) {
                if ([refPort.target_p isEqual:protoAlg.p]) continue;
                
                //8. 不应期 -> 不可激活;
                if ([SMGUtils containsSub_p:refPort.target_p parent_ps:except_ps]) continue;
                
                //9. 找model (无则新建) (性能: 此处在循环中,所以防重耗60ms正常,收集耗100ms正常);
                NSMutableDictionary *protoDic = refPort.targetHavMv ? protoPDic : protoRDic;
                AIMatchAlgModel *model = [protoDic objectForKey:@(refPort.target_p.pointerId)];
                if (!model) {
                    model = [[AIMatchAlgModel alloc] init];
                    //9. 收集;
                    [protoDic setObject:model forKey:@(refPort.target_p.pointerId)];
                }
                model.matchAlg = refPort.target_p;
                
                //9. 映射（i表示protoIndex，从ref中找assT找到即为assIndex）（此处必须先读出assA才能找着对应的assIndex，如果有性能问题，随后可以把assIndex存到refPort.params中）。
                AIAlgNodeBase *assA = [SMGUtils searchNode:refPort.target_p];
                NSInteger assIndex = [assA.content_ps indexOfObject:subMatchModel.match_p];
                if (assIndex == -1) continue;
                [model.indexDic setObject:@(i) forKey:@(assIndex)];
                
                //10. 统计匹配度matchCount & 相近度<1个数nearCount & 相近度sumNear & 引用强度sumStrong
                model.matchCount++;
                model.groupValueMatchCount += subMatchModel.matchCount;
                model.nearCount++;
                model.sumNear *= subMatchModel.matchValue;
                model.sumRefStrong += (int)refPort.strong.value;
            }
        }
    }
    
    //11. 多码特征的识别用竞争方式（测试与训练的mnist，其H通道不同，所以没法全含，这里用竞争方式）。
    //> 既然无法全含，就得把indexDic存下来，到类比时用，因为未匹配到的特征在类比时是无法取得位置符合度字典的（参考上面的model.indexDic收集）。
    NSArray *validPAlgs = nil; NSArray *validRAlgs = nil;
    if ([SMGUtils filterSingleFromArr:protoAlg.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return PitIsFeature(item);
    }]) {
        //2025.04.07：BUG-修复最后都是匹配数=2的，因为BS这两个通道加起来，也远没有hColors通道作用大，改成以gvMatchCount的和来判断匹配数。
        CGFloat pinJunMatchCount_R = protoRDic.count == 0 ? 0 : [SMGUtils sumOfArr:protoRDic.allValues convertBlock:^double(AIMatchAlgModel *obj) {
            return obj.groupValueMatchCount;
        }] / (float)protoRDic.count;
        validRAlgs = [SMGUtils filterArr:protoRDic.allValues checkValid:^BOOL(AIMatchAlgModel *item) {
            return item.groupValueMatchCount >= pinJunMatchCount_R;
        }];
        CGFloat pinJunMatchCount_P = protoPDic.count == 0 ? 0 : [SMGUtils sumOfArr:protoPDic.allValues convertBlock:^double(AIMatchAlgModel *obj) {
            return obj.groupValueMatchCount;
        }] / (float)protoPDic.count;
        validPAlgs = [SMGUtils filterArr:protoPDic.allValues checkValid:^BOOL(AIMatchAlgModel *item) {
            return item.groupValueMatchCount > pinJunMatchCount_P;
        }];
        //NSLog(@"平均GV匹配数：%.2f %.2f",pinJunMatchCount_R,pinJunMatchCount_P);
    }
    
    //12. 全含判断: 从大到小,依次取到对应的node和matchingCount (注: 支持相近后,应该全是全含了,参考25084-1) (性能:无缓存时读400耗400ms,有缓存时30ms);
    else {
        validPAlgs = [self recognitionAlg_CheckValid:protoPDic.allValues protoAlgCount:protoAlg.count];
        validRAlgs = [self recognitionAlg_CheckValid:protoRDic.allValues protoAlgCount:protoAlg.count];
    }
    
    //13. 似层交层分开进行竞争 (分开竞争是以前就一向如此的,因为同质竞争才公平) (为什么要保留交层: 参考31134-TODO1);
    //2025.04.19: 改为用isJiao来判断交似层，避免很交层特征的却归到似层里，而原本整体特征却因为竞争力不如这些假的，反被顶掉。
    NSArray *validPSAlgs = [SMGUtils filterArr:validPAlgs checkValid:^BOOL(AIMatchAlgModel *item) {
        return !item.matchAlg.isJiao;
    }];
    NSArray *validPJAlgs = [SMGUtils filterArr:validPAlgs checkValid:^BOOL(AIMatchAlgModel *item) {
        return item.matchAlg.isJiao;
    }];
    NSArray *validRSAlgs = [SMGUtils filterArr:validRAlgs checkValid:^BOOL(AIMatchAlgModel *item) {
        return !item.matchAlg.isJiao;
    }];
    NSArray *validRJAlgs = [SMGUtils filterArr:validRAlgs checkValid:^BOOL(AIMatchAlgModel *item) {
        return item.matchAlg.isJiao;
    }];
    
    //13. 识别过滤器 (参考28109-todo2);
    NSArray *filterPSAlgs = [AIFilter recognitionAlgFilter:validPSAlgs radio:0.5f];
    NSArray *filterPJAlgs = [AIFilter recognitionAlgFilter:validPJAlgs radio:0.5f];
    NSArray *filterRSAlgs = [AIFilter recognitionAlgFilter:validRSAlgs radio:0.36f];
    NSArray *filterRJAlgs = [AIFilter recognitionAlgFilter:validRJAlgs radio:0.36f];
    
    //14. 识别竞争机制 (参考2722d-方案2);
    //14. 按nearA排序 (参考25083-2&公式2 & 25084-1);
    //15. 未将全含返回,则返回最相似 (2020.10.22: 全含返回,也要返回seemAlg) (2022.01.15: 支持相近匹配后,全是全含没局部了);
    inModel.matchAlgs_PS = [AIRank recognitionAlgRank:filterPSAlgs];
    inModel.matchAlgs_PJ = [AIRank recognitionAlgRank:filterPJAlgs];
    inModel.matchAlgs_RS = [AIRank recognitionAlgRank:filterRSAlgs];
    inModel.matchAlgs_RJ = [AIRank recognitionAlgRank:filterRJAlgs];
    
    //16. debugLog
    NSLog(@"\n概念识别结果 (感似:%ld条 理似:%ld条 感交:%ld 理交:%ld) protoAlg:%@",inModel.matchAlgs_PS.count,inModel.matchAlgs_RS.count,inModel.matchAlgs_PJ.count,inModel.matchAlgs_RJ.count,Alg2FStr(protoAlg));
    [inModel log4HavXianWuJv_AlgPJ:@"fltx1"];
    
    //17. debugLog2
    NSArray *logModels = [SMGUtils sortBig2Small:inModel.matchAlgs_All compareBlock1:^double(AIMatchAlgModel *obj) {
        return obj.matchAlg.isJiao;
    } compareBlock2:^double(AIMatchAlgModel *obj) {
        return obj.matchValue;
    }];
    for (AIMatchAlgModel *model in logModels) {
        AIAlgNodeBase *assAlg = [SMGUtils searchNode:model.matchAlg];
        NSLog(@"%@概念识别结果：A%ld%@ \t匹配（T数：%d GV数：%ld 度：%.2f）proto:%@ ass:%@",assAlg.p.isJiao?@"局部":@"整体",assAlg.pId,CLEANSTR([SMGUtils convertArr:assAlg.content_ps convertBlock:^id(AIKVPointer *obj) {
            return STRFORMAT(@"T%ld",obj.pointerId);
            //AIFeatureNode *itemT = [SMGUtils searchNode:obj];
            //return STRFORMAT(@"T%ld 交层=%d 整体=%d",obj.pointerId,obj.isJiao,itemT.zenTiModel != nil);
        }]),model.matchCount,model.groupValueMatchCount,model.matchValue,CLEANSTR([protoAlg getLogDesc:true].allKeys),CLEANSTR([assAlg getLogDesc:assAlg.p.isJiao]));
    }
    
    //18. debugLog3
    [TIUtils printLogDescRate:[SMGUtils convertArr:logModels convertBlock:^id(AIMatchAlgModel *obj) {
        return obj.matchAlg;
    }] protoLogDesc:CLEANSTR([protoAlg getLogDesc:false].allKeys) prefix:@"概念"];
    
    //19. 概念识别结果可视化（参考34176）。
    [SMGUtils runByMainQueue:^{
        //[theApp.imgTrainerView setDataForAlgs:logModels];
        [theApp.imgTrainerView setDataForAlg:protoAlg lab:STRFORMAT(@"ProtoA%ld",protoAlg.pId)];
        for (AIMatchAlgModel *model in logModels) {
            AIAlgNodeBase *assAlg = [SMGUtils searchNode:model.matchAlg];
            [theApp.imgTrainerView setDataForAlg:assAlg lab:STRFORMAT(@"%@assA%ld",assAlg.p.isJiao?@"局部":@"整体",assAlg.pId)];
        }
    }];
    [AIRecognitionCache printLog:true];
}

/**
 *  MARK:--------------------概念识别全含判断--------------------
 */
+(NSArray*) recognitionAlg_CheckValid:(NSArray*)protoPRModels protoAlgCount:(NSInteger)protoAlgCount{
    //1. 全含判断: 从大到小,依次取到对应的node和matchingCount (注: 支持相近后,应该全是全含了,参考25084-1);
    return [SMGUtils filterArr:protoPRModels checkValid:^BOOL(AIMatchAlgModel *item) {
        //2. 过滤掉匹配度<85%的;
        //if (item.matchValue < 0.60f) return false;
        
        //3. 过滤掉非全含的 (当count!=matchCount时为局部匹配: 局部匹配partAlgs已废弃);
        AIAlgNodeBase *itemAlg = [SMGUtils searchNode:item.matchAlg];
        if (itemAlg.count != item.matchCount) return false;
        
        //4. 过滤掉非似层的 (参考29064-todo1);
        //2024.03.28: 交似层都返回 (参考31134-TODO1);
        //if (itemAlg.count != protoAlgCount) return false;
        return true;
    }];
}

/**
 *  MARK:--------------------概念识别-第二步: 抽具象关联--------------------
 */
+(void) recognitionAlgStep2:(AIShortMatchModel*)inModel {
    //5. 关联处理 & 外类比 (这样后面TOR理性决策时,才可以直接对当前瞬时实物进行很好的理性评价) (参考21091-蓝线);
    NSLog(@"概念识别关联 (感似:%ld条 理似:%ld条 感交:%ld 理交:%ld) protoAlg:%@",inModel.matchAlgs_PS.count,inModel.matchAlgs_RS.count,inModel.matchAlgs_PJ.count,inModel.matchAlgs_RJ.count,Alg2FStr(inModel.protoAlg));
    for (AIMatchAlgModel *matchModel in inModel.matchAlgs_All) {
        //4. 识别到时,value.refPorts -> 更新/加强微信息的引用序列
        AIAbsAlgNode *matchAlg = [SMGUtils searchNode:matchModel.matchAlg];
        [AINetUtils insertRefPorts_AllAlgNode:matchModel.matchAlg content_ps:matchAlg.content_ps difStrong:1];
        
        //5. 存储protoAlg与matchAlg之间的相近度记录 (参考27153-todo2);
        [inModel.protoAlg updateMatchValue:matchAlg matchValue:matchModel.matchValue];
        
        //6. 对proto直接抽象指向matchAlg,并增强强度值 (为保证抽象多样性,所以相近的也抽具象关联) (参考27153-3);
        [AINetUtils relateAlgAbs:matchAlg conNodes:@[inModel.protoAlg] isNew:false];
        [AITest test25:matchAlg conNodes:@[inModel.protoAlg]];
        
        //7. 存映射。
        [inModel.protoAlg updateIndexDic:matchAlg indexDic:matchModel.indexDic];
    }
    
    for (AIMatchAlgModel *matchModel in ARR_SUB(inModel.matchAlgs_PS, 0, 5)) {
        //7. log
        NSString *prDesc = [inModel.matchAlgs_R containsObject:matchModel] ? @"r" : @"p";
        NSString *sjDesc = [inModel.matchAlgs_Si containsObject:matchModel] ? @"s" : @"j";
        if (Log4MAlg) NSLog(@"%@%@-->>>(%d) 全含item: %@   \t相近度 => %.2f (count:%d)",prDesc,sjDesc,matchModel.sumRefStrong,Pit2FStr(matchModel.matchAlg),matchModel.matchValue,matchModel.matchCount);
    }
}

//MARK:===============================================================
//MARK:                     < 时序识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------时序局部匹配算法--------------------
 *
 *  --------------------V1--------------------
 *  参考: n17p7 TIR_FO模型到代码
 *  _param assFoIndexAlg    : 用来联想fo的索引概念 (shortMem的第3层 或 rethink的第1层) (match层,参考n18p2)
 *  _param assFoBlock       : 联想fos (联想有效的5个)
 *  _param checkItemValid   : 检查item(fo.alg)的有效性 notnull (可考虑写个isBasedNode()判断,因protoAlg可里氏替换,目前仅支持后两层)
 *  @param inModel          : 装饰结果到inModel中;
 *  _param indexProtoAlg    : assFoIndexAlg所对应的protoAlg,用来在不明确时,用其独特稀疏码指引向具象时序找"明确"预测;
 *  _param fromRegroup      : 调用者
 *                              1. 正常识别时: cutIndex=lastAssIndex;
 *                              2. 源自regroup时: cutIndex需从父任务中判断 (默认为-1);
 *  _param maskFo           : 识别时:protoFo中的概念元素为parent层, 而在反思时,其元素为match层;
 *  @param matchAlgs        : 触发此识别时的那一帧的概念识别结果 (参考28103-2);
 *  @param protoOrRegroupCutIndex : proto或regroup当前已经进展到哪里,发进来cutIndex (proto时一般是全已发生);
 *  TODO_TEST_HERE:调试Pointer能否indexOfObject
 *  TODO_TEST_HERE:调试下item_p在indexOfObject中,有多个时,怎么办;
 *  TODO_TEST_HERE:测试下cPartMatchingThreshold配置值是否合理;
 *  @desc1: 在类比中,仅针对最后一个元素,与前面元素进行类比;
 *  @desc2: 内类比大小,将要取消(由外类比取代),此处不再支持;而内类比有无,此处理性概念全是"有";
 *  @desc:
 *      1. 根据最后一个节点,取refPorts,
 *      2. 对共同引用者的,顺序,看是否是正确的从左到右顺序;
 *      3. 能够匹配到更多个概念节点,越预测准确;
 *  TODO_FUTURE:判断概念匹配,目前仅支持一层抽象判断,是否要支持多层?实现方式比如(索引 / TIRAlg和TIRFo的协作);
 *
 *  @version:
 *      20191231: 测试到,点击饥饿,再点击乱投,返回matchFo:nil matchValue:0;所以针对此识别失败问题,发现了_fromShortMem和_fromRethink的不同,且支持了两层assFo,与全含;(参考:n18p2)
 *      20200627: 支持明确价值预测 & 支持更匹配的时序预测 (参考:20052);
 *      20200703: 废弃明确价值预测功能,因为认知期要广入,决策期再细修 (参考20063);
 *
 *  --------------------V1.5--------------------
 *  @desc
 *      1. 由v1整理而来,逻辑与v1一致 (将v1中checkItemValid和assFoBlock回调,直接写在方法中,而不由外界传入);
 *      2. 时序识别v1.5 (在V1的基础上改的,与V2最大的区别,是其未按照索引计数排序);
 *
 *  @status 启用,因为v2按照countDic排序的方式,不利于找出更确切的抽象结果;
 *
 *  --------------------v2--------------------
 *  @desc 功能说明:
 *      1. 本次v2迭代,主要在识别率上进行改进,因为v1识别率太低 (参考20111),所以迭代了v2版 (参考20112);
 *      2. 目前判断有效引用,不支持"必须包含某protoAlg" (代码第5步),以前需要再支持即可;
 *  @desc 执行步骤:
 *      1. 原始时序protoFo的每个元素都是索引;
 *      2. 对每个元素protoAlg自身1条 + 抽象5条 = 共6条做索引;
 *      3. 根据6条取refPorts引用时序;
 *      4. 对所有引用的时序,做计数判断,引用了越多的原始元素protoAlg,排在越前面;
 *      5. 从前开始找,找出引用即多,又全含的结果返回;
 *  @version 候选集
 *      2020.07.18: 将整个allRef_2拍平成一维数组,并去重 (即所有帧的refFos都算做候选集);
 *      2020.07.19: 改为仅取最后一位的refFos (因为最后一位是焦点帧,并且全含判断算法也需要支持仅末位候选集);
 *      2020.11.12: 支持except_ps参数,因为在FromShortMem时,matchAFo会识别protoFo返回,所以将protoFo不应期掉 (参考21144);
 *      2021.01.18: 联想matchFo时,由原本只获取Normal类型,改为将HNGL也加入其中 (参考22052-1a,实测未影响原多向飞行训练);
 *      2021.01.23: 支持多识别 (参考22072BUG & TIR_Fo_FromRethink注释todo更多元的评价 & 22073-todo1);
 *      2021.01.24: 改回仅识别Normal类型,因为HNGL太多了,不那么必要,还特麻烦,太多matchFos导致性能差 (参考22052-改1);
 *      2021.01.24: 将无mv指向的,算无效 (因为有大量未执行的正向反馈类比) (参考22072);
 *      2021.01.26: 为多时序识别结果做去重 (参考22074-BUG3);
 *      2021.01.31: 将无mv指向的,放开 (因为R-模式需要) (等支持反向反馈外类比后,再关掉) (参考n22p10);
 *      2021.02.03: 反向反馈外类比已支持,将无mv指向的关掉 (参考version上条);
 *      2021.02.04: 将matchFos中的虚mv筛除掉,因为现在R-模式不使用matchFos做解决方案,现在留着没用,等有用时再打开;
 *      2021.04.15: 无mv指向的支持返回为matchRFos,原来有mv指向的重命名为matchPFos (参考23014-分析1&23016);
 *      2021.06.30: 支持cutIndex回调,识别和反思时,分别走不同逻辑 (参考23152);
 *      2021.08.19: 结果PFos和RFos按(强度x匹配度)排序 (参考23222-BUG2);
 *      2022.01.16: 仅保留10条rFos和pFos (因为在十四测中,发现它们太多了,都有40条rFos的时候,依窄出原则,太多没必要);
 *      2022.03.05: 将保留10条改为全保留,因为不同调用处,需要不同的筛选排序方式 (参考25134-方案2);
 *      2022.03.09: 将排序规则由"强度x匹配度",改成直接由SP综合评分来做 (参考25142 & 25114-TODO2);
 *      2022.04.30: 识别时assIndexes取proto+matchs+parts (参考25234-1);
 *      2022.05.12: 仅识别有mv指向的结果 (参考26022-3);
 *      2022.05.18: 把pFo排序因子由评分绝对值,改成取负,因为正价值不构成任务,所以把它排到最后去;
 *      2022.05.20: 1. 废弃仅识别有mv指向的 (参考26073-TODO7);
 *      2022.05.20: 2. RFos排序,不受被引用强度影响 (参考26073-TODO9);
 *      2022.05.20: 3. prFos排序,以SP稳定性为准 (参考26073-TODO8);
 *      2022.05.20: 4. 提升识别准确度: 窄入,调整结果20条为NarrowLimit=5条 (参考26073-TODO6);
 *      2022.05.23: 将稳定性低的识别结果过滤掉 (参考26096-BUG4);
 *      2022.05.24: 稳定性支持衰减 (参考26104-方案);
 *      2022.06.07: cRFoNarrowLimit调整为0,即关掉RFos结果 (参考2619j-TODO3);
 *      2022.06.08: 排序公式改为sumNear / nearCount (参考26222-TODO1);
 *      2022.11.10: 因为最近加强了抽具象多层多样性,所以从matchAlgs+partAlgs取改为从lastAlg.absPorts取 (效用一样);
 *      2022.11.10: 时序识别中alg相似度复用-准备部分 & 参数调整 (参考27175-5);
 *      2022.11.15: 对识别结果,直接构建抽具象关联 (参考27177-todo6);
 *      2022.12.28: 求出匹配部分的综合引用强度值,并参与到综合竞争中 (参考2722f-todo13&todo14);
 *      2022.12.29: 时序识别后,增强indexDic已发生部分的refStrong和contentStrong (参考2722f-todo32&todo33);
 *      2023.02.21: 废弃收集proto的lastAlg当索引,因为它只被protoFo一条时序引用,所以在时序识别中没什么用 (参考28103-4另);
 *      2023.02.21: 传入触发帧概念识别结果matchAlgs的前10条做为时序识别的索引 (参考28103-2);
 *      2023.02.24: 提升时序识别成功率: 把索引改成所有proto帧的抽象alg (参考28107-todo1);
 *      2023.02.24: 提升时序识别成功率: 废弃matchRFos (其实早废弃了,借着这次改,彻底此处相关代码删掉);
 *      2023.02.24: 提升时序识别成功率: 时序结果保留20% (参考28107-todo4);
 *      2023.03.15: 打开matchRFos (参考28181-方案3);
 *      2023.03.17: 关闭matchRFos (参考28184-原因1&2);
 *      2023.07.11: 行为化反思时,将regroupCutIndex传进来,并根据它计算出absMatchFo的cutIndex,避免因此而计算sp率等不准确;
 *      2023.07.19: TC线程_因为数组多线程导致,导致foreach中闪退问题 (改加上copy);
 *      2024.10.29: 时序识别似层化 (参考33111-TODO1);
 *  @status 废弃,因为countDic排序的方式,不利于找出更确切的抽象结果 (识别不怕丢失细节,就怕不确切,不全含);
 */
+(void) recognitionFoStep1:(AIFoNodeBase*)protoOrRegroupFo except_ps:(NSArray*)except_ps decoratorInModel:(AIShortMatchModel*)inModel fromRegroup:(BOOL)fromRegroup matchAlgs:(NSArray*)matchAlgs protoOrRegroupCutIndex:(NSInteger)protoOrRegroupCutIndex debugMode:(BOOL)debugMode{
    //1. 数据准备;
    except_ps = ARRTOOK(except_ps);
    NSMutableArray *protoPModels = [[NSMutableArray alloc] init];
    NSMutableArray *protoRModels = [[NSMutableArray alloc] init];
    
    //2. 广入: 对每个元素,分别取索引序列 (参考25083-1);
    NSArray *protoOrRegroupContent_ps = [protoOrRegroupFo.content_ps copy];
    for (NSInteger i = 0; i < protoOrRegroupContent_ps.count; i++) {
        AIKVPointer *proto_p = ARR_INDEX(protoOrRegroupContent_ps, i);
        AIAlgNodeBase *protoAlg = [SMGUtils searchNode:proto_p];
        
        //3. 每个abs_p分别索引;
        NSArray *protoAlgAbs_ps = [self getProtoAlgAbsPs:protoOrRegroupFo protoIndex:i inModel:inModel fromRegroup:fromRegroup];
        
        //4. 仅保留似层: 索引absAlg是交层,则直接continue (参考33111-TODO1);
        protoAlgAbs_ps = [SMGUtils filterArr:protoAlgAbs_ps checkValid:^BOOL(AIKVPointer *item) {
            return !item.isJiao;
        }];
        NSLog(@"索引数: %ld -> %ld",protoAlg.absPorts.count,protoAlgAbs_ps.count);
        
        for (AIKVPointer *absAlg_p in protoAlgAbs_ps) {
            AIAlgNodeBase *absAlg = [SMGUtils searchNode:absAlg_p];
            
            //5. 第2_取abs_p的refPorts (参考28107-todo2);
            NSArray *refPorts = [[AINetUtils refPorts_All4Alg_Normal:absAlg] copy];
            
            //6. RFo的长度>1才有意义 (参考28183-BUG1);
            refPorts = [SMGUtils filterArr:refPorts checkValid:^BOOL(AIPort *item) {
                if (Switch4RecognitionMatchRFos) {
                    //a. 打开pFos和rFos;
                    AIFoNodeBase *refFo = [SMGUtils searchNode:item.target_p];
                    return item.targetHavMv || refFo.count > 1;
                } else {
                    //b. 只打开matchPFos;
                    return item.targetHavMv;
                }
            }];
            
            //7. 每个refPort做两件事:
            for (AIPort *refPort in refPorts) {
                //8. 不应期 -> 不可激活 & 收集到不应期同一fo仅处理一次;
                if ([SMGUtils containsSub_p:refPort.target_p parent_ps:except_ps]) continue;
                except_ps = [SMGUtils collectArrA:except_ps arrB:@[refPort.target_p]];
                
                //7. 仅保留似层: 联想到的fo是交层,则直接continue (参考33111-TODO1);
                if (refPort.target_p.isJiao) continue;
                
                //7. 全含判断;
                AIFoNodeBase *refFo = [SMGUtils searchNode:refPort.target_p];
                NSDictionary *indexDic = [self recognitionFo_CheckValidV3:refFo protoOrRegroupFo:protoOrRegroupFo fromRegroup:fromRegroup inModel:inModel];
                if (!DICISOK(indexDic)) continue;
                
                //7. 取absCutIndex, 说明: cutIndex指已发生到的index,后面则为时序预测; matchValue指匹配度(0-1)
                NSInteger cutIndex = [AINetUtils getCutIndexByIndexDicV2:indexDic protoOrRegroupCutIndex:protoOrRegroupCutIndex];
                
                //7. 根据indexDic取nearCount & sumNear;
                NSArray *nearData = [AINetUtils getNearDataByIndexDic:indexDic absFo:refFo.pointer conFo:protoOrRegroupFo.pointer callerIsAbs:false];
                int nearCount = NUMTOOK(ARR_INDEX(nearData, 0)).intValue;
                CGFloat sumNear = NUMTOOK(ARR_INDEX(nearData, 1)).floatValue;
                
                //8. 被引用强度;
                NSInteger sumRefStrong = [AINetUtils getSumRefStrongByIndexDic:indexDic matchFo:refFo.pointer];
                
                //7. 实例化识别结果AIMatchFoModel;
                AIMatchFoModel *newMatchFo = [AIMatchFoModel newWithMatchFo:refFo.pointer protoOrRegroupFo:protoOrRegroupFo.pointer sumNear:sumNear nearCount:nearCount indexDic:indexDic cutIndex:cutIndex sumRefStrong:sumRefStrong baseFrameModel:inModel];
                if (Log4MFo) NSLog(@"时序识别itemSUCCESS 匹配度:%f %@->%@",newMatchFo.matchFoValue,Fo2FStr(refFo),Mvp2Str(refFo.cmvNode_p));
                
                //9. 收集到pFos/rFos;
                if (refFo.cmvNode_p) {
                    [protoPModels addObject:newMatchFo];
                } else {
                    [protoRModels addObject:newMatchFo];
                }
            }
        }
    }
    
    //10. 过滤强度前20% (参考28111-todo1);
    NSArray *filterPModels = [AIFilter recognitionFoFilter:protoPModels];
    NSArray *filterRModels = [AIFilter recognitionFoFilter:protoRModels];
    
    //10. 按照 (强度x匹配度) 排序,强度最重要,包含了价值初始和使用频率,其次匹配度也重要 (参考23222-BUG2);
    NSArray *sortPs = [AIRank recognitionFoRank:filterPModels];
    NSArray *sortRs = [AIRank recognitionFoRank:filterRModels];
    inModel.matchPFos = [[NSMutableArray alloc] initWithArray:sortPs];
    inModel.matchRFos = [[NSMutableArray alloc] initWithArray:sortRs];
    if (debugMode) NSLog(@"\n时序识别结果 P(%ld条) R(%ld条)",inModel.matchPFos.count,inModel.matchRFos.count);
    [inModel log4HavXianWuJv_PFos:@"fltx2"];
    
    //2024.12.05: 每次反馈同F只计一次: 避免F值快速重复累计到很大,sp更新(同场景下的)防重推 (参考33137-方案v5);
    //NSMutableArray *except4SP2F = [[NSMutableArray alloc] init];
    //13. inSP值子即父: 时序识别成功后,protoFo从0到cutIndex全计P+1 (参考33112-TODO4.3 & 33134-FIX2a);
    //2024.12.10: 先关掉这里,因为在forecast_Multi()中,已经给pFo已发生部分计了sp值,这里再推到F层,就重复了 (并且这种做法,只是做了proto层和pFo层,pFo的F层并未照顾到,另外其实也不太建议在识别成功后,把已发生层全计上数,感觉和SP的初衷不太相符);
    //for (NSInteger i = 0; i <= protoOrRegroupCutIndex; i++) {
    //    [AINetUtils updateInSPStrong_4IF:protoOrRegroupFo conSPIndex:i difStrong:1 type:ATPlus except4SP2F:except4SP2F];
    //}
}

/**
 *  MARK:--------------------时序识别之: protoFo&assFo匹配判断--------------------
 *  要求: protoFo必须全含assFo对应的last匹配下标之前的所有元素,即:
 *       1. proto的末帧,必须在assFo中找到 (并记录找到的assIndex为cutIndex截点);
 *       2. assFo在cutIndex截点前的部分,必须在protoFo中找到 (找到即全含,否则为整体失败);
 *  例如: 如: protFo:[abcde] 全含 assFo:[acefg]
 *  名词说明:
 *      1. 全含: 指从lastAssIndex向前,所有的assItemAlg都匹配成功;
 *      2. 非全含: 指从lastAssIndex向前,只要有一个assItemAlg匹配失败,则非全含;
 *  _param outOfFos : 用于计算衰减值; (未知何时已废弃)
 *  @version
 *      2022.04.30: 将每帧的matchAlgs和partAlgs用于全含判断,而不是单纯用protoFo来判断 (参考25234-6);
 *      2022.05.23: 反思时,改回旧有mIsC判断方式 (参考26096-BUG6);
 *      2022.05.25: 将衰后稳定性计算集成到全含判断方法中 (这样性能好些);
 *      2022.06.08: 稳定性低的不过滤了,因为学时统计,不关稳定性(概率)的事儿 (参考26222-TODO1);
 *      2022.06.08: 排序公式改为sumNear / nearCount (参考26222-TODO1);
 *      2022.09.15: 修复indexDic收集的KV反了的BUG (与pFo.indexDic的定义不符);
 *      2022.11.10: 复用alg相似度,且原本比对相似度的性能问题自然也ok了 (参考27175-5);
 *      2022.11.11: 全改回用mIsC判断,因为等效 (matchAlgs全是protoAlg的抽象,且mIsC是有缓存的,无性能问题),且全用mIsC后代码更精简;
 *      2022.11.11: 将找末位,和找全含两个部分,合而为一,使算法代码更精简易读 (参考27175-7);
 *      2022.11.11: BUG_indexDic中有重复的Value (一个protoA对应多个assA): 将nextMaxForProtoIndex改为protoIndex-1后ok (参考27175-8);
 *      2022.11.13: 迭代V2: 仅返回indexDic (参考27177);
 *      2023.07.11: 仅普通正向protoFo时序识别时,才要求末帧必含,regroup则不必如此 (参考30057-修复);
 *      2024.10.10: 迭代V3: 把从后往前,改成从前往后 (参考33093);
 *      2024.10.10: 把判断映射(mIsC) 与 判断是否全含(条件满足) => 整理成两步 (参考33093-TIPS);
 *  @result 判断protoFo是否全含assFo: 成功时返回indexDic / 失败时返回空dic;
 */
+(NSDictionary*) recognitionFo_CheckValidV3:(AIFoNodeBase*)assFo protoOrRegroupFo:(AIFoNodeBase*)protoOrRegroupFo fromRegroup:(BOOL)fromRegroup inModel:(AIShortMatchModel*)inModel {
    if (Log4MFo) NSLog(@"------------------------ 时序全含检查 ------------------------\nass:%@->%@",Fo2FStr(assFo),Mvp2Str(assFo.cmvNode_p));
    
    //==================== STEP1: 从前往后取匹配映射indexDic ====================
    
    //11. 数据准备;
    NSMutableDictionary *indexDic = [[NSMutableDictionary alloc] init]; //记录protoIndex和assIndex的映射字典 <K:assIndex, V:protoIndex>;
    
    //12. 依次mIsC判断匹配: 匹配时_记录indexDic映射 (此处proto抽象仅指向刚识别的matchAlgs,所以与contains等效);
    NSInteger nextStartForAssIndex = 0;
    for (NSInteger protoIndex = 0; protoIndex < protoOrRegroupFo.count; protoIndex++) {
        AIKVPointer *protoAlg_p = ARR_INDEX(protoOrRegroupFo.content_ps, protoIndex);
        for (NSInteger assIndex = nextStartForAssIndex; assIndex < assFo.count; assIndex++) {
            AIKVPointer *assAlg_p = ARR_INDEX(assFo.content_ps, assIndex);
            
            //13. 概念识别没有进行关联,所以此处也调用getProtoAlgAbsPs,替代mIsC,末帧时直接可以用inModel.matchAlg_PS.contains()来 (参考3313b-TODO5);
            NSArray *protoAlgAbs_ps = [self getProtoAlgAbsPs:protoOrRegroupFo protoIndex:protoIndex inModel:inModel fromRegroup:fromRegroup];
            BOOL mIsC = [protoAlg_p isEqual:assAlg_p] || [protoAlgAbs_ps containsObject:assAlg_p];
            if (mIsC) {
                
                //13. 匹配时_记录下次循环ass时,从哪帧开始倒序循环: nextMaxForAssIndex进度;
                //2024.12.01: 修复此处有可能输出0->1,1->0的BUG (参考33137-问题1);
                nextStartForAssIndex = assIndex + 1;
                [indexDic setObject:@(protoIndex) forKey:@(assIndex)];
                if (Log4MFo) NSLog(@"时序识别全含判断有效+1帧 (assIndex:%ld protoIndex:%ld)",assIndex,protoIndex);
                break;
            }
        }
    }
    
    //==================== STEP2: 判断含不含proto末帧,以及前段匹配是否都充足 (参考33093-TIPS) ====================
    
    //21. 前段必须全含,缺一帧也不行: 全含时,它发现的最大index就等于发现映射数 (如: 最大下标3时,发现4个);
    //说明: 中途assFo有任意一帧在proto中未匹配到,则全含失败;
    NSInteger maxAssIndex = -1;
    for (NSNumber *assIndex in indexDic.allKeys) {
        if (assIndex.integerValue > maxAssIndex) maxAssIndex = assIndex.integerValue;
    }
    if (maxAssIndex != indexDic.count - 1) {
        if (Log4MFo) NSLog(@"ass前段有一帧在proto未找到,则非全含:%@",CLEANSTR(indexDic));
        return [NSMutableDictionary new];
    }
    
    //22. TI时序识别时,要求必须包含proto末帧,否则返回failure;
    //说明: 一帧帧全匹配到了,但最终没匹配到proto的末帧,也全含失败;
    if (!fromRegroup && ![indexDic objectForKey:@(protoOrRegroupFo.count - 1)]) {
        if (Log4MFo) NSLog(@"ass最后未与proto末帧匹配上,则非全含:%@",CLEANSTR(indexDic));
        return [NSMutableDictionary new];
    }
    
    //23. 至此前段全含条件满足,返回映射结果;
    if (Log4MFo) NSLog(@"全含success:%@",CLEANSTR(indexDic));
    return indexDic;
}

/**
 *  MARK:--------------------时序识别第二步: 抽具象关联--------------------
 */
+(void) recognitionFoStep2:(AIFoNodeBase*)protoOrRegroupFo inModel:(AIShortMatchModel*)inModel debugMode:(BOOL)debugMode {
    //1. 数据准备;
    NSArray *allMatchFos = [[SMGUtils collectArrA:inModel.matchPFos arrB:inModel.matchRFos] copy];
    if (debugMode) NSLog(@"\n时序识别关联 P(%ld条) R(%ld条)",inModel.matchPFos.count,inModel.matchRFos.count);
    
    //2. 关联处理,直接protoFo抽象指向matchFo,并持久化indexDic (参考27177-todo6);
    for (AIMatchFoModel *item in allMatchFos) {
        //4. 识别到时,refPorts -> 更新/加强微信息的引用序列
        AIFoNodeBase *matchFo = [SMGUtils searchNode:item.matchFo];
        [AINetUtils updateRefStrongByIndexDic:item.indexDic2 matchFo:item.matchFo];
        [AINetUtils updateContentStrongByIndexDic:item.indexDic2 matchFo:item.matchFo];
        
        //5. 存储matchFo与protoFo之间的indexDic映射 (参考27177-todo5);
        [protoOrRegroupFo updateIndexDic:matchFo indexDic:item.indexDic2];
        
        //6. 对proto直接抽象指向matchAlg,并增强强度值 (为保证抽象多样性,所以相近的也抽具象关联) (参考27153-3);
        [AINetUtils relateFoAbs:matchFo conNodes:@[protoOrRegroupFo] isNew:false];
        
        //7. 存储protoFo与matchFo之间的匹配度度记录 (存每个alg元素的乘积匹配度) (参考27153-todo2 & 33143-方案1);
        [protoOrRegroupFo updateMatchValue:matchFo matchValue:item.sumNear];
        
        //8. 调试日志;
        if (debugMode) NSLog(@"%ld. %@强度:(%ld)(%ld/%ld)\t> %@->{%.2f} (SP:%@) indexDic:%@ 匹配度 => %.2f",[allMatchFos indexOfObject:item],matchFo.cmvNode_p?@"P":@"",item.sumRefStrong,item.cutIndex,matchFo.count,Fo2FStr(matchFo),[AIScore score4MV_v2FromCache:item],CLEANSTR(matchFo.spDic),CLEANSTR(item.indexDic2),item.matchFoValue);
    }
}

//MARK:===============================================================
//MARK:                     < Canset识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------Canset概念识别--------------------
 *  @desc Canset场景内概念识别算法 (参考3014a-方案 & 3014b);
 *  @param sceneFo : 当前canset所在的sceneFo (cansetAlg识别是要限定于场景内的,sceneFo就是这个场景);
 *  @version
 *      2023.10.26: 废弃 (参考3014a-追加结果);
 */
//+(void) recognitionCansetAlg:(AIAlgNodeBase*)protoAlg sceneFo:(AIFoNodeBase*)sceneFo inModel:(AIShortMatchModel*)inModel {
//    //1. 关于调用者:
//    //  a. 哪里在调用cansetFo识别,哪里就在fo识别前先调用下这个;
//    //  b. 或者再提前点,调用普通alg识别时,结合下工作记忆,顺带把这个也跑了;
//}

/**
 *  MARK:--------------------Canset时序识别--------------------
 *  @desc 功能说明:
 *          1. 识别: 用条件满足来实现类似全含判断功能 (参考28185-todo3);
 *          2. 增强: 识别结果增强sp和eff (参考28185-todo4);
 *        现状说明:
 *          调用者1. newCanset有效时,会调用canset识别,类比,sp+1,eff+1;
 *          调用者2. 反馈canset无效时,会调用canset识别,不类比,sp+1,eff-1;
 *          调用者3. 迁移时,会调用canset识别,类比,sp+0,eff+0;
 *          注: 反馈无效时,sp也会+1的代码是以前的,此处未改,但它是否合理,待测出不合理时再来改正;
 *  @version
 *      2023.03.18: 失败时,也调用Canset识别,并将es计负分 (参考28185-todo5);
 *      2023.03.30: 支持过滤器 (参考29042);
 *      2023.04.04: 将Canset过滤器改为根据indexDic映射数来 (参考29055);
 *      2023.04.07: 因为性能原因,并且newCanset时就识别类比的意义也没找着,所以关闭Canset识别 (后面会改为在迁移时进行懒识别类比) (参考29059-改动 & 29067-todo2);
 *      2023.04.19: TCTransfer迁移后调用Canset识别类比,但不对SPEFF+1 (参考29069-todo12 & todo12.1);
 *      2023.09.01: 因为场景单一时不会触发transfer导致canset识别类比永远不会发生,所以改回newCanset时即刻触发canset识别类比 (参考30124-原则&todo1);
 *      2023.09.01: newCanset触发时,EFF根据"有效或无效",更新+-1,TCTransfer触发时EFF不变 (参考30124-todo2&todo3);
 *      2023.10.23: 关闭canset识别和类比 (参考3014b-方案5 & 3014c-todo2);
 *      2023.10.26: 废弃canset识别 (参考3014c-todo2);
 */
//+(void) recognitionCansetFo:(AIKVPointer*)newCanset_p sceneFo:(AIKVPointer*)sceneFo_p es:(EffectStatus)es {
//    if (!Switch4RecognitionCansetFo) return;
//    //1. 取出旧有候选集;
//    AIFoNodeBase *newCanset = [SMGUtils searchNode:newCanset_p];
//    AIFoNodeBase *sceneFo = [SMGUtils searchNode:sceneFo_p];
//
//    //TODO20231003: 此处为hCanset时: (因canset识别被关闭,此todo先不做)
//    //1. 取oldCanset用的index应该不同 (随后做下处理);
//    //2. 打日志时,把当前是rCanset还是hCanset打出来,以便调试canset的竞争成长相关;
//
//    NSArray *oldCansets = [sceneFo getConCansets:sceneFo.count];
//    NSLog(@"\n----------- Canset识别 (EFF:%@ 候选数:%ld) -----------\nnewCanset:%@\nsceneFo:%@",EffectStatus2Str(es),oldCansets.count,Fo2FStr(newCanset),Fo2FStr(sceneFo));
//    NSMutableArray *matchModels = [[NSMutableArray alloc] init];
//
//    //2. 旧有候选集: 作为识别池;
//    for (AIKVPointer *oldCanset in oldCansets) {
//        //3. 不应期 (不识别自身);
//        if ([newCanset.pointer isEqual:oldCanset]) continue;
//        AIFoNodeBase *oldCansetFo = [SMGUtils searchNode:oldCanset];
//
//        //4. 判断newCanset全含cansetFo (返回全含indexDic) (参考29025-23c);
//        NSDictionary *indexDic = [self checkFoValidMatch_NewCanset:newCanset oldCanset:oldCansetFo sceneFo:sceneFo];
//        if (!DICISOK(indexDic)) continue;
//
//        //5. 收集;
//        [matchModels addObject:[AIMatchCansetModel newWithMatchFo:oldCansetFo indexDic:indexDic]];
//    }
//
//    //6. AIFilter过滤 (参考29042);
//    NSArray *filterModels = [AIFilter recognitionCansetFilter:matchModels sceneFo:sceneFo];
//
//    //7. 日志
//    NSLog(@"\nCanset识别结果: %ld条",filterModels.count);
//    for (AIMatchCansetModel *model in filterModels) {
//        AIEffectStrong *eff = [sceneFo getEffectStrong:model.matchFo.count solutionFo:model.matchFo.pointer];
//        NSLog(@"-->>> %@ SP:%@ EFF:%@",Fo2FStr(model.matchFo),CLEANSTR(model.matchFo.spDic),CLEANSTR(eff));
//    }
//
//    //8. 识别后处理: 外类比 & 增强SP & 增强EFF;
//    for (AIMatchCansetModel *model in filterModels) {
//        //9. 只要全含 & 非无效newCanset => 对二者进行外类比 (参考29025-24 & 29027-方案3);
//        if (es != ES_NoEff) {
//            [AIAnalogy analogyCansetFo:model.indexDic newCanset:newCanset oldCanset:model.matchFo sceneFo:sceneFo es:es];
//        }
//
//        //10. 条件满足的都算识别结果 (更新sp和eff) (参考28185-todo4);
//        if (es != ES_Default) {
//            [model.matchFo updateSPStrong:0 end:model.matchFo.count - 1 type:ATPlus];
//            [sceneFo updateEffectStrong:sceneFo.count solutionFo:model.matchFo.pointer status:es];
//        }
//    }
//}

/**
 *  MARK:--------------------Canset的全含判断 (参考29025-23)--------------------
 *  @desc 全含说明: 要求newCanset包含oldCanset,才返回肯定结果; 
 *          示例: 比如:新[1,3,5,7,9a]和旧[1,5,9b]和场景[1,5] = 是全含的,并最终返回<1:1, 2:3, 3:5>; //其中9a和9b有共同抽象
 *  @version
 *      2023.04.10: 场景包含帧判断全含时,改用mIsC而不是绝对同一个节点 (因为场景内canset可类比抽象) (参考29067-todo1.1);
 *      2023.10.26: 废弃canset识别 (参考3014c-todo2);
 *  @result 全含时,返回二者的indexDic;
 */
//+(NSDictionary*) checkFoValidMatch_NewCanset:(AIFoNodeBase*)newCanset oldCanset:(AIFoNodeBase*)oldCanset sceneFo:(AIFoNodeBase*)sceneFo {
//    //1. 数据准备;
//    NSMutableDictionary *indexDic = [[NSMutableDictionary alloc] init];
//    NSDictionary *newIndexDic = [sceneFo getConIndexDic:newCanset.pointer];
//    NSDictionary *oldIndexDic = [sceneFo getConIndexDic:oldCanset.pointer];
//
//    //3. 说明: 所有帧,都要判断新的全含旧的,只要有一帧失败就全失败 (参考29025-23a);
//    NSInteger protoMin = 0;
//    for (NSInteger oldIndex = 0; oldIndex < oldCanset.count; oldIndex ++) {
//        AIKVPointer *oldAlg = ARR_INDEX(oldCanset.content_ps, oldIndex);
//        BOOL findItem = false;
//        for (NSInteger newIndex = protoMin; newIndex < newCanset.count; newIndex++) {
//            AIKVPointer *newAlg = ARR_INDEX(newCanset.content_ps, newIndex);
//
//            //4. 分别判断old和new这一帧是否被sceneFo场景包含 (参考29025-23b);
//            NSNumber *oldKey = ARR_INDEX([oldIndexDic allKeysForObject:@(oldIndex)], 0);
//            NSNumber *newKey = ARR_INDEX([newIndexDic allKeysForObject:@(newIndex)], 0);
//
//            //5. 如果二者都包含=>即场景包含帧: (因为canset都优先取matchAlg,所以oldAlg和newAlg一般是同一节点) (参考29025-23b);
//            if (oldKey && newKey) {
//                //5. 但因为会类比抽象所以有时不是同一节点: 此时要求new抽象指向old: 算匹配成功 (参考29067-todo1.1);
//                if ([TOUtils mIsC_1:newAlg c:oldAlg]) {
//                    findItem = true;
//                }
//            } else if (oldKey != newKey) {
//                //6. 如果二者有一个包含,则此帧失败 (参考29025-23b2 & 23c3);
//                break;
//            } else {
//                //7. 如果二者都不包含,则判断二者有没有共同的抽象 (参考29025-23c);
//                //2023.10.17: 关闭mc共同抽象为依据 (参考30148-todo1.1);
//                BOOL mcIsBro = false;//[TOUtils mcIsBro:newAlg c:oldAlg];
//                if (mcIsBro) {
//                    //8. 有共同抽象=>则此帧成功 (参考29025-23c);
//                    findItem = true;
//                } else {
//                    //9. 无共同抽象,则继续找newCanset的下帧,看能不能有共同抽象 (参考29025-23c2);
//                }
//            }
//
//            //10. 此帧成功: 记录newIndex & 并记录protoMin (参考29025-23d);
//            if (findItem) {
//                protoMin = newIndex + 1;
//                [indexDic setObject:@(newIndex) forKey:@(oldIndex)];
//                if (Log4SceneIsOk) NSLog(@"\t第%ld帧,条件满足通过 canset:%@ (fromProto:F%ldA%ld)",oldIndex,Pit2FStr(oldAlg),newCanset.pointer.pointerId,newAlg.pointerId);
//                break;
//            }
//        }
//
//        //11. 有一条失败,则全失败 (参考29025-23e);
//        if (!findItem) {
//            if (Log4SceneIsOk) NSLog(@"\t第%ld帧,条件满足未通过 canset:%@ (fromProtoFo:F%ld)",oldIndex,Pit2FStr(oldAlg),newCanset.pointer.pointerId);
//            return nil;
//        }
//    }
//
//    //12. 全找到,则成功;
//    if (Log4SceneIsOk) NSLog(@"条件满足通过:%@ (fromProtoFo:%ld)",Fo2FStr(oldCanset),newCanset.pointer.pointerId);
//    return indexDic;
//}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

//返回protoAlg的索引 (一般是取它的抽象);
+(NSArray*) getProtoAlgAbsPs:(AIFoNodeBase*)protoOrRegroupFo protoIndex:(NSInteger)protoIndex inModel:(AIShortMatchModel*)inModel fromRegroup:(BOOL)fromRegroup {
    //1. 数据准备;
    AIKVPointer *proto_p = ARR_INDEX(protoOrRegroupFo.content_ps, protoIndex);
    
    //2. 每个abs_p分别索引;
    NSArray *protoAlgAbs_ps = nil;
    if (PitIsMv(proto_p)) {
        //3. mv时,直接返回自己就行;
        protoAlgAbs_ps = @[proto_p];
    } else if (protoIndex == protoOrRegroupFo.count - 1 && !fromRegroup) {
        //4. 末帧时,抽具象概念还没关联,不能从absPorts访问到它,所以直接从inModel.matchAlgs来访问 (参考3313b-TODO2);
        protoAlgAbs_ps = [SMGUtils convertArr:inModel.matchAlgs_PS convertBlock:^id(AIMatchAlgModel *obj) {
            return obj.matchAlg;
        }];
    } else {
        //5. 别的,把抽象关联返回;
        AIAlgNodeBase *protoAlg = [SMGUtils searchNode:proto_p];
        protoAlgAbs_ps = Ports2Pits(protoAlg.absPorts);
    }
    return protoAlgAbs_ps;
}

/**
 *  MARK:--------------------获取微观一层在宏观一层content_ps中的下标--------------------
 */
+(MapModel*) findSmallRefAtBigIndex:(NSArray*)smallMatchModels bigNode:(AINodeBase*)bigNode {
    for (AIMatchModel *smallMatchModel in smallMatchModels) {
        NSInteger findIndex = [bigNode.content_ps indexOfObject:smallMatchModel.match_p];
        if (findIndex > -1) {
            return [MapModel newWithV1:@(findIndex) v2:smallMatchModel];//找到直接返回。
        }
    }
    return nil;
}

+(void) printLogDescRate:(NSArray*)ass_ps protoLogDesc:(NSString*)protoLogDesc prefix:(NSString*)prefix {
    //18. debugLog3
    NSMutableDictionary *allLogDic = [NSMutableDictionary new];
    for (AIKVPointer *ass_p in ass_ps) {
        AINodeBase *assNode = [SMGUtils searchNode:ass_p];
        NSDictionary *itemLogDic = [assNode getLogDesc:true];
        for (NSString *key in itemLogDic.allKeys) {
            NSInteger oldCount = NUMTOOK([allLogDic objectForKey:key]).integerValue;
            NSInteger newCount = NUMTOOK([itemLogDic objectForKey:key]).integerValue;
            [allLogDic setObject:@(oldCount + newCount) forKey:key];
        }
    }
    NSInteger sum = [SMGUtils sumOfArr:allLogDic.allValues convertBlock:^double(NSNumber *obj) {
        return obj.integerValue;
    }];
    NSArray *allLogKeys = [SMGUtils sortBig2Small:allLogDic.allKeys compareBlock:^double(NSString *key) {
        NSInteger itemCount = NUMTOOK([allLogDic objectForKey:key]).integerValue;
        return itemCount / (float)sum;
    }];
    NSLog(@"%@%@识别结果总结：%@",protoLogDesc?protoLogDesc:@"",prefix,CLEANSTR([SMGUtils convertArr:allLogKeys convertBlock:^id(NSString *key) {
        NSInteger itemCount = NUMTOOK([allLogDic objectForKey:key]).integerValue;
        return STRFORMAT(@"%@=%.2f ",key,itemCount / (float)sum);
    }]));
}

@end
