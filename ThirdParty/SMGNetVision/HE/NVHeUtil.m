//
//  NVHeUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2019/7/2.
//  Copyright © 2019年 XiaoGang. All rights reserved.
//

#import "NVHeUtil.h"
#import "AINetIndex.h"
#import "AIKVPointer.h"
#import "AIAlgNodeBase.h"
#import "NSString+Extension.h"
#import "ThinkingUtils.h"
#import "AIScore.h"
#import "TVUtil.h"
#import "ImvAlgsHungerModel.h"
#import "ImvAlgsHurtModel.h"

@implementation NVHeUtil

+(BOOL) isHeight:(CGFloat)height fromContent_ps:(NSArray*)fromContent_ps {
    for (AIKVPointer *p in ARRTOOK(fromContent_ps)) {
        if ([p.dataSource isEqualToString:@"sizeHeight"]) {
            if ([NUMTOOK([AINetIndex getData:p]) floatValue] == 5) {
                return true;
            }
        }
    }
    return false;
}

+(NSString*) getLightStr4Ps:(NSArray*)node_ps{
    return [self getLightStr4Ps:node_ps simple:true header:true sep:@","];
}
+(NSString*) getLightStr4Ps:(NSArray*)node_ps simple:(BOOL)simple header:(BOOL)header sep:(NSString*)sep{
    //1. 数据检查
    NSMutableString *result = [[NSMutableString alloc] init];
    node_ps = ARRTOOK(node_ps);
    sep = STRTOOK(sep);
    
    //2. 拼接返回
    NSString *lastStr = @"";
    for (AIKVPointer *item_p in node_ps){
        NSString *str = [NVHeUtil getLightStr:item_p simple:simple header:header from:node_ps];
        if (STRISOK(str)) {
            if ([str isEqualToString:lastStr]) {
                [result appendFormat:@"-%@",sep];
            } else if ([result containsString:str]) {
                [result appendFormat:@"%@%ld%@",[self isMv:item_p]?@"M":@"A",item_p.pointerId,sep];
            } else {
                [result appendFormat:@"%@%@",str,sep];
            }
        }
        lastStr = str;
    }
    return SUBSTRToIndex(result, result.length - sep.length);
}

+(NSString*) getLightStr:(AIKVPointer*)node_p {
    return [self getLightStr:node_p simple:true header:false];
}
+(NSString*) getLightStr:(AIKVPointer*)node_p simple:(BOOL)simple header:(BOOL)header {
    return [self getLightStr:node_p simple:simple header:header from:nil];
}
+(NSString*) getLightStr:(AIKVPointer*)node_p simple:(BOOL)simple header:(BOOL)header from:(NSArray*)from{
    NSString *lightStr = @"";
    if (ISOK(node_p, AIKVPointer.class)) {
        if ([self isValue:node_p]) {
            lightStr = [self getLightStr_ValueP:node_p from:from];
        }else if (PitIsGroupValue(node_p)) {
            lightStr = @"";
        }else if (PitIsFeature(node_p)) {
            AIFeatureNode *tNode = [SMGUtils searchNode:node_p];
            lightStr = STRFORMAT(@"T%ld%@",tNode.pId,CLEANSTR([tNode getLogDesc:true]));
        }else if ([self isAlg:node_p]) {
            AIAlgNodeBase *algNode = [SMGUtils searchNode:node_p];
            if (algNode) {
                if (simple) {
                    NSString *firstValueStr = [self getLightStr_ValueP:ARR_INDEX(algNode.content_ps, 0) from:algNode.content_ps];
                    lightStr = STRFORMAT(@"%@%@",firstValueStr,(algNode.content_ps.count > 1) ? @"..." : @"");
                }else{
                    lightStr = [self getLightStr4Ps:algNode.content_ps simple:simple header:header sep:@","];
                }
                
                //简化日志1: 概念加后辍
                int height = NUMTOOK([AINetIndex getData:[SMGUtils filterSingleFromArr:algNode.content_ps checkValid:^BOOL(AIKVPointer *item) {
                    return [@"sizeHeight" isEqualToString:item.dataSource];
                }]]).intValue;
                int border = NUMTOOK([AINetIndex getData:[SMGUtils filterSingleFromArr:algNode.content_ps checkValid:^BOOL(AIKVPointer *item) {
                    return [@"border" isEqualToString:item.dataSource];
                }]]).intValue;
                if (height == 100) {
                    lightStr = STRFORMAT(@"%@,棒",lightStr);
                } else if (height == 30) {
                    lightStr = STRFORMAT(@"%@,鸟",lightStr);
                } else if (height == 5) {
                    //返回有向无距,或有距无向,无向无距,方便查看相关日志;
                    AIKVPointer *xianV = [self getXian:node_p];
                    AIKVPointer *jvV = [self getJv:node_p];
                    int xian = NUMTOOK([AINetIndex getData:xianV]).intValue;
                    int jv = NUMTOOK([AINetIndex getData:jvV]).intValue;
                    NSString *borderDesc = border > 0 ? @"皮果" : @"果";
                    if (xianV && !jvV) lightStr = STRFORMAT(@"有向无距%@%d",borderDesc,xian);
                    else if (!xianV && jvV) lightStr = STRFORMAT(@"有距无向%@%d",borderDesc,jv);
                    else if (!xianV && !jvV) lightStr = STRFORMAT(@"无向无距%@",borderDesc);
                    else if (xianV && jvV) lightStr = STRFORMAT(@"%@,%@",lightStr,borderDesc);
                }
                
                //简化日志2: 飞不加header
                if ([SMGUtils filterSingleFromArr:algNode.content_ps checkValid:^BOOL(AIKVPointer *item) {
                    return [FLY_RDS isEqualToString:item.algsType] || [KICK_RDS isEqualToString:item.algsType];
                }]) {
                    header = false;
                }
            }
        }else if([self isFo:node_p]){
            AIFoNodeBase *foNode = [SMGUtils searchNode:node_p];
            if (foNode) {
                lightStr = [self getLightStr4Ps:foNode.content_ps simple:simple header:header sep:@","];
            }
        }else if([self isMv:node_p]){
            CGFloat score = [AIScore score4MV:node_p ratio:1.0f];
            lightStr = STRFORMAT(@"%@%@%@",Mvp2DeltaStr(node_p),Class2Str(NSClassFromString(node_p.algsType)),Double2Str_NDZ(score));
        }
    }
    //2. 返回;
    if (header) lightStr = [self decoratorHeader:lightStr node_p:node_p];
    return lightStr;
}

