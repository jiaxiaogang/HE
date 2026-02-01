//
//  AIPort.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/9/7.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AIPort.h"
#import "AIKVPointer.h"

@implementation AIPort

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.target_p = [coder decodeObjectForKey:@"target_p"];
        self.strong = [coder decodeObjectForKey:@"strong"];
        self.header = [coder decodeObjectForKey:@"header"];
        self.targetHavMv = [coder decodeBoolForKey:@"targetHavMv"];
        self.params = [coder decodeObjectForKey:@"params"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.target_p forKey:@"target_p"];
    [coder encodeObject:self.strong forKey:@"strong"];
    [coder encodeObject:self.header forKey:@"header"];
    [coder encodeBool:self.targetHavMv forKey:@"targetHavMv"];
    [coder encodeObject:self.params forKey:@"params"];
}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(AIPortStrong *)strong{
    if (_strong == nil) {
        _strong = [[AIPortStrong alloc] init];
    }
    return _strong;
}

-(NSMutableDictionary *)params {
    if (!ISOK(_params, NSMutableDictionary.class)) _params = [[NSMutableDictionary alloc] initWithDictionary:_params];
    return _params;
}

-(void) strongPlus{
    self.strong.value ++;
}

-(CGRect) rect {
    NSValue *rectValue = [self.params objectForKey:@"r"];
    return rectValue ? rectValue.CGRectValue : CGRectNull;
}

-(BOOL) isEqual:(AIPort*)object{
    if (ISOK(object, AIPort.class)) {
        if (self.target_p) {
            return [self.target_p isEqual:object.target_p] && [self.params isEqual:object.params];
        }
    }
    return false;
}

@end


//MARK:===============================================================
//MARK:                     < AIPortStrong >
//MARK:===============================================================
@implementation AIPortStrong


//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(void) updateValue {
    long long nowTime = [[NSDate date] timeIntervalSince1970];
    if (nowTime > self.updateTime) {
        self.value -= MAX(0, (nowTime - self.updateTime) / 86400);//(目前先每天减1;)
    }
    self.updateTime = nowTime;
}


/**
 *  MARK:--------------------NSCoding--------------------
 */
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.value = [coder decodeIntegerForKey:@"value"];
        self.updateTime = [coder decodeDoubleForKey:@"updateTime"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.value forKey:@"value"];
    [coder encodeDouble:self.updateTime forKey:@"updateTime"];
}

@end


//MARK:===============================================================
//MARK:                     < SP强度模型 >
//MARK:===============================================================
@implementation AISPStrong


+(id) newWithS:(CGFloat)sStrong P:(CGFloat)pStrong {
    AISPStrong *result = [[AISPStrong alloc] init];
    result.sStrong = sStrong;
    result.pStrong = pStrong;
    return result;
}

-(NSString *)description{
    return STRFORMAT(@"S%.0fP%.0f",self.sStrong,self.pStrong);
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.sStrong = [coder decodeFloatForKey:@"sStrong"];
        self.pStrong = [coder decodeFloatForKey:@"pStrong"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeFloat:self.sStrong forKey:@"sStrong"];
    [coder encodeFloat:self.pStrong forKey:@"pStrong"];
}

/**
 *  MARK:--------------------NSCopying--------------------
 */
- (id)copyWithZone:(NSZone __unused *)zone {
    AISPStrong *copy = [[self.class allocWithZone:zone] init];
    copy.sStrong = self.sStrong;
    copy.pStrong = self.pStrong;
    return copy;
}

@end

//MARK:===============================================================
//MARK: < 内存记录sp防重(主要用于TOFoModel.outSPRecord和pFo.inSPRecord) >
//MARK:===============================================================
@implementation SPMemRecord

-(NSMutableDictionary *)spRecord{
    if (!_spRecord) _spRecord = [[NSMutableDictionary alloc] init];
    return _spRecord;
}

/**
 *  MARK:--------------------防重检查和回滚--------------------
 *  @param spIndex type difStrong : 本次要执行更新sp的几个参数值;
 *  @param backBlock : 发现重复,调用回滚的block
 *  @param runBlock : 本次允许,调用执行的block
 */
-(void) update:(NSInteger)spIndex type:(AnalogyType)type difStrong:(NSInteger)difStrong backBlock:(void(^)(NSInteger mDifStrong,AnalogyType mType))backBlock runBlock:(void(^)())runBlock {
    //1. 取得canstFrom的spStrong;
    AISPStrong *value = [self.spRecord objectForKey:@(spIndex)];
    if (!value) value = [[AISPStrong alloc] init];
    [self.spRecord setObject:value forKey:@(spIndex)];
    
    //2. 避免重复 (执行过的,不再执行);
    if (type == ATPlus && value.pStrong > 0) return;
    if (type == ATSub && value.sStrong > 0) return;
    
    //3. 避免冲突 (对立面执行过,回滚);
    if (type == ATPlus && value.sStrong > 0) {
        backBlock(-value.sStrong,ATSub);
        value.sStrong = 0;
    }
    if (type == ATSub && value.pStrong > 0) {
        backBlock(-value.pStrong,ATPlus);
        value.pStrong = 0;
    }
    
    //4. 把此次SP更新下;
    //2024.11.18: outSP+1时,F层也+1 (F层从transferPort迁移关联来取) (参考33112-TODO3);
    runBlock();
    
    //5. 把此次SP更新值记录到outSPRecord避免下次重复或冲突;
    if (type == ATSub) {
        value.sStrong = difStrong;
    } else {
        value.pStrong = difStrong;
    }
}

@end
