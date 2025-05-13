//
//  NVHeUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2019/7/2.
//  Copyright © 2019年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NVHeUtil : NSObject

/**
 *  MARK:--------------------判断是否节点尺寸为height--------------------
 */
+(BOOL) isHeight:(CGFloat)height fromContent_ps:(NSArray*)fromContent_ps;


/**
 *  MARK:--------------------获取value微信息的light描述--------------------
 */
+(NSString*) getLightStr4Ps:(NSArray*)node_ps;
+(NSString*) getLightStr4Ps:(NSArray*)node_ps simple:(BOOL)simple header:(BOOL)header sep:(NSString*)sep;
+(NSString*) getLightStr:(AIKVPointer*)node_p;
+(NSString*) getLightStr:(AIKVPointer*)node_p simple:(BOOL)simple header:(BOOL)header;
+(NSString*) getLightStr_Value:(double)value algsType:(NSString*)algsType dataSource:(NSString*)dataSource;


//MARK:===============================================================
//MARK:                     < 节点类型判断 >
//MARK:===============================================================
+(BOOL) isValue:(AIKVPointer*)node_p;
+(BOOL) isGroupValue:(AIKVPointer*)node_p;
+(BOOL) isFeature:(AIKVPointer*)node_p;
+(BOOL) isGroupFeature:(AIKVPointer*)node_p;
+(BOOL) isAlg:(AIKVPointer*)node_p;
+(BOOL) isFo:(AIKVPointer*)node_p;
+(BOOL) isMv:(AIKVPointer*)node_p;
+(BOOL) isAbs:(AIKVPointer*)node_p;

/**
 *  MARK:--------------------稀疏码转str--------------------
 */
+(NSString*) direction2Str:(CGFloat)value;
+(NSString*) fly2Str:(CGFloat)value;

/**
 *  MARK:--------------------checkIs--------------------
 */
//fo包含有皮果
+(BOOL) foHavYouPiGuo:(AIKVPointer*)fo_p;

//fo包含无皮果
+(BOOL) foHavWuPiGuo:(AIKVPointer*)fo_p;

//alg是有皮果
+(BOOL) algIsYouPiGuo:(AIKVPointer*)alg_p;

//alg是无皮果
+(BOOL) algIsWuPiGuo:(AIKVPointer*)alg_p;

//取向码
+(AIKVPointer*) getXian:(AIKVPointer*)alg_p;

//取距码
+(AIKVPointer*) getJv:(AIKVPointer*)alg_p;

//alg是踢行为
+(BOOL) algIsKick:(AIKVPointer*)alg_p;

//alg是飞行为
+(BOOL) algIsFly:(AIKVPointer*)alg_p;

//alg是饥饿
+(BOOL) algIsJiE:(AIKVPointer*)alg_p;

/**
 *  MARK:--------------------有向无距--------------------
 */
+(BOOL) foHavXianWuJv:(AIKVPointer*)fo_p;
+(BOOL) algHavXianWuJv:(AIKVPointer*)alg_p;

//取alg中某区码的稀疏码的值 (比如: 取概念的高的值是5);
+(double) findValueFromAlg:(AIKVPointer*)fromAlg_p byDS:(NSString*)byDS;
@end
