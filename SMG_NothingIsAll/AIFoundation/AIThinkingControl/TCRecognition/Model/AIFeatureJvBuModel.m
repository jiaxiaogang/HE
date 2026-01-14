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

-(void) run4MatchValueAndMatchDegreeAndMatchAssProtoRatio {
    //1. 匹配度。
    [self run4MatchValue];
    
    //2. 符合度。
    self.matchDegree = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.matchDegree;
    }] / self.bestGVs.count;
    //2025.05.21: 符合度乘积版：改成求乘积，因为看日志，感觉竞争结果中，符合度太弱了，都差不多都很高（后发现类比时定责总是不准，先回滚回用平均值）。
    //self.matchDegree = 1;
    //for (AIFeatureJvBuItem *item in self.bestGVs) {
    //    self.matchDegree *= item.matchDegree;
    //}
    
    //3. 此处没有protoT.count，所以健全度直接用assCount也是不影响竞争的。
    //2025.05.11: 修复健全度低问题，由总assT.count改成bestGVs.count，因为并不判断全含，所以由总数改成匹配到的数。
    self.matchAssProtoRatio = self.bestGVs.count;
    
    //4. 匹配率
    self.matchAssRatio = self.bestGVs.count / (float)self.assT.count;
    
    //5. 色似度
    self.matchDiffValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.diffValue;
    }] / self.bestGVs.count;
    
    //6. 视角匹配度。
    self.matchRectValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allKeys convertBlock:^double(NSNumber *assIndex) {
        AIFeatureJvBuItem *obj = [self.bestGVs objectForKey:assIndex];
        NSValue *assRect = ARR_INDEX(self.assT.rects, assIndex.integerValue);
        return obj.bestGVAtProtoTRect.size.width / assRect.CGRectValue.size.width;
    }] / self.bestGVs.count;
    
    //7. 类比淘汰bestGVs不会更新到jvBuModel.bestGVs了，这直接把assT在protoT的位置算出来。
    [self run4BestGvsAtProtoTRect];
}

-(void) run4MatchValue {
    //1. 匹配度。
    self.matchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs.allValues convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.matchValue;
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

// 2025.08.14: 支持防过抽、防过具（防抽具二者互相制衡，动态平衡竞争）、分区竞争、归一化，即：分区匹配度 * 防过具象 * 防过抽象（参考35064 & 35082-方案3 & 方案4）。
-(CGFloat) getSTMatch {
    return self.areaRankRatio;// * self.bestGVs.count;// * self.matchDiffValue;
}

//2025.08.26: 组特征竞争要避免太抽象-匹配率高即为抽象显著的（参考35068-方案1）。
-(CGFloat) getGTMatch {
    return self.matchValue * self.matchAssRatio * self.matchAssRatio;// * self.matchDiffValue;
}

-(NSString*) getSTMatchDesc {
    return STRFORMAT(@"匹配度:%.2f \t防抽(抽象等级%ld):%.2f \t防具:%.2f = \t区域竞争力:%.2f \t(%.0f/%ld=%.0f)",
                     self.matchValue,self.assT.absLevel,self.absLevelRatio,self.conPortStrongRatio,self.areaRankRatio,
                     self.areaRankSum,self.areaRankNum,self.areaRankScore);
}

-(NSString*) getGTMatchDesc {
    //return STRFORMAT(@"\t匹配度:%.2f",self.matchValue);
    return STRFORMAT(@"\t匹配度:%.2f\t匹配率:%.1f",self.matchValue,self.matchAssRatio);
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
    
    // TODOTOMORROW20260114:
    // 待查1、查下此处明明只有2条gv，但防抽0.71分太高了，导致过抽象。
    // 0. 单特征识别结果:T213     (2/4)     匹配度:1.00     防抽:0.71     防具:0.25 =     区域竞争力:1.00     (143/13=11) bestGVs_Proto:<x0 y0 w27 h27>
    // 经查、现在防过抽是根据抽象等级来计算的，而有时从40条抽象到2条需要7次，有时只需要2次，assST的长度与absLevel并不线性正相关，因为ST匹配数决定了absST的长度，所以受此干扰很严重。
    // 所以、absLevel不适合做为计算“防过抽”的因素唯一，assST长度更直观可考虑替代之。
    
    // 待查：查下那么多ST经历，为什么还能识别这么不准确，是不是广入有问题？
    // 待查：为什么ST结果全几乎是全屏显示，难道每个0,0,27,27都匹配度很高，实在淘汰不了它？
    
    // 给区域内的stModels排名 & 并计分 & 计次（排名越大越好）。
    // 方案1、区域综合竞争后，打分时，对防抽防具最后30%名进行降权（参考36096-TODO3.3）。
    zoneSTModels = [SMGUtils sortSmall2Big:zoneSTModels compareBlock:^double(AIFeatureJvBuModel *obj) {
        return obj.matchValue * self.absLevelRatio * self.conPortStrongRatio;
    }];
    for (NSInteger i = 0; i < zoneSTModels.count; i++) {
        AIFeatureJvBuModel *obj = ARR_INDEX(zoneSTModels, i);
        
        // 对于防抽防具值<0.3的，进行权重打压（避免从平均学渣中选出劣币）。
        CGFloat daYaValue = MIN(obj.absLevelRatio, obj.conPortStrongRatio);
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
    //    obj.areaRankSum += i * obj.absLevelRatio * obj.conPortStrongRatio; // 累计名次（参考35076-TODO2.2）;
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
    CGRect itemGV_ProtoRect = [SMGUtils convertBAtA:self.beginGV_ProtoRect atB:beginGV_AssRect.CGRectValue B:itemGV_AssRect.CGRectValue];
    return itemGV_ProtoRect;
}

// 计算整个assST_ProtoRect
-(void) run4AssST_ProtoRect {
    CGRect bestGVs_AssST = [SMGUtils convertArr2Rect:self.bestGVs.allKeys itemRectBlock:^CGRect(NSNumber *item) {
        return [self.assT rectByIndex:item.integerValue];
    }];
    CGRect assSTRect = [SMGUtils convertArr2Rect:self.assT.rects itemRectBlock:^CGRect(NSValue *item) {
        return item.CGRectValue;
    }];
    self.assST_ProtoRect = [SMGUtils convertBAtA:self.bestGVsAtProtoTRect atB:bestGVs_AssST B:assSTRect];
}

// bestGVs根据匹配度末尾淘汰20%（参考35138-TODO1）。
-(void) filter4MatchValue {
    // 方案1：竞争末尾淘汰20%（参考35138-TODO1）。
    //NSArray *sort = [SMGUtils sortSmall2Big:self.bestGVs.allKeys compareBlock:^double(NSNumber *key) {
    //    AIFeatureJvBuItem *value = [self.bestGVs objectForKey:key];
    //    return value.matchValue;
    //}];
    //NSArray *invalidKeys = ARR_SUB(sort, 0, sort.count * 0.2f);
    
    // 方案2：直接把matchValue<0.6的过滤掉（参考35138-TODO1）。
    NSArray *invalidKeys = [SMGUtils filterArr:self.bestGVs.allKeys checkValid:^BOOL(NSNumber *key) {
        AIFeatureJvBuItem *value = [self.bestGVs objectForKey:key];
        return value.matchValue < 0.6f;
    }];
    [self.bestGVs removeObjectsForKeys:invalidKeys];
}

@end
