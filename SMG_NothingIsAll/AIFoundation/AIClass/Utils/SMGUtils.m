//
//  SMGUtils.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/19.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "SMGUtils.h"
#import "PINCache.h"
#import "XGRedisUtil.h"
#import "XGRedis.h"

@implementation SMGUtils

//MARK:===============================================================
//MARK:                     < PointerId >
//MARK:===============================================================
+(NSInteger) createPointerId:(NSString*)algsType dataSource:(NSString*)dataSource{
    return [self createPointerId:true algsType:algsType dataSource:dataSource];
}

+(NSInteger) createPointerId:(BOOL)updateLastId algsType:(NSString*)algsType dataSource:(NSString*)dataSource{
    NSInteger lastId = [SMGUtils getLastNetNodePointerId:algsType dataSource:dataSource];
    if (updateLastId) {
        [SMGUtils setNetNodePointerId:1 algsType:algsType dataSource:dataSource];
    }
    return lastId + 1;
}

+(NSInteger) getLastNetNodePointerId:(NSString*)algsType dataSource:(NSString*)dataSource{
    return [[NSUserDefaults standardUserDefaults] integerForKey:STRFORMAT(@"AIPointer_LastNetNodePointerId_KEY_%@_%@",algsType,dataSource)];
}

+(void) setNetNodePointerId:(NSInteger)count algsType:(NSString*)algsType dataSource:(NSString*)dataSource{
    NSInteger lastPId = [self getLastNetNodePointerId:algsType dataSource:dataSource];
    [[NSUserDefaults standardUserDefaults] setInteger:lastPId + count forKey:STRFORMAT(@"AIPointer_LastNetNodePointerId_KEY_%@_%@",algsType,dataSource)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//MARK:===============================================================
//MARK:                     < AIPointer >
//MARK:===============================================================

//General指针
+(AIKVPointer*) createPointer:(NSString*)folderName algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut type:(AnalogyType)type{
    NSInteger pointerId = [SMGUtils createPointerId:algsType dataSource:dataSource];
    
    //TODOTOMORROW: 查20151-BUG9 (此处新指针有重复,导致问题);
    if ([kPN_CMV_NODE isEqualToString:folderName] || [kPN_ABS_CMV_NODE isEqualToString:folderName]) {
        WLog(@"---------引用强度BUG-mv新指针:%ld",pointerId);
    }
    AIKVPointer *kvPointer = [AIKVPointer newWithPointerId:pointerId folderName:folderName algsType:algsType dataSource:dataSource isOut:isOut type:type];
    return kvPointer;
}

//Direction的mv分区pointer;(存引用序列)
+(AIKVPointer*) createPointerForDirection:(NSString*)mvAlgsType direction:(MVDirection)direction{
    NSInteger pointerId = 0;
    AIKVPointer *kvPointer = [AIKVPointer newWithPointerId:pointerId folderName:kPN_DIRECTION((long)direction) algsType:mvAlgsType dataSource:DefaultDataSource isOut:false type:ATDefault];
    return kvPointer;
}

//生成小脑CanOut指针;
+(AIKVPointer*) createPointerForCerebelCanOut{
    AIKVPointer *pointer = [AIKVPointer newWithPointerId:0 folderName:kPN_CEREBEL_CANOUT algsType:DefaultAlgsType dataSource:DefaultDataSource isOut:false type:ATDefault];
    return pointer;
}

//生成indexValue的指针;
+(AIKVPointer*) createPointerForValue:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut{
    NSInteger pointerId = [self createPointerId:algsType dataSource:dataSource];
    return [AIKVPointer newWithPointerId:pointerId folderName:kPN_VALUE algsType:algsType dataSource:dataSource isOut:isOut type:ATDefault];
}

+(AIKVPointer*) createPointerForValue:(NSInteger)pointerId algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut{
    return [AIKVPointer newWithPointerId:pointerId folderName:kPN_VALUE algsType:algsType dataSource:dataSource isOut:isOut type:ATDefault];
}

+(AIKVPointer*) createPointerForIndex{
    NSInteger pointerId = 0;
    return [AIKVPointer newWithPointerId:pointerId folderName:kPN_INDEX algsType:DefaultAlgsType dataSource:DefaultDataSource isOut:false type:ATDefault];
}

+(AIKVPointer*) createPointerForGVIndex:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut {
    return [AIKVPointer newWithPointerId:0 folderName:kPN_GV_INDEX algsType:at dataSource:ds isOut:isOut type:ATDefault];
}

+(AIKVPointer*) createPointerForData:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut{
    NSInteger pointerId = 0;
    return [AIKVPointer newWithPointerId:pointerId folderName:kPN_DATA algsType:algsType dataSource:dataSource isOut:isOut type:ATDefault];
}

+(AIKVPointer*) createPointerForGroupValue:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut {
    NSInteger pointerId = [SMGUtils createPointerId:DefaultAlgsType dataSource:dataSource];
    return [self createPointerForGroupValue:pointerId at:at dataSource:dataSource isOut:isOut];
}

+(AIKVPointer*) createPointerForGroupValue:(NSInteger)pId at:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut {
    return [AIKVPointer newWithPointerId:pId folderName:kPN_GROUPVALUE_NODE algsType:at dataSource:dataSource isOut:isOut type:ATDefault];
}

+(AIKVPointer*) createPointerForFeature:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut {
    NSInteger pointerId = [SMGUtils createPointerId:DefaultAlgsType dataSource:dataSource];
    return [AIKVPointer newWithPointerId:pointerId folderName:kPN_FEATURE_NODE algsType:at dataSource:dataSource isOut:isOut type:ATDefault];
}

+(AIKVPointer*) createPointerForGroupFeature:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut {
    NSInteger pointerId = [SMGUtils createPointerId:DefaultAlgsType dataSource:ds];
    return [AIKVPointer newWithPointerId:pointerId folderName:kPN_GROUPFEATURE_NODE algsType:at dataSource:ds isOut:isOut type:ATDefault];
}

/**
 *  MARK:--------------------生成alg指针--------------------
 *  @version
 *      2021.09.25: 将algsType由pointerId改为" ";
 *      2021.09.25: 将at由参数传入,因为有些稀疏码没有ds(如FLY_RDS),此时构建glAlg,就只能传来at (参考24021-概念部分-4);
 */
+(AIKVPointer*) createPointerForAlg:(NSString*)folderName at:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut type:(AnalogyType)type{
    NSInteger pointerId = [SMGUtils createPointerId:DefaultAlgsType dataSource:dataSource];
    return [AIKVPointer newWithPointerId:pointerId folderName:folderName algsType:at dataSource:dataSource isOut:isOut type:type];
}

/**
 *  MARK:--------------------生成fo指针--------------------
 *  @version
 *      2021.09.25: 将at由参数传入,因为有些稀疏码没有ds(如FLY_RDS),此时构建glFo,就只能传来at (参考24021-时序部分-3);
 */
+(AIKVPointer*) createPointerForFo:(NSString*)folderName at:(NSString*)at ds:(NSString*)ds type:(AnalogyType)type{
    return [self createPointer:folderName algsType:at dataSource:ds isOut:false type:type];
}

@end


/**
 *  MARK:--------------------比较--------------------
 */
@implementation SMGUtils (Compare)

//+(BOOL) compareItemA:(id)itemA itemB:(id)itemB{
//    if (itemA == nil && itemB == nil) {
//        return true;
//    }else if(itemA == nil || itemB == nil || ![self compareKindClassWithItemA:itemA itemB:itemB]){
//        return false;
//    }else{
//        if ([itemA isKindOfClass:[NSString class]]) {
//            return [(NSString*)itemA isEqualToString:itemB];        //NSString
//        }else if ([itemA isKindOfClass:[NSNumber class]]) {
//            return [itemA isEqualToNumber:itemB];                   //NSNumber
//        }else if ([itemA isKindOfClass:[NSValue class]]) {
//            return [itemA isEqualToValue:itemB];                    //NSValue
//        }else if ([itemA isKindOfClass:[NSArray class]]) {
//            return [itemA isEqualToArray:itemB];                    //NSArray
//        }else if ([itemA isKindOfClass:[NSDictionary class]]) {
//            return [itemA isEqualToDictionary:itemB];               //NSDictionary
//        }else if ([itemA isKindOfClass:[NSSet class]]) {
//            return [itemA isEqualToSet:itemB];                      //NSSet
//        }else if ([itemA isKindOfClass:[NSData class]]) {
//            return [itemA isEqualToData:itemB];                     //NSData
//        }else if ([itemA isKindOfClass:[NSDate class]]) {
//            return [itemA isEqualToDate:itemB];                     //NSDate
//        }else if ([itemA isKindOfClass:[NSAttributedString class]]) {
//            return [itemA isEqualToAttributedString:itemB];         //NSAttributedString
//        }else if ([itemA isKindOfClass:[NSIndexSet class]]) {
//            return [itemA isEqualToIndexSet:itemB];                 //NSIndexSet
//        }else if ([itemA isKindOfClass:[NSTimeZone class]]) {
//            return [itemA isEqualToTimeZone:itemB];                 //NSTimeZone
//        }else if ([itemA isKindOfClass:[NSHashTable class]]) {
//            return [itemA isEqualToHashTable:itemB];                //NSHashTable
//        }else if ([itemA isKindOfClass:[NSOrderedSet class]]) {
//            return [itemA isEqualToOrderedSet:itemB];               //NSOrderedSet
//        }else if ([itemA isKindOfClass:[NSDateInterval class]]) {
//            return [itemA isEqualToDateInterval:itemB];             //NSDateInterval
//        }else{
//            return [itemA isEqual:itemB];                           //不识别的类型
//        }
//    }
//}
//
//+(BOOL) compareArrayA:(NSArray*)arrA arrayB:(NSArray*)arrB{
//    if (arrA == nil && arrB == nil) {
//        return true;
//    }else if(!ARRISOK(arrA) || !ARRISOK(arrB)){
//        return false;
//    }else{
//        for (NSObject *itemA in arrA) {
//            BOOL find = false;
//            for (NSObject *itemB in arrB) {
//                if ([itemA isEqual:itemB]) {
//                    find = true;
//                    break;
//                }
//            }
//            if (!find) {
//                return false;
//            }
//        }
//        return true;
//    }
//}
//
//+(BOOL) compareItemA:(id)itemA containsItemB:(id)itemB{
//    if (itemB == nil) {
//        return true;
//    }else if(itemA == nil || ![self compareKindClassWithItemA:itemA itemB:itemB]){
//        return false;
//    }else{
//        if ([itemA isKindOfClass:[NSString class]]) {
//            return [(NSString*)itemA containsString:itemB];        //NSString
//        }else if ([itemA isKindOfClass:[NSArray class]]) {
//            BOOL itemAContainsItemB = true;//默认true;查到一个不包含设为false;
//            for (id bItem in itemB) {
//                BOOL aItemContainsBItem = false;//默认fale;查到一个包含设为true;
//                for (id aItem in itemA) {
//                    if ([self compareItemA:aItem containsItemB:bItem]) {
//                        aItemContainsBItem = true;
//                        break;
//                    }
//                }
//                if (!aItemContainsBItem) {
//                    itemAContainsItemB = false;
//                }
//            }
//            //return [itemA containsObject:itemB];
//            return itemAContainsItemB;                    //NSArray
//        }else if ([itemA isKindOfClass:[NSDictionary class]]) {
//            for (NSString *key in [(NSDictionary*)itemB allKeys]) { //NSDictionary
//                if(![SMGUtils compareItemA:[(NSDictionary*)itemA objectForKey:key] containsItemB:[(NSDictionary*)itemB objectForKey:key]]){
//                    return false;
//                }
//            }
//            return true;
//        }else if ([itemA isKindOfClass:[NSSet class]]) {
//            return [itemA containsObject:itemB];                      //NSSet
//        }else if ([itemA isKindOfClass:[NSDate class]]) {
//            return [itemA containsDate:itemB];                     //NSDate
//        }else if ([itemA isKindOfClass:[NSIndexSet class]]) {
//            return [itemA containsIndexes:itemB];                 //NSIndexSet
//        }else if ([itemA isKindOfClass:[NSHashTable class]]) {
//            return [itemA containsObject:itemB];                //NSHashTable
//        }else if ([itemA isKindOfClass:[NSOrderedSet class]]) {
//            return [itemA containsObject:itemB];               //NSOrderedSet
//        }else{
//            return [SMGUtils compareItemA:itemA itemB:itemB];       //不识别的类型
//        }
//    }
//}
//
//
///**
// *  MARK:--------------------对比itemA和itemB是否有继承关系或同类型(NSObject除外)--------------------
// */
//+(BOOL) compareKindClassWithItemA:(id)itemA itemB:(id)itemB{
//    if (itemA == nil && itemB == nil) {
//        return true;
//    }else if(itemA == nil || itemB == nil){
//        return false;
//    }else{
//        if ([itemA isKindOfClass:[NSArray class]]) {
//            return [itemB isKindOfClass:[NSArray class]];
//        }else if([itemA isKindOfClass:[NSString class]]){
//            return [itemB isKindOfClass:[NSString class]];
//        }else if([itemA isKindOfClass:[NSDictionary class]]){
//            return [itemB isKindOfClass:[NSDictionary class]];
//        }else{
//            BOOL isSeem = ([itemA class] == [itemB class]);
//            BOOL isKind = ([itemA isKindOfClass:[itemB class]] || [itemB isKindOfClass:[itemA class]]);
//            return isSeem || isKind;
//        }
//    }
//}


/**
 *  MARK:--------------------比较refsA是否比refsB大--------------------
 */
//+(NSComparisonResult) compareRefsA_p:(NSArray*)refsA_p refsB_p:(NSArray*)refsB_p{
//    //1. 数据检查 & 准备
//    refsA_p = ARRTOOK(refsA_p);
//    refsB_p = ARRTOOK(refsB_p);
//    NSInteger aLength = refsA_p.count;
//    NSInteger bLength = refsB_p.count;
//    
//    //2. 比较大小
//    for (NSInteger i = 0; i < MIN(aLength, bLength); i++) {
//        AIKVPointer *itemA = ARR_INDEX(refsA_p, i);
//        AIKVPointer *itemB = ARR_INDEX(refsB_p, i);
//        NSNumber *aNum = [SMGUtils searchObjectForPointer:itemA fileName:kFNValue];
//        NSNumber *bNum = [SMGUtils searchObjectForPointer:itemB fileName:kFNValue];
//        NSComparisonResult result = [NUMTOOK(aNum) compare:NUMTOOK(bNum)] ;
//        if (result != NSOrderedSame) {
//            return result;
//        }
//    }
//    
//    //3. 前面都一样
//    return aLength > bLength ? NSOrderedAscending : aLength < bLength ? NSOrderedDescending : NSOrderedSame;
//}

+(NSComparisonResult) comparePointerA:(AIPointer*)pA pointerB:(AIPointer*)pB{
    //1. 数据检查
    BOOL aIsOk = ISOK(pA, AIKVPointer.class);
    BOOL bIsOk = ISOK(pB, AIKVPointer.class);
    if (!aIsOk || !bIsOk) {
        return (aIsOk == bIsOk) ? NSOrderedSame : (aIsOk ? NSOrderedAscending : NSOrderedDescending);
    }
    
    //2. PointerId越小越排前面
    if (pA.pointerId > pB.pointerId) {
        return NSOrderedDescending;
    }else if(pA.pointerId < pB.pointerId){
        return NSOrderedAscending;
    }else{
        return [XGRedisUtil compareStrA:pA.identifier strB:pB.identifier];
    }
}

+(NSComparisonResult) comparePortA:(AIPort*)pA portB:(AIPort*)pB{
    //1. 数据检查
    BOOL aIsOk = ISOK(pA, AIPort.class);
    BOOL bIsOk = ISOK(pB, AIPort.class);
    if (!aIsOk || !bIsOk) {
        return (aIsOk == bIsOk) ? NSOrderedSame : (aIsOk ? NSOrderedAscending : NSOrderedDescending);
    }
    
    //2. 默认按StrongValue从小到大排序 (self.strongValue越小越排前面)
    if (pA.strong.value > pB.strong.value) {
        return NSOrderedDescending;
    }else if(pA.strong.value < pB.strong.value){
        return NSOrderedAscending;
    }else{
        //3. 然后对比目标地址。
        NSComparisonResult comparisonByTargetP = [SMGUtils comparePointerA:pA.target_p pointerB:pB.target_p];
        if (comparisonByTargetP != NSOrderedSame) return comparisonByTargetP;
        
        //4. 再然后对比params的hash值。
        if (pA.params && pB.params) {
            return [SMGUtils compareIntA:CLEANSTR(pA.params).hash intB:CLEANSTR(pB.params).hash];
        }
        return NSOrderedSame;
    }
}

/**
 *  MARK:--------------------比较intA是否比intB大--------------------
 */
+(NSComparisonResult) compareIntA:(NSInteger)intA intB:(NSInteger)intB{
    return intA > intB ? NSOrderedAscending : intA < intB ? NSOrderedDescending : NSOrderedSame;
}


/**
 *  MARK:--------------------比较floatA是否比floatB大--------------------
 *  @desc 从大到小排序,前大后小;
 */
+(NSComparisonResult) compareFloatA:(CGFloat)floatA floatB:(CGFloat)floatB{
    return floatA > floatB ? NSOrderedAscending : floatA < floatB ? NSOrderedDescending : NSOrderedSame;
}
+(NSComparisonResult) compareDoubleA:(CGFloat)doubleA doubleB:(CGFloat)doubleB{
    return doubleA > doubleB ? NSOrderedAscending : doubleA < doubleB ? NSOrderedDescending : NSOrderedSame;
}


@end



@implementation SMGUtils (DB)

/**
 *  MARK:--------------------SQL语句之rowId--------------------
 */
+(NSString*) sqlWhere_RowId:(NSInteger)rowid{
    return [NSString stringWithFormat:@"rowid='%ld'",(long)rowid];
}

//+(NSString*) sqlWhere_K:(id)columnName V:(id)value{
//    return [NSString stringWithFormat:@"%@='%@'",columnName,value];
//}
//
//+(NSDictionary*) sqlWhereDic_K:(id)columnName V:(id)value{
//    if (value) {
//        return [[NSDictionary alloc] initWithObjectsAndKeys:value,STRTOOK(columnName), nil];
//    }
//    return nil;
//}

+(id) searchObjectForPointer:(AIPointer*)pointer fileName:(NSString*)fileName time:(double)time{
    if (ISOK(pointer, AIPointer.class)) {
        return [self searchObjectForFilePath:pointer.filePath fileName:fileName time:time];
    }
    return nil;
}

+(id) searchObjectForFilePath:(NSString*)filePath fileName:(NSString*)fileName time:(double)time{
    //1. 数据检查
    filePath = STRTOOK(filePath);
    
    //2. 优先取redis
    NSString *key = STRFORMAT(@"%@/%@",filePath,fileName);//随后去掉前辍
    id result = [[XGRedis sharedInstance] objectForKey:key];
    NSString *fromType = @"XGRedis";
    
    //3. 再取wedis
    if (result == nil) {
        result = [[XGWedis sharedInstance] objectForKey:key];
        fromType = @"XGWedis";
        
        //4. 最后取disk
        if (result == nil) {
            PINDiskCache *cache = [[PINDiskCache alloc] initWithName:@"" rootPath:filePath];
            result = [cache objectForKey:fileName];
            fromType = @"Disk";
            DebugR();
            [theTC updateTCDebugLastRCount];
        }
        
        //5. 存到redis (wedis/disk)
        if (time > 0 && result) {
            [[XGRedis sharedInstance] setObject:result forKey:key time:time];
        }
    }
    return result;
}

//根据pid找时序（方法不严谨，不可在内核中使用，只可用于临时调试等用途）。
//比如：AIFoNodeBase *F2187 = [AppDelegate searchFoByPointerId:2187];
+(AIFoNodeBase*) searchFoByPointerId:(NSInteger)pointerId {
    //依次从这些属性下找节点，找着则返回。
    for (NSNumber *isOut in @[@(true),@(false)]) {
        for (NSString *fn in @[kPN_FO_ABS_NODE,kPN_FRONT_ORDER_NODE]) {
            for (NSString *at in @[DefaultAlgsType]) {
                AIKVPointer *node_p = [AIKVPointer newWithPointerId:pointerId folderName:fn algsType:at dataSource:DefaultDataSource isOut:isOut.boolValue type:ATDefault];
                AIFoNodeBase *fo = [SMGUtils searchNode:node_p];//读node类型
                if (fo) return fo;
            }
        }
    }
    return nil;
}

//+(void) insertObject:(NSObject*)obj rootPath:(NSString*)rootPath fileName:(NSString*)fileName{
//    [self insertObject:obj rootPath:rootPath fileName:fileName time:0 saveDB:true];
//}
+(void) insertObject:(NSObject*)obj pointer:(AIPointer*)pointer fileName:(NSString*)fileName time:(double)time{
    if (ISOK(pointer, AIPointer.class)) {
        [self insertObject:obj rootPath:pointer.filePath fileName:fileName time:time saveDB:true];
    }
}
+(void) insertObject:(NSObject*)obj rootPath:(NSString*)rootPath fileName:(NSString*)fileName time:(double)time saveDB:(BOOL)saveDB{
    //1. 存disk (异步持久化)
    NSString *key = STRFORMAT(@"%@/%@",rootPath,fileName);
    if (saveDB) {
        [[XGWedis sharedInstance] setObject:obj forKey:key];
        
        //2. 持久化block;
        //2023.07.21: TC线程改为串行了,所以此处不再调用主线程持久化;
        Act1 saveBlock = ^(AsyncMutableDictionary *dic) {
            for (NSString *saveKey in dic.allKeys) {
                id saveObj = [dic objectForKey:saveKey];
                NSString *sep = @"/";
                NSString *saveFileName = STRTOOK(ARR_INDEX_REVERSE(STRTOARR(saveKey, sep), 0));
                NSString *saveRootPath = STRTOOK(SUBSTR2INDEX(saveKey, (saveKey.length - saveFileName.length - 1)));
                PINDiskCache *cache = [[PINDiskCache alloc] initWithName:@"" rootPath:saveRootPath];
                [cache setObject:saveObj forKey:saveFileName];
                DebugW();
                [theTC updateTCDebugLastWCount];
            }
            if (dic.count > 0) {
                NSLog(@">>>>>>>>>WriteDisk,%lu",(unsigned long)dic.count);
            }
        };
        [[XGWedis sharedInstance] setSaveBlock:saveBlock];
    }
    
    //2. 存redis
    [[XGRedis sharedInstance] setObject:obj forKey:key time:time];//随后去掉(redisKey)前辍
}

+(id) searchNode:(AIKVPointer*)pointer {
    if (ISOK(pointer, AIKVPointer.class)) {
        return [self searchObjectForFilePath:pointer.filePath fileName:kFNNode time:cRTNode(pointer)];
    }
    return nil;
}

/**
 *  MARK:--------------------搜索节点组--------------------
 *  @result notnull
 */
+(NSArray*) searchNodes:(NSArray*)ps {
    //1. 数据准备
    ps = ARRTOOK(ps);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. search
    for (AIKVPointer *item_p in ps) {
        AINodeBase *itemNode = [SMGUtils searchNode:item_p];
        if (itemNode) [result addObject:itemNode];
    }
    return result;
}

+(void) insertNode:(AINodeBase*)node{
    if (ISOK(node, AINodeBase.class)) {
        [self insertObject:node pointer:node.pointer fileName:kFNNode time:cRTNode(node.pointer)];
    }
}

/**
 *  MARK:--------------------组码索引序列--------------------
 */
+(id) searchGVIndexForPointer:(AIPointer*)gvIndex_p itemIndex:(NSInteger)itemIndex {
    return [SMGUtils searchObjectForPointer:gvIndex_p fileName:kFN_GV_Index(itemIndex) time:cRT_GV_Index];
}

+(void) insertGVIndex:(NSArray*)gvIndexObj gvIndex_p:(AIPointer*)gvIndex_p itemIndex:(NSInteger)itemIndex {
    [self insertObject:gvIndexObj pointer:gvIndex_p fileName:kFN_GV_Index(itemIndex) time:cRT_GV_Index];
}

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Contains) >
//MARK:===============================================================
@implementation SMGUtils (Contains)

+(BOOL) containsSub_ps:(NSArray*)sub_ps parent_ps:(NSArray*)parent_ps{
    sub_ps = ARRTOOK(sub_ps);
    for (AIPointer *sub_p in sub_ps) {
        if (![self containsSub_p:sub_p parent_ps:parent_ps]) {
            return false;
        }
    }
    return true;
}

+(BOOL) containsSub_p:(AIPointer*)sub_p parent_ps:(NSArray*)parent_ps{
    if (ISOK(sub_p, AIPointer.class) && ARRISOK(parent_ps)) {
        for (AIPointer *parent_p in parent_ps) {
            if ([sub_p isEqual:parent_p]) {
                return true;
            }
        }
    }
    return false;
}

+(BOOL) containsSub_p:(AIPointer*)sub_p parentPorts:(NSArray*)parentPorts{
    NSArray *parent_ps = [SMGUtils convertPointersFromPorts:parentPorts];
    return [SMGUtils containsSub_p:sub_p parent_ps:parent_ps];
}

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (convert) >
//MARK:===============================================================
@implementation SMGUtils (Convert)

+(NSMutableArray*) convertPointersFromPorts:(NSArray*)ports{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (AIPort *port in ARRTOOK(ports)) {
        if (ISOK(port, AIPort.class) && ISOK(port.target_p, AIPointer.class)) {
            [result addObject:port.target_p];
        }
    }
    return result;
}

+(NSMutableArray*) convertPointersFromNodes:(NSArray*)nodes{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (AINodeBase *node in ARRTOOK(nodes)) {
        if (ISOK(node, AINodeBase.class)) {
            [result addObject:node.pointer];
        }
    }
    return result;
}

//simples转pits;
+(NSMutableArray*) convertPointersFromSimples:(NSArray*)simples{
    return [SMGUtils convertArr:simples convertBlock:^id(AIShortMatchModel_Simple *obj) {
        return obj.alg_p;
    }];
}

+(NSString*) convertPointers2String:(NSArray*)pointers{
    NSMutableString *mStr = [[NSMutableString alloc] init];
    for (AIPointer *p in ARRTOOK(pointers)) {
        [mStr appendFormat:@"%@_%ld,",p.identifier,(long)p.pointerId];
    }
    return mStr;
}

//2021.02.05: 概念嵌套早已废弃
//+(NSMutableArray*) convertValuePs2MicroValuePs:(NSArray*)value_ps{
//    //1. 数据准备
//    NSMutableArray *mic_ps = [[NSMutableArray alloc] init];
//
//    //2. 逐个收集
//    for (AIKVPointer *value_p in value_ps) {
//
//        //3. 概念嵌套时
//        if ([kPN_ALG_ABS_NODE isEqualToString:value_p.folderName]) {
//            AIAlgNodeBase *algNode = [SMGUtils searchNode:value_p];
//
//            //4. 递归取嵌套的value_ps
//            if (ISOK(algNode, AIAlgNodeBase.class)) {
//                [mic_ps addObjectsFromArray:[self convertValuePs2MicroValuePs:algNode.content_ps]];
//            }
//        }
//
//        //5. 非概念嵌套时,直接收集;
//        [mic_ps addObject:value_p];
//    }
//    return mic_ps;
//}

//任意arr元素类型转换 notnull
+(NSMutableArray*) convertArr:(NSArray*)arr convertBlock:(id(^)(id obj))convertBlock{
    //1. 数据准备;
    arr = ARRTOOK(arr);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. 转换
    for (id obj in arr) {
        id convertItem = convertBlock(obj);
        if (convertItem) [result addObject:convertItem];
    }
    return result;
}

+(NSMutableArray*) convertArr:(NSArray*)arr iConvertBlock:(id(^)(NSInteger i, id obj))iConvertBlock {
    //1. 数据准备;
    arr = ARRTOOK(arr);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. 转换
    for (NSInteger i = 0; i < arr.count; i++) {
        id obj = ARR_INDEX(arr, i);
        id convertItem = iConvertBlock(i,obj);
        if (convertItem) [result addObject:convertItem];
    }
    return result;
}

+(NSMutableArray*) convertArr:(NSArray*)arr convertItemArrBlock:(NSArray*(^)(id obj))convertItemArrBlock{
    //1. 数据准备;
    arr = ARRTOOK(arr);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. 转换
    for (id obj in arr) {
        NSArray *convertItemArr = convertItemArrBlock(obj);
        if (ARRISOK(convertItemArr)) [result addObjectsFromArray:convertItemArr];
    }
    return result;
}

/**
 *  MARK:--------------------将arr转成dic--------------------
 */
+(NSDictionary*) convertArr2Dic:(NSArray*)objs kvBlock:(NSArray*(^)(id obj))kvBlock {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for (id obj in objs) {
        NSArray *kvArr = kvBlock(obj);
        id k = ARR_INDEX(kvArr, 0), v = ARR_INDEX(kvArr, 1);
        if (k && v) [result setObject:v forKey:k];
    }
    return result;
}

/**
 *  MARK:--------------------将dic转成dic--------------------
 */
+(NSDictionary*) convertDic:(NSDictionary*)protoDic kvBlock:(NSArray*(^)(id protoK,id protoV))kvBlock {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for (id protoK in protoDic.allKeys) {
        id protoV = [protoDic objectForKey:protoK];
        NSArray *kvArr = kvBlock(protoK,protoV);
        id k = ARR_INDEX(kvArr, 0), v = ARR_INDEX(kvArr, 1);
        if (k && v) [result setObject:v forKey:k];
    }
    return result;
}

+(NSDictionary*) reverseDic:(NSDictionary*)protoDic {
    return [self convertDic:protoDic kvBlock:^NSArray *(id protoK, id protoV) {
        return @[protoV,protoK];
    }];
}

+(NSArray*) reverseArr:(NSArray*)array {
    NSEnumerator *enumerator = [array reverseObjectEnumerator];
    return [enumerator allObjects];
}

/**
 *  MARK:--------------------从foPorts中找出含valueIden的元素并返回--------------------
 *  @desc 每个fo,仅判断首条符合的alg;
 */
+(NSMutableArray*) convertAlgPsFromFoPorts:(NSArray*)foPorts valueIden:(NSString*)valueIden{
    return [SMGUtils convertArr:foPorts convertBlock:^id(AIPort *item) {
        //1. 从fo中检查alg元素是否包含同区码 (将首条符合的返回);
        AIFoNodeBase *fo = [SMGUtils searchNode:item.target_p];
        NSArray *validAlg_ps = [SMGUtils filterAlg_Ps:fo.content_ps valueIdentifier:valueIden itemValid:nil];
        if (ARRISOK(validAlg_ps)) {
            return ARR_INDEX(validAlg_ps, 0);
        }
        
        //2. 找不到返空;
        return nil;
    }];
}

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Sort) >
//MARK:===============================================================
@implementation SMGUtils (Sort)

