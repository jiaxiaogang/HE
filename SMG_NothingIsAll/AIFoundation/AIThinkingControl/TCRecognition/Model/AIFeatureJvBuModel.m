//
//  AIFeatureJvBuModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuModel.h"

@implementation AIFeatureJvBuModel

+(id) new:(AIFeatureNode*)assT beginAssIndex:(NSInteger)beginAssIndex beginGV_ProtoRect:(CGRect)beginGV_ProtoRect {
    AIFeatureJvBuModel *result = [AIFeatureJvBuModel new];
    result.assT = assT;
    result.beginAssIndex = beginAssIndex;
    result.beginGV_ProtoRect = beginGV_ProtoRect;
    return result;
}

-(NSMutableDictionary *)bestGVs {
    if (!_bestGVs) _bestGVs = [NSMutableDictionary new];
    return _bestGVs;
}

-(void) run4MatchValue {
    self.matchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.matchValue;
    }] / self.bestGVs.count;
}

-(void) run4DirectionMatchValue {
    self.directionMatchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return [obj.baseGVMatchValue[[AINetGroupValueIndex directionKey:self.assT.ds]] floatValue];
    }] / self.bestGVs.count;
}

-(void) run4JunMatchValue {
    self.junMatchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return [obj.baseGVMatchValue[[AINetGroupValueIndex junKey:self.assT.ds]] floatValue];
    }] / self.bestGVs.count;
}

-(void) run4DiffMatchValue {
    self.diffMatchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return [obj.baseGVMatchValue[[AINetGroupValueIndex diffKey:self.assT.ds]] floatValue];
    }] / self.bestGVs.count;
}

-(void) run4SepMatchValue {
    self.sepMatchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return [obj.baseGVMatchValue[[AINetGroupValueIndex sepKey:self.assT.ds]] floatValue];
    }] / self.bestGVs.count;
}

-(void) run4BestGvsAtProtoTRect {
    self.bestGVsAtProtoTRect = CGRectNull;
    for (AIFeatureJvBuItem *item in self.bestGVs.allValues) {
        self.bestGVsAtProtoTRect = CGRectUnion(self.bestGVsAtProtoTRect, item.bestGVAtProtoTRect);
    }
}

-(void) run4BestGvsAtAssTRect {
    self.bestGVsAtAssTRect = CGRectNull;
    for (NSNumber *assIndex in self.bestGVs.allKeys) {
        CGRect itemGV_AssSTRect = [self.assT rectByIndex:assIndex.integerValue];
        self.bestGVsAtAssTRect = CGRectUnion(self.bestGVsAtAssTRect, itemGV_AssSTRect);
    }
}

// 平均名次（越大越好）（求平均原因：参考35076-TODO2.3）。
-(CGFloat) areaRankScore {
    return self.areaRankNum > 0 ? self.areaRankSum / self.areaRankNum : 0.0f;
}