//获取value_p的light描述;
+(NSString*) getLightStr_ValueP:(AIKVPointer*)value_p from:(NSArray*)from{
    if (!value_p) return @"";
    double value = [NUMTOOK([AINetIndex getData:value_p]) doubleValue];
    NSString *valueStr = [self getLightStr_Value:value algsType:value_p.algsType dataSource:value_p.dataSource];
    if ([@"sizeWidth" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"宽%@",valueStr);
    }else if ([@"sizeHeight" isEqualToString:value_p.dataSource]) {
        return @"";//STRFORMAT(@"高%@",valueStr);
    }else if ([@"colorRed" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"红%@",valueStr);
    }else if ([@"colorBlue" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"蓝%@",valueStr);
    }else if ([@"colorGreen" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"绿%@",valueStr);
    }else if ([@"radius" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"形%@",valueStr);
    }else if ([@"direction" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"向%@",valueStr);
    }else if ([@"distance" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"距%@",valueStr);
    }else if ([@"distanceX" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"X距%@",valueStr);
    }else if ([@"distanceY" isEqualToString:value_p.dataSource]) {
        if (ARRISOK(from) && NUMTOOK(ARR_INDEX([SMGUtils convertArr:from convertBlock:^id(AIKVPointer *item) {
            if ([@"sizeHeight" isEqualToString:item.dataSource]) return NUMTOOK([AINetIndex getData:item]);
            return nil;
        }], 0)).doubleValue == 100) return STRFORMAT(@"Y距_%@_%@",[TVUtil distanceYDesc:value],valueStr);
        return STRFORMAT(@"Y距%@",valueStr);
    }else if ([@"speed" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"速%@",valueStr);
    }else if ([@"border" isEqualToString:value_p.dataSource]) {
        return @"";//STRFORMAT(@"皮%@",valueStr);
    }else if ([@"posX" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"X%@",valueStr);
    }else if ([@"posY" isEqualToString:value_p.dataSource]) {
        return STRFORMAT(@"Y%@",valueStr);
    }else if([EAT_RDS isEqualToString:value_p.algsType]){
        return STRFORMAT(@"吃%@",valueStr);
    }else if([FLY_RDS isEqualToString:value_p.algsType]){
        return STRFORMAT(@"飞%@",valueStr);
    }else if([KICK_RDS isEqualToString:value_p.algsType]){
        return STRFORMAT(@"踢%@",valueStr);
    }else if([NSStringFromClass(ImvAlgsHungerModel.class) isEqualToString:value_p.algsType] && [@"urgentTo" isEqualToString:value_p.dataSource]){
        return STRFORMAT(@"饿%@",valueStr);
    }else if([NSStringFromClass(ImvAlgsHurtModel.class) isEqualToString:value_p.algsType] && [@"urgentTo" isEqualToString:value_p.dataSource]){
        return STRFORMAT(@"疼%@",valueStr);
    }
    return valueStr;
}