+(NSArray*) sortPointers:(NSArray*)ps{
    ps = ARRTOOK(ps);
    return [ps sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [SMGUtils comparePointerA:obj1 pointerB:obj2];
    }];
}

/**
 *  MARK:--------------------从大到小排序--------------------
 */
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock:(double(^)(id obj))compareBlock{
    return [SMGUtils sortBig2Small:arr compareBlock1:compareBlock compareBlock2:nil];
}
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2{
    return [SMGUtils sortBig2Small:arr compareBlock1:compareBlock1 compareBlock2:compareBlock2 compareBlock3:nil];
}
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3 {
    return [self sortBig2Small:arr compareBlock1:compareBlock1 compareBlock2:compareBlock2 compareBlock3:compareBlock3 compareBlock4:nil];
}
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3 compareBlock4:(double(^)(id obj))compareBlock4 {
    //1. 数据检查;
    arr = ARRTOOK(arr);
    
    //2. 排序返回;
    return [arr sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        //3. 一级对比;
        NSComparisonResult result = NSOrderedSame;
        if (compareBlock1) result = [SMGUtils compareDoubleA:compareBlock1(obj1) doubleB:compareBlock1(obj2)];
        
        //4. 二级对比;
        if (result == NSOrderedSame && compareBlock2) result = [SMGUtils compareDoubleA:compareBlock2(obj1) doubleB:compareBlock2(obj2)];
        
        //5. 三级对比;
        if (result == NSOrderedSame && compareBlock3) result = [SMGUtils compareDoubleA:compareBlock3(obj1) doubleB:compareBlock3(obj2)];
        
        //6. 四级对比;
        if (result == NSOrderedSame && compareBlock4) result = [SMGUtils compareDoubleA:compareBlock4(obj1) doubleB:compareBlock4(obj2)];
        return result;
    }];
}
//从小到大,就是大到小的值取负 (反过来);
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock:(double(^)(id obj))compareBlock {
    return [SMGUtils sortSmall2Big:arr compareBlock1:compareBlock compareBlock2:nil];
}
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 {
    return [SMGUtils sortSmall2Big:arr compareBlock1:compareBlock1 compareBlock2:compareBlock2 compareBlock3:nil];
}
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3 {
    return [SMGUtils sortSmall2Big:arr compareBlock1:compareBlock1 compareBlock2:compareBlock2 compareBlock3:compareBlock3 compareBlock4:nil];
}
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3 compareBlock4:(double(^)(id obj))compareBlock4 {
    return [SMGUtils sortBig2Small:arr compareBlock1:^double(id obj) {
        return compareBlock1 ? -compareBlock1(obj) : 0;
    } compareBlock2:^double(id obj) {
        return compareBlock2 ? -compareBlock2(obj) : 0;
    } compareBlock3:^double(id obj) {
        return compareBlock3 ? -compareBlock3(obj) : 0;
    } compareBlock4:^double(id obj) {
        return compareBlock4 ? -compareBlock4(obj) : 0;
    }];
}

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Remove) >
//MARK:===============================================================
@implementation SMGUtils (Remove)

