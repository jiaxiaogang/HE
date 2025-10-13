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
    CGFloat wMatchDegree = [self run4XYWHItemMatchDegree:baseGTModel.wModel curV:self.wRate];
    CGFloat hMatchDegree = [self run4XYWHItemMatchDegree:baseGTModel.hModel curV:self.hRate];
    CGFloat xMatchDegree = [self run4XYWHItemMatchDegree:baseGTModel.xModel curV:self.xDelta];
    CGFloat yMatchDegree = [self run4XYWHItemMatchDegree:baseGTModel.yModel curV:self.yDelta];
    
    self.itemMatchDegree = wMatchDegree * hMatchDegree * xMatchDegree * yMatchDegree;
}

// 把xywh其中一个维度的位置符合度算出来。
-(CGFloat) run4XYWHItemMatchDegree:(MapModel*)xywhItemModel curV:(CGFloat)curV {
    // 数据准备。
    CGFloat pinjun = NUMTOOK(xywhItemModel.v1).floatValue;
    CGFloat min = NUMTOOK(xywhItemModel.v2).floatValue;
    CGFloat max = NUMTOOK(xywhItemModel.v3).floatValue;
    
    // FINDBUG：hRate = 9/12=0.75 baseGTModel.hModel.v4span = 0.028 v1平均=0.764 v2min=0.75 v3max=0.778 所以：1-(0.75-1)/0.028=-7.999
    // FINDBUG：hRate = 14/18=0.778 baseGTModel.hModel.v4span = 0.057 v1平均=0.981 v2min=0.943 v3max=1 所以：1-(0.0778-1)/0.057=-2.88
    // 线索：此处当前hRate也没越界，但却算出-7.999，明天继续分析下，这里怎么限定一下它的值范围。
    // BUGFIX：此处当前hRate越界了，以往经验中，最小的是0.943，但新的hRate却成了0.778，这里限定一下它的值范围。
    curV = MIN(MAX(curV, min), max);
    
    // 改成cur与平均之间的距离：当小于pinjun的话就是在平均与min之间的占位比例，大于pinjun的话就是在平均与max之间的占位比例，越接近平均越匹配。
    // 小于平均时：越靠近min越接近0，越靠近pinjun越接近1。
    // 大于平均时：越靠近max越接近0，越靠近pinjun越接近1。
    CGFloat span = curV < pinjun ? pinjun - min : max - pinjun;
    CGFloat score = curV < pinjun ? curV - min : max - curV;
    CGFloat result = span > 0 ? score / span : 1;
    
    // xywhMatchDegree可能<0的问题：上面已经对curV的值越界做了处理，这个不应该还有<0的问题了。
    if (result < 0 || result > 1) {
        ELog(@"查下itemMatchDegree值越界：%.2f %.3f %.3f %.3f %.3f",result,curV,pinjun,min,max);
    }
    
    // 精度处理（避免-0.0000001这种问题）。
    return (int)(result * 100) / 100.0f;
}

@end
