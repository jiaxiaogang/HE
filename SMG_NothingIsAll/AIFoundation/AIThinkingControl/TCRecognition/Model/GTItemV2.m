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
        self.beBroSTStrongRatioCache = -1;
        self.beAssSTStrongRatioByContentCache = -1;
        self.beBroSTStrongRatioByContentCache = -1;
    }
    return self;
}

-(AIFeatureNode*) baseBroST {
    AIKVPointer *broST_p = ARR_INDEX(self.baseAssGT.content_ps, self.broSTIndex);
    return [SMGUtils searchNode:broST_p];
}

-(CGRect) assST_ProtoT {
    return self.baseSTModel.assST_ProtoRect;
}

-(CGRect) broST_AssGT {
    return [self.baseAssGT rectByIndex:self.broSTIndex];
}

-(CGRect) absST_ProtoT {
    // 计算过，则直接返回缓存结果。
    if (!CGRectIsEmpty(self.absST_ProtoTCache)) return self.absST_ProtoTCache;
    
    // 设AbsST为A，AssST为B，ProtoT为C计算如下：
    // A_B
    AIPort *conPort = [SMGUtils filterSingleFromArr:self.baseAbsST.conPorts checkValid:^BOOL(AIPort *item) {
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

-(CGRect) broST_ProtoT {
    // 计算过，则直接返回缓存结果。
    if (!CGRectIsEmpty(self.broST_ProtoTCache)) return self.broST_ProtoTCache;
    
    // 设BroST为B，ProtoT为A，AbsST为C，求BAtA，计算如下：
    // C_B：absST_BroST
    AIKVPointer *broST_p = ARR_INDEX(self.baseAssGT.content_ps, self.broSTIndex);
    AIPort *conPort = [SMGUtils filterSingleFromArr:self.baseAbsST.conPorts checkValid:^BOOL(AIPort *item) {
        return [item.target_p isEqual:broST_p];
    }];
    CGRect absST_BroST = conPort.rect;
    
    // C_A：absST_ProtoT
    CGRect absST_ProtoT = [self absST_ProtoT];
    
    // B：broSTRect
    AIFeatureNode *broST = [SMGUtils searchNode:broST_p];
    CGRect broSTRect = [SMGUtils convertArr2Rect:broST.rects itemRectBlock:^CGRect(NSValue *item) {
        return item.CGRectValue;
    }];
    
    // B_A：broST_ProtoT
    self.broST_ProtoTCache = [SMGUtils convertBAtAWithCAtA:absST_ProtoT cAtB:absST_BroST B:broSTRect];
    return self.broST_ProtoTCache;
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

// 对于broST的显著程度（参考36021-TODO2）。
-(CGFloat) beBroSTStrongRatio {
    // 有缓存复用返回。
    if (self.beBroSTStrongRatioCache != -1) return self.beBroSTStrongRatioCache;
    
    // 无缓存新计算返回。
    self.beBroSTStrongRatioCache = [self beGeneralSTStrongRatio:self.baseBroST];
    return self.beBroSTStrongRatioCache;
}

// 对于assST.content的显著程度（参考36022）
-(CGFloat) beAssSTStrongRatioByContent {
    // 有缓存复用返回。
    if (self.beAssSTStrongRatioByContentCache != -1) return self.beAssSTStrongRatioByContentCache;
    
    // 无缓存新计算返回。
    self.beAssSTStrongRatioByContentCache = [self beGeneralSTStrongRatioByContent:self.baseSTModel.assT];
    return self.beAssSTStrongRatioByContentCache;
}

// 对于broST.content的显著程度（参考36022）
-(CGFloat) beBroSTStrongRatioByContent {
    // 有缓存复用返回。
    if (self.beBroSTStrongRatioByContentCache != -1) return self.beBroSTStrongRatioByContentCache;
    
    // 无缓存新计算返回。
    self.beBroSTStrongRatioByContentCache = [self beGeneralSTStrongRatioByContent:self.baseBroST];
    return self.beBroSTStrongRatioByContentCache;
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
        return [item.target_p isEqual:self.baseAbsST.p];
    }];
    
    // 求出当前baseAbsST的归一化显著度。
    return best > 0 ? (float)baseAbsPort.strong.value / best : 0;
}

-(CGFloat) beGeneralSTStrongRatioByContent:(AIFeatureNode*)generalConST {
    if ([generalConST isEqual:self.baseAbsST]) return 1;
    
    // 取出absST有些哪些元素。
    NSDictionary *indexDic = [generalConST getAbsIndexDic:self.baseAbsST.p];
    
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

@end
