//
//  SMGUtils.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/19.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>


@class AIPointer,AIKVPointer,AIObject,AIArray,ThinkModel,AIPort,AINodeBase,AIAlgNodeBase,MapModel;
@interface SMGUtils : NSObject


//MARK:===============================================================
//MARK:                     < PointerId >
//MARK:===============================================================
+(NSInteger) createPointerId:(NSString*)algsType dataSource:(NSString*)dataSource;
+(NSInteger) createPointerId:(BOOL)updateLastId algsType:(NSString*)algsType dataSource:(NSString*)dataSource;
+(NSInteger) getLastNetNodePointerId:(NSString*)algsType dataSource:(NSString*)dataSource;
+(void) setNetNodePointerId:(NSInteger)count algsType:(NSString*)algsType dataSource:(NSString*)dataSource;

//MARK:===============================================================
//MARK:                     < AIPointer >
//MARK:===============================================================
//General指针
+(AIKVPointer*) createPointer:(NSString*)folderName algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut type:(AnalogyType)type;

//Direction的mv分区pointer;(存引用序列)
+(AIKVPointer*) createPointerForDirection:(NSString*)mvAlgsType direction:(MVDirection)direction;

//生成小脑CanOut指针;
+(AIKVPointer*) createPointerForCerebelCanOut;

//生成indexValue的指针;
+(AIKVPointer*) createPointerForValue:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut;
+(AIKVPointer*) createPointerForValue:(NSInteger)pointerId algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut;

//索引指针
+(AIKVPointer*) createPointerForIndex;
+(AIKVPointer*) createPointerForGVIndex:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut;

//微信息值指针
+(AIKVPointer*) createPointerForData:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut;

+(AIKVPointer*) createPointerForGroupValue:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut;
+(AIKVPointer*) createPointerForGroupValue:(NSInteger)pId at:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut;
+(AIKVPointer*) createPointerForFeature:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut;
+(AIKVPointer*) createPointerForGroupFeature:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut;
/**
 *  MARK:--------------------概念节点指针--------------------
 *  @param dataSource : 有三种情况;
 *      1. input输入TIR新概念时,概念的ds就是算法的at,比如:AIVersionAgls;
 *      2. 类比构建器时,概念的ds就是类比源,比如:有无大小同异;
 *      3. 默认(其它)时,概念节点的ds是其content_ps中稀疏码共同的at;
 */
+(AIKVPointer*) createPointerForAlg:(NSString*)folderName at:(NSString*)at dataSource:(NSString*)dataSource isOut:(BOOL)isOut type:(AnalogyType)type;

/**
 *  MARK:--------------------时序节点指针--------------------
 *  @param ds : 有两种情况;
 *      1. 类比构建器时,时序的ds就是类比源,比如:有无大小同异;
 *      2. 默认(其它)时,时序节点的ds=DefaultDataSource;
 */
+(AIKVPointer*) createPointerForFo:(NSString*)folderName at:(NSString*)at ds:(NSString*)ds type:(AnalogyType)type;

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Compare) >
//MARK:===============================================================
@interface SMGUtils (Compare)

//+(BOOL) compareItemA:(id)itemA itemB:(id)itemB;
//+(BOOL) compareArrayA:(NSArray*)arrA arrayB:(NSArray*)arrB;
//+(BOOL) compareItemA:(id)itemA containsItemB:(id)itemB;
//+(NSComparisonResult) compareRefsA_p:(NSArray*)refsA_p refsB_p:(NSArray*)refsB_p;//比较refsA是否比refsB大


//比较pA是否比pB大 (1级pId,2级identifier)
+(NSComparisonResult) comparePointerA:(AIPointer*)pA pointerB:(AIPointer*)pB;

//类比port (1级强度,2级pointer)
+(NSComparisonResult) comparePortA:(AIPort*)pA portB:(AIPort*)pB;
+(NSComparisonResult) compareIntA:(NSInteger)intA intB:(NSInteger)intB;
+(NSComparisonResult) compareFloatA:(CGFloat)floatA floatB:(CGFloat)floatB;
+(NSComparisonResult) compareDoubleA:(CGFloat)doubleA doubleB:(CGFloat)doubleB;

@end


//MARK:===============================================================
//MARK:                     < @SMGUtils (DB) >
//MARK:===============================================================
@interface SMGUtils (DB)
/**
 *  MARK:--------------------SQL语句之rowId--------------------
 */
