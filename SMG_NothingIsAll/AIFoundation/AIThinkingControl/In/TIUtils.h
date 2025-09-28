//
//  TIUtils.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/27.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIFeatureJvBuModels,DDic,AIGroupFeatureNode,AIFeatureJvBuItem;
@interface TIUtils : NSObject

//MARK:===============================================================
//MARK:                     < 单特征识别 >
//MARK:===============================================================
+(NSArray*) recognitionFeatureV2_Step1:(NSDictionary*)gvIndex at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoRect:(CGRect)protoRect protoColorDic:(NSDictionary*)protoColorDic excepts:(DDic*)excepts gvRectExcept:(NSMutableDictionary*)gvRectExcept beginRectExcept:(NSMutableArray*)beginRectExcept assRectExcept:(NSMutableArray*)assRectExcept dotSize:(CGFloat)dotSize;
+(void) recognitionFeatureV2_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel;

//MARK:===============================================================
//MARK:                     < 组特征识别 >
//MARK:===============================================================
+(NSArray*) recognitionGroupFeatureV4_Step1:(NSDictionary*)gvIndex at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoRect:(CGRect)protoRect protoColorDic:(NSDictionary*)protoColorDic excepts:(DDic*)excepts gvRectExcept:(NSMutableDictionary*)gvRectExcept beginRectExcept:(NSMutableArray*)beginRectExcept assRectExcept:(NSMutableArray*)assRectExcept dotSize:(CGFloat)dotSize itemSTModels:(NSArray*)itemSTModels;
+(void) recognitionGroupFeatureV4_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel;
+(NSArray*) recognitionGroupFeatureV5:(AIKVPointer*)protoFeature_p matchModels:(NSArray*)matchModels;
+(NSArray*) recognitionGroupFeatureV6:(AIKVPointer*)protoFeature_p matchModels:(NSArray*)matchModels;

//MARK:===============================================================
//MARK:                     < 概念识别 >
//MARK:===============================================================
+(void) recognitionAlgStep1:(NSArray*)except_ps inModel:(AIShortMatchModel*)inModel;

/**
 *  MARK:--------------------概念识别-第二步: 抽具象关联--------------------
 */
+(void) recognitionAlgStep2:(AIShortMatchModel*)inModel;

//MARK:===============================================================
//MARK:                     < 时序识别 >
//MARK:===============================================================
+(void) recognitionFoStep1:(AIFoNodeBase*)protoOrRegroupFo except_ps:(NSArray*)except_ps decoratorInModel:(AIShortMatchModel*)inModel fromRegroup:(BOOL)fromRegroup matchAlgs:(NSArray*)matchAlgs protoOrRegroupCutIndex:(NSInteger)protoOrRegroupCutIndex debugMode:(BOOL)debugMode;

/**
 *  MARK:--------------------时序识别第二步: 抽具象关联--------------------
 */
+(void) recognitionFoStep2:(AIFoNodeBase*)protoOrRegroupFo inModel:(AIShortMatchModel*)inModel debugMode:(BOOL)debugMode;


//MARK:===============================================================
//MARK:                     < Canset识别 >
//MARK:===============================================================
//+(void) recognitionCansetAlg:(AIAlgNodeBase*)protoAlg sceneFo:(AIFoNodeBase*)sceneFo inModel:(AIShortMatchModel*)inModel;
//+(void) recognitionCansetFo:(AIKVPointer*)newCanset_p sceneFo:(AIKVPointer*)sceneFo_p es:(EffectStatus)es;

+(void) printLogDescRate:(NSArray*)asses protoLogDesc:(NSString*)protoLogDesc prefix:(NSString*)prefix convertNodeBlock:(id(^)(id obj))convertNodeBlock convertMatchBlock:(float(^)(id obj))convertMatchBlock;

+(AIFeatureJvBuItem*) ziJvItem:(NSInteger)curIndex
                          assT:(AIFeatureNode*)assT
                 lastProtoRect:(CGRect)lastProtoRect
                 lastAtAssRect:(CGRect)lastAtAssRect
                 protoColorDic:(NSDictionary*)protoColorDic
                            ds:(NSString*)ds
                  dataDicCache:(NSDictionary*)dataDicCache
                    vInfoCache:(NSDictionary*)vInfoCache;

@end
