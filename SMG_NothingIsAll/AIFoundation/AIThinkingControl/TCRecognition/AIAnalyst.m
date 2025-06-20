//
//  AIAnalyst.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/6/10.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "AIAnalyst.h"

@implementation AIAnalyst

//MARK:===============================================================
//MARK:                     < Alg匹配度 (由TO调用) >
//MARK: @desc 目前写在AINetUtils.getNearData()中,回头看整理到此处;
//MARK:===============================================================

//MARK:===============================================================
//MARK:                     < Value相近度 (由TI调用) >
//MARK:===============================================================

/**
 *  MARK:--------------------比对稀疏码相近度--------------------
 *  @result 返回0到1 (0:稀疏码完全不同, 1稀疏码完全相同) (参考26127-TODO6);
 *  @param vInfo 为性能优化复用vInfo (为空时,此方法会自取);
 *  @version
 *      2023.03.13: 支持循环码时的相近度计算 (参考28174-todo2);
 *      2023.03.16: 修复首尾差值算错的BUG (因为测得360左右度和180左右度相近度是0.9以上);
 */
+(CGFloat) compareCansetValue:(AIKVPointer*)cansetV_p protoValue:(AIKVPointer*)protoV_p vInfo:(AIValueInfo*)vInfo {
    return [self compareCansetValue:cansetV_p protoValue:protoV_p vInfo:vInfo fromDataDic:nil];
}

+(CGFloat) compareCansetValue:(AIKVPointer*)cansetV_p protoValue:(AIKVPointer*)protoV_p vInfo:(AIValueInfo*)vInfo fromDataDic:(NSDictionary*)dataDic {
    //1. 取稀疏码值;
    double cansetData = [NUMTOOK([AINetIndex getData:cansetV_p fromDataDic:dataDic]) doubleValue];
    double protoData = [NUMTOOK([AINetIndex getData:protoV_p fromDataDic:dataDic]) doubleValue];
    
    //2. 计算相近度返回;
    return [self compareCansetValue:cansetData protoV:protoData at:cansetV_p.algsType ds:cansetV_p.dataSource isOut:protoV_p.isOut vInfo:vInfo];
}

+(CGFloat) compareCansetValue:(double)cansetV protoV:(double)protoV at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut vInfo:(AIValueInfo*)vInfo{
    //1. 数据准备;
    if (!vInfo) vInfo = [AINetIndex getValueInfo:at ds:ds isOut:isOut];
    if (vInfo.span == 0) return 1;
    double delta = [AINetIndexUtils deltaWithValueA:cansetV valueB:protoV at:at ds:ds vInfo:vInfo];
    
    //2. 循环时: 计算出nearV相近度 (参考28174-todo2);
    if (vInfo.loop) {
        return MAX(0, 1 - delta / (vInfo.span / 2));
    }
    
    //3. 线性时: 计算出nearV相近度 (参考25082-公式1);
    return MAX(0, 1 - delta / vInfo.span);
}

/**
 *  MARK:--------------------比对组码相近度--------------------
 */
+(CGFloat) compareGV:(double)assV protoV:(double)protoV at:(NSString*)at ds:(NSString*)ds minData:(float)minData maxData:(float)maxData itemIndex:(NSInteger)itemIndex {
    //1. 数据准备;
    AIValueInfo *vInfo = [AINetIndex getGVValueInfo:at ds:ds minData:minData maxData:maxData itemIndex:itemIndex];
    if (vInfo.span == 0) return 1;
    double delta = [AINetIndexUtils deltaWithValueA:assV valueB:protoV at:at ds:ds vInfo:vInfo];
    
    //2. 循环时: 计算出nearV相近度 (参考28174-todo2);
    if (vInfo.loop) {
        return 1 - delta / (vInfo.span / 2);
    }
    
    //3. 线性时: 计算出nearV相近度 (参考25082-公式1);
    return 1 - delta / vInfo.span;
}

@end