+(NSString*) sqlWhere_RowId:(NSInteger)rowid;
//+(NSString*) sqlWhere_K:(id)columnName V:(id)value;
//+(NSDictionary*) sqlWhereDic_K:(id)columnName V:(id)value;


/**
 *  MARK:--------------------searchObj--------------------
 */
+(id) searchObjectForPointer:(AIPointer*)pointer fileName:(NSString*)fileName time:(double)time;//找到后,缓存到redis,time秒;
+(id) searchObjectForFilePath:(NSString*)filePath fileName:(NSString*)fileName time:(double)time;
+(id) searchFoByPointerId:(NSInteger)pointerId;


/**
 *  MARK:--------------------insertObj--------------------
 */
//+(void) insertObject:(NSObject*)obj rootPath:(NSString*)rootPath fileName:(NSString*)fileName;
+(void) insertObject:(NSObject*)obj pointer:(AIPointer*)pointer fileName:(NSString*)fileName time:(double)time;
+(void) insertObject:(NSObject*)obj rootPath:(NSString*)rootPath fileName:(NSString*)fileName time:(double)time saveDB:(BOOL)saveDB;//同时插入到redis,time秒


/**
 *  MARK:--------------------Node--------------------
 */
+(id) searchNode:(AIKVPointer*)pointer;
+(NSArray*) searchNodes:(NSArray*)ps;
+(void) insertNode:(AINodeBase*)node;

/**
 *  MARK:--------------------组码索引序列--------------------
 */
+(id) searchGVIndexForPointer:(AIPointer*)gvIndex_p itemIndex:(NSInteger)itemIndex;
+(void) insertGVIndex:(NSArray*)gvIndexObj gvIndex_p:(AIPointer*)gvIndex_p itemIndex:(NSInteger)itemIndex;

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Contains) >
//MARK:===============================================================
@interface SMGUtils (Contains)

//判断parent_ps是否包含sub_ps;
+(BOOL) containsSub_ps:(NSArray*)sub_ps parent_ps:(NSArray*)parent_ps;
+(BOOL) containsSub_p:(AIPointer*)sub_p parent_ps:(NSArray*)parent_ps;
+(BOOL) containsSub_p:(AIPointer*)sub_p parentPorts:(NSArray*)parentPorts;

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (convert) >
//MARK:===============================================================
@interface SMGUtils (Convert)

/**
 *  MARK:--------------------将ports端口中指向转换为指针数组返回--------------------
 *  @result notnull
 */
+(NSMutableArray*) convertPointersFromPorts:(NSArray*)ports;

//nodes转pointers
+(NSMutableArray*) convertPointersFromNodes:(NSArray*)nodes;

//simples转pits;
+(NSMutableArray*) convertPointersFromSimples:(NSArray*)simples;

//将pointers转字符串;
+(NSString*) convertPointers2String:(NSArray*)pointers;

//将概念中的value_ps(含嵌套)展开成纯微信息的组; @result : notnull
//2021.02.05: 概念嵌套早已废弃
//+(NSMutableArray*) convertValuePs2MicroValuePs:(NSArray*)value_ps;

//任意arr元素类型转换 notnull
+(NSMutableArray*) convertArr:(NSArray*)arr convertBlock:(id(^)(id obj))convertBlock;
+(NSMutableArray*) convertArr:(NSArray*)arr iConvertBlock:(id(^)(NSInteger i, id obj))iConvertBlock;
+(NSMutableArray*) convertArr:(NSArray*)arr convertItemArrBlock:(NSArray*(^)(id obj))convertItemArrBlock;
//将arr转成dic
+(NSDictionary*) convertArr2Dic:(NSArray*)objs kvBlock:(NSArray*(^)(id obj))kvBlock;
//将dic转成dic
+(NSDictionary*) convertDic:(NSDictionary*)protoDic kvBlock:(NSArray*(^)(id protoK,id protoV))kvBlock;
+(NSDictionary*) reverseDic:(NSDictionary*)protoDic;
+(NSArray*) reverseArr:(NSArray*)array;

/**
 *  MARK:--------------------从foPorts中找出含valueIden的元素并返回--------------------
 *  @desc 每个fo,仅判断首条符合的alg;
 */