+(NSMutableArray*) removeSub_ps:(NSArray*)sub_ps parent_ps:(NSArray*)parent_ps{
    sub_ps = ARRTOOK(sub_ps);
    NSMutableArray *result = [[NSMutableArray alloc] initWithArray:parent_ps];
    for (AIPointer *sub_p in sub_ps) {
        result = [self removeSub_p:sub_p parent_ps:result];
    }
    return result;
}

+(NSMutableArray*) removeSub_p:(AIPointer*)sub_p parent_ps:(NSArray*)parent_ps{
    NSMutableArray *result_ps = [[NSMutableArray alloc] initWithArray:parent_ps];
    if (ISOK(sub_p, AIPointer.class)) {
        [result_ps removeObject:sub_p];
    }
    return result_ps;
}

/**
 *  MARK:--------------------取差集--------------------
 *  @param checkValid : 将要移除的item返回true,保留的返回false;
 */
+(NSMutableArray*) removeArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid {
    NSMutableArray *result = [[NSMutableArray alloc] initWithArray:arr];
    NSArray *removeItems = [SMGUtils filterArr:arr checkValid:checkValid limit:NSIntegerMax];
    [result removeObjectsInArray:removeItems];
    return result;
}

+(NSMutableArray*) removeArr:(NSArray *)removeArr parentArr:(NSArray*)parentArr {
    return [self removeArr:removeArr parentArr:parentArr convertBlock:^id(id item) {
        return item;
    }];
}

