//
//  TCRecognitionInvoke.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/27.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCRecognitionInvoke.h"

#define cDebugMode false

#define mIndexPsPool [NSMutableDictionary new]


@implementation TCRecognitionInvoke

static NSMutableDictionary *indexPsPool;
static NSMutableDictionary *vInfoCache;
static NSMutableDictionary *dataDicCache;
static NSMutableDictionary *valueGroupDataCache; // 稀疏码分一百组，每个组的稀疏码值。
static NSMutableDictionary *valueResultPool; // 稀疏码识别结果缓存 <K=valueDS_分组下标，V=识别结果>
static DDic *bestGVsPoolV2; // 构建bestGVs的元素的复用池 <K=protoRect的分组索引 和 assST.itemGV.pId, V=bestGVItem>
static DDic *protoGVIndexPoolV2; // 从protoDic的类似切图只切一次，这是复用池（类似protoRect区域，直接复用切图计算protoGVIndex结果）。
static int bestGVsPoolTotalCount = 0, bestGVsPoolMissCount = 0, cutImgPoolTotalCount = 0, cutImgPoolMissCount = 0;

static DDic *bestSTsPool; // 构建bestSTs的元素的复用池 <K=protoRect的分组索引 和 assGT.itemST.pId, V=bestSTItem>

static NSMutableDictionary *gtZiJvGTPool; // GT自举之GT处理结果的缓存池
static NSMutableDictionary *gtZiJvSTPool; // GT自举之ST处理结果的缓存池

static int _curMaxSize; // 当前视觉输入的宽高尺寸。

+(void) resetPool {
    indexPsPool = [NSMutableDictionary new];
    vInfoCache = [NSMutableDictionary new];
    dataDicCache = [NSMutableDictionary new];
    valueGroupDataCache = [NSMutableDictionary new];
    valueResultPool = [NSMutableDictionary new];
    bestGVsPoolV2 = [DDic new];
    protoGVIndexPoolV2 = [DDic new];
    bestGVsPoolTotalCount = 0;
    bestGVsPoolMissCount = 0;
    cutImgPoolTotalCount = 0;
    cutImgPoolMissCount = 0;
    bestSTsPool = [DDic new];
    gtZiJvGTPool = [NSMutableDictionary new];
    gtZiJvSTPool = [NSMutableDictionary new];
}

//MARK:===============================================================
//MARK:                     < 单稀疏码识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------单稀疏码识别--------------------
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

+(NSArray*) recognitionValue:(CGFloat)rate minLimit:(NSInteger)minLimit at:(NSString*)at ds:(NSString*)valueDS isOut:(BOOL)isOut protoData:(CGFloat)protoData {
    // 优先从复用池取：单稀疏码识别结果复用池（参考35107-TODO3.2）。
    NSString *poolKey = [self getPoolKeyOfProtoData:protoData valueDS:valueDS];
    NSArray *poolResult = [valueResultPool objectForKey:poolKey];
    // 有复用直接返回，无复用，再进行识别。
    if (poolResult) return poolResult;
    
    //1. 取索引序列 & 当前稀疏码值;
    NSDictionary *cacheDataDic = [dataDicCache objectForKey:valueDS];
    NSArray *index_ps = [indexPsPool objectForKey:valueDS];
    double max = [CortexAlgorithmsUtil maxOfLoopValue:at ds:valueDS itemIndex:GVIndexTypeOfDataSource];
    AIValueInfo *vInfo = [vInfoCache objectForKey:valueDS];
    
    //2. 按照相近度排序;
    NSArray *indexPsMapModels = [SMGUtils convertArr:index_ps convertBlock:^id(AIKVPointer *obj) {
        double objData = [NUMTOOK([AINetIndex getData:obj fromDataDic:cacheDataDic]) doubleValue];
        double nearDelta = [CortexAlgorithmsUtil nearDeltaOfValue:protoData assNum:objData max:max];
        return [DoubleObjMapModel newWithDoubleValue:nearDelta obj:obj];
    }];
    NSArray *near_ps = [SMGUtils sortSmall2Big:indexPsMapModels compareBlock:^double(DoubleObjMapModel *obj) {
        return obj.doubleValue;
    }];
    
    //3. 窄出,仅返回前NarrowLimit条 (最多narrowLimit条,最少1条);
    NSInteger limit = MAX(near_ps.count * rate, minLimit);
    near_ps = ARR_SUB(near_ps, 0, limit);
    
    //4. 转matchModel模型并返回，取上相近度。
    NSArray *result = [SMGUtils convertArr:near_ps convertBlock:^id(DoubleObjMapModel *indexMapModel) {
        //5. 第1_计算出nearV (参考25082-公式1) (性能:400次计算,耗100ms很正常);
        //2024.04.27: BUG_这里有nearV为0的,导致后面可能激活一些完全不准确的结果 (修复: 加上末尾淘汰: 相似度为0的就不收集了先,看下应该也不影响别的什么);
        AIKVPointer *near_p = indexMapModel.obj;
        double nearData = [NUMTOOK([AINetIndex getData:near_p fromDataDic:cacheDataDic]) doubleValue];
        CGFloat matchValue = [AIAnalyst compareCansetValue:nearData protoV:protoData at:near_p.algsType ds:near_p.dataSource isOut:near_p.isOut vInfo:vInfo];
        if (matchValue <= 0) return nil;//把相近度为0的过滤掉。
        
        //6. 构建model
        AIMatchModel *model = [[AIMatchModel alloc] init];
        model.match_p = near_p;
        model.matchValue = matchValue;
        return model;
    }];
    
    // 把结果添加到复用池（参考35107-TODO3.2）。
    [valueResultPool setObject:result forKey:poolKey];
    return result;
}

//MARK:===============================================================
//MARK:                     < 识别入口 >
//MARK:===============================================================

// 识别前初始化
+(void) recognitionInit:(NSDictionary*)colorDic whSize:(CGFloat)whSize at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc {
    // 初始化缓存池数据。
    [self resetPool];
    _curMaxSize = whSize;
    
    // 加载稀疏码相关缓存池。
    // TODO: 随后测下这里有没用，没用删掉，忘了什么时候写的什么作用了。
    NSArray *gvIndexKeys = [AINetGroupValueIndex gvIndexKeys:ds];
    for (NSString *valueDS in gvIndexKeys) {
        // 初始化indexPsPool。
        NSArray *index_ps = [AINetIndex getIndex_ps:at ds:valueDS isOut:false];
        [indexPsPool setObject:index_ps forKey:valueDS];
        
        // 提前加载好vInfo缓存，后面复用。
        AIValueInfo *vInfo = [AINetIndex getValueInfo:at ds:valueDS isOut:false];
        [vInfoCache setObject:vInfo forKey:valueDS];
        
        // 提前加载好dataDic缓存，后面复用。
        NSDictionary *dataDic = [AINetIndexUtils searchDataDic:at ds:valueDS isOut:false];
        [dataDicCache setObject:dataDic forKey:valueDS];
        
        // 提前加载好单稀疏码分组（参考35107-TODO3.1）。
        NSMutableArray *itemValueGroupDataCache = [NSMutableArray new];
        NSArray *groupScores = [SMGUtils convertArr:index_ps convertBlock:^id(AIKVPointer *obj) { return [AINetIndex getData:obj fromDataDic:dataDic]; }];
        groupScores = [SMGUtils sortSmall2Big:groupScores compareBlock:^double(NSNumber *obj) { return obj.doubleValue; }];
        NSInteger groupCount = MIN(groupScores.count, 100);
        CGFloat groupStep = groupCount > 0 ? groupScores.count / groupCount : 0;
        for (int i = 1; i < groupCount + 1; i++) { // 1-100
            NSInteger index = i == groupCount ? groupScores.count - 1 : (int)(i * groupStep) - 1; // 0-99（避免越界）（可能不包含0，但绝对包含最后一条）。
            [itemValueGroupDataCache addObject:ARR_INDEX(groupScores, index)];
        }
        [valueGroupDataCache setObject:itemValueGroupDataCache forKey:valueDS];
    }
}

//MARK:===============================================================
//MARK:                     < 稀疏码识别 >
//MARK:===============================================================

