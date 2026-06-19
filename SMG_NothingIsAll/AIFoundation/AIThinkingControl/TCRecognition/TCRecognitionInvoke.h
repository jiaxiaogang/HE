//
//  TCRecognitionInvoke.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/27.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIFeatureJvBuModels,DDic,AIGroupFeatureNode,AIFeatureJvBuItem,PRJSModel;
@interface TCRecognitionInvoke : NSObject

//MARK:===============================================================
//MARK:                     < 初始化 >
//MARK:===============================================================
+(void) recognitionInit:(NSDictionary*)colorDic whSize:(CGFloat)whSize at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc;

//MARK:===============================================================
//MARK:                     < 稀疏码识别 >
//MARK:===============================================================
+(PRJSModel*) recognitionSVAndGV_Step1:(NSDictionary*)colorDic at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoRect:(CGRect)protoRect beginGVExcept:(NSMutableDictionary*)beginGVExcept;

//MARK:===============================================================
//MARK:                     < 单特征识别 >
//MARK:===============================================================
+(PRJSModel*) recognitionFeatureV2_Step1:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut protoColorDic:(NSDictionary*)protoColorDic excepts:(DDic*)excepts gvRectExcept:(NSMutableDictionary*)gvRectExcept stModels:(PRJSModel*)stModels allGVs:(PRJSModel*)allGVs;
+(void) recognitionFeatureV2_Step3:(AIFeatureJvBuModels*)decoratorJvBuModel ds:(NSString*)ds logDesc:(NSString*)logDesc protoCount:(NSInteger)protoCount;

//MARK:===============================================================
//MARK:                     < 组特征识别 >
//MARK:===============================================================
+(NSArray*) recognitionGroupFeatureV9_Step1:(NSArray*)stModels logDesc:(NSString*)logDesc colorDic:(NSDictionary*)colorDic ds:(NSString*)ds;
+(void) recognitionGroupFeatureV9_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel logDesc:(NSString*)logDesc ds:(NSString*)ds;

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


/**
 *  MARK:--------------------切图缓存池--------------------
 */
+(NSDictionary*) getGVIndexFromPoolOrCutProtoImgV2:(CGRect)protoRect rectKey:(MapModel*)rectKey protoColorDic:(NSDictionary*)protoColorDic ds:(NSString*)ds;

/**
 *  MARK:--------------------切图分组--------------------
 *  @desc 对protoRect计算复用字典的key索引（参考35121-TODO1.1）。
 */
+(MapModel*) getIndexsOfProtoRect:(CGRect)protoRect;

@end