+(NSMutableArray*) removeArr:(NSArray *)removeArr parentArr:(NSArray*)parentArr convertBlock:(id(^)(id item))convertBlock {
    NSArray *convertedRemoveArr = [SMGUtils convertArr:removeArr convertBlock:convertBlock];
    return [SMGUtils filterArr:parentArr checkValid:^BOOL(id item) {
        id convertedParentItem = convertBlock(item);
        return ![convertedRemoveArr containsObject:convertedParentItem];
    }];
}

/**
 *  MARK:--------------------防重--------------------
 *  _param convertBlock : 用于转换"判断防重的数据类型";
 *  @desc 性能说明: 当AIPort类型时,防重5000条以上时,用时经常1.5s以上 (所以此方法尽量少用);
 *  @result notnull
 */
+(NSMutableArray*) removeRepeat:(NSArray*)protoArr{
    return [self removeRepeat:protoArr convertBlock:^id(id obj) {
        return obj;
    }];
}

+(NSMutableArray*) removeRepeat:(NSArray*)protoArr convertBlock:(id(^)(id obj))convertBlock{
    //1. 数据准备
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSMutableArray *resultConverteds = [[NSMutableArray alloc] init];
    protoArr = ARRTOOK(protoArr);
    
    //2. 防重收集
    for (id proto in protoArr) {
        
        //3. 将已收集部分和当前proto转为converted后的类型;
        id protoConverted = convertBlock(proto);
        
        //4. 判断是否已包含 (未包含则收集);
        if (![resultConverteds containsObject:protoConverted]) {
            [result addObject:proto];
            [resultConverteds addObject:protoConverted];
        }
    }
    return result;
}