+(NSArray*) recognitionSVAndGV:(NSDictionary*)colorDic at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoRect:(CGRect)protoRect beginGVExcept:(NSMutableDictionary*)beginGVExcept {
    //14. 切出当前gv：九宫。
    //2025.12.11: 切图复用（参考35105-TODO3.1）。
    MapModel *rectKey = [self getIndexsOfProtoRect:protoRect];
    NSDictionary *gvIndex = [TCRecognitionInvoke getGVIndexFromPoolOrCutProtoImgV2:protoRect rectKey:rectKey protoColorDic:colorDic ds:ds];
    if (!DICISOK(gvIndex)) return nil;
    
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
    
    //4. 组码识别
    NSArray *gMatchModels = [AIRecognitionCache getCache:gvKey cacheBlock:^id{
        return [self recognitionSVAndGV_Invoke:vModels at:at isOut:isOut rate:0.15 minLimit:3 forProtoGV:nil];
    }];
    
    // for (AIMatchModel *gModel in allGVs) {
        // 防重：80%相似的区域内，多个一样的gModel，只做一次切入点。
        //NSMutableArray *gvIdProtoRects = [beginGVExcept objectForKey:@(gModel.match_p.pointerId)];
        //if (!gvIdProtoRects) {
        //    gvIdProtoRects = [NSMutableArray new];
        //    [beginGVExcept setObject:gvIdProtoRects forKey:@(gModel.match_p.pointerId)];
        //}
        //[gvIdProtoRects addObject:@(protoRect)];
    // }
    return [SMGUtils convertArr:gMatchModels convertBlock:^id(AIMatchModel *gModel) {
        return [MapModel newWithV1:gModel v2:@(protoRect)];
    }];
}

+(NSArray*) recognitionSVAndGV_Invoke:(NSArray*)vModels at:(NSString*)at isOut:(BOOL)isOut rate:(CGFloat)rate minLimit:(NSInteger)minLimit forProtoGV:(AIKVPointer*)forProtoGV {
    //1. 数据准备
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    
    //2. 先把protoGV解读成索引值。
    for (NSInteger itemIndex = 0; itemIndex < vModels.count; itemIndex++) {
        
        //3. 取所有当前组码的itemIndex下的索引序列 & 当前码的索引值 & 当前码的最大值。
        MapModel *item = ARR_INDEX(vModels, itemIndex);
        NSString *ds = item.v1;
        CGFloat itemData = NUMTOOK(item.v2).floatValue;
        NSArray *vMatchModels = [AIRecognitionCache getCache:STRFORMAT(@"%@_%.2f",item.v1,itemData) cacheBlock:^id{
            return [self recognitionValue:0.2 minLimit:10 at:at ds:ds isOut:isOut protoData:itemData];//v1单码特征
        }];
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
    }
    
    //11. 过滤掉匹配度为0的 & 非全含的 & 不识别protoG自己。
    NSArray *gMatchModels = [SMGUtils filterArr:resultDic.allValues checkValid:^BOOL(AIMatchModel *item) {
        return item.matchValue > 0 && item.matchCount == vModels.count && (!forProtoGV || ![item.match_p isEqual:forProtoGV]);
    }];
    
    // TODOTOMORROW20260524: 整个GV的竞争得替代下，无论是自举时，还是GV识别时，都得替代下（参考38036）。
    
    //21. 按匹配度排序。
    gMatchModels = [SMGUtils sortBig2Small:gMatchModels compareBlock:^double(AIMatchModel *obj) {
        return obj.matchValue;
    }];
    
    //24. 过滤不准确的结果。
    gMatchModels = ARR_SUB(gMatchModels, 0, MIN(20, MAX(5, gMatchModels.count * 0.2)));
    
    //25. 更新: ref强度 & 相似度 & 抽具象;
    for (AIMatchModel *matchModel in gMatchModels) {
        //2025.03.30: 这儿性能不太好，经查现在组码识别不需要单码索引强度做竞争，先关掉。
        //[AINetUtils insertRefPorts_General:assNode.p content_ps:assNode.content_ps difStrong:1 header:assNode.header];
        if (forProtoGV) {
            AIGroupValueNode *assNode = [SMGUtils searchNode:matchModel.match_p];//性能：起初需要IO时1ms/条，后面有缓存后均耗0.05ms 总22ms。
            AIGroupValueNode *protoGroupValue = [SMGUtils searchNode:forProtoGV];
            [protoGroupValue updateMatchValue:assNode matchValue:matchModel.matchValue];//性能均耗0.15ms 总65ms
            [AINetUtils relateGeneralAbs:assNode absConPorts:assNode.conPorts conNodes:@[protoGroupValue] isNew:false difStrong:1];//性能均耗0.25ms 总97ms
        }
        //NSLog(@"组码识别结果(%ld/%ld) GV%ld 匹配数:%ld 匹配度:%.2f",[gMatchModels indexOfObject:matchModel],gMatchModels.count,matchModel.match_p.pointerId,matchModel.matchCount,matchModel.matchValue);
    }
    return gMatchModels;
}

//MARK:===============================================================
//MARK:                     < 特征识别 >
//MARK:===============================================================

/**
 *  MARK:--------------------单特征识别--------------------
 *  @desc 识别抽象的单特征：通过组码向refPorts找特征结果（起初似层结果较多，但后期随着抽象，会慢慢变成结果中几乎都是交层）。
 *  @param stModels 已收集的stModels（用于防重）。
 *  @test 作用：此总结可方便该算法的测试与BUG分析。
 *        目标：需达成以下功能。
 *         1. 多样性（比如0的各个局部，都得有多个识别结果，使后续GT识别中，可以每元素contains判断到，以取交识别到更准确的GT）。
 *         2. 稳定性（不得只识别最具象和最抽象，而是稳定的中间部位，得识别到）。
 *         3. 显著性（得慢慢竞争浮现出显著的局部特征结果，比如小人的头总是圆的）。
 *         4. 竞争性（广入窄出）。
 *  @version
 *      2025.08.02: v1-由单特征自举算法复用而来，可用于支持组特征自举识别功能（参考35061-TODO3）
 */
