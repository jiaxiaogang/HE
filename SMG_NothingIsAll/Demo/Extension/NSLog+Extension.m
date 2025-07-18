//
//  NSLog+Extension.m
//  SMG_NothingIsAll
//
//  Created by jia on 2020/9/21.
//  Copyright © 2020年 XiaoGang. All rights reserved.
//

#import "NSLog+Extension.h"
#import "ImvAlgsHungerModel.h"
#import "ImvAlgsHurtModel.h"
#import "AINetIndex.h"

@implementation NSLog_Extension

+(NSString*) convertTOStatus2Desc:(TOModelStatus)status {
    if(status == TOModelStatus_Runing){
        return @"Runing";
    }else if(status == TOModelStatus_ActYes){
        return @"ActYes";
    }else if(status == TOModelStatus_ActNo){
        return @"ActNo";
    }else if(status == TOModelStatus_ScoreNo){
        return @"ScoreNo";
    }else if(status == TOModelStatus_OuterBack){
        return @"OuterBack";
    }else if(status == TOModelStatus_Finish){
        return @"Finish";
    }else if(status == TOModelStatus_WithOut){
        return @"WithOut";
    }
    return STRFORMAT(@"Other(%ld)",status);
}

+(NSString*) convertATType2Desc:(AnalogyType)atType{
    if (atType == ATHav) return @"有";
    if (atType == ATNone) return @"无";
    if (atType == ATGreater) return @"大";
    if (atType == ATLess) return @"小";
    if (atType == ATSub) return @"坏";
    if (atType == ATPlus) return @"好";
    if (atType == ATDiff) return @"虚";
    if (atType == ATSame) return @"实";
    return @"普";
}

+(NSString*) convertTIStatus2Desc:(TIModelStatus)status{
    if(status == TIModelStatus_LastWait){
        return @"等待反馈";
    }else if(status == TIModelStatus_OutBackReason){
        return @"理性反馈";
    }else if(status == TIModelStatus_OutBackSameDelta){
        return @"同向反馈";
    }else if(status == TIModelStatus_OutBackNone){
        return @"无反馈";
    }
    return @"Default";
}

+(NSString*) convertCansetStatus2Desc:(CansetStatus)status{
    if(status == CS_None){
        return @"CS_None";
    }else if(status == CS_Besting){
        return @"CS_Besting";
    }else if(status == CS_Bested){
        return @"CS_Bested";
    }
    return @"CS_Other";
}

+(NSString*) convertClass2Desc:(Class)clazz{
    if ([ImvAlgsHungerModel.class isEqual:clazz]) {
        return @"饿";
    }else if ([ImvAlgsHurtModel.class isEqual:clazz]) {
        return @"疼";
    }
    return @"无";
}

+(NSString*) convertClassName2Desc:(NSString*)className {
    return [self convertClass2Desc:NSClassFromString(className)];
}

+(NSString*) convertMvp2DeltaDesc:(AIKVPointer*)mv_p{
    AICMVNodeBase *mv = [SMGUtils searchNode:mv_p];
    if (mv) {
        NSInteger delta = [NUMTOOK([AINetIndex getData:mv.delta_p]) integerValue];
        if (delta > 0) return @"↑";
        else if(delta < 0) return @"↓";
    }
    return @"⇅";
}

+(NSString*) convertSceneType2Desc:(SceneType)type simple:(BOOL)simple{
    if (type == SceneTypeI) return @"I";
    if (type == SceneTypeFather) return simple ? @"F" : @"Father";
    if (type == SceneTypeBrother) return simple ? @"B" : @"Brother";
    return @"";
}

+(NSString*) convertRect2Desc:(CGRect)rect {
    NSString *x = [self convertFloat2NoDotBackZeroStr:rect.origin.x];
    NSString *y = [self convertFloat2NoDotBackZeroStr:rect.origin.y];
    NSString *w = [self convertFloat2NoDotBackZeroStr:rect.size.width];
    NSString *h = [self convertFloat2NoDotBackZeroStr:rect.size.height];
    return STRFORMAT(@"<x%@ y%@ w%@ h%@>",x,y,w,h);
}

//float转str: 保留小数后三位，但去掉小数后末尾的0。
+(NSString*) convertFloat2NoDotBackZeroStr:(CGFloat)value {
    NSString *result = [NSString stringWithFormat:@"%.3f",value];
    if ([@".000" isEqualToString:SUBSTRFromIndex(result, result.length - 4)]) {
        result = SUBSTRToIndex(result, result.length - 4);
    } else if ([@"00" isEqualToString:SUBSTRFromIndex(result, result.length - 2)]) {
        result = SUBSTRToIndex(result, result.length - 2);
    } else if ([@"0" isEqualToString:SUBSTRFromIndex(result, result.length - 1)]) {
        result = SUBSTRToIndex(result, result.length - 1);
    }
    return result;
}

@end
