//
//  AIFeatureJvBuModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureJvBuModel.h"

@implementation AIFeatureJvBuModel

+(id) new:(AIFeatureNode*)assT {
    AIFeatureJvBuModel *result = [AIFeatureJvBuModel new];
    result.assT = assT;
    return result;
}

-(NSMutableArray *)bestGVs {
    if (!_bestGVs) _bestGVs = [NSMutableArray new];
    return _bestGVs;
}

-(void) run4MatchValueAndMatchDegreeAndMatchAssProtoRatio {
    //1. 匹配度。
    self.matchValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.matchValue;
    }] / self.bestGVs.count;
    
    //2. 符合度。
    self.matchDegree = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs convertBlock:^double(AIFeatureJvBuItem *obj) {
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
    self.matchDiffValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs convertBlock:^double(AIFeatureJvBuItem *obj) {
        return obj.diffValue;
    }] / self.bestGVs.count;
    
    //6. 视角匹配度。
    self.matchRectValue = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs convertBlock:^double(AIFeatureJvBuItem *obj) {
        NSValue *assRect = ARR_INDEX(self.assT.rects, obj.assIndex);
        return obj.bestGVAtProtoTRect.size.width / assRect.CGRectValue.size.width;
    }] / self.bestGVs.count;
    
    //7. 类比淘汰bestGVs不会更新到jvBuModel.bestGVs了，这直接把assT在protoT的位置算出来。
    [self run4BestGvsAtProtoTRect];
}

-(void) run4BestGvsAtProtoTRect {
    self.bestGVsAtProtoTRect = CGRectNull;
    for (AIFeatureJvBuItem *item in self.bestGVs) {
        self.bestGVsAtProtoTRect = CGRectUnion(self.bestGVsAtProtoTRect, item.bestGVAtProtoTRect);
    }
}

//2025.08.14: 因为竞争浮现不明显，去掉色似度后ok了，如果以后因为去掉色似度导致bug，可以改回来，然后把匹配率改成2次方来强调它的作用试下（参考35064）。
-(CGFloat) getSTMatch {
    // 说明：防止过度抽象或过度具象：显著度matchAssRatio可以防止过度具象，匹配数bestGVs.count可以防止过度抽象（二者互相制衡，动态平衡竞争）。
    // xxxx.xx.xx: 防止过度具象：加上matchAssRatio (bestGVs.count/assST.count)，如果过度具象bestGVs肯定不达标，这样就能让它没竞争力（缺点是越抽象越显著，它可能过度抽象）。
    // 2025.10.20: 防止过度抽象：加上bestGVs.count，因为这样就可以防止过度抽象，因为过度抽象的bestGVs.count会越来越接近1条（缺点是越具象匹配数越大，它可能过度具象）。
    // 2025.10.28: 加上分区竞争后，bestGVs.count太重了，会导致识别的st全是过度具象的，进而导致GT识别时取交对撞不到结果（参考35082-方案3）。
    // 2025.10.29: 改为归一化之后的：分区匹配度 * 防过具象 * 防过抽象（参考35082-方案4）。
    // 2025.10.31: 稳定结果中，越抽象的越好：加上absLevelRatio。
    // return self.areaRankRatio * self.matchAssRatio * self.bestGVsCountRatio * self.conPortStrongRatio;// * self.bestGVs.count;// * self.matchDiffValue;
    // return self.areaRankRatio * (1-self.absLevelRatio) * self.conPortStrongRatio;// * self.bestGVs.count;// * self.matchDiffValue;
    return self.areaRankRatio;// * self.bestGVs.count;// * self.matchDiffValue;
}

//2025.08.26: 组特征竞争要避免太抽象-匹配率高即为抽象显著的（参考35068-方案1）。
-(CGFloat) getGTMatch {
    return self.matchValue * self.matchAssRatio * self.matchAssRatio;// * self.matchDiffValue;
    //return self.matchValue;
}

-(NSString*) getSTMatchDesc {
    // return STRFORMAT(@"\t匹配度:%.2f\t匹配率:%.1f\t色似度:%.1f",self.matchValue,self.matchAssRatio,self.matchDiffValue);
    // return STRFORMAT(@"\t区匹配度:%.1f\t防过具象:%.1f(%ld/%ld)\t防过抽象:%.1f\t稳中取抽象:%.1f = 综合:%.2f",self.areaRankRatio,self.matchAssRatio,self.bestGVs.count,self.assT.count,self.bestGVsCountRatio,self.conPortStrongRatio,self.areaRankRatio*self.matchAssRatio*self.bestGVsCountRatio*self.conPortStrongRatio);
    // return STRFORMAT(@"\t匹配数:(%ld/%ld) 区度:%.1f x 防抽:%.1f x 防具:%.1f = 综合:%.2f",self.bestGVs.count,self.assT.count,self.areaRankRatio,(1-self.absLevelRatio),self.conPortStrongRatio,self.areaRankRatio*self.conPortStrongRatio*self.absLevelRatio);
    return STRFORMAT(@"匹配度:%.2f \t防抽:%.2f \t防具:%.2f = \t区域竞争力:%.2f(%.0f/%ld=%.0f)",
                     self.matchValue,self.absLevelRatio,self.conPortStrongRatio,self.areaRankRatio,
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
    CGFloat scale = 1.3f;
    CGRect zoneRect = CGRectMake(centP.x - protoR.size.width * scale * 0.5f, centP.y - protoR.size.height * scale * 0.5f, protoR.size.width * scale, protoR.size.height * scale);
    NSArray *zoneSTModels = [SMGUtils filterArr:stModels checkValid:^BOOL(AIFeatureJvBuModel *item) {
        return CGRectContainsRect(zoneRect, item.bestGVsAtProtoTRect);
    }];
    
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

@end