+(NSArray*) recognitionFeatureV2_Step1:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoColorDic:(NSDictionary*)protoColorDic excepts:(DDic*)excepts gvRectExcept:(NSMutableDictionary*)gvRectExcept stModels:(NSMutableArray*)stModels allGVs:(NSArray*)allGVs {
    // 数据准备
    NSMutableArray *result = [NSMutableArray new];
    NSMutableArray *assRectExcept = [NSMutableArray new];// 被成功匹配过所有GV区域防重。
    
    // ================== 控制广入条数: refPorts竞争 ==================
    
    // 对所有gv识别结果的，所有refPorts。
    NSMutableArray *refModels = [NSMutableArray new];
    for (MapModel *gv in allGVs) {
        AIMatchModel *gModel = gv.v1;
        NSValue *protoRect = gv.v2;
        NSArray *refPorts = [AINetUtils refPorts_All:gModel.match_p];
        for (AIPort *refPort in refPorts) {
            [refModels addObject:[MapModel newWithV1:@(gModel.matchValue) v2:refPort v3:protoRect]];
        }
    }
    
    // 避免ST激活太多的: 强度越好 x 越准确的 = 越优先。
    NSArray *sorts = [SMGUtils sortBig2Small:refModels compareBlock:^double(MapModel *model) {
        AIPort *refPort = model.v2;
        NSNumber *matchValue = model.v1;
        return matchValue.floatValue * refPort.strong.value;
    }];
    NSArray *valids = ARR_SUB(sorts, 0, MAX(10, MIN(600, sorts.count * 0.2f)));
    
    // ================== 识别 ==================
    
    // 每个refPort自举，到proto对应下相关区域的匹配度符合度等;
    NSMutableDictionary *assSTCounted = [NSMutableDictionary new];
    for (MapModel *gvResult in valids) {
        AIPort *refPort = gvResult.v2;
        CGRect protoRect = VALTOOK(gvResult.v3).CGRectValue;
        
        // 同一个assST只有10次准入机会（参考36037-TODO1）。
        NSInteger oldCount = NUMTOOK([assSTCounted objectForKey:@(refPort.target_p.pointerId)]).integerValue;
        if (oldCount > 9) continue;
        
        // 数据准备
        AIFeatureNode *assT = [SMGUtils searchNode:refPort.target_p];
        if (!assT) continue;
        NSInteger beginAssIndex = [assT indexOfRect:refPort.rect];//[assT.content_ps indexOfObject:gModel.match_p];
        if (beginAssIndex == -1) continue;
        
        CGRect lastAtAssRect = refPort.rect;//ARR_INDEX(assT.rects, beginAssIndex).CGRectValue;
        CGRect lastProtoRect = protoRect;
        
        // 2025.06.12：lastProtoRect强转为Int，避免精度太高，各种aiPort中的以rect防重和rect判等都无效。
        lastProtoRect = CGRectMake((int)(lastProtoRect.origin.x+0.5f), (int)(lastProtoRect.origin.y+0.5f), (int)(lastProtoRect.size.width+0.5f), (int)(lastProtoRect.size.height+0.5f));
        
        // STModel防重复用池。
        AIFeatureJvBuModel *oldModel = [self getSTModelFromPoolV2:result runedSTModelsPool:stModels newBeginGV_ProtoRect:lastProtoRect newBeginAssIndex:beginAssIndex assST:assT];
        if (oldModel) continue;
        
        //21. 自举：每个assT一条条自举自身的gv（移到stZiJvWithAssT方法中循环并整体返回）。
        CGRect beginGV_AssT = [assT rectByIndex:beginAssIndex];
        CGRect beginGV_Proto = protoRect;
        CGRect defaultBaseST_Proto = [SMGUtils convertNewAAtCWithAAtB:beginGV_AssT aAtC:beginGV_Proto newAAtB:assT.rect];
        AIFeatureJvBuModel *model = [self stZiJv:assT beginAssIndex:beginAssIndex lastProtoRect:lastProtoRect lastAtAssRect:lastAtAssRect protoColorDic:protoColorDic ds:ds defaultBaseST_Proto:defaultBaseST_Proto];
        
        //53. 成功识别过的区域防重：如果此处已经被别的assT扫描并成功识别过了，则记录下，它不再做切入点进行别的识别了（参考35042-TODO4）。
        [assRectExcept addObjectsFromArray:[SMGUtils convertArr:model.bestGVs.allValues convertBlock:^id(AIFeatureJvBuItem *obj) {
            return @(obj.bestGVAtProtoTRect);
        }]];
        [result addObject:model];
        
        // 更新准入机会。
        [assSTCounted setObject:@(oldCount + 1) forKey:@(model.assT.pId)];
    }
    NSLog(@"ST广入:%ld 识别到:%ld",valids.count,result.count);
    return result;
}

/**
 *  MARK:--------------------单特征识别结果竞争--------------------
 *  @version
 *      2025.08.07: 构建protoT废弃（参考35062-TODO3）。
 */
+(void) recognitionFeatureV2_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel ds:(NSString*)ds logDesc:(NSString*)logDesc protoCount:(NSInteger)protoCount {
    // bestGVs末尾淘汰（尽可能的广入窄出充分竞争，参考37033B-9切合理论-原则）。
    for (AIFeatureJvBuModel *model in decoratorJvBuModel.stModels) {
        [model filter4ZonHe];
    }
    
    //43. 处理匹配度
    for (AIFeatureJvBuModel *model in decoratorJvBuModel.stModels) {
        [model run4OuterShapeMatchValue];                               // 外形
        [model run4InnerEigenMatchValue];                               // 内征
        // [model run4MatchValueAndMatchDegreeAndMatchAssProtoRatio];   // 符合度等
        // [model run4AdjacentScore];                                   // 计算相邻度
        // [model run4CenterScore];                                     // 中心度
        [model run4BestGvsAtProtoTRect];                                // 计算bestGVs_Proto（计算assST_Proto要用到，然后在GT识别计算位置符合度时也要用到）。
        [model run4AssST_ProtoRect];                                    // 计算assST_ProtoRect（计算完整性要用到）
        [model run4IntactRate];                                         // 完整性
        [model run4AverageContentStrong];                               // 稳定性
    }
    
    [decoratorJvBuModel run4AbsPortStrongScore];        // 抽象强度得分
    [decoratorJvBuModel run4ModelMatchCountScore];      // 匹配数归一化：防过抽。
    [decoratorJvBuModel run4AverageContentStrongScore]; // 强度归一化得分
    [decoratorJvBuModel run4BestsCountScore:protoCount];// 根据排名归一化：分子匹配数。
    [decoratorJvBuModel run4TotalCountScore:protoCount];// 根据排名归一化：分母总数。
    
    // 竞争因子计算：防止过度抽象匹配数。
    // [decoratorJvBuModel run4BestGVsCountRatio];
    
    // 竞争因子计算：在稳定层里，抽象优先。
    // [decoratorJvBuModel run4ModelMatchRatioScore];
    
    // 竞争因子计算：分区竞争匹配度。
    // [decoratorJvBuModel run4AreaRankRatioV2];
    
    // 递进式竞争：主在前辅在后层层嵌套（参考38033）。
    // 动态计算filterRate：定义最终保留条数，根据当前条数和过滤次数，用幂次求出每次过滤率。
    // 公式：最终条数 = 当前条数 * filterRate^过滤次数 => filterRate = pow(最终条数/当前条数, 1/过滤次数)
    NSInteger finalCount = 10; // 最终保留条数
    NSInteger filterCount = 2; // 过滤次数（数量、外形，共2次）
    NSInteger currentCount = decoratorJvBuModel.stModels.count;
    CGFloat filterRate = currentCount > finalCount ? pow((double)finalCount / currentCount, 1.0 / filterCount) : 1.0f;
    filterRate = MAX(0.0f, MIN(1.0f, filterRate)); // 限制在合理范围内
    NSArray *sorts = decoratorJvBuModel.stModels;
    
    // 数量（数量少的太多了，外形后20%，几乎全是只有1-2条的，所以数量最重要）（参考38034-方案3）。
    sorts = [SMGUtils sortBig2Small:sorts compareBlock:^double(AIFeatureJvBuModel *item) {
        return item.bestGVs.count;
    }];
    sorts = ARR_SUB(sorts, 0, sorts.count * filterRate + 0.5f);
    
    // 外形（参考38034-方案3）。
    sorts = [SMGUtils sortBig2Small:sorts compareBlock:^double(AIFeatureJvBuModel *item) {
        return item.outerShapeMatchValue;
    }];
    sorts = ARR_SUB(sorts, 0, sorts.count * filterRate + 0.5f);
    
    // 内征（先关掉：现在内征不那么重要，且内征应该是计算相邻的GV间，其相对内征是否连续，对内征来说这个连续性才重要）（参考38034-方案3）。
    //sorts = [SMGUtils sortBig2Small:sorts compareBlock:^double(AIFeatureJvBuModel *item) {
    //    return item.innerEigenMatchValue;
    //}];
    //sorts = ARR_SUB(sorts, 0, sorts.count * filterRate + 0.5f);
    
    // 防重过滤器：此处每个特征的不同层级，可能识别到同一个特征，可以按匹配度防下重（关掉:同一个assGT可能有多个groups结果 打开:全成了同一个结果，多个结果用注视完成）。
    //NSArray *validModels = [SMGUtils removeRepeat:sorts convertBlock:^id(AIFeatureJvBuModel *obj) {
    //    return @(obj.assT.pId);
    //}];
    NSArray *validModels = sorts;
    NSLog(@"ST窄出:%ld 识别到:%ld",validModels.count,decoratorJvBuModel.stModels.count);
    
    //61. 更新: ref强度 & 相似度 & 抽具象 & 映射 & conPort.rect;
    for (AIFeatureJvBuModel *model in validModels) {
        //2025.04.22: 这儿性能不太好，经查现在特征识别不需要组码索引强度做竞争，先关掉。
        [AINetUtils insertRefPorts_General:model.assT.p content_ps:[SMGUtils convertArr:model.bestGVs.allValues convertBlock:^id(AIFeatureJvBuItem *obj) {
            return obj.baseGV_p;
        }] difStrong:1 header:model.assT.header];
        
        // 更新内容强度（用于计算稳定性）。
        [model.assT updateContentPortStrong:model.bestGVs.allKeys difStrong:1];
        
        //52. debug (\t符合度:%.1f\t健全度:%.1f)
        NSLog(@"%02ld. 单特征识别结果:T%04ld %@",[validModels indexOfObject:model]+1,model.assT.pId,model.stScoreDesc);
        [SMGUtils runByMainQueue:^{
            [theApp.imgTrainerView setDataForJvBuModelV2:model lab:STRFORMAT(@"%ld-识别单T%ld(%ld/%ld)",[validModels indexOfObject:model]+1, model.assT.pId,model.bestGVs.count,model.assT.count) left:0 top:0 tvId:1];
        }];
    }
    
    //61. debugLog
    [TCRecognitionInvoke printLogDescRate:validModels protoLogDesc:nil prefix:@"单特征" convertNodeBlock:^NSArray*(AIFeatureJvBuModel *obj) {
        return [SMGUtils convertArr:obj.allValidAbsST_ps convertBlock:^id(AIKVPointer *obj) {
            return [SMGUtils searchNode:obj];
        }];
    } convertMatchBlock:^float(AIFeatureJvBuModel *obj) {
        return obj.stScore;
    }];
    
    // 更新logDesc到assT（参考36052）。
    for (AIFeatureJvBuModel *model in validModels) {
        // [model.assT updateLogDescItem:logDesc rate:model.matchValue];
        for (AIPort *validAbsPort in model.validAbsSTPorts) {
            AIGroupFeatureNode *validAbs = [SMGUtils searchNode:validAbsPort.target_p];
            CGFloat absMatch = [validAbs getConMatchValue:model.assT.p];
            [validAbs updateLogDescItem:logDesc rate:absMatch * model.outerShapeMatchValue * model.innerEigenMatchValue];
        }
    }
    
    //60. 更新赋值回去。
    decoratorJvBuModel.stModels = [[NSMutableArray alloc] initWithArray:validModels];
}

