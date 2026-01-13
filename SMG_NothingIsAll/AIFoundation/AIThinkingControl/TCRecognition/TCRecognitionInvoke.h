//
//  TCRecognitionInvoke.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/27.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIFeatureJvBuModels,DDic,AIGroupFeatureNode,AIFeatureJvBuItem;
@interface TCRecognitionInvoke : NSObject

//MARK:===============================================================
//MARK:                     < 单特征识别 >
//MARK:===============================================================
+(void) recognitionFeatureV2_Step0:(NSDictionary*)colorDic whSize:(CGFloat)whSize at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc;

//MARK:===============================================================
//MARK:                     < 组特征识别 >
//MARK:===============================================================
+(NSArray*) recognitionGroupFeatureV6:(NSArray*)stModels logDesc:(NSString*)logDesc protoGT:(AIGroupFeatureNode*)protoGT;

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
                            ds:(NSString*)ds;

@end
