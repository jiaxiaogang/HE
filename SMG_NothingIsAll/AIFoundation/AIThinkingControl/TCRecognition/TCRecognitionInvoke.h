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
//MARK:                     < 识别入口 >
//MARK:===============================================================
+(void) recognitionInit:(NSDictionary*)colorDic whSize:(CGFloat)whSize at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc protoST:(AIFeatureNode*)protoST;

+(NSArray*) recognition:(NSString*)at
                     ds:(NSString*)ds
               colorDic:(NSDictionary*)colorDic
                excepts:(DDic*)excepts
                curRect:(CGRect)curRect
          beginGVExcept:(NSMutableDictionary*)beginGVExcept
           gvRectExcept:(NSMutableDictionary*)gvRectExcept
              jvBuModel:(AIFeatureJvBuModels*)jvBuModel
                protoST:(AIFeatureNode*)protoST
                logDesc:(NSString*)logDesc;

//MARK:===============================================================
//MARK:                     < 组特征识别 >
//MARK:===============================================================
+(void) recognitionFeatureV2_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel protoColorDic:(NSDictionary*)protoColorDic ds:(NSString*)ds logDesc:(NSString*)logDesc protoST:(AIFeatureNode*)protoST;
+(void) recognitionGroupFeatureV9_Step2:(AIFeatureJvBuModels*)decoratorJvBuModel logDesc:(NSString*)logDesc colorDic:(NSDictionary*)colorDic ds:(NSString*)ds;

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

@end