// ST分区均衡竞争算法：分别对每个stModel所在的区域进行竞争排名计分。
// 2025.10.21：支持分区竞争：每一条都与区域内所有条目进行竞争排名（起因：越来越只识别到0的下半部分，上半部分一条都没有）（参考35076-TODO2）。
-(void) run4ItemAreaRankScore:(NSArray*)stModels {
    // 当前Rect和Center点。
    CGRect protoR = self.bestGVsAtProtoTRect;
    CGPoint centP = [MathUtils getRectCenterPoint:protoR];
    
    // 缩放大1.3倍区域，找出所有在这个区域里的stModels（参考35076-TODO2）。
    // 2025.12.07: BUG：查训练多个0后，ST识别的前20名会有严重的同质化问题（全是0的下半部分），所以：此处改成，不仅包含，还得宽高相近（不然最大的那个GV全包含，所有gv都得先把它这个老大干掉才行）。
    CGFloat scale = 1.3f;
    CGRect zoneRect = CGRectMake(centP.x - protoR.size.width * scale * 0.5f, centP.y - protoR.size.height * scale * 0.5f, protoR.size.width * scale, protoR.size.height * scale);
    NSArray *zoneSTModels = [SMGUtils filterArr:stModels checkValid:^BOOL(AIFeatureJvBuModel *item) {
        CGFloat wRate = item.bestGVsAtProtoTRect.size.width / protoR.size.width;
        CGFloat hRate = item.bestGVsAtProtoTRect.size.height / protoR.size.height;
        BOOL whValid = wRate > 0.77f && wRate < 1.3f && hRate > 0.77f && hRate < 1.3f;
        return whValid && CGRectContainsRect(zoneRect, item.bestGVsAtProtoTRect);
    }];
    
    // 给区域内的stModels排名 & 并计分 & 计次（排名越大越好）。
    // 方案1、区域综合竞争后，打分时，对防抽防具最后30%名进行降权（参考36096-TODO3.3）。
    // 2026.01.21: 去掉防过具，改为准确中取具象（因为很难对撞上，所有有效全含的抽象全算识别结果）（参考35152-TODO1 & 35153）。
    zoneSTModels = [SMGUtils sortSmall2Big:zoneSTModels compareBlock:^double(AIFeatureJvBuModel *obj) {
        return obj.matchValue * self.modelMatchCountScore/* * self.modelMatchRatioScore*/;
    }];
    for (NSInteger i = 0; i < zoneSTModels.count; i++) {
        AIFeatureJvBuModel *obj = ARR_INDEX(zoneSTModels, i);
        
        // 对于防抽防具值<0.3的，进行权重打压（避免从平均学渣中选出劣币）。
        CGFloat daYaValue = obj.modelMatchCountScore; // MIN(obj.modelMatchCountScore, obj.modelMatchRatioScore);
        CGFloat daYaWeight = daYaValue < 0.3f ? daYaValue / 0.3f : 1;
        
        obj.areaRankSum += (i * daYaWeight); // 累计名次（参考35076-TODO2.2）;
        obj.areaRankNum += 1;
    }
    
    // 方案2、如果方案1有问题，可以考虑此方案，区域只按匹配度竞争，防抽防具单纯用做权重。
    //zoneSTModels = [SMGUtils sortSmall2Big:zoneSTModels compareBlock:^double(AIFeatureJvBuModel *obj) {
    //    return obj.matchValue;
    //}];
    //for (NSInteger i = 0; i < zoneSTModels.count; i++) {
    //    AIFeatureJvBuModel *obj = ARR_INDEX(zoneSTModels, i);
    //
    //    // 对于防抽防具进行权重打压（避免从平均学渣中选出劣币）。
    //    obj.areaRankSum += i * obj.modelMatchCountScore * obj.modelMatchRatio; // 累计名次（参考35076-TODO2.2）;
    //    obj.areaRankNum += 1;
    //}
}


-(AIFeatureJvBuItem*) getBestGVByAssIndex:(NSInteger)assIndex {
    // 找有没旧的
    return [self.bestGVs objectForKey:@(assIndex)];
}

// bestGVs新收集一条时，都要先判断下是否比旧的更best，再收集，如果没旧的好，则直接跳过（参考35105-TODO6.2 & TODO6.4）。
-(void) updateBestGVs:(AIFeatureJvBuItem*)newBestGV assIndex:(NSInteger)assIndex {
    // 找有没旧的
    AIFeatureJvBuItem *old = [self getBestGVByAssIndex:assIndex];
    
    // 没旧的 或 有旧的但更好 => 则收集（参考35105-TODO6.4）。
    if (!old || newBestGV.matchValue > old.matchValue) {
        [self.bestGVs setObject:newBestGV forKey:@(assIndex)];
    }
}

// 计算assIndex对应的ProtoRect中范围（用beginIndex来推算）（参考35126-TODO2）。
-(CGRect) getItemGV_ProtoRect:(NSInteger)itemAssIndex {
    NSValue *beginGV_AssRect = ARR_INDEX(self.assT.rects, self.beginAssIndex);
    NSValue *itemGV_AssRect = ARR_INDEX(self.assT.rects, itemAssIndex);
    CGRect itemGV_ProtoRect = [SMGUtils convertBAtAWithCAtA:self.beginGV_ProtoRect cAtB:beginGV_AssRect.CGRectValue B:itemGV_AssRect.CGRectValue];
    return itemGV_ProtoRect;
}

// 计算整个assST_ProtoRect
-(CGRect) run4AssST_ProtoRect {
    CGRect bestGVs_AssST = [SMGUtils convertArr2Rect:self.bestGVs.allKeys itemRectBlock:^CGRect(NSNumber *item) {
        return [self.assT rectByIndex:item.integerValue];
    }];
    CGRect assSTRect = [SMGUtils convertArr2Rect:self.assT.rects itemRectBlock:^CGRect(NSValue *item) {
        return item.CGRectValue;
    }];
    CGRect bestGVs_Proto = [SMGUtils convertArr2Rect:self.bestGVs.allValues itemRectBlock:^CGRect(AIFeatureJvBuItem *item) {
        return item.bestGVAtProtoTRect;
    }];
    self.assST_ProtoRect = [SMGUtils convertBAtAWithCAtA:bestGVs_Proto cAtB:bestGVs_AssST B:assSTRect];
    return self.assST_ProtoRect;
}