+(AIKVPointer*) filterSameIdentifier_p:(AIKVPointer*)a_p b_ps:(NSArray*)b_ps{
    if (!a_p) return nil;
    return ARR_INDEX([self filterSameIdentifier_Dic:@[a_p] b_ps:b_ps].allValues, 0);
}
+(NSMutableDictionary*) filterSameIdentifier_Dic:(NSArray*)a_ps b_ps:(NSArray*)b_ps{
    return [SMGUtils filterPointers:a_ps b_ps:b_ps checkItemValid:^BOOL(AIKVPointer *a_p, AIKVPointer *b_p) {
        return a_p ? [a_p.identifier isEqualToString:b_p.identifier] : false;
    }];
}
//+(NSArray*) filterSameIdentifier_Arr:(NSArray*)from_ps valid_ps:(NSArray*)valid_ps{
//    NSMutableArray *result = [[NSMutableArray alloc] init];
//    [SMGUtils foreach:from_ps b_ps:valid_ps tryOut:^(AIKVPointer *a_p, AIKVPointer *b_p) {
//        if ([a_p.identifier isEqualToString:b_p.identifier]) {
//            [result addObject:a_p];
//        }
//    }];
//    return result;
//}
+(AIKVPointer*) filterSameIdentifier_DiffId_p:(AIKVPointer*)a_p b_ps:(NSArray*)b_ps{
    if (! a_p) return nil;
    return ARR_INDEX([SMGUtils filterSameIdentifier_DiffId_ps:@[a_p] b_ps:b_ps].allValues, 0);
}
+(NSMutableDictionary*) filterSameIdentifier_DiffId_ps:(NSArray*)a_ps b_ps:(NSArray*)b_ps{
    return [SMGUtils filterPointers:a_ps b_ps:b_ps checkItemValid:^BOOL(AIKVPointer *a_p, AIKVPointer *b_p) {
        if (a_p && b_p) {
            return [a_p.identifier isEqualToString:b_p.identifier] && a_p.pointerId != b_p.pointerId;
        }
        return false;
    }];
}

