//
//  AINodeBase.m
//  SMG_NothingIsAll
//
//  Created by jiaxiaogang on 2018/9/26.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "AINodeBase.h"
#import "AIKVPointer.h"

@implementation AINodeBase

-(NSMutableArray *)conPorts{
    if (!ISOK(_conPorts, NSMutableArray.class)) _conPorts = [[NSMutableArray alloc] initWithArray:_conPorts];
    return _conPorts;
}

-(NSMutableArray *)absPorts{
    if (!ISOK(_absPorts, NSMutableArray.class)) _absPorts = [[NSMutableArray alloc] initWithArray:_absPorts];
    return _absPorts;
}

-(NSMutableArray *)contentPorts{
    if (_contentPorts == nil) _contentPorts = [[NSMutableArray alloc] init];
    return _contentPorts;
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================
-(NSInteger) count{
    return self.content_ps.count;
}

-(NSMutableArray *)content_ps{
    return [SMGUtils convertArr:self.contentPorts convertBlock:^id(AIPort *obj) {
        return obj.target_p;
    }];
}

-(void) setContent_ps:(NSArray*)content_ps {
    [self setContent_ps:content_ps getStrongBlock:^NSInteger(AIKVPointer *item_p) {
        return 1;
    }];
}

-(AIKVPointer*) p {
    return self.pointer;
}

-(NSInteger) pId {
    return self.pointer.pointerId;
}

/**
 *  MARK:--------------------设置引用--------------------
 *  @version
 *      2023.04.15: BUG_此处header应该以alg元素为准;
 *      2023.06.18: 支持mvNode取content_ps为delta_p和urgent_p,避免nil生成header,导致分不清mv和空概念 (参考30026-修复);
 */
-(void) setContent_ps:(NSArray*)content_ps getStrongBlock:(NSInteger(^)(AIKVPointer *item_p))getStrongBlock{
    content_ps = ARRTOOK(content_ps);
    self.contentPorts = [SMGUtils convertArr:content_ps convertBlock:^id(AIKVPointer *obj) {
        //1. 数据准备: 求出header
        AIAlgNodeBase *alg = [SMGUtils searchNode:obj];
        NSArray *sortValue_ps = ARRTOOK([SMGUtils sortPointers:alg.content_ps]);
        NSString *header = [NSString md5:[SMGUtils convertPointers2String:sortValue_ps]];
        
        //2. 生成port
        AIPort *port = [[AIPort alloc] init];
        port.target_p = obj;
        port.header = header;
        port.strong.value = getStrongBlock(obj);
        return port;
    }];
}

//MARK:===============================================================
//MARK:                     < 匹配度 (支持: 概念,时序) >
//MARK:===============================================================

-(NSMutableDictionary *)absMatchDic{
    if (!ISOK(_absMatchDic, NSMutableDictionary.class)) _absMatchDic = [[NSMutableDictionary alloc] initWithDictionary:_absMatchDic];
    return _absMatchDic;
}

-(NSMutableDictionary *)conMatchDic{
    if (!ISOK(_conMatchDic, NSMutableDictionary.class)) _conMatchDic = [[NSMutableDictionary alloc] initWithDictionary:_conMatchDic];
    return _conMatchDic;
}

/**
 *  MARK:--------------------更新抽具象相似度--------------------
 *  @callers : 由具象节点调用;
 *  @param absNode : 传抽象节点进来,而self为具象节点 (目前支持alg和fo两种类型);
 *  @version
 *      2022.10.24: 将algNode的抽具象关系也存上相似度 (参考27153-todo2);
 */
-(void) updateMatchValue:(AINodeBase*)absNode matchValue:(CGFloat)matchValue{
    //1. 更新抽象相似度;
    [self.absMatchDic setObject:@(matchValue) forKey:@(absNode.pId)];
    
    //2. 更新具象相似度;
    [absNode.conMatchDic setObject:@(matchValue) forKey:@(self.pointer.pointerId)];
    
    //3. 保存节点;
    [SMGUtils insertNode:self];
    [SMGUtils insertNode:absNode];
}

/**
 *  MARK:--------------------取抽或具象的相近度--------------------
 *  @version
 *      2022.12.04: 当二者相等时,默认返回1 (因为时序识别时mIsC1有自身判断,所以取相似度时要兼容支持下);
 */
-(CGFloat) getConMatchValue:(AIKVPointer*)con_p {
    if (PitIsMv(self.pointer) && PitIsMv(con_p)) return [self getMatchValue4Mv:con_p];
    if ([self.pointer isEqual:con_p]) return 1;
    [AITest test26:self.conMatchDic checkA:con_p];
    return NUMTOOK([self.conMatchDic objectForKey:@(con_p.pointerId)]).floatValue;
}
-(CGFloat) getAbsMatchValue:(AIKVPointer*)abs_p {
    if (PitIsMv(self.pointer) && PitIsMv(abs_p)) return [self getMatchValue4Mv:abs_p];
    if ([self.pointer isEqual:abs_p]) return 1;
    [AITest test26:self.absMatchDic checkA:abs_p];
    return NUMTOOK([self.absMatchDic objectForKey:@(abs_p.pointerId)]).floatValue;
}

/**
 *  MARK:--------------------mv匹配度 (参考28171-todo9)--------------------
 *  @desc mv的匹配度就是匹配度的相近度;
 */
-(CGFloat) getMatchValue4Mv:(AIKVPointer*)otherMv_p {
    if ([self.pointer.algsType isEqualToString:otherMv_p.algsType]) {
        AICMVNodeBase *selfMv = (AICMVNodeBase*)self;
        AICMVNodeBase *otherMv = [SMGUtils searchNode:otherMv_p];
        return [AIAnalyst compareCansetValue:selfMv.urgentTo_p protoValue:otherMv.urgentTo_p vInfo:nil];
    }
    return 0;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

-(BOOL)isEqual:(AINodeBase*)object{
    return [self.pointer isEqual:object.pointer];
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.pointer = [aDecoder decodeObjectForKey:@"pointer"];
        self.conPorts = [aDecoder decodeObjectForKey:@"conPorts"];
        self.absPorts = [aDecoder decodeObjectForKey:@"absPorts"];
        self.contentPorts = [aDecoder decodeObjectForKey:@"contentPorts"];
        self.conMatchDic = [aDecoder decodeObjectForKey:@"conMatchDic"];
        self.absMatchDic = [aDecoder decodeObjectForKey:@"absMatchDic"];
    }
    return self;
}

/**
 *  MARK:--------------------序列化--------------------
 *  @bug
 *      2020.07.10: 最近老闪退,前段时间XGWedis异步存由10s改为2s,有UMeng看是这里闪的,打try也能捕获这里抛了异常,将ports加了copy试下,应该好了;
 *      2020.12.27: 老闪退,将ports加了copy应该就好了 (原来就有过类似问题,这次全局conPorts,absPorts和refPorts都加了copy);
 */
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.pointer forKey:@"pointer"];
    [aCoder encodeObject:[self.conPorts copy] forKey:@"conPorts"];
    [aCoder encodeObject:[self.absPorts copy] forKey:@"absPorts"];
    [aCoder encodeObject:[self.contentPorts copy] forKey:@"contentPorts"];
    [aCoder encodeObject:[self.conMatchDic copy] forKey:@"conMatchDic"];
    [aCoder encodeObject:[self.absMatchDic copy] forKey:@"absMatchDic"];
}

@end
