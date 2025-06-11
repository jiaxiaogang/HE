//
//  AIPointer.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/5/20.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AIPointer.h"

@implementation AIPointer

/**
 *  MARK:--------------------public--------------------
 */
-(BOOL) isEqual:(AIPointer*)object{//重写指针对比地址方法;
    return [AINetUtils equal4PitA:self pitB:object];
}

-(NSMutableDictionary *)params{
    if (_params == nil) {
        _params = [[NSMutableDictionary alloc] init];
    }
    return _params;
}

-(NSString*) filePath{
    return STRFORMAT(@"%@_%ld",self.params,(long)self.pointerId);
}

-(NSString*) identifier{
    return STRFORMAT(@"%@",self.params);
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.pointerId = [aDecoder decodeIntegerForKey:@"pointerId"];
        self.params = [aDecoder decodeObjectForKey:@"params"];
        self.isJiao = [aDecoder decodeBoolForKey:@"isJiao"];
        self.isGT = [aDecoder decodeBoolForKey:@"isGT"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.pointerId forKey:@"pointerId"];
    [aCoder encodeObject:self.params forKey:@"params"];
    [aCoder encodeBool:self.isJiao forKey:@"isJiao"];
    [aCoder encodeBool:self.isGT forKey:@"isGT"];
}

-(id) paramForKey:(NSString*)key{
    return [self.params objectForKey:STRTOOK(key)];
}

/**
 *  MARK:--------------------NSCopying--------------------
 */
- (id)copyWithZone:(NSZone __unused *)zone {
    AIPointer *copy = [[AIPointer alloc] init];
    copy.pointerId = self.pointerId;
    copy.params = self.params;
    copy.isJiao = self.isJiao;
    copy.isGT = self.isGT;
    return copy;
}

@end
