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
    return result;
}

// 根据conST分别在：assGT和protoGT的rect，计算切入点的wh比例。
// 这个whRate就是基准比例，即符合这个比例才是正常的（比如1:2)，如果不符合了反而不正常（比如下一元素变成1:1了）。
// 当然真正竞争的时候，会以平均比例为基准，即匹配了那么多，排除最高低分之后的平均分为基准，离平均分近即匹配，离平均分远则不匹配。
-(CGFloat) wRate {
    return self.conST_ProtoGT.size.width / self.conST_AssGT.size.width;
}

-(CGFloat) hRate {
    return self.conST_ProtoGT.size.height / self.conST_AssGT.size.height;
}

-(CGFloat) xDelta {
    return self.conST_ProtoGT.origin.x / self.conST_AssGT.origin.x;
}

-(CGFloat) yDelta {
    return self.conST_ProtoGT.origin.y / self.conST_AssGT.origin.y;
}

-(CGFloat) matchRate {
    return MIN(self.wRate / self.hRate, self.hRate / self.wRate);
}

-(CGFloat) getMatchDegree {
    //TODO: 此处根据整个model的平均位置符合度，计算当前item的位置符合度。
    return 1;
}

@end