+(NSArray*) filterPointers:(NSArray *)from_ps checkValid:(BOOL(^)(AIKVPointer *item_p))checkValid {
    return [self filterArr:from_ps checkValid:checkValid];
}

+(NSMutableDictionary*) filterPointers:(NSArray *)a_ps b_ps:(NSArray*)b_ps checkItemValid:(BOOL(^)(AIKVPointer *a_p,AIKVPointer *b_p))checkItemValid {
    //1. 数据准备
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    a_ps = ARRTOOK(a_ps);
    b_ps = ARRTOOK(b_ps);
    for (AIKVPointer *a_p in a_ps) {
        for (AIKVPointer *b_p in b_ps) {
            if (checkItemValid && checkItemValid(a_p,b_p)) {
                [result setObject:b_p forKey:OBJ2DATA(a_p)];
            }
        }
    }
    return result;
}

/**
 *  MARK:--------------------交集--------------------
 *  @version
 *      2020.12.13: 使之改为保持parent_ps有序 (以前的旧有方式是dic筛选,会使无序,导致原有序被打乱,比如参考21194的BUG);
 *  @result notnull (返回结果,保持以arrB的顺序);
 */
+(NSArray*) filterArrA:(NSArray*)arrA arrB:(NSArray*)arrB {
    return [self filterArr:arrB checkValid:^BOOL(id item) {
        return [arrA containsObject:item];
    }];
}
+(NSMutableArray*) filterArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid {
    return [SMGUtils filterArr:arr checkValid:checkValid limit:NSIntegerMax];
}
+(NSMutableArray*) filterArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid limit:(NSInteger)limit{
    //1. 数据准备
    arr = ARRTOOK(arr);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. 筛选
    for (id item in arr) {
        if (item && checkValid && checkValid(item)) {
            [result addObject:item];
            if (result.count >= limit) break;
        }
    }
    return result;
}

