//
//  AINetIndex.m
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/4/20.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "AINetIndex.h"
#import "PINCache.h"
#import "XGRedisUtil.h"

@implementation AINetIndex

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
+(AIKVPointer*) getDataPointerWithData:(NSNumber*)data algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut{
    //1. 数据准备
    if (ISOK(data, NSNumber.class)) {
        //2. 2025.03.18: 性能优化：最大精度为小数点后3位（如果不限精度，一个稀疏码索引可能有上万条，稀疏码太碎会导致性能问题，尤其是支持面向现实世界的视觉后）。
        //注意：此处只是总体限制，是放的比较宽的，随后要么把最大最小值报进来，内核中自动处理精度，要么就在感官算法层就把精度自己控制好再传进来。
        //原则：感官层做精度处理：要保证整个稀疏码可能的值，其总量在不影响感知的前提下越少越好，比如：人类的声音频率范围和感知最小差。
        //TODO: 随后把每个ds的稀疏码值的span值域传进来，然后自动计算精度（一般保留1/1000的精度就够用了）。
        data = @(roundf([(NSNumber*)data floatValue] * 10000) / 10000);
    } else {
        return nil;
    }

    //2. 取索引序列 和 稀疏码值字典;
    AINetIndexModel *model = [AINetIndexUtils searchIndexModel:algsType ds:dataSource isOut:isOut];
    NSMutableDictionary *dataDic = [[NSMutableDictionary alloc] initWithDictionary:[AINetIndexUtils searchDataDic:algsType ds:dataSource isOut:isOut]];

    //3. 使用二分法查找data
    __block AIKVPointer *resultPointer;
    [XGRedisUtil searchIndexWithCompare:^NSComparisonResult(NSInteger checkIndex) {
        NSNumber *checkPointerIdNumber = ARR_INDEX(model.pointerIds, checkIndex);
        long checkPointerId = [NUMTOOK(checkPointerIdNumber) longValue];
        AIKVPointer *checkValue_p = [SMGUtils createPointerForValue:checkPointerId algsType:algsType dataSource:dataSource isOut:isOut];
        NSString *key = STRFORMAT(@"%ld",(long)checkValue_p.pointerId);
        id checkValue = [dataDic objectForKey:key];
        NSComparisonResult compareResult;
        BOOL dataIsRect = ISOK(data, NSValue.class) && strcmp([(NSValue*)data objCType], @encode(CGRect)) == 0;
        BOOL checkIsRect = ISOK(checkValue, NSValue.class) && strcmp([(NSValue*)checkValue objCType], @encode(CGRect)) == 0;
        if (dataIsRect && checkIsRect) {
            // NSValue(CGRect) 使用字符串比较
            NSString *checkStr = NSStringFromCGRect([(NSValue*)checkValue CGRectValue]);
            NSString *dataStr = NSStringFromCGRect([(NSValue*)data CGRectValue]);
            compareResult = [checkStr compare:dataStr];
        } else {
            compareResult = [NUMTOOK(checkValue) compare:data];
        }
        return compareResult;
    } startIndex:0 endIndex:model.pointerIds.count - 1 success:^(NSInteger index) {
        NSNumber *pointerIdNum = ARR_INDEX(model.pointerIds, index);
        long pointerId = [NUMTOOK(pointerIdNum) longValue];
        AIKVPointer *value_p = [SMGUtils createPointerForValue:pointerId algsType:algsType dataSource:dataSource isOut:isOut];
        resultPointer = value_p;
    } failure:^(NSInteger index) {
        //4. 未找到;创建一个;
        AIKVPointer *value_p = [SMGUtils createPointerForValue:algsType dataSource:dataSource isOut:isOut];
        NSString *key = STRFORMAT(@"%ld",(long)value_p.pointerId);
        [dataDic setObject:data forKey:key];
        resultPointer = value_p;
        
        if (model.pointerIds.count <= index) {
            [model.pointerIds addObject:@(value_p.pointerId)];
        }else{
            [model.pointerIds insertObject:@(value_p.pointerId) atIndex:index];
        }
        
        //5. 存
        [AINetIndexUtils insertIndexModel:model isOut:isOut];
        [AINetIndexUtils insertDataDic:dataDic at:algsType ds:dataSource isOut:isOut];
    }];
    
    return resultPointer;
}

/**
 *  MARK:--------------------获取稀疏码值--------------------
 *  _param fromDataDic 为性能好,可提前缓存好dataDic,传入进来便于复用;
 */
+(NSNumber*) getData:(AIKVPointer*)value_p{
    return [self getData:value_p fromDataDic:nil];
}
+(NSNumber*) getData:(AIKVPointer*)value_p fromDataDic:(NSDictionary*)dataDic {
    if (!DICISOK(dataDic)) dataDic = [AINetIndexUtils searchDataDic:value_p.algsType ds:value_p.dataSource isOut:value_p.isOut];
    return [dataDic objectForKey:STRFORMAT(@"%ld",(long)value_p.pointerId)];
}

/**
 *  MARK:--------------------获取索引序列--------------------
 *  @desc 将索引序列转为稀疏码指针数组返回;
 *  @version
 *      2022.05.20: 支持宽入窄出,仅返回前NarrowLimit条 (参考26073-TODO1);
 *      2022.05.21: V索引不能太窄,改成1000 (参考26075);
 *  @result notnull
 */