/**
 *  MARK:--------------------组特征识别--------------------
 *  @desc Step2 尽可能照顾特征的整体性，通过交层向下找似层结果（参考34135-TODO2）。
 *  @version
 *      2025.05.07: v2-支持自适应粒度。
 *      2025.09.09: v5-改回GT为独立网络模块（参考35072-TODO3）。
 *      2026.01.29: v7-提升对撞率，识别通路调整：“assST -> absST -> broST -> assGT”（参考36011）。
 *      2026.03.13: v9-迭代为ZiJvGroup模型，减维至GV层来实现GT自举，从而解决ST错位的问题（参考36074-方案）。
 */
+(NSArray*) recognitionGroupFeatureV9_Step1:(NSArray*)stModels logDesc:(NSString*)logDesc colorDic:(NSDictionary*)colorDic ds:(NSString*)ds {
    // 数据准备
    NSMutableArray *allGTGroups = [NSMutableArray new];
    
    // ================== 控制广入条数: refPorts竞争 ==================
    // assST层。
    NSMutableArray *refModels = [NSMutableArray new];
    for (AIFeatureJvBuModel *stModel in stModels) {
        
        // absST层：有效（全含）absST。
        for (AIKVPointer *abs_p in stModel.allValidAbsST_ps) {
            // ========= 模式1、ass->abs通路 =========
            NSArray *refPorts = [AINetUtils refPorts_All:abs_p];
            
            //// ========= 模式2、ass->abs->bro通路 =========
            //AIFeatureNode *absST = [SMGUtils searchNode:abs_p];
            //
            //// broST层。
            //NSArray *bro_ps = [SMGUtils collectArrA:Ports2Pits([AINetUtils conPorts_All:absST]) arrB:@[abs_p]];
            //for (AIKVPointer *bro_p in bro_ps) {
            //    NSArray *refPorts = [AINetUtils refPorts_All:bro_p];
            //
            //    // 性能优化、减少refPorts的切入点。
            //    refPorts = ARR_SUB(refPorts, 0, MAX(3, refPorts.count * 0.3f));
            //
            //    // 逐个求refGT。
            //    for (AIPort *refPort in refPorts) {
            //
            //        if (refPort.target_p.isJiao) continue;
            //
            //        // assGT。
            //        AIGroupFeatureNode *assGT = [SMGUtils searchNode:refPort.target_p];
            //        NSInteger beginIndex = [assGT indexOfRect:refPort.rect];
            //
            //        // gt自举算法。
            //        GTZiJvModelV2 *gtZiJvModel = [self gtZiJvV10:assGT beginIndex:beginIndex beginSTModel:stModel colorDic:colorDic ds:ds absST:absST];
            //        if (gtZiJvModel.bestSTs.count == 0) continue;
            //
            //        // 收集。
            //        [allGTGroups addObject:gtZiJvModel];
            //    }
            //}
            
            // 收集
            for (AIPort *refPort in refPorts) {
                [refModels addObject:[MapModel newWithV1:stModel v2:refPort]];
            }
            
        }
    }
    NSArray *sorts = [SMGUtils sortBig2Small:refModels compareBlock:^double(MapModel *obj) {
        AIPort *refPort = obj.v2;
        return refPort.strong.value;
    }];
    NSArray *valids = ARR_SUB(sorts, 0, MAX(10, MIN(150, sorts.count * 0.3f)));
    
    // ================== 识别 ==================
    for (MapModel *refModel in valids) {
        AIFeatureJvBuModel *stModel = refModel.v1;
        AIPort *refPort = refModel.v2;
        
        // 逐个求refGT。
        // assGT。
        AIGroupFeatureNode *assGT = [SMGUtils searchNode:refPort.target_p];
        NSInteger beginIndex = [assGT indexOfRect:refPort.rect];
        
        // gt自举算法。
        GTZiJvModelV2 *gtZiJvModel = [self gtZiJvV10:assGT beginIndex:beginIndex beginSTModel:stModel colorDic:colorDic ds:ds absST:nil];
        if (gtZiJvModel.bestSTs.count == 0) continue;
        
        // 收集。
        if (![allGTGroups containsObject:gtZiJvModel]) [allGTGroups addObject:gtZiJvModel];
    }
    
    // 内部bests根据匹配度进行末尾淘汰：匹配度差的就该被竞争淘汰剔除掉（尽可能的广入窄出充分竞争，参考37033B-9切合理论-原则）。
    for (GTZiJvModelV2 *gtGroup in allGTGroups) {
        [gtGroup filter4ZonHe];
    }
    
    // 竞争因子：匹配度 & 匹配数（防过抽）。
    AddDebugCodeBlock_KeyV3();
    NSInteger maxMatchCount = [SMGUtils filterBestScore:allGTGroups scoreBlock:^CGFloat(GTZiJvModelV2 *item) {
        return item.bestSTs.count;
    }];
    CGFloat protoGTArea = [SMGUtils computeArea4STModels_Proto:stModels];
    for (GTZiJvModelV2 *gtGroup in allGTGroups) {
        [gtGroup run4GTOuterShapeMatchValue];
        [gtGroup run4GTInnerEigenMatchValue];
        [gtGroup run4GTMatchDegree];
        [gtGroup run4GTMatchCountRatio];
        [gtGroup run4STMatchDegree];
        [gtGroup run4STMatchCountRatio];
        [gtGroup run4MatchCountRatioV2];
        [gtGroup run4GTValidAbs_ps];
        [gtGroup run4CountRatio:maxMatchCount];
        [gtGroup run4IntactRate_All:protoGTArea];
        [gtGroup run4IntactRate_Proto:protoGTArea];
        [gtGroup run4AverageContentStrong];
    }
    AddDebugCodeBlock_KeyV3();
    NSLog(@"GT广入:%ld 识别到:%ld",valids.count,allGTGroups.count);
    return allGTGroups;
}