// 定责淘汰（参考35138-TODO1）。
-(void) filter4BestGVs {
    // bestGVs递进淘汰法：不同在于，此处每一层采用了定责淘汰，因为此处不是竞争淘汰，而是找到稳定的抽象后，就不要再一直变少了，不然会有大量过抽象节点的问题。
    // 方向定责淘汰
    [self run4DirectionMatchValue];
    NSString *directionKey = [AINetGroupValueIndex directionKey:self.assT.ds];
    self.bestGVs = [SMGUtils filterDic:self.bestGVs checkValid:^BOOL(id key, AIFeatureJvBuItem *value) {
        return [TCLearningUtil noZeRenForPingJun:[value.baseGVMatchValue[directionKey] floatValue] bigerMatchValue:self.directionMatchValue fanForce:1.0f];
    }];

    // 均色值定责淘汰
    [self run4JunMatchValue];
    NSString *junKey = [AINetGroupValueIndex junKey:self.assT.ds];
    self.bestGVs = [SMGUtils filterDic:self.bestGVs checkValid:^BOOL(id key, AIFeatureJvBuItem *value) {
        return [TCLearningUtil noZeRenForPingJun:[value.baseGVMatchValue[junKey] floatValue] bigerMatchValue:self.junMatchValue fanForce:1.3f];
    }];

    // 色差值定责淘汰
    [self run4DiffMatchValue];
    NSString *diffKey = [AINetGroupValueIndex diffKey:self.assT.ds];
    self.bestGVs = [SMGUtils filterDic:self.bestGVs checkValid:^BOOL(id key, AIFeatureJvBuItem *value) {
        return [TCLearningUtil noZeRenForPingJun:[value.baseGVMatchValue[diffKey] floatValue] bigerMatchValue:self.diffMatchValue fanForce:1.6f];
    }];

    // 分隔点定责淘汰
    [self run4SepMatchValue];
    NSString *sepKey = [AINetGroupValueIndex sepKey:self.assT.ds];
    self.bestGVs = [SMGUtils filterDic:self.bestGVs checkValid:^BOOL(id key, AIFeatureJvBuItem *value) {
        return [TCLearningUtil noZeRenForPingJun:[value.baseGVMatchValue[sepKey] floatValue] bigerMatchValue:self.sepMatchValue fanForce:2.0f];
    }];

    self.bestGVs = [SMGUtils filterDic:self.bestGVs checkValid:^BOOL(id key, AIFeatureJvBuItem *value) {
        return [TCLearningUtil noZeRenForPingJun:value.matchValue bigerMatchValue:self.matchValue];
    }];
}

-(NSArray*) validAbsSTPorts {
    if (!_validAbsSTPorts) {
        NSArray *allAbsSTPorts = [AINetUtils absPorts_All:self.assT];
        
        // 方案1、用抽具象的indexDic映射，来判断它是否全含（前提：需要存上抽具象特征的indexDic映射）。
        self.validAbsSTPorts = [SMGUtils filterArr:allAbsSTPorts checkValid:^BOOL(AIPort *item) {
            NSDictionary *indexDic = [self.assT getAbsIndexDic:item.target_p];
            // bestGVs了全含absST，则这条absST有效，收集它。
            return ![SMGUtils filterSingleFromArr:indexDic.allValues checkValid:^BOOL(id item) {
                return ![self.bestGVs.allKeys containsObject:item];
            }];
        }];
        
        // 方案2、直接取出absST.content判断是否被全含。
        // 更难判断，因为不止得判断指针包含，还得判断rect也对应着，因为st.content中的itemGV是可能重复的（所以还是先用方案1吧）。
    }
    return _validAbsSTPorts;
}

// 计算有效抽象
-(NSArray *) allValidAbsST_ps {
    NSMutableArray *result = [NSMutableArray new];
    if (self.abs_p) [result addObject:self.abs_p];
    if (ARRISOK(self.validAbsSTPorts)) [result addObjectsFromArray:Ports2Pits(self.validAbsSTPorts)];
    return result;
}