+(NSMutableArray*) filterArr:(NSArray *)arrA arrB:(NSArray*)arrB convertBlock:(id(^)(id item))convertBlock {
    NSArray *convertedArrB = [SMGUtils convertArr:arrB convertBlock:^id(id obj) {
        return convertBlock(obj);
    }];
    return [SMGUtils filterArr:arrA checkValid:^BOOL(id item) {
        id convertedItemA = convertBlock(item);
        return [convertedArrB containsObject:convertedItemA];
    }];
}

+(NSMutableDictionary*) filterDic:(NSDictionary *)dic checkValid:(BOOL(^)(id key,id value))checkValid {
    //1. 数据准备
    dic = DICTOOK(dic);
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    //2. 筛选
    for (id key in dic.allKeys) {
        id value = [dic objectForKey:key];
        if (checkValid && checkValid(key,value)) {
            [result setObject:value forKey:key];
        }
    }
    return result;
}

//用analogyType来筛选ports
+(NSArray*) filterPorts_Normal:(NSArray*)ports{
    NSArray *noTypes = @[@(ATGreater),@(ATLess),@(ATHav),@(ATNone),
                         @(ATPlus),@(ATSub),@(ATDiff),@(ATSame)];
    return [SMGUtils filterPorts:ports havTypes:nil noTypes:noTypes];
}
+(NSArray*) filterPorts:(NSArray*)ports havTypes:(NSArray*)havTypes noTypes:(NSArray*)noTypes{
    //1. 数据检查
    havTypes = ARRTOOK(havTypes);
    noTypes = ARRTOOK(noTypes);
    ports = ARRTOOK(ports);
    
    //3. 筛选类型
    return [SMGUtils filterArr:ports checkValid:^BOOL(AIPort *item) {
        //a. hav筛选 (必须被havDSArr包含);
        if (ARRISOK(havTypes) && ![havTypes containsObject:@(item.target_p.type)]) return false;
        //b. no筛选 (必须不被noDSArr包含);
        if (ARRISOK(noTypes) && [noTypes containsObject:@(item.target_p.type)]) return false;
        //c. 干不死的,有效;
        return true;
    }];
}

+(id) filterSingleFromArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid {
    arr = ARRTOOK(arr);
    for (id item in arr) {
        if (checkValid && checkValid(item)) return item;
    }
    return nil;
}

/**
 *  MARK:--------------------找出最大的--------------------
 *  @param scoreBlock 单条评分 notnull
 *  @result 返回bestObj和bestScore;
 */
+(id) filterBestObj:(NSArray*)arr scoreBlock:(CGFloat(^)(id item))scoreBlock {
    return [SMGUtils filterBest:arr scoreBlock:scoreBlock].v1;
}
+(CGFloat) filterBestScore:(NSArray*)arr scoreBlock:(CGFloat(^)(id item))scoreBlock {
    return NUMTOOK([SMGUtils filterBest:arr scoreBlock:scoreBlock].v2).floatValue;
}
+(MapModel*) filterBest:(NSArray*)arr scoreBlock:(CGFloat(^)(id item))scoreBlock {
    arr = ARRTOOK(arr);
    CGFloat bestScore = CGFLOAT_MIN;
    id bestObj = nil;
    for (AIKVPointer *curObj in arr) {
        CGFloat curScore = scoreBlock(curObj);
        if (bestObj == nil || curScore > bestScore) {
            bestObj = curObj;
            bestScore = curScore;
        }
    }
    return [MapModel newWithV1:bestObj v2:@(bestScore)];
}

/**
 *  MARK:--------------------筛选alg by 指定标识--------------------
 *  @desc 从alg_ps中查找含valueIdentifier标识稀疏码的概念并返回;
 *  @result 逐条返回 + 中断前所有收集全返回;
 */
