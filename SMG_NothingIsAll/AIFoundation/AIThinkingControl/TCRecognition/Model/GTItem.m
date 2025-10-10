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
    // hRate = 14/18=0.778 baseGTModel.hModel.v4span = 0.057 v1平均=0.981 v2min=0.943 v3max=1 所以：1-(0.0778-1)/0.057=-2.88
    // 线索：看起来其实还是当前hRate越界了，以往经验中，最小的是0.943，但新的hRate却成了0.778，这里限定一下它的值范围。
    CGFloat curWRate = MAX(self.wRate, NUMTOOK(baseGTModel.wModel.v2).floatValue);
    CGFloat curHRate = MAX(self.hRate, NUMTOOK(baseGTModel.hModel.v2).floatValue);
    CGFloat curXDelta = MAX(self.xDelta, NUMTOOK(baseGTModel.xModel.v2).floatValue);
    CGFloat curYDelta = MAX(self.yDelta, NUMTOOK(baseGTModel.yModel.v2).floatValue);
    
    // 求四个相近度（参考34136-TODO4），然后四个要素乘积“位置符合度”（参考34136-TODO5）。
    // 根据item与proto的差距 / 最大差距 = 得出相近度。
    CGFloat wMatchDegree = 1 - (NUMTOOK(baseGTModel.wModel.v4).floatValue == 0 ? 0 : fabs(curWRate - 1) / NUMTOOK(baseGTModel.wModel.v4).floatValue);
    
    
    // hRate = 9/12=0.75 baseGTModel.hModel.v4span = 0.028 v1平均=0.764 v2min=0.75 v3max=778 所以：1-(0.75-1)/0.028=-7.999
    // 线索：此处当前hRate也没越界，但却算出-7.999，明天继续分析下，这里怎么限定一下它的值范围。
    CGFloat hMatchDegree = 1 - (NUMTOOK(baseGTModel.hModel.v4).floatValue == 0 ? 0 : fabs(curHRate - 1) / NUMTOOK(baseGTModel.hModel.v4).floatValue);
    
    CGFloat xMatchDegree = 1 - (NUMTOOK(baseGTModel.xModel.v4).floatValue == 0 ? 0 : fabs(curXDelta) / NUMTOOK(baseGTModel.xModel.v4).floatValue);
    CGFloat yMatchDegree = 1 - (NUMTOOK(baseGTModel.yModel.v4).floatValue == 0 ? 0 : fabs(curYDelta) / NUMTOOK(baseGTModel.yModel.v4).floatValue);
    
    // xyMatchDegree可能<0的问题：调用时的newItem的yDelta，比前面的那些最大的span，确实有可能更大。（这样的话，应该是把yMatchDegree最小不能<0就行了）。
    if (wMatchDegree < 0 || hMatchDegree < 0 || xMatchDegree < 0 || yMatchDegree < 0) {
        NSLog(@"查下为负原因");
    }
    xMatchDegree = MAX(xMatchDegree, 0);
    yMatchDegree = MAX(yMatchDegree, 0);
    
    // 精度处理（避免-0.0000001这种问题）。
    wMatchDegree = (int)(wMatchDegree * 100) / 100.0f;
    hMatchDegree = (int)(hMatchDegree * 100) / 100.0f;
    xMatchDegree = (int)(xMatchDegree * 100) / 100.0f;
    yMatchDegree = (int)(yMatchDegree * 100) / 100.0f;
    
    self.itemMatchDegree = wMatchDegree * hMatchDegree * xMatchDegree * yMatchDegree;
    
    // todotomorrow20251007: 此处yMatchDegree还是有为负的情况问题。
    if (self.itemMatchDegree < 0 || self.itemMatchDegree > 1) {
        ELog(@"itemMatchDegree值越界：%.2f %.3f %.3f",self.itemMatchDegree,self.yDelta,NUMTOOK(baseGTModel.yModel.v4).floatValue);
        NSLog(@"");
    }
}

@end
