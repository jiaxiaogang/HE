//
//  AINetIndex.h
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/4/20.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  MARK:--------------------微信息索引--------------------
 *  1. Input索引 (海马)
 *      >
 *      >
 *
 *  2. Output索引 (小脑)
 *      > 装箱 (用于将outLog信息进行装索引)
 *          AIKVPointer *output_p = [theNet getOutputIndex:algsType dataSource:dataSource outputObj:outputObj];
 *
 *      > 记录可输出reference (用于将指针,索引到引用序列)
 *          [theNet setNetNodePointerToOutputReference:output_p algsType:algsType dataSource:dataSource difStrong:1];
 */
@class AIPointer,AIKVPointer,AIValueInfo;
@interface AINetIndex : NSObject


/**
 *  MARK:--------------------根据data直接查找value_p--------------------
 *  1. 如果未找到,则创建一个,并返回;
 */
+(AIKVPointer*) getDataPointerWithData:(NSNumber*)data algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut;


/**
 *  MARK:--------------------取微信息值--------------------
 */
+(NSNumber*) getData:(AIKVPointer*)value_p;
+(NSNumber*) getData:(AIKVPointer*)value_p fromDataDic:(NSDictionary*)dataDic;

/**
 *  MARK:--------------------获取索引序列--------------------
 */
+(NSArray*) getIndex_ps:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut;

/**
 *  MARK:--------------------获取某标识索引序列的值域--------------------
 */
+(double) getIndexSpan:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut;

/**
 *  MARK:--------------------获取值的信息--------------------
 *  @result notnull;
 */
+(AIValueInfo*) getValueInfo:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut;
+(AIValueInfo*) getGVValueInfo:(NSString*)at ds:(NSString*)ds minData:(float)minData maxData:(float)maxData itemIndex:(NSInteger)itemIndex;

@end


/**
 *  MARK:--------------------内存DataSortModel (一组index)--------------------
 *  1. 排序是根据"值"大小排;
 *  2. pointerIds里存的是"值的指针"的pointerId;
 */
@interface AINetIndexModel : NSObject <NSCoding>

@property (strong,nonatomic) NSMutableArray *pointerIds;
@property (strong,nonatomic) NSString *algsType;
@property (strong,nonatomic) NSString *dataSource;

@end


//MARK:===============================================================
//MARK:                     < 码域信息 >
//MARK:===============================================================
@interface AIValueInfo : NSObject

+(AIValueInfo*) newWithMin:(double)min max:(double)max loop:(BOOL)loop;

@property (assign, nonatomic) double min; //最大值
@property (assign, nonatomic) double max; //最小值
@property (assign, nonatomic) BOOL loop; //是否循环码
-(double) span;

@end