+(NSMutableArray*) convertAlgPsFromFoPorts:(NSArray*)foPorts valueIden:(NSString*)valueIden;

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Sort) >
//MARK:===============================================================
@interface SMGUtils (Sort)

//对ps进行从大到小的排序
+(NSArray*) sortPointers:(NSArray*)ps;

//从大到小排序
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock:(double(^)(id obj))compareBlock;
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2;
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3;
+(NSArray*) sortBig2Small:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3 compareBlock4:(double(^)(id obj))compareBlock4;
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock:(double(^)(id obj))compareBlock;
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2;
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3;
+(NSArray*) sortSmall2Big:(NSArray*)arr compareBlock1:(double(^)(id obj))compareBlock1 compareBlock2:(double(^)(id obj))compareBlock2 compareBlock3:(double(^)(id obj))compareBlock3 compareBlock4:(double(^)(id obj))compareBlock4;

@end


//MARK:===============================================================
//MARK:                     < SMGUtils (Remove) >
//MARK:===============================================================
@interface SMGUtils (Remove)

/**
 *  MARK:--------------------取差集--------------------
 *  @result notnull
 */
+(NSMutableArray*) removeSub_ps:(NSArray*)sub_ps parent_ps:(NSArray*)parent_ps;
+(NSMutableArray*) removeSub_p:(AIPointer*)sub_p parent_ps:(NSArray*)parent_ps;
+(NSMutableArray*) removeArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid;

//取差集,因为model类型无法判断equal,所以用convertBlock来返回能判断equal的类型 (比如point,long等);
+(NSMutableArray*) removeArr:(NSArray *)removeArr parentArr:(NSArray*)parentArr;
+(NSMutableArray*) removeArr:(NSArray *)removeArr parentArr:(NSArray*)parentArr convertBlock:(id(^)(id item))convertBlock;

/**
 *  MARK:--------------------防重--------------------
 *  _param convertBlock : 用于转换"判断防重的数据类型";
 *  @result notnull
 */
+(NSMutableArray*) removeRepeat:(NSArray*)protoArr;
+(NSMutableArray*) removeRepeat:(NSArray*)protoArr convertBlock:(id(^)(id obj))convertBlock;

/**
 *  MARK:--------------------取交集--------------------
 *  @result notnull
 */
//从bps中,找到与ap同区的bItem返回;
+(AIKVPointer*) filterSameIdentifier_p:(AIKVPointer*)a_p b_ps:(NSArray*)b_ps;
//从bps中,找到与aps同区的 所有映射结果 返回 (根据key去重);
+(NSMutableDictionary*) filterSameIdentifier_Dic:(NSArray*)a_ps b_ps:(NSArray*)b_ps;
//从from中,找出valid同区的 所有结果返回 (不去重);
//+(NSArray*) filterSameIdentifier_Arr:(NSArray*)from_ps valid_ps:(NSArray*)valid_ps;
//从b_ps中,找出与a_p同区不同值的指针;
+(AIKVPointer*) filterSameIdentifier_DiffId_p:(AIKVPointer*)a_p b_ps:(NSArray*)b_ps;
//同区不同值
+(NSMutableDictionary*) filterSameIdentifier_DiffId_ps:(NSArray*)a_ps b_ps:(NSArray*)b_ps;

/**
 *  MARK:--------------------从from_ps中,筛选出有效的元素返回--------------------
 *  @result notnull
 */
+(NSArray*) filterPointers:(NSArray *)from_ps checkValid:(BOOL(^)(AIKVPointer *item_p))checkValid;

/**
 *  MARK:--------------------从a_ps和b_ps中,筛选出有效的元素映射返回--------------------
 *  @result notnull (返回的字典中key,为NSData类型)
 */
+(NSMutableDictionary*) filterPointers:(NSArray *)a_ps b_ps:(NSArray*)b_ps checkItemValid:(BOOL(^)(AIKVPointer *a_p,AIKVPointer *b_p))checkItemValid;

/**
 *  MARK:--------------------筛选数组--------------------
 *  @result notnull
 */
+(NSArray*) filterArrA:(NSArray*)arrA arrB:(NSArray*)arrB;
+(NSMutableArray*) filterArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid;
+(NSMutableArray*) filterArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid limit:(NSInteger)limit;

//取交集: 因为obj不能全判断equal,所以加上convertBlock方法,使之能转成判断equal的对象,来实现取交集;
+(NSMutableArray*) filterArr:(NSArray *)arrA arrB:(NSArray*)arrB convertBlock:(id(^)(id item))convertBlock;

