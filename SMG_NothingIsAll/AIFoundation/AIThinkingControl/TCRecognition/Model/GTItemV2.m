//
//  GTItemV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/1/29.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "GTItemV2.h"

@implementation GTItemV2

-(id) init {
    self =[super init];
    if (self) {
        self.beAssSTStrongRatioCache = -1;
        self.beAssSTStrongRatioByContentCache = -1;
    }
    return self;
}

-(AIFeatureNode*) baseBroST {
    AIKVPointer *broST_p = ARR_INDEX(self.baseAssGT.content_ps, self.assGTIndex);
    return [SMGUtils searchNode:broST_p];
}

-(CGRect) assST_ProtoT {
    return self.baseSTModel.assST_ProtoRect;
}

-(CGRect) absST_AssGT {
    return [self.baseAssGT rectByIndex:self.assGTIndex];
}

-(CGRect) absST_ProtoT {
    // 计算过，则直接返回缓存结果。
    if (!CGRectIsEmpty(self.absST_ProtoTCache)) return self.absST_ProtoTCache;
    
    // 设AbsST为A，AssST为B，ProtoT为C计算如下：
    // A_B
    AIFeatureNode *absST = [SMGUtils searchNode:self.baseAbsST];
    AIPort *conPort = [SMGUtils filterSingleFromArr:absST.conPorts checkValid:^BOOL(AIPort *item) {
        return [item.target_p isEqual:self.baseSTModel.assT.p];
    }];
    CGRect absST_AssST = conPort.rect;
    
    // B_C
    CGRect assST_ProtoT = [self assST_ProtoT];
    
    // BSize
    CGRect assSTRect = [SMGUtils convertArr2Rect:self.baseSTModel.assT.rects itemRectBlock:^CGRect(NSValue *item) {
        return item.CGRectValue;
    }];
    
    // A_C
    self.absST_ProtoTCache = [SMGUtils convertAAtCWithAAtB:absST_AssST bAtC:assST_ProtoT protoBSize:assSTRect.size];
    return self.absST_ProtoTCache;
}

//MARK:===============================================================
//MARK: < 显著度：因为通路是ass,abs,bro，所以显著度有两个值（参考36019-步骤2&3）>
//MARK:===============================================================

// 对于assST的显著程度（参考36021-TODO1）。
-(CGFloat) beAssSTStrongRatio {
    // 有缓存复用返回。
    if (self.beAssSTStrongRatioCache != -1) return self.beAssSTStrongRatioCache;
    
    // 无缓存新计算返回。
    self.beAssSTStrongRatioCache = [self beGeneralSTStrongRatio:self.baseSTModel.assT];
    return self.beAssSTStrongRatioCache;
}

// 对于assST.content的显著程度（参考36022）
-(CGFloat) beAssSTStrongRatioByContent {
    // 有缓存复用返回。
    if (self.beAssSTStrongRatioByContentCache != -1) return self.beAssSTStrongRatioByContentCache;
    
    // 无缓存新计算返回。
    self.beAssSTStrongRatioByContentCache = [self beGeneralSTStrongRatioByContent:self.baseSTModel.assT];
    return self.beAssSTStrongRatioByContentCache;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(CGFloat) beGeneralSTStrongRatio:(AIFeatureNode*)generalConST {
    // 取出所有抽象特征。
    NSArray *absPorts = [AINetUtils absPorts_All:generalConST];
    
    // 找出最显著的。
    NSInteger best = [SMGUtils filterBestScore:absPorts scoreBlock:^CGFloat(AIPort *item) {
        return item.strong.value;
    }];
    
    // 找出当前baseAbsST显著值。
    AIPort *baseAbsPort = [SMGUtils filterSingleFromArr:absPorts checkValid:^BOOL(AIPort *item) {
        return [item.target_p isEqual:self.baseAbsST];
    }];
    
    // 求出当前baseAbsST的归一化显著度。
    return best > 0 ? (float)baseAbsPort.strong.value / best : 0;
}

-(CGFloat) beGeneralSTStrongRatioByContent:(AIFeatureNode*)generalConST {
    if ([generalConST.p isEqual:self.baseAbsST]) return 1;
    
    // 取出absST有些哪些元素。
    NSDictionary *indexDic = [generalConST getAbsIndexDic:self.baseAbsST];
    
    // 找出最显著的。
    NSInteger best = [SMGUtils filterBestScore:generalConST.contentPorts scoreBlock:^CGFloat(AIPort *item) {
        return item.strong.value;
    }];
    
    // 找出当前baseAbsST显著值（absST的元素，对应在conST中的内容的平均显著值）。
    NSInteger sumStrongOfAbsST = [AINetUtils getSumContentStrongByIndexes:indexDic.allValues baseNode:generalConST];
    CGFloat pinjunStrongOfAbsST = indexDic.count > 0 ? (float)sumStrongOfAbsST / indexDic.count : 0.0f;
    
    // 求出当前baseAbsST的归一化显著度。
    return best > 0 ? pinjunStrongOfAbsST / best : 0.0f;
}

// 综合显著度（参考36021）。
-(CGFloat) zonHeStrongRatio {
    // 2026.02.18: 先关掉，因为显著度也没起到什么作用，关掉看下有没问题，没问题的话，废弃掉，避免导致算法复杂，导致有别的问题而不知。
    return 1;
    // return self.beAssSTStrongRatio * self.beBroSTStrongRatio;
}

// GTItem的综合竞争分（用于GT自举算法竞争）。
-(CGFloat) zonHeScore {
    return self.baseSTModel.stScore * self.matchValue * self.zonHeStrongRatio * self.matchDegree;
}

@end