+(NSArray*) getIndex_ps:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut{
    //1. 取出索引序列;
    AINetIndexModel *indexModel = [AINetIndexUtils searchIndexModel:at ds:ds isOut:isOut];
    
    //2. 转为稀疏码指针数组返回;
    NSArray *nears = [SMGUtils convertArr:indexModel.pointerIds convertBlock:^id(NSNumber *obj) {
        return [SMGUtils createPointerForValue:[NUMTOOK(obj) longValue] algsType:at dataSource:ds isOut:isOut];
    }];
    
    //3. 窄出,仅返回前NarrowLimit条;
    return ARR_SUB(nears, 0, cIndexNarrowLimit);
}

/**
 *  MARK:--------------------获取某标识索引序列的值域--------------------
 *  @desc 获取索引序列的值域 (参考25082-公式1);
 *  @result 值域不为负
 */
+(double) getIndexSpan:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut {
    AIValueInfo *info = [self getValueInfo:at ds:ds isOut:isOut];
    return info.span;
}

/**
 *  MARK:--------------------获取值的信息--------------------
 *  @result notnull;
 */
+(AIValueInfo*) getValueInfo:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut {
    //0. 如果是循环码时,直接返回指定数;
    double maxLoopValue = [CortexAlgorithmsUtil maxOfLoopValue:at ds:ds itemIndex:GVIndexTypeOfDataSource];
    if (maxLoopValue > 0) {
        return [AIValueInfo newWithMin:0 max:maxLoopValue loop:true];
    }
    
    //1. 取索引序列 & 稀疏码值字典;
    AINetIndexModel *model = [AINetIndexUtils searchIndexModel:at ds:ds isOut:isOut];
    NSDictionary *dataDic = [AINetIndexUtils searchDataDic:at ds:ds isOut:isOut];
    
    //2. 取出最大最小pointerId;
    long minPId = [NUMTOOK(ARR_INDEX(model.pointerIds, 0)) longValue];
    long maxPId = [NUMTOOK(ARR_INDEX_REVERSE(model.pointerIds, 0)) longValue];
    
    //3. 取出最大最小的稀疏码值;
    NSNumber *minData = [dataDic objectForKey:STRFORMAT(@"%ld",minPId)];
    NSNumber *maxData = [dataDic objectForKey:STRFORMAT(@"%ld",maxPId)];
    if (!NUMISOK(minData) || !NUMISOK(maxData)) {
        return [AIValueInfo newWithMin:0 max:0 loop:false];
    }
    return [AIValueInfo newWithMin:minData.doubleValue max:maxData.doubleValue loop:false];
}

+(AIValueInfo*) getGVValueInfo:(NSString*)at ds:(NSString*)ds minData:(float)minData maxData:(float)maxData itemIndex:(NSInteger)itemIndex {
    //0. 如果是循环码时,直接返回指定数;
    double maxLoopValue = [CortexAlgorithmsUtil maxOfLoopValue:at ds:ds itemIndex:itemIndex];
    if (maxLoopValue > 0) {
        return [AIValueInfo newWithMin:0 max:maxLoopValue loop:true];
    } else {
        return [AIValueInfo newWithMin:minData max:maxData loop:false];
    }
}

//MARK:===============================================================
//MARK:                     < output >
//MARK:===============================================================

//暂时不实现小脑网络;
//-(void) setIndexReference:(AIKVPointer*)indexPointer target_p:(AIKVPointer*)target_p difValue:(int)difValue{
//    //    [self.outReference setNodePointerToOutputReference:nil algsType:nil dataSource:nil difStrong:0];
//    //    [outReference setReference:indexPointer target_p:target_p difValue:difValue];
//}
//-(NSArray*) getIndexReference:(AIKVPointer*)indexPointer limit:(NSInteger)limit{
//    //    self.outReference getNodePointersFromOutputReference:algsType dataSource:dataSource limit:333333
//    //    return [self.outReference getReference:indexPointer limit:limit];
//    return nil;
//}

@end


//MARK:===============================================================
//MARK:                     < 内存DataSortModel (一组index) >
//MARK:===============================================================
@implementation AINetIndexModel : NSObject

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(NSMutableArray *)pointerIds{
    if (!ISOK(_pointerIds, NSMutableArray.class)) _pointerIds = [[NSMutableArray alloc] initWithArray:_pointerIds];
    return _pointerIds;
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.pointerIds = [aDecoder decodeObjectForKey:@"pointerIds"];
        self.algsType = [aDecoder decodeObjectForKey:@"algsType"];
        self.dataSource = [aDecoder decodeObjectForKey:@"dataSource"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self.pointerIds copy] forKey:@"pointerIds"];
    [aCoder encodeObject:self.algsType forKey:@"algsType"];
    [aCoder encodeObject:self.dataSource forKey:@"dataSource"];
}

@end

//MARK:===============================================================
//MARK:                     < 码域信息 >
//MARK:===============================================================
@implementation AIValueInfo : NSObject

+(AIValueInfo*) newWithMin:(double)min max:(double)max loop:(BOOL)loop {
    AIValueInfo *info = [[AIValueInfo alloc] init];
    info.min = min;
    info.max = max;
    info.loop = loop;
    return info;
}

-(double) span {
    return self.max - self.min;
}

@end