/**
 *  MARK:--------------------筛选字典--------------------
 *  @result notnull
 */
+(NSMutableDictionary*) filterDic:(NSDictionary *)dic checkValid:(BOOL(^)(id key,id value))checkValid;

/**
 *  MARK:--------------------用analogyType来筛选ports--------------------
 *  @result notnull
 */
+(NSArray*) filterPorts_Normal:(NSArray*)ports;
+(NSArray*) filterPorts:(NSArray*)ports havTypes:(NSArray*)havTypes noTypes:(NSArray*)noTypes;

/**
 *  MARK:--------------------查找单条--------------------
 */
+(id) filterSingleFromArr:(NSArray *)arr checkValid:(BOOL(^)(id item))checkValid;

/**
 *  MARK:--------------------找出最大的--------------------
 */
+(id) filterBestObj:(NSArray*)arr scoreBlock:(CGFloat(^)(id item))scoreBlock;
+(CGFloat) filterBestScore:(NSArray*)arr scoreBlock:(CGFloat(^)(id item))scoreBlock;
+(MapModel*) filterBest:(NSArray*)arr scoreBlock:(CGFloat(^)(id item))scoreBlock;

/**
 *  MARK:--------------------筛选alg by 指定标识--------------------
 */
+(NSArray*) filterAlg_Ps:(NSArray*)alg_ps valueIdentifier:(NSString*)valueIdentifier itemValid:(void(^)(AIAlgNodeBase *alg,AIKVPointer *value_p))itemValid;

/**
 *  MARK:--------------------筛选指针 by isOut--------------------
 *  @param proto_ps : 从中筛选
 *  @param isOut : false时筛选出非out的pointers
 *  注:未判定是否连续;
 */
+(NSArray*) filterPointers:(NSArray*)proto_ps isOut:(BOOL)isOut;

/**
 *  MARK:--------------------筛选指针 by 指定标识--------------------
 */
+(NSArray*) filterPointers:(NSArray*)from_ps identifier:(NSString*)identifier;

/**
 *  MARK:--------------------筛选端口 by 指定标识--------------------
 */
+(NSArray*) filterAlgPorts:(NSArray*)algPorts valueIdentifier:(NSString*)valueIdentifier;
//筛选foPorts中,包含稀疏码同区码的;
+(NSArray*) filterFoPorts:(NSArray*)foPorts valueIdentifier:(NSString*)valueIdentifier;
//筛选fos中,包含稀疏码同区码的;
+(NSArray*) filterFos:(NSArray*)fos valueIdentifier:(NSString*)valueIdentifier;

@end

//MARK:===============================================================
//MARK:                     < SMGUtils (Collect) >
//MARK:===============================================================
@interface SMGUtils (Collect)

/**
 *  MARK:--------------------并集--------------------
 *  @result notnull
 */
+(NSMutableArray *) collectArrA:(NSArray*)arrA arrB:(NSArray*)arrB;
//不管顺序: 先收集bigArr再收集littleArr
+(NSMutableArray *) collectArrA_NoRepeat:(NSArray*)arrA arrB:(NSArray*)arrB;
//保持顺序: 先收集first再收集second
+(NSMutableArray *) collectArrA_NoRepeat_Sort:(NSArray*)firstArr arrB:(NSArray*)secondArr;

@end

@interface SMGUtils (Other)

/**
 *  MARK:--------------------遍历--------------------
 */
//+(void) foreach:(NSArray *)a_ps b_ps:(NSArray*)b_ps tryOut:(void(^)(AIKVPointer *a_p,AIKVPointer *b_p))tryOut;

/**
 *  MARK:--------------------for正反序执行--------------------
 */
+(void) fori:(NSArray *)arr min:(NSInteger)min max:(NSInteger)max run:(BOOL(^)(id item,NSInteger i))run forward:(BOOL)forward;

+(double) sumOfArr:(NSArray *)arr convertBlock:(double(^)(id obj))convertBlock;

//返回点数的层级（比如81返回4）
+(int) convertDotSize2Level:(CGFloat)dotSize;

+(void) runByMainQueue:(dispatch_block_t)block;

//从mDic中找mArr找到返回，没找到则新建。
+(NSArray*) findOrCreateArr:(NSMutableDictionary*)fromDic key:(id)key;

@end
