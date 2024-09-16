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
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.target_p forKey:@"target_p"];
    [coder encodeObject:self.strong forKey:@"strong"];
    [coder encodeObject:self.header forKey:@"header"];
    [coder encodeBool:self.targetHavMv forKey:@"targetHavMv"];
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

-(void) strongPlus{
    self.strong.value ++;
}

-(BOOL) isEqual:(AIPort*)object{
    if (ISOK(object, AIPort.class)) {
        if (self.target_p) {
            return [self.target_p isEqual:object.target_p];
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

-(NSString *)description{
    return STRFORMAT(@"S%ldP%ld",(long)self.sStrong,(long)self.pStrong);
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.sStrong = [coder decodeIntegerForKey:@"sStrong"];
        self.pStrong = [coder decodeIntegerForKey:@"pStrong"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.sStrong forKey:@"sStrong"];
    [coder encodeInteger:self.pStrong forKey:@"pStrong"];
}

@end


//MARK:===============================================================
//MARK:                     < 有效强度模型 >
//MARK:===============================================================
@implementation AIEffectStrong

+(AIEffectStrong*) newWithSolutionFo:(AIKVPointer*)solutionFo{
    AIEffectStrong *result = [[AIEffectStrong alloc] init];
    result.solutionFo = solutionFo;
    return result;
}

-(NSString *)description{
    return STRFORMAT(@"H%ldN%ld",(long)self.hStrong,(long)self.nStrong);
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.solutionFo = [coder decodeObjectForKey:@"solutionFo"];
        self.hStrong = [coder decodeIntegerForKey:@"hStrong"];
        self.nStrong = [coder decodeIntegerForKey:@"nStrong"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.solutionFo forKey:@"solutionFo"];
    [coder encodeInteger:self.hStrong forKey:@"hStrong"];
    [coder encodeInteger:self.nStrong forKey:@"nStrong"];
}

@end