+(void) recognitionGroupFeatureV9_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel logDesc:(NSString*)logDesc ds:(NSString*)ds {
    
    // 强度归一化得分。
    [GTZiJvModelsV2 computeAverageContentStrongScoreWithGTModels:decoratorJvBuModel.gtModels];
    
    // 匹配数归一化得分：依据排名。
    [GTZiJvModelsV2 computeBestsCountScoreWithGTModelsByRank:decoratorJvBuModel.gtModels];
    
    // 最后进行综合竞争，把最符合的找出来。
    NSArray *resultModels = [SMGUtils sortBig2Small:decoratorJvBuModel.gtModels compareBlock:^double(GTZiJvModelV2 *obj) {
        return obj.zonHeScore;
    }];
    AddDebugCodeBlock_KeyV3();
    
    // 防重过滤器：此处每个特征的不同层级，可能识别到同一个特征，可以按匹配度防下重（关掉:同一个assGT可能有多个groups结果 打开:全成了同一个结果，多个结果用注视完成）。
    resultModels = [SMGUtils removeRepeat:resultModels convertBlock:^id(GTZiJvModelV2 *obj) {
        return @(obj.baseGT.pId);
    }];
    
    // 优胜劣汰：5条以下时全要，10条以下时要60%，20条要40%，60条要30%，再多留20%，最多留20条。
    NSInteger count = resultModels.count;
    float needRate = count < 5 ? 1 : count < 10 ? 0.7 : count < 20 ? 0.5 : count < 40 ? 0.4 : 0.2;
    resultModels = ARR_SUB(resultModels, 0, MIN(20, count * needRate));
    NSLog(@"GT窄出:%ld 识别到:%ld",resultModels.count,decoratorJvBuModel.gtModels.count);
    AddDebugCodeBlock_KeyV3();
    
    // 更新: ref强度 & 相似度 & 抽具象 & 映射;
    for (GTZiJvModelV2 *model in resultModels) {
        // debug
        NSLog(@"%02ld. 组特征识别结果:T%04ld %@",[resultModels indexOfObject:model]+1,model.baseGT.pId,model.zonHeDesc);
        AddDebugCodeBlock_KeyV3(); // 计数:7 均耗:68.35 = 总耗:478 读:0 写:0
        
        // 更新内容强度（用于计算稳定性）。
        for (STZiJvModelV2 *stGroup in model.bestSTs.allValues) {
            [stGroup.baseST updateContentPortStrong:stGroup.bestGVs.allKeys difStrong:1];
        }
        [model.baseGT updateContentPortStrong:model.bestSTs.allKeys difStrong:1];
        
        // 组特征识别结果可视化（参考34176）。
        [SMGUtils runByMainQueue:^{
            [theApp.imgTrainerView setDataForGTModelV3:model lab:STRFORMAT(@"%ld识GT%ld(%ld/%ld)",[resultModels indexOfObject:model]+1,model.baseGT.pId,model.bestSTs.count,model.baseGT.count) left:0 top:0 tvId:3];
        }];
    }
    AddDebugCodeBlock_KeyV3();
    
    // debugLog
    [TCRecognitionInvoke printLogDescRate:resultModels protoLogDesc:nil prefix:STRFORMAT(@"组特征") convertNodeBlock:^NSArray*(GTZiJvModelV2 *obj) {
        return [SMGUtils convertArr:obj.validAbs_ps convertBlock:^id(AIKVPointer *obj) {
            return [SMGUtils searchNode:obj];
        }];
        // return @[obj.baseGT];
    } convertMatchBlock:^float(GTZiJvModelV2 *obj) {
        return obj.zonHeScore;
    }];
    AddDebugCodeBlock_KeyV3();
    
    // 更新logDesc到assT（参考36052）。
    for (GTZiJvModelV2 *model in resultModels) {
        //[model.baseGT updateLogDescItem:logDesc rate:model.zonHeScore];
        for (AIKVPointer *validAbs_p in model.validAbs_ps) {
            AIGroupFeatureNode *validAbs = [SMGUtils searchNode:validAbs_p];
            CGFloat absMatch = [validAbs getConMatchValue:model.baseGT.p];
            [validAbs updateLogDescItem:logDesc rate:absMatch * model.gtOuterShapeMatchValue * model.gtInnerEigenMatchValue];
        }
    }
    AddDebugCodeBlock_KeyV3();
    PrintDebugCodeBlock_KeyV3();
    decoratorJvBuModel.gtModels = [[NSMutableArray alloc] initWithArray:resultModels];
    
    // debug
    NSLog(@"切图池复用率：%d / %d = %.2f",cutImgPoolTotalCount - cutImgPoolMissCount,cutImgPoolTotalCount,(float)(cutImgPoolTotalCount - cutImgPoolMissCount) / cutImgPoolTotalCount);
    NSLog(@"BestGV池复用率：%d / %d = %.2f",bestGVsPoolTotalCount - bestGVsPoolMissCount,bestGVsPoolTotalCount,(float)(bestGVsPoolTotalCount - bestGVsPoolMissCount) / bestGVsPoolTotalCount);
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
            //TODO: 改为在特征识别完后，识别Alg，此处兼容下。
            // subMatchModels = [AIRecognitionCache getCache:item_p cacheBlock:^id{ }];
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
    //2025.04.19: 改为用isJiao来判断交似层，避免很交层特征的却归到似层里，而原本组特征却因为竞争力不如这些假的，反被顶掉。
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
    [TCRecognitionInvoke printLogDescRate:[SMGUtils convertArr:logModels convertBlock:^NSArray*(AIMatchAlgModel *obj) {
        return @[obj.matchAlg];
    }] protoLogDesc:CLEANSTR([protoAlg getLogDesc:false].allKeys) prefix:@"概念" convertNodeBlock:^id(id obj) {
        return [SMGUtils searchNode:obj];
    } convertMatchBlock:nil];
    
    //19. 概念识别结果可视化（参考34176）。
    [SMGUtils runByMainQueue:^{
        //[theApp.imgTrainerView setDataForAlgs:logModels];
        [theApp.imgTrainerView setDataForAlg:protoAlg lab:STRFORMAT(@"ProtoA%ld",protoAlg.pId) tvId:3];
        for (AIMatchAlgModel *model in logModels) {
            AIAlgNodeBase *assAlg = [SMGUtils searchNode:model.matchAlg];
            [theApp.imgTrainerView setDataForAlg:assAlg lab:STRFORMAT(@"%@assA%ld",assAlg.p.isJiao?@"局部":@"整体",assAlg.pId) tvId:3];
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
                NSInteger sumRefStrong = [AINetUtils getSumContentStrongByIndexes:indexDic.allKeys baseNode:refFo];
                
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
        [AINetUtils updateContentStrongByIndexes:item.indexDic2.allKeys toNode:matchFo];
        
        //5. 存储matchFo与protoFo之间的indexDic映射 (参考27177-todo5);
        [protoOrRegroupFo updateIndexDic:matchFo indexDic:item.indexDic2];
        
        //6. 对proto直接抽象指向matchAlg,并增强强度值 (为保证抽象多样性,所以相近的也抽具象关联) (参考27153-3);
        [AINetUtils relateFoAbs:matchFo conNodes:@[protoOrRegroupFo] isNew:false];
        
        //7. 存储protoFo与matchFo之间的匹配度度记录 (存每个alg元素的乘积匹配度) (参考27153-todo2 & 33143-方案1);
        [protoOrRegroupFo updateMatchValue:matchFo matchValue:item.sumNear];
        
        //8. 调试日志;
        if (debugMode) NSLog(@"%ld. %@强度:(%ld)(%02ld/%02ld)\t> %@->{%.2f} (SP:%@) indexDic:%@ 匹配度 => %.2f",[allMatchFos indexOfObject:item],matchFo.cmvNode_p?@"P":@"",item.sumRefStrong,item.cutIndex,matchFo.count,Fo2FStr(matchFo),[AIScore score4MV_v2FromCache:item],CLEANSTR(matchFo.spDic),CLEANSTR(item.indexDic2),item.matchFoValue);
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

+(void) printLogDescRate:(NSArray*)asses protoLogDesc:(NSString*)protoLogDesc prefix:(NSString*)prefix convertNodeBlock:(NSArray*(^)(id obj))convertNodeBlock convertMatchBlock:(float(^)(id obj))convertMatchBlock {
    //18. debugLog3
    NSMutableDictionary *allLogDic = [NSMutableDictionary new];
    for (id itemAss in asses) {
        NSArray *assNodes = convertNodeBlock(itemAss);
        CGFloat match = convertMatchBlock ? convertMatchBlock(itemAss) : 1;
        for (AINodeBase *assNode in assNodes) {
            NSDictionary *itemLogDic = [assNode getLogDesc_Number:true];
            for (NSString *key in itemLogDic.allKeys) {
                CGFloat oldCount = NUMTOOK([allLogDic objectForKey:key]).floatValue;
                CGFloat newCount = NUMTOOK([itemLogDic objectForKey:key]).floatValue;
                [allLogDic setObject:@(oldCount + newCount * match) forKey:key];
            }
        }
    }
    CGFloat max = [SMGUtils filterBestScore:allLogDic.allValues scoreBlock:^CGFloat(NSNumber *obj) {
        return obj.floatValue;
    }];
    NSArray *allLogKeys = [SMGUtils sortBig2Small:allLogDic.allKeys compareBlock:^double(NSString *key) {
        CGFloat itemCount = NUMTOOK([allLogDic objectForKey:key]).floatValue;
        return itemCount / max;
    }];
    NSLog(@"%@%@识别结果总结：%@",protoLogDesc?protoLogDesc:@"",prefix,CLEANSTR([SMGUtils convertArr:allLogKeys convertBlock:^id(NSString *key) {
        CGFloat itemCount = NUMTOOK([allLogDic objectForKey:key]).floatValue;
        return STRFORMAT(@"%@=%.0f%% ",key,max > 0 ? itemCount / max * 100 : 0);
    }]));
}

/**
 *  MARK:--------------------GT自举算法--------------------
 *  @param assGT 取它的itemST分别进行判断匹配，然后还会再马itemST展开成itemGV，进行判断匹配（参考36074-方案）。
 */
+(GTZiJvModelV2*) gtZiJvV10:(AIGroupFeatureNode*)assGT beginIndex:(NSInteger)beginIndex beginSTModel:(AIFeatureJvBuModel*)beginSTModel colorDic:(NSDictionary*)colorDic ds:(NSString*)ds absST:(AIFeatureNode*)absST {
    
    // ============ 模式1、ass->abs通路 ============
    // 同一个Img识别的同一个ST，只进行一次GT自举（参考36074-TODO6 & TODO7）（复用率：39 / 77 = 50.6%）。
    GTZiJvModelV2 *old = [gtZiJvGTPool objectForKey:@(assGT.pId)];
    if (old) return old;
    CGRect assGTRect = assGT.rect;

    // ==================== step0. 根据切入点，推算出assGT默认在Proto中的Rect ====================
    AIKVPointer *beginST_p = ARR_INDEX(assGT.content_ps, beginIndex);
    AIFeatureNode *beginST = [SMGUtils searchNode:beginST_p];
    NSArray *conPorts = [AINetUtils conPorts_All:beginST];
    AIPort *conPort = [SMGUtils filterSingleFromArr:conPorts checkValid:^BOOL(AIPort *item) { return [item.target_p isEqual:beginSTModel.assT.p]; }];
    // 1. 根据assST_Proto 和 beginST_AssST = 求出beginST_Proto。
    CGRect beginST_AssST = conPort.rect;
    CGRect assST_Proto = beginSTModel.assST_ProtoRect;
    CGRect beginST_Proto = [SMGUtils convertAAtCWithAAtB:beginST_AssST bAtC:assST_Proto protoBSize:beginSTModel.assT.rect.size];

    // 2. 根据beginST_Proto 和 beginST_AssGT = 求出assGT_Proto。
    CGRect beginST_AssGT = [assGT rectByIndex:beginIndex];
    CGRect defaultAssGT_Proto = [SMGUtils convertNewAAtCWithAAtB:beginST_AssGT aAtC:beginST_Proto newAAtB:assGTRect];
    
    //// ============ 模式2、ass->abs->bro通路 ============
    //// 同一个Img识别的同一个ST，只进行一次GT自举（参考36074-TODO6 & TODO7）（复用率：39 / 77 = 50.6%）。
    //GTZiJvModelV2 *old = [gtZiJvGTPool objectForKey:@(assGT.pId)];
    //if (old) return old;
    //CGRect assGTRect = assGT.rect;
    //
    //// ==================== step0. 根据切入点，推算出targetGT默认在Proto中的Rect ====================
    //AIKVPointer *broST_p = ARR_INDEX(assGT.content_ps, beginIndex);
    //AIFeatureNode *broST = [SMGUtils searchNode:broST_p];
    //NSArray *conPorts = [AINetUtils conPorts_All:absST];
    //AIPort *assConPort = [SMGUtils filterSingleFromArr:conPorts checkValid:^BOOL(AIPort *item) { return [item.target_p isEqual:beginSTModel.assT.p]; }];
    //
    //// 取absST_BroST
    //CGRect absST_BroST = CGRectZero;
    //if ([broST isEqual:absST]) {
    //    absST_BroST = absST.rect;
    //} else {
    //    AIPort *broConPort = [SMGUtils filterSingleFromArr:conPorts checkValid:^BOOL(AIPort *item) { return [item.target_p isEqual:broST.p]; }];
    //    absST_BroST = broConPort.rect;
    //}
    //
    //// 得出bro在assST中的rect。
    //CGRect absST_AssST = assConPort.rect;
    //CGRect fullBroRect = broST.rect;
    //CGRect broST_AssST = [SMGUtils convertNewAAtCWithAAtB:absST_BroST aAtC:absST_AssST newAAtB:fullBroRect];
    //
    //// 得出broST_Proto。
    //CGRect assST_Proto = beginSTModel.assST_ProtoRect;
    //CGRect fullAssSTRect = beginSTModel.assT.rect;
    //CGRect broST_Proto = [SMGUtils convertAAtCWithAAtB:broST_AssST bAtC:assST_Proto protoBSize:fullAssSTRect.size];
    //
    //// 得出assGT_Proto。
    //CGRect broST_AssGT = [assGT rectByIndex:beginIndex];
    //CGRect defaultAssGT_Proto = [SMGUtils convertNewAAtCWithAAtB:broST_AssGT aAtC:broST_Proto newAAtB:assGTRect];
    
    // ==================== step1. 根据当前assGT目标，对微观一级allST进行自举 ====================
    
    // 依次自举absGV
    GTZiJvModelV2 *gtResult = [GTZiJvModelV2 new];
    gtResult.baseGT = assGT;
    for (NSInteger i = 0; i < assGT.count; i++) {
        NSInteger stIndex = (beginIndex + i) % assGT.count;
        AIKVPointer *itemST_p = ARR_INDEX(assGT.content_ps, stIndex);
        AIFeatureNode *itemST = [SMGUtils searchNode:itemST_p];
        
        // ==================== step2. 根据当前itemST目标，对微观一级allGV进行自举 ====================
        CGRect assGT_Proto = gtResult.bestSTs.count > 0 ? [gtResult hopeProtoRectByAll] : defaultAssGT_Proto;
        
        // 找出最好的stResult结果。
        STZiJvModelV2 *bestSTResult = nil;
        
        // 锚点交由权重求和来计算：根据锚点，求出十种newST_Proto。
        NSArray *cut_Protos = [WeightedSumCutUtil calcAdsorbProtoRects:gtResult.bestSTs baseT:assGT curIndex:stIndex baseT_Proto:assGT_Proto];
        for (NSValue *cut_Proto in cut_Protos) {
            // checkST_Proto已经算出st在proto中的rect。
            CGRect checkST_Proto = cut_Proto.CGRectValue;
            
            STZiJvModelV2 *curSTResult = [STZiJvModelV2 new];
            curSTResult.baseST = itemST;
            for (NSInteger gvIndex = 0; gvIndex < itemST.count; gvIndex++) {
                
                // ==================== Step4: GV切图自举，计算itemGV与实际Proto的匹配度等（参考36112）====================
                
                // GV自举（按整个taqrgetGT_Proto来计算缩放锚点）。
                AIFeatureJvBuItem *gvResult = [self gvZiJv:gvIndex colorDic:colorDic ds:ds baseST:curSTResult.baseST oldBestGVs:curSTResult.bestGVs baseST_Proto:checkST_Proto];
                if (!gvResult) continue;
                [curSTResult.bestGVs setObject:gvResult forKey:@(gvIndex)];
                
                // 每收集一条bestGV，就把stResult.hopeProtoRectByAllCache置为null，以及时更新。
                curSTResult.hopeProtoRectByAllCache = CGRectNull;
                
                // 可考虑gt.hopeProtoRectByAllCache也清空，即每次gv更新时，gt也及时重算。
                // gtResult.hopeProtoRectByAllCache = CGRectNull;
            }
            
            // 保留更好的stResult。
            if (bestSTResult == nil || curSTResult.bestGVs.count > bestSTResult.bestGVs.count) {
                bestSTResult = curSTResult;
            }
        }
    
        // 每收集一条bestST，就把gtResult.hopeProtoRectByAllCache置为null，以及时更新。
        if (bestSTResult.bestGVs.count > 0) [gtResult.bestSTs setObject:bestSTResult forKey:@(stIndex)];
        gtResult.hopeProtoRectByAllCache = CGRectNull;
    }
    
    // 结果加入缓存池。
    [gtZiJvGTPool setObject:gtResult forKey:@(assGT.pId)];
    return gtResult;
}

/**
 *  MARK:--------------------自举：每个assT一条条自举自身的gv--------------------
 *  @return 返回所有成功自举的bestItem数组（按curIndex顺序）
 */
+(AIFeatureJvBuModel*) stZiJv:(AIFeatureNode*)assT beginAssIndex:(NSInteger)beginAssIndex lastProtoRect:(CGRect)lastProtoRect lastAtAssRect:(CGRect)lastAtAssRect protoColorDic:(NSDictionary*)protoColorDic ds:(NSString*)ds defaultBaseST_Proto:(CGRect)defaultBaseST_Proto {
    // 无复用时新建并识别。
    AIFeatureJvBuModel *stModel = [AIFeatureJvBuModel new:assT beginAssIndex:beginAssIndex beginGV_ProtoRect:lastProtoRect];
    
    // 21. 自举：每个assT一条条自举自身的gv。
    for (NSInteger i = 0; i < assT.count; i++) {
        NSInteger curIndex = (beginAssIndex + i) % assT.count;
        
        // baseST_Proto最初时，由lastProtoRect估算，收集到stModel.bestGVs后再以bestGVs来估算。
        CGRect baseST_Proto = stModel.bestGVs.count > 0 ? [stModel run4AssST_ProtoRect] : defaultBaseST_Proto;
        
        // GV自举（按上条lastProtoRect来计算缩放锚点）。
        AIFeatureJvBuItem *best = [self gvZiJv:curIndex colorDic:protoColorDic ds:ds baseST:stModel.assT oldBestGVs:stModel.bestGVs baseST_Proto:baseST_Proto];
        
        //41. 有中断匹配不上的gv，直接计为自举审核失败。
        if (!best) continue;
        
        //43. 记录curIndex，以使bestGVs知道与assT哪帧映射且用于排序等。
        //2025.05.12: 自适应粒度单特征识别的位置符合度本来就是自举位置来判断匹配度的，位置不符合时匹配度就无法达标，所以：要么用scale与1的距离来表示，要么直接不判断它。
        [stModel updateBestGVs:best assIndex:curIndex];
    }
    return stModel;
}

/**
 *  MARK:--------------------GV自举（通过CutImg切图实现）--------------------
 *  @param oldBestGVs : 已收集到的bestGVs
 */
+(AIFeatureJvBuItem*) gvZiJv:(NSInteger)newGVIndex colorDic:(NSDictionary*)colorDic ds:(NSString*)ds baseST:(AIFeatureNode*)baseST oldBestGVs:(NSDictionary*)oldBestGVs baseST_Proto:(CGRect)baseST_Proto {
    AIKVPointer *newGV = ARR_INDEX(baseST.content_ps, newGVIndex);
    
    // 锚点交由权重求和来计算：根据锚点，求出十种newST_Proto。
    NSArray *cut_Protos = [WeightedSumCutUtil calcAdsorbProtoRects:oldBestGVs baseT:baseST curIndex:newGVIndex baseT_Proto:baseST_Proto];
    AIFeatureJvBuItem *best = nil;
    for (NSValue *cut_Proto in cut_Protos) {
        CGRect checkCurProtoRect = cut_Proto.CGRectValue;
        
        // 2025.06.12：lastProtoRect强转为Int，避免精度太高，各种aiPort中的以rect防重和rect判等都无效。
        // 2025.06.20：更提前转成int，因为在getSubDots的时候，就需要是正确的int值了。
        checkCurProtoRect = [SMGUtils rectNoDot:checkCurProtoRect];
        
        // 2025.06.20：如果到proto切范围为空，则直接跳过，判定为该itemGV未匹配到。
        if (checkCurProtoRect.size.width < 1 || checkCurProtoRect.size.height < 1) return nil;
        
        // 池子复用。
        MapModel *rectKey = [self getIndexsOfProtoRect:checkCurProtoRect];
        AIFeatureJvBuItem *curBestGVItem = [bestGVsPoolV2 objectV5ForKey1:rectKey.v1 k2:rectKey.v2 k3:rectKey.v3 k4:rectKey.v4 k5:@(newGV.pointerId)];
        bestGVsPoolTotalCount ++;
        NSDictionary *lastProtoGVIndex = nil;
        if ([@"isNull" isEqual:curBestGVItem]) return nil; //占位空，则说明上次已经失败过，还按失败处理（此处防重掉18%）。
        if (!curBestGVItem) {
            bestGVsPoolMissCount ++;
            //33. 切出当前gv：九宫。
            //2025.05.10: 出界处理：如checkCurProtoRect出界到视角之外，比如<0或者>max（采用方案2，直接continue）。
            //  方案1、用assT的解析来填充，不然就没对局部显示的进行识别了。
            //  方案2、可以出界的不做判断，最后计算匹配度时是要除掉bestGVs.count，所以不做判断并不会影响匹配度。
            //2025.12.11: 切图复用（参考35105-TODO3.1）。
            NSDictionary *protoGVIndex = [self getGVIndexFromPoolOrCutProtoImgV2:checkCurProtoRect rectKey:rectKey protoColorDic:colorDic ds:ds];
            if (!protoGVIndex || [@"isNull" isEqual:protoGVIndex]) {
                //这里切到null，也应该存到bestGVsPoolV2中：占位空，如果失败，失败也缓存上。
                [bestGVsPoolV2 setObjectV5:@"isNull" k1:rectKey.v1 k2:rectKey.v2 k3:rectKey.v3 k4:rectKey.v4 k5:@(newGV.pointerId)];
                return nil;
            }
            
            //34. 求切出的curProtoGV九宫与curAssGV的匹配度。
            CGFloat outerShapeMatchValue = 1, innerEigenMatchValue = 1;
            NSMutableDictionary *baseGVIndex = [NSMutableDictionary new];
            AIGroupValueNode *curAssGV = [SMGUtils searchNode:newGV];
            for (AIKVPointer *assV in curAssGV.content_ps) {
                // 数据准备
                CGFloat protoData = NUMTOOK([protoGVIndex objectForKey:assV.dataSource]).floatValue;
                NSDictionary *dataDic = [dataDicCache objectForKey:assV.dataSource];
                AIValueInfo *vInfo = [vInfoCache objectForKey:assV.dataSource];

                // 内征（色差和色均值）需要在assT的各元素间保持过滤平缓（参考37033-TODO3）。
                if ([AINetGroupValueIndex isInnerEigen:assV.dataSource]) {
                    // 判断当前protoData与上一帧protoData的匹配度（性能好）|| 或改为判断当前protoData与周边protoData的匹配度（性能差）。
                    CGFloat lastProtoData = NUMTOOK([lastProtoGVIndex objectForKey:assV.dataSource]).floatValue;
                    CGFloat vMatchValue = [AIAnalyst compareCansetValue:lastProtoData protoV:protoData at:assV.algsType ds:assV.dataSource isOut:assV.isOut vInfo:vInfo];
                    innerEigenMatchValue *= vMatchValue;
                    baseGVIndex[assV.dataSource] = @(vMatchValue);
                }
                // 外形（方向和分隔点）需要protoT与assT一致（参考37033-TODO2）。
                else {
                    double assData = [NUMTOOK([AINetIndex getData:assV fromDataDic:dataDic]) doubleValue];
                    CGFloat vMatchValue = [AIAnalyst compareCansetValue:assData protoV:protoData at:assV.algsType ds:assV.dataSource isOut:assV.isOut vInfo:vInfo];
                    outerShapeMatchValue *= vMatchValue;
                    baseGVIndex[assV.dataSource] = @(vMatchValue);
                }
            }
            curBestGVItem = [AIFeatureJvBuItem new:checkCurProtoRect outerShapeMatchValue:outerShapeMatchValue matchDegree:1 innerEigenMatchValue:innerEigenMatchValue baseGV_p:newGV];
            curBestGVItem.baseGVIndex = baseGVIndex;
            curBestGVItem.protoGVIndex = protoGVIndex;
            
            // 记录缓存池
            [bestGVsPoolV2 setObjectV5:curBestGVItem k1:rectKey.v1 k2:rectKey.v2 k3:rectKey.v3 k4:rectKey.v4 k5:@(newGV.pointerId)];
            
            // 记录protoGVIndex，以供内征分析用。
            lastProtoGVIndex = protoGVIndex;
        }
        
        //35. 保留最匹配的一条。
        if (!best || best.outerShapeMatchValue * best.innerEigenMatchValue < curBestGVItem.outerShapeMatchValue * curBestGVItem.innerEigenMatchValue) {
            best = curBestGVItem;
        }
    }
    return best;
}

//MARK:===============================================================
//MARK:  < ST识别缓存池（1、GVIndex切图缓存 2、GVItem缓存 3、STModel缓存 >
//MARK:===============================================================

/**
 *  MARK:--------------------切图缓存池--------------------
 */
//2025.12.11: 此处对checkCurProtoRect从protoColorDic切图做复用，如果和曾切过的rect有90%区域相似，则直接复用（参考35105-TODO3.1）。
//2025.12.20: 升级v2-继续性能优化：用分组索引来直接取复用结果（参考35121-方案1）。
//@result 有可能返回nil，因为切图切到空结果，也会复用到池子里，避免重复取空。
+(NSDictionary*) getGVIndexFromPoolOrCutProtoImgV2:(CGRect)protoRect rectKey:(MapModel*)rectKey protoColorDic:(NSDictionary*)protoColorDic ds:(NSString*)ds {
    // <3时九宫每格切不到一个像素，直接返回nil（不然生成的GVIndex会是默认0,0,0,0四个值，导致很多判不准）（参考38022-BUG）。
    if (protoRect.size.width < 3 || protoRect.size.height < 3) return nil;
    
    NSDictionary *protoGVIndex = [protoGVIndexPoolV2 objectV4ForKey1:rectKey.v1 k2:rectKey.v2 k3:rectKey.v3 k4:rectKey.v4];
    cutImgPoolTotalCount ++;
    
    // 有旧的则直接复用
    if (protoGVIndex) return protoGVIndex;
    cutImgPoolMissCount ++;
    
    // 无相似则切图计算
    NSArray *subDots = [ThinkingUtils getSubDots:protoColorDic gvRect:protoRect];
    protoGVIndex = ARRISOK(subDots) ? [AINetGroupValueIndex convertGVIndexData:subDots ds:ds] : nil;
    
    // 新增一条计算记录（如果为空，则存一条空结果占位符。
    [protoGVIndexPoolV2 setObjectV4:protoGVIndex ? protoGVIndex : @"isNull" k1:rectKey.v1 k2:rectKey.v2 k3:rectKey.v3 k4:rectKey.v4];
    return protoGVIndex;
}

/**
 *  MARK:--------------------STModel缓存池--------------------
 *  @desc 从stModels池中，找newAssST类似的旧结果，进行返回。
 *  @version
 *      2025.12.29: V2迭代，每个stModel都用beginAssIndex下的gv_ProtoRect来判断同组（参考35126-方案1 & TODO4）。
 *  @param runingSTModelsPool 本次执行识别中的已有结果集
 *  @param runedSTModelsPool 往次执行识别中的已有结果集
 *  _param newAssST 新AssST（查这个assST可复用的结果返回）
 *  _param newAssSTRect 新AssST的整个体rect。
 *  _param newBestGVsAtProtoTRect 切入点在proto上的rect。
 *  _param newBestGVsAtAssRect 切入点在assST上的rect。
 */
+(AIFeatureJvBuModel*) getSTModelFromPoolV2:(NSMutableArray*)runingSTModelsPool runedSTModelsPool:(NSMutableArray*)runedSTModelsPool newBeginGV_ProtoRect:(CGRect)newBeginGV_ProtoRect newBeginAssIndex:(NSInteger)newBeginAssIndex assST:(AIFeatureNode*)assST {
    MapModel *newIndexKeys = [self getIndexsOfProtoRect:newBeginGV_ProtoRect];
    NSArray *allPool = [SMGUtils collectArrA:runedSTModelsPool arrB:runingSTModelsPool];
    
    for (AIFeatureJvBuModel *oldModel in allPool) {
        // 找出同一个pid（参考35105-TODO6.1）。
        if (oldModel.assT.pId != assST.pId) continue;
        
        // 取旧模型中，同样切入index的gv_ProtoRect。
        CGRect oldBeginGV_ProtoRect = [oldModel getItemGV_ProtoRect:newBeginAssIndex];
        MapModel *oldIndexKeys = [self getIndexsOfProtoRect:oldBeginGV_ProtoRect];
        
        // 索引一样则可用同一个。
        if (NUMTOOK(newIndexKeys.v1).intValue == NUMTOOK(oldIndexKeys.v1).intValue &&
            NUMTOOK(newIndexKeys.v2).intValue == NUMTOOK(oldIndexKeys.v2).intValue &&
            NUMTOOK(newIndexKeys.v3).intValue == NUMTOOK(oldIndexKeys.v3).intValue &&
            NUMTOOK(newIndexKeys.v4).intValue == NUMTOOK(oldIndexKeys.v4).intValue) {
            return oldModel;
        }
    }
    return nil;
}

/**
 *  MARK:--------------------稀疏码下标分组池（参考35107-TODO3.1）--------------------
 *  @result 看protoData的值属于哪一组，把这组的下标返回，值范围为0-100（共101组，最后一组为超标组，即以前从未有过这么大值）。
 */
+(NSString*) getPoolKeyOfProtoData:(CGFloat)protoData valueDS:(NSString*)valueDS {
    NSInteger index = [self getIndexOfProtoData:protoData valueDS:valueDS];
    return STRFORMAT(@"%@_%ld",valueDS,index);
}
+(NSInteger) getIndexOfProtoData:(CGFloat)protoData valueDS:(NSString*)valueDS {
    // 取当前valueDS的排序下标池（itemCache为从小到大的排列）。
    NSArray *itemCache = [valueGroupDataCache objectForKey:valueDS];
    
    // 找出protoData所属的组下标。
    for (NSNumber *groupData in itemCache) {
        if (protoData <= groupData.doubleValue) return [itemCache indexOfObject:groupData];
    }
    
    // 比最大的都大，直接全返回超标count值，这些超标值复用同一个识别结果。
    return itemCache.count;
}

/**
 *  MARK:--------------------切图分组--------------------
 *  @desc 对protoRect计算复用字典的key索引（参考35121-TODO1.1）。
 */
+(MapModel*) getIndexsOfProtoRect:(CGRect)protoRect {
    // 结果
    int wIndex = -1, xIndex = -1, hIndex = -1, yIndex = -1;
    
    // 循环找出wh在哪个粒度层，以及算出xy在这个粒度层属于第几份。
    float dotSize = 1;
    int curIndex = 0;
    while (true) {
        // 找出当前w属于哪一个粒度层，直接做为wIndex索引编号（参考35121-TODO1.2）。
        // 每层按每个dotSize分五份，当前x属于哪一份，直接一除就得出了。比如：dotSize为10时，一份为2，则x=18时，xIndex=9（参考35121-TODO1.3）。
        if (protoRect.size.width <= dotSize) {
            wIndex = curIndex;
            xIndex = (int)(protoRect.origin.x / (dotSize * 0.2));
        }
        
        // 同上wxIndex计算方法。
        if (protoRect.size.height <= dotSize) {
            hIndex = curIndex;
            yIndex = (int)(protoRect.origin.y / (dotSize * 0.2));
        }
        
        // 四个index找完，则退出循环。
        if (wIndex > -1 && xIndex > -1 && hIndex > -1 && yIndex > -1) break;
        
        // 大于最大则越界，也退出循环。
        if (dotSize > _curMaxSize) break;
        dotSize *= 1.3f;
        curIndex ++;
    }
    
    // 四个全返回（参考35121-TODO1.4）。
    return [MapModel newWithV1:@(wIndex) v2:@(xIndex) v3:@(hIndex) v4:@(yIndex)];
}

@end