// 相邻度（参考36032-方案）。
-(void) run4AdjacentScore {
    // 根据model.bestGVs.allKeys数值是否相邻来计算。
    // 计算相邻得分：归一化到 0~1，越连续分数越高
    NSArray *sortedKeys = [SMGUtils sortSmall2Big:self.bestGVs.allKeys compareBlock:^double(NSNumber *obj) {
        return obj.integerValue;
    }];
    if (sortedKeys.count <= 1) {
        self.adjacentScore = 1.0;
        return;
    }
    
    NSInteger totalSpan = self.assT.count - 1;                 // 理论最大跨度
    NSInteger realSpan  = [sortedKeys.lastObject integerValue] - [sortedKeys.firstObject integerValue];
    
    // 计算空隙总和：直接由“实际跨度 - 已占索引数 + 1”得出。
    NSInteger gapSum = realSpan - sortedKeys.count + 1;
    
    // 归一化：0 表示最分散，1 表示完全连续
    self.adjacentScore = totalSpan > 0 ? 1.0 - (CGFloat)gapSum / totalSpan : 1.0;
}

// 中心度：bestGVs.allKeys 越集中在 assT 中间越好，越靠近两端越差，归一化到 0~1
-(void) run4CenterScore {
    if (self.bestGVs.count == 0) {
        self.centerScore = 0.0;
        return;
    }
    
    // 计算所有 key 的平均索引
    CGFloat avgIndex = [SMGUtils sumOfArr:self.bestGVs.allKeys convertBlock:^double(NSNumber *obj) {
        return obj.integerValue;
    }] / self.bestGVs.count;
    
    // 理论中心点
    CGFloat center = (self.assT.count - 1) / 2.0;
    
    // 计算偏离中心的绝对距离，最大可能偏离为 center
    CGFloat deviation = fabs(avgIndex - center);
    CGFloat maxDeviation = center;
    
    // 归一化：0 表示完全偏离（在两端），1 表示正好在中间
    self.centerScore = maxDeviation > 0 ? 1.0 - (deviation / maxDeviation) : 1.0;
}

// 匹配率
-(CGFloat)modelMatchRatio {
    return (float)self.bestGVs.count / self.assT.count;
}

/**
 *  MARK:--------------------辅因子：完整性（参考36144-方案2）--------------------
 *  @desc 计算所有有效GVs的总着色面积（去重交集），除以protoT面积，得完整性。
 */
-(void) run4IntactRate {
    // 1、在protoGT环境占用率 = 所有有效GVs的union面积 / protoGT面积
    CGFloat assT_AssT = [SMGUtils computeUnionAreaOfRects:[SMGUtils removeRepeat4Rects:self.assT.rects]]; // assT自身的高亮面积。
    CGRect assTRect = self.assT.rect;
    CGFloat assProtoRate = (self.assST_ProtoRect.size.width * self.assST_ProtoRect.size.height) / (assTRect.size.width * assTRect.size.height);
    CGFloat assT_Proto = assT_AssT * assProtoRate; // assT在protoST中的高亮面积。
    CGFloat bests_Proto = [SMGUtils computeArea4STModels_Proto:@[self]];
    CGFloat protoRate = (assT_Proto > 0) ? (bests_Proto / assT_Proto) : 0;
    
    // 2、在assGT环境占用率 = 所有有效GVs的union面积 / assGT面积
    CGFloat bests_AssT = [SMGUtils computeUnionAreaOfRects:[SMGUtils removeRepeat4Rects:[SMGUtils convertArr:self.bestGVs.allKeys convertBlock:^id(NSNumber *key) {
        return ARR_INDEX(self.assT.rects, key.integerValue);
    }]]]; // bests_AssT的高亮面积。
    CGFloat assRate = (assT_AssT > 0) ? (bests_AssT / assT_AssT) : 0;
    
    // 3、二者取其小（参考如下两例，所以得取小）。
    // 示例1、当bests占用proto为100%，但占用assGT为40%时（比如：assGT是0，proto是1，bests只是assGT=0左侧的竖1）。
    // 示例2、当bests占用assGT为100%，但占用proto为40%时（比如：assGT是1，proto是0，bests只匹配到proto=0的左侧）。
    self.intactRate = MIN(protoRate, assRate);
    
    // 4、裁剪到0~1
    self.intactRate = MIN(1.0f, MAX(0.0f, self.intactRate));
}

/**
 *  MARK:--------------------辅因子：稳定性（参考36145-方案）--------------------
 */
-(void) run4AverageContentStrong {
    self.averageContentStrong = [self.assT getAverageContentStrong:self.bestGVs.allKeys];
}

