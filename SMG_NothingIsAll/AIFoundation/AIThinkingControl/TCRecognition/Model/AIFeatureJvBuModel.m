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
    //self.matchDegree = self.bestGVs.count == 0 ? 0 : [SMGUtils sumOfArr:self.bestGVs convertBlock:^double(AIFeatureJvBuItem *obj) {
    //    return obj.matchDegree;
    //}] / self.bestGVs.count;
    //2025.05.21: 符合度乘积版：改成求乘积，因为看日志，感觉竞争结果中，符合度太弱了，都差不多都很高。
    self.matchDegree = 1;
    for (AIFeatureJvBuItem *item in self.bestGVs) {
        self.matchDegree *= item.matchDegree;
    }
    
    //3. 此处没有protoT.count，所以健全度直接用assCount也是不影响竞争的。
    //2025.05.11: 修复健全度低问题，由总assT.count改成bestGVs.count，因为并不判断全含，所以由总数改成匹配到的数。
    self.matchAssProtoRatio = self.bestGVs.count;
}

-(void) run4AssTAtProtoTRect {
    self.assTAtProtoTRect = CGRectNull;
    for (AIFeatureJvBuItem *item in self.bestGVs) {
        self.assTAtProtoTRect = CGRectUnion(self.assTAtProtoTRect, item.bestGVAtProtoTRect);
    }
}

@end