+(NSArray*) filterAlg_Ps:(NSArray*)alg_ps valueIdentifier:(NSString*)valueIdentifier itemValid:(void(^)(AIAlgNodeBase *alg,AIKVPointer *value_p))itemValid{
    return [SMGUtils filterPointers:alg_ps checkValid:^BOOL(AIKVPointer *item_p) {
        AIAlgNodeBase *alg = [SMGUtils searchNode:item_p];
        if (alg) {
            for (AIKVPointer *itemValue_p in alg.content_ps) {
                if ([valueIdentifier isEqualToString:itemValue_p.identifier]) {
                    if (itemValid) itemValid(alg,itemValue_p);
                    return true;
                }
            }
        }
        return false;
    }];
}

/**
 *  MARK:--------------------筛选指针 by isOut--------------------
 *  @param proto_ps : 从中筛选
 *  @param isOut : false时筛选出非out的pointers
 *  注:未判定是否连续;
 */
+(NSArray*) filterPointers:(NSArray*)proto_ps isOut:(BOOL)isOut{
    return [SMGUtils filterPointers:proto_ps checkValid:^BOOL(AIKVPointer *item_p) {
        return item_p.isOut == isOut;
    }];
}

/**
 *  MARK:--------------------筛选指针 by 指定标识--------------------
 */
+(NSArray*) filterPointers:(NSArray*)from_ps identifier:(NSString*)identifier{
    return [SMGUtils filterPointers:from_ps checkValid:^BOOL(AIKVPointer *item_p) {
        return [identifier isEqualToString:item_p.identifier];
    }];
}

/**
 *  MARK:--------------------筛选端口 by 指定标识--------------------
 */
+(NSArray*) filterAlgPorts:(NSArray*)algPorts valueIdentifier:(NSString*)valueIdentifier{
    return [SMGUtils filterArr:algPorts checkValid:^BOOL(AIPort *item) {
        AIAlgNodeBase *alg = [SMGUtils searchNode:item.target_p];
        return ARRISOK([SMGUtils filterPointers:alg.content_ps identifier:valueIdentifier]);
    }];
}
//筛选foPorts中,包含稀疏码同区码的;
+(NSArray*) filterFoPorts:(NSArray*)foPorts valueIdentifier:(NSString*)valueIdentifier{
    return [SMGUtils filterArr:foPorts checkValid:^BOOL(AIPort *item) {
        //检查fo.content是否包含某同区码稀疏码;
        AIFoNodeBase *fo = [SMGUtils searchNode:item.target_p];
        return ARRISOK([SMGUtils filterAlg_Ps:fo.content_ps valueIdentifier:valueIdentifier itemValid:nil]);
    }];
}
//筛选fos中,包含稀疏码同区码的;
+(NSArray*) filterFos:(NSArray*)fos valueIdentifier:(NSString*)valueIdentifier{
    return [SMGUtils filterArr:fos checkValid:^BOOL(AIFoNodeBase *fo) {
        //检查fo.content是否包含某同区码稀疏码;
        return ARRISOK([SMGUtils filterAlg_Ps:fo.content_ps valueIdentifier:valueIdentifier itemValid:nil]);
    }];
}

@end

//MARK:===============================================================
//MARK:                     < SMGUtils (Collect) >
//MARK:===============================================================
@implementation SMGUtils (Collect)

+(NSMutableArray *) collectArrA:(NSArray*)arrA arrB:(NSArray*)arrB{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [result addObjectsFromArray:arrA];
    [result addObjectsFromArray:arrB];
    return result;
}

//不管顺序: 先收集bigArr再收集littleArr
+(NSMutableArray *) collectArrA_NoRepeat:(NSArray*)arrA arrB:(NSArray*)arrB{
    //1. 数据准备;
    arrA = ARRTOOK(arrA);
    arrB = ARRTOOK(arrB);
    NSArray *litArr = arrA.count < arrB.count ? arrA : arrB;
    NSArray *bigArr = arrA.count < arrB.count ? arrB : arrA;
    
    //2. 先收集大的,再收集小的;
    return [SMGUtils collectArrA_NoRepeat_Sort:bigArr arrB:litArr];
}

//保持顺序: 先收集first再收集second
+(NSMutableArray *) collectArrA_NoRepeat_Sort:(NSArray*)firstArr arrB:(NSArray*)secondArr{
    //1. 数据准备;
    firstArr = ARRTOOK(firstArr);
    secondArr = ARRTOOK(secondArr);
    
    //2. 先收集大的;
    NSMutableArray *result = [[NSMutableArray alloc] initWithArray:firstArr];
    
    //3. 再收集小的;
    for (id second in secondArr) {
        if (![result containsObject:second]) {
            [result addObject:second];
        }
    }
    return result;
}

@end

//MARK:===============================================================
//MARK:                     < SMGUtils (Other) >
//MARK:===============================================================
@implementation SMGUtils (Other)

//+(void) foreach:(NSArray *)a_ps b_ps:(NSArray*)b_ps tryOut:(void(^)(AIKVPointer *a_p,AIKVPointer *b_p))tryOut {
//    a_ps = ARRTOOK(a_ps);
//    b_ps = ARRTOOK(b_ps);
//    for (AIKVPointer *a_p in a_ps) {
//        for (AIKVPointer *b_p in b_ps) {
//            if (tryOut) tryOut(a_p,b_p);
//        }
//    }
//}

/**
 *  MARK:--------------------for正反序执行--------------------
 *  @param min : 循环含min
 *  @param max : 执行到max-1 (不含max);
 *  @param run : 每条回调,返回true时,中断循环;
 */
+(void) fori:(NSArray *)arr min:(NSInteger)min max:(NSInteger)max run:(BOOL(^)(id item,NSInteger i))run forward:(BOOL)forward{
    //1. 数据检查;
    arr = ARRTOOK(arr);
    if (!forward) return;
    
    //2. 执行循环;
    for (NSInteger i = min; i < max; i++) {
        NSInteger index = forward ? i : max - i - 1;
        if (run(ARR_INDEX(arr, index),index)) return;
    }
}

+(double) sumOfArr:(NSArray *)arr convertBlock:(double(^)(id obj))convertBlock{
    //1. 数据准备;
    arr = ARRTOOK(arr);
    double sumResult = 0;
    
    //2. 转换
    for (id obj in arr) sumResult += convertBlock(obj);
    return sumResult;
}

//返回点数的层级（比如81返回4）
+(int) convertDotSize2Level:(CGFloat)dotSize {
    return (int)(log(dotSize) / log(3) + 0.1999f);//因为高层级时，它有精度问题，导致4.9999998 强转Int后变成4，所以另外加上0.1999。
}

+(void) runByMainQueue:(dispatch_block_t)block {
    dispatch_async(dispatch_get_main_queue(), block);
}

@end
