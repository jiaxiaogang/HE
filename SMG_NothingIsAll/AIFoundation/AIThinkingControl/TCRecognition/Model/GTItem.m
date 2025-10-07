//
//  GTItem.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "GTItem.h"

@implementation GTItem

+(id) new:(NSInteger)protoIndex assIndex:(NSInteger)assIndex conST_ProtoGT:(CGRect)conST_ProtoGT conST_AssGT:(CGRect)conST_AssGT {
    GTItem *result = [GTItem new];
    result.protoIndex = protoIndex;
    result.assIndex = assIndex;
    result.conST_ProtoGT = conST_ProtoGT;
    result.conST_AssGT = conST_AssGT;
    return result;
}

// 根据conST分别在：assGT和protoGT的rect，计算切入点的wh比例。
// 这个whRate就是基准比例，即符合这个比例才是正常的（比如1:2)，如果不符合了反而不正常（比如下一元素变成1:1了）。
// 当然真正竞争的时候，会以平均比例为基准，即匹配了那么多，排除最高低分之后的平均分为基准，离平均分近即匹配，离平均分远则不匹配。
-(CGFloat) wRate {
    return MIN(self.conST_ProtoGT.size.width / self.conST_AssGT.size.width, self.conST_AssGT.size.width / self.conST_ProtoGT.size.width);
}

-(CGFloat) hRate {
    return MIN(self.conST_ProtoGT.size.height / self.conST_AssGT.size.height, self.conST_AssGT.size.height / self.conST_ProtoGT.size.height);
}

-(CGFloat) xDelta {
    return self.conST_ProtoGT.origin.x - self.conST_AssGT.origin.x;
}

-(CGFloat) yDelta {
    return self.conST_ProtoGT.origin.y - self.conST_AssGT.origin.y;
}

-(void) run4ItemMatchDegree:(GTModel*)baseGTModel {
    // 求四个相近度（参考34136-TODO4），然后四个要素乘积“位置符合度”（参考34136-TODO5）。
    // 根据item与proto的差距 / 最大差距 = 得出相近度。
    CGFloat wMatchDegree = 1 - (NUMTOOK(baseGTModel.wModel.v4).floatValue == 0 ? 0 : fabs(self.wRate - 1) / NUMTOOK(baseGTModel.wModel.v4).floatValue);
    CGFloat hMatchDegree = 1 - (NUMTOOK(baseGTModel.hModel.v4).floatValue == 0 ? 0 : fabs(self.hRate - 1) / NUMTOOK(baseGTModel.hModel.v4).floatValue);
    CGFloat xMatchDegree = 1 - (NUMTOOK(baseGTModel.xModel.v4).floatValue == 0 ? 0 : fabs(self.xDelta) / NUMTOOK(baseGTModel.xModel.v4).floatValue);
    CGFloat yMatchDegree = 1 - (NUMTOOK(baseGTModel.yModel.v4).floatValue == 0 ? 0 : fabs(self.yDelta) / NUMTOOK(baseGTModel.yModel.v4).floatValue);
    
    // 精度处理（避免-0.0000001这种问题）。
    wMatchDegree = (int)(wMatchDegree * 100) / 100.0f;
    hMatchDegree = (int)(hMatchDegree * 100) / 100.0f;
    xMatchDegree = (int)(xMatchDegree * 100) / 100.0f;
    yMatchDegree = (int)(yMatchDegree * 100) / 100.0f;
    
    self.itemMatchDegree = wMatchDegree * hMatchDegree * xMatchDegree * yMatchDegree;
    
    // todotomorrow20251007: 此处yMatchDegree还是有为负的情况问题。
    if (self.itemMatchDegree < 0 || self.itemMatchDegree > 1) {
        ELog(@"itemMatchDegree值越界：%.2f",self.itemMatchDegree);
    }
}

@end