//获取value的light描述;
+(NSString*) getLightStr_Value:(double)value algsType:(NSString*)algsType dataSource:(NSString*)dataSource{
    if(value == ATHav || value == ATNone || value == ATGreater ||
       value == ATLess || value == ATPlus || value == ATSub){
        return [NSLog_Extension convertATType2Desc:value];
    }else if([FLY_RDS isEqualToString:algsType]){
        return [NVHeUtil fly2Str:value];
    }else if([KICK_RDS isEqualToString:algsType]){
        return [NVHeUtil fly2Str:value];
    }else if([@"direction" isEqualToString:dataSource]){
        return [NVHeUtil direction2Str:value];
    }
    return Double2Str_NDZ(value);
}


//MARK:===============================================================
//MARK:                     < 节点类型判断 >
//MARK:===============================================================
+(BOOL) isValue:(AIKVPointer*)node_p{
    return [kPN_VALUE isEqualToString:node_p.folderName] || [kPN_DATA isEqualToString:node_p.folderName] || [kPN_INDEX isEqualToString:node_p.folderName];
}

+(BOOL) isGroupValue:(AIKVPointer*)node_p{
    return [kPN_GROUPVALUE_NODE isEqualToString:node_p.folderName];
}

+(BOOL) isFeature:(AIKVPointer*)node_p{
    return [kPN_FEATURE_NODE isEqualToString:node_p.folderName];
}

+(BOOL) isGroupFeature:(AIKVPointer*)node_p{
    return [kPN_GROUPFEATURE_NODE isEqualToString:node_p.folderName];
}

+(BOOL) isAlg:(AIKVPointer*)node_p{
    return [kPN_ALG_NODE isEqualToString:node_p.folderName] || [kPN_ALG_ABS_NODE isEqualToString:node_p.folderName];
}

+(BOOL) isFo:(AIKVPointer*)node_p{
    return [kPN_FRONT_ORDER_NODE isEqualToString:node_p.folderName] || [kPN_FO_ABS_NODE isEqualToString:node_p.folderName];
}

+(BOOL) isMv:(AIKVPointer*)node_p{
    return [kPN_CMV_NODE isEqualToString:node_p.folderName] || [kPN_ABS_CMV_NODE isEqualToString:node_p.folderName];
}

+(BOOL) isAbs:(AIKVPointer*)node_p{
    return [kPN_FO_ABS_NODE isEqualToString:node_p.folderName] || [kPN_ABS_CMV_NODE isEqualToString:node_p.folderName] || [kPN_ALG_ABS_NODE isEqualToString:node_p.folderName];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
+(NSString*) decoratorHeader:(NSString*)lightStr node_p:(AIKVPointer*)node_p{
    NSString *pIdStr = node_p ? STRFORMAT(@"%ld",node_p.pointerId) : @"";
    if ([self isAlg:node_p]) {
        return STRFORMAT(@"A%@(%@)",pIdStr,lightStr);
    }else if([self isFo:node_p]){
        return STRFORMAT(@"F%@[%@]",pIdStr,lightStr);
    }else if([self isMv:node_p]){
        return STRFORMAT(@"M%@{%@}",pIdStr,lightStr);
    }
    return lightStr;
}

/**
 *  MARK:--------------------方向--------------------
 *  @version
 *      2023.03.13: 飞方向有8向,但视觉方向改为360向了 (因为早已支持相近匹配了);
 */
+(NSString*) direction2Str:(CGFloat)value{
    return STRFORMAT(@"%.0f",value);
}

+(NSString*) fly2Str:(CGFloat)value{
    int caseValue = value * 8;
    switch (caseValue) {
        case 0: return @"←";
        case 1: return @"↖";
        case 2: return @"↑";
        case 3: return @"↗";
        case 4: return @"→";
        case 5: return @"↘";
        case 6: return @"↓";
        case 7: return @"↙";
    }
    return @"";
}

/**
 *  MARK:--------------------checkIs--------------------
 */
//fo包含有皮果
+(BOOL) foHavYouPiGuo:(AIKVPointer*)fo_p {
    AIFoNodeBase *fo = [SMGUtils searchNode:fo_p];
    return [SMGUtils filterSingleFromArr:fo.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return [self algIsYouPiGuo:item];
    }];
}