// ST综合竞争分（用于ST识别竞争）。
-(CGFloat) stScore {
    // v1
    // return obj.areaRankRatio * obj.adjacentScore * obj.centerScore;
    
    // v2：20260401前挺准确的，不过想再优化成v3（参考36131）。
    // return self.matchValue * self.modelMatchCountScore * self.absPortStrongScore;
    
    // v3：GT识别仅识别具层，只保留匹配度匹配率（参考36131）。
    // return self.matchValue * self.modelMatchRatio;
    
    // v4：完整性替代匹配率（参考36144）。
    // return self.matchValue * self.intactRate;
    
    // v5：ST按道理来说不要求完整性，主要还是要求稳定性（本来局部特征就提倡复用到各个GT中）。
    // return self.matchValue * self.bestGVs.count;
    
    // v6：打开交层了：匹配数防过具 和 匹配率防过抽 都需要。
    // return self.matchValue * self.modelMatchRatio * self.bestGVs.count;
    
    // v7：匹配数和匹配率，随着加权求和切图法，几乎全是100%，改回只用匹配度来排序（改为主辅层层递进式竞争了，此处关掉）。
    //return [MathUtils getCooledValue:1 - MAX(self.outerShapeMatchValue, self.innerEigenMatchValue) finishValue:cOuterShapeWeight]
    //            * [AIScore scoreWeight:self.totalCountScore weight:cTotalCountWeight]
    //            * [AIScore scoreWeight:self.bestsCountScore weight:cBestsCountWeight];
    
    // v8：改为乘积单纯参与了主辅递进式竞争的因子。
    return self.bestsCountScore * self.matchValue;
}

-(NSString*) stScoreDesc {
    // v2：20260401前挺准确的，不过想再优化成v3（参考36131）。
    // return STRFORMAT(@"匹配度:%.2f 匹配率:%.2f 抽象强度(%02ld):%.2f = 总分:%.2f",self.matchValue,self.modelMatchCountScore,self.validAbsSTPorts.count,self.absPortStrongScore,self.stScore);
    
    // v3：GT识别仅识别具层，只保留匹配度匹配率（参考36131）。
    // return STRFORMAT(@"匹配度:%.2f 匹配率:%.2f = 总分:%.2f",self.matchValue,self.modelMatchRatio,self.stScore);
    
    // v4：完整性替代匹配率（参考36144）。
    // return STRFORMAT(@"匹配度:%.2f 完整性:%.2f = 总分:%.2f (稳定性:%.2f)",self.matchValue,self.intactRate,self.stScore,self.averageContentStrong);
    
    // v5：ST按道理来说不要求完整性，主要还是要求稳定性（本来局部特征就提倡复用到各个GT中）。
    // return STRFORMAT(@"匹配度:%.2f 匹配数:%ld = 总分:%.2f（稳定性:%.2f）",self.matchValue,self.bestGVs.count,self.stScore,self.averageContentStrong);
    
    // v6：打开交层了：匹配数防过具 和 匹配率防过抽 都需要。
    // return STRFORMAT(@"匹配度:%.2f 匹配率:%.2f 匹配数:%02ld = 总分:%.2f（稳定性:%.2f）",self.matchValue,self.modelMatchRatio,self.bestGVs.count,self.stScore,self.averageContentStrong);
    
    // v7：匹配数和匹配率，随着加权求和切图法，几乎全是100%，改回只用匹配度来排序。
    //return STRFORMAT(@"匹配度:%.2f (外形:%.2f 内征:%.2f) 元素数:%.2f (%02ld) 匹配数:%.2f (%02ld) = 总分:%.2f",
    //                 [MathUtils getCooledValue:1 - MAX(self.outerShapeMatchValue, self.innerEigenMatchValue) finishValue:cOuterShapeWeight],self.outerShapeMatchValue,self.innerEigenMatchValue,
    //                 [AIScore scoreWeight:self.totalCountScore weight:cTotalCountWeight],self.assT.count,
    //                 [AIScore scoreWeight:self.bestsCountScore weight:cBestsCountWeight],self.bestGVs.count,
    //                 self.stScore);
    
    // v8：改为打印纯参与了主辅递进式竞争的因子。
    return STRFORMAT(@"匹配数:%.2f (%02ld) 匹配度:%.2f = 总分:%.2f",self.bestsCountScore,self.bestGVs.count,self.matchValue,self.stScore);
}

@end
