//
//  AIFeatureNode.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/18.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIFeatureNode.h"

@implementation AIFeatureNode

-(NSArray *)rects {
    if (!_rects) _rects = [NSArray new];
    return _rects;
}

//内容的md5值，特征以content_ps和level,x,y共同生成。
-(NSString*) getHeaderNotNull {
    if (!STRISOK(self.header)) self.header = [AINetUtils getFeatureNodeHeader:self.content_ps rects:self.rects];
    return self.header;
}

//根据rect找下标，找不到时返-1。
-(NSInteger) indexOfRect:(CGRect)rect {
    //写该方法起因：
    //1. 在特征识别时，只是知道 根据protoIndex识别 并ref映射到target了。
    //2. 我们知道的是：target与i有映射，但不知道i与target的哪个元素有映射。
    //3. 应该根据refPort中的levelxy到target里去找对应下标，这样才能找着映射。
    for (NSInteger i = 0; i < self.count; i++) {
        if (CGRectEqualToRect(VALTOOK(ARR_INDEX(self.rects, i)).CGRectValue, rect)) {
            return i;
        }
    }
    return -1;
}

//MARK:===============================================================
//MARK:                     < 特征位置符合度 >
//MARK:===============================================================
-(NSMutableDictionary *)absMatchDegreeDic{
    if (!ISOK(_absMatchDegreeDic, NSMutableDictionary.class)) _absMatchDegreeDic = [[NSMutableDictionary alloc] initWithDictionary:_absMatchDegreeDic];
    return _absMatchDegreeDic;
}

-(NSMutableDictionary *)conMatchDegreeDic{
    if (!ISOK(_conMatchDegreeDic, NSMutableDictionary.class)) _conMatchDegreeDic = [[NSMutableDictionary alloc] initWithDictionary:_conMatchDegreeDic];
    return _conMatchDegreeDic;
}

-(void) updateMatchDegree:(AINodeBase*)absNode matchDegree:(CGFloat)matchDegree {
   //1. 更新抽象相似度;
   [self.absMatchDic setObject:@(matchDegree) forKey:@(absNode.pId)];
   
   //2. 更新具象相似度;
   [absNode.conMatchDic setObject:@(matchDegree) forKey:@(self.pointer.pointerId)];
   
   //3. 保存节点;
   [SMGUtils insertNode:self];
   [SMGUtils insertNode:absNode];
}

-(CGFloat) getConMatchDegree:(AIKVPointer*)con_p {
    if ([self.pointer isEqual:con_p]) return 1;
    return NUMTOOK([self.conMatchDegreeDic objectForKey:@(con_p.pointerId)]).floatValue;
}
-(CGFloat) getAbsMatchDegree:(AIKVPointer*)abs_p {
    if ([self.pointer isEqual:abs_p]) return 1;
    return NUMTOOK([self.absMatchDegreeDic objectForKey:@(abs_p.pointerId)]).floatValue;
}

//MARK:===============================================================
//MARK:       < degree组（不进行持久化，仅用于step1识别结果的类比中） >
//MARK:===============================================================
-(NSMutableDictionary *)degreeDDic{
    if (!ISOK(_degreeDDic, NSMutableDictionary.class)) _degreeDDic = [[NSMutableDictionary alloc] initWithDictionary:_degreeDDic];
    return _degreeDDic;
}
-(void) updateDegreeDic:(NSInteger)assPId degreeDic:(NSDictionary*)degreeDic {
    [self.degreeDDic setObject:degreeDic forKey:@(assPId)];
}
-(NSDictionary*) getDegreeDic:(NSInteger)assPId {
    return [self.degreeDDic objectForKey:@(assPId)];
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.rects = [aDecoder decodeObjectForKey:@"rects"];
        self.absMatchDegreeDic = [aDecoder decodeObjectForKey:@"absMatchDegreeDic"];
        self.conMatchDegreeDic = [aDecoder decodeObjectForKey:@"conMatchDegreeDic"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.rects forKey:@"rects"];
    [aCoder encodeObject:self.absMatchDegreeDic forKey:@"absMatchDegreeDic"];
    [aCoder encodeObject:self.conMatchDegreeDic forKey:@"conMatchDegreeDic"];
}

@end