//fo包含无皮果
+(BOOL) foHavWuPiGuo:(AIKVPointer*)fo_p {
    AIFoNodeBase *fo = [SMGUtils searchNode:fo_p];
    return [SMGUtils filterSingleFromArr:fo.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return [self algIsWuPiGuo:item];
    }];
}

//alg是有皮果
+(BOOL) algIsYouPiGuo:(AIKVPointer*)alg_p {
    BOOL heightIsOk = [self findValueFromAlg:alg_p byDS:@"sizeHeight"] == 5;
    BOOL borderIsOk = [self findValueFromAlg:alg_p byDS:@"border"] > 0;
    return heightIsOk && borderIsOk;
}

//alg是无皮果
+(BOOL) algIsWuPiGuo:(AIKVPointer*)alg_p {
    BOOL heightIsOk = [self findValueFromAlg:alg_p byDS:@"sizeHeight"] == 5;
    BOOL borderIsOk = [self findValueFromAlg:alg_p byDS:@"border"] == 0;
    return heightIsOk && borderIsOk;
}

//取向码
+(AIKVPointer*) getXian:(AIKVPointer*)alg_p {
    return [self checkValueFromAlg:alg_p valueDSIs:@"direction"];
}
//取距码
+(AIKVPointer*) getJv:(AIKVPointer*)alg_p {
    return [self checkValueFromAlg:alg_p valueDSIs:@"distance"];
}

//alg是踢行为
+(BOOL) algIsKick:(AIKVPointer*)alg_p {
    return [self checkValueFromAlg:alg_p valueATIs:KICK_RDS];
}

//alg是飞行为
+(BOOL) algIsFly:(AIKVPointer*)alg_p {
    return [self checkValueFromAlg:alg_p valueATIs:FLY_RDS];
}

//alg是饥饿
+(BOOL) algIsJiE:(AIKVPointer*)alg_p {
    if ([Pit2FStr(alg_p) containsString:@"饿"]) {
        if (!PitIsMv(alg_p) || alg_p.pointerId != 1) {
            NSLog(@"查下当alg类型时,怎么判定它是饥饿节点");
        }
    }
    
    if ([NSStringFromClass(ImvAlgsHungerModel.class) isEqualToString:alg_p.algsType]) {
        return true;
    }
    return false;
}

/**
 *  MARK:--------------------有向无距--------------------
 */
+(BOOL) foHavXianWuJv:(AIKVPointer*)fo_p {
    AIFoNodeBase *fo = [SMGUtils searchNode:fo_p];
    return [SMGUtils filterSingleFromArr:fo.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return [self algHavXianWuJv:item];
    }];
}
+(BOOL) algHavXianWuJv:(AIKVPointer*)alg_p {
    return [self getXian:alg_p] && ![self getJv:alg_p];
}

//判断alg中某区码的稀疏码的at类型是valueATIs (比如: 取概念有踢特征);
+(AIKVPointer*) checkValueFromAlg:(AIKVPointer*)fromAlg_p valueATIs:(NSString*)valueATIs {
    AIAlgNodeBase *fromAlg = [SMGUtils searchNode:fromAlg_p];
    AIKVPointer *findValue_p = [SMGUtils filterSingleFromArr:fromAlg.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return [valueATIs isEqualToString:item.algsType];
    }];
    return findValue_p;
}
+(AIKVPointer*) checkValueFromAlg:(AIKVPointer*)fromAlg_p valueDSIs:(NSString*)valueDSIs {
    AIAlgNodeBase *fromAlg = [SMGUtils searchNode:fromAlg_p];
    AIKVPointer *findValue_p = [SMGUtils filterSingleFromArr:fromAlg.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return [valueDSIs isEqualToString:item.dataSource];
    }];
    return findValue_p;
}

//取alg中某区码的稀疏码的值 (比如: 取概念的高的值是5);
+(double) findValueFromAlg:(AIKVPointer*)fromAlg_p byDS:(NSString*)byDS {
    AIAlgNodeBase *fromAlg = [SMGUtils searchNode:fromAlg_p];
    AIKVPointer *findValue_p = [SMGUtils filterSingleFromArr:fromAlg.content_ps checkValid:^BOOL(AIKVPointer *item) {
        return [byDS isEqualToString:item.dataSource];
    }];
    if (!findValue_p) return 0;
    return [NUMTOOK([AINetIndex getData:findValue_p]) doubleValue];
}

@end
