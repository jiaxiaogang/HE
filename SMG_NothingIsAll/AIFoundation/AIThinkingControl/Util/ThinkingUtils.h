//
//  ThinkingUtils.h
//  SMG_NothingIsAll
//
//  Created by jia on 2018/3/23.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIFrontOrderNode,AIAlgNodeBase,AIShortMatchModel,TOAlgModel,AIFeatureNode,AIFeatureZenTiModels;
@interface ThinkingUtils : NSObject

@end


//MARK:===============================================================
//MARK:                     < ThinkingUtils (CMV) >
//MARK:===============================================================
@interface ThinkingUtils (CMV)


/**
 *  MARK:--------------------取mvType或algsType对应的targetType--------------------
 */
+(BOOL) isBadWithAT:(NSString*)algsType;


/**
 *  MARK:--------------------检查有没需求--------------------
 *  @result 返回为目标方向: 向上任务(delta>0),向下任务(delta<0),和无任务;
 */
+(BOOL) havDownDemand:(NSString*)algsType delta:(NSInteger)delta;
+(BOOL) havDemand:(AIKVPointer*)cmvNode_p;
+(BOOL) havUpDemand:(NSString*)algsType delta:(NSInteger)delta;
+(BOOL) havDemand:(NSString*)algsType delta:(NSInteger)delta;
+(MVDirection) getDemandDirection:(NSString*)algsType delta:(NSInteger)delta;

/**
 *  MARK:--------------------转为direction--------------------
 */
//获取索引方向 (有了索引方向后,可供目标方向取用)
+(MVDirection) getMvReferenceDirection:(NSInteger)delta;

/**
 *  MARK:--------------------解析algsMVArr--------------------
 *  cmvAlgsArr->mvValue
 */
+(void) parserAlgsMVArrWithoutValue:(NSArray*)algsArr success:(void(^)(AIKVPointer *delta_p,AIKVPointer *urgentTo_p,NSString *algsType))success;
+(void) parserAlgsMVArr:(NSArray*)algsArr success:(void(^)(AIKVPointer *delta_p,AIKVPointer *urgentTo_p,NSInteger delta,NSInteger urgentTo,NSString *algsType))success;

//判断mv是否为持续价值 (比如:饥饿是持续性,疼痛是单发的) (参考32041-TODO1);
+(BOOL) isContinuousWithAT:(NSString*)algsType;

//判断当前节点的父RDemand任务是不是持续性价值;
+(BOOL) baseRDemandIsContinuousWithAT:(TOModelBase*)subModel;

@end


//MARK:===============================================================
//MARK:                     < ThinkingUtils (In) >
//MARK:===============================================================
@interface ThinkingUtils (In)

/**
 *  MARK:--------------------检测算法结果的result_ps是否为mv输入--------------------
 *  (饿或不饿)
 */
+(BOOL) dataIn_CheckMV:(NSArray*)algResult_ps;

/**
 *  MARK:--------------------在主线程跑act--------------------
 */
+(void) runAtTiThread:(Act0)act;
+(void) runAtToThread:(Act0)act;
+(void) runAtMainThread:(Act0)act;
+(void) runAtThread:(dispatch_queue_t)queue act:(Act0)act;

+(NSMutableDictionary*) copySPDic:(NSDictionary*)protoSPDic;

/**
 *  MARK:--------------------按绝对xy坐标对InputGroupValueModels进行排序--------------------
 */
+(NSArray*) sortInputGroupValueModels:(NSArray*)models;
+(NSArray*) sortInputGroupFeatureModels:(NSArray*)models;

/**
 *  MARK:--------------------计算assTo是否在其该出现的位置（返回符合度）--------------------
 */
+(CGFloat) checkAssToMatchDegree:(AIFeatureNode*)protoFeature protoIndex:(NSInteger)protoIndex assGVModels:(NSArray*)assGVModels checkRefPort:(AIPort*)checkRefPort debugMode:(BOOL)debugMode;
+(CGFloat) checkAssToMatchDegree:(CGPoint)protoFrom protoTo:(CGPoint)protoTo
                         assFrom:(CGPoint)assFrom assTo:(CGPoint)assTo debugMode:(BOOL)debugMode;
+(CGFloat) checkAssToMatchDegreeV2:(AIFeatureNode*)protoFeature protoIndex:(NSInteger)protoIndex assGVModels:(NSArray*)assGVModels checkRefPort:(AIPort*)checkRefPort debugMode:(BOOL)debugMode;

/**
 *  MARK:--------------------从色值xy字典中获取9宫数据--------------------
 *  @param gvRect 表示gv区域的绝对坐标
 */
+(NSArray*) getSubDots:(NSDictionary*)colorDic gvRect:(CGRect)gvRect;

//把rcmdExcept中交/并>70%的当时识别过的gv_ps收集返回，用于局部特征识别时防重（参考35041-TODO3）。
+(NSArray*) getBeginRectExceptGV_ps:(CGRect)newRect beginRectExcept:(NSDictionary*)beginRectExcept;

//两个rect的区域匹配度（度 = 交 / 并）
+(CGFloat) matchOfRect:(CGRect)oldRect newRect:(CGRect)newRect;

@end
