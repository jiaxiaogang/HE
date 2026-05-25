//
//  TCRecognitionUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2023/5/30.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import "TCRecognitionUtil.h"

@implementation TCRecognitionUtil

/**
 *  MARK:--------------------获取V重要性字典 (参考29105 & 29106)--------------------
 *  @result 返回结果为重要性字典<K:稀疏码标识,V:重要性值> & 做了最小值1的缩放处理 (参考29107-步骤1);
 *  @version
 *      2023.06.02: 优化vInfo在循环中,导致的性能问题,把vInfo移到尽可以循环外,然后传进去复用后性能ok (参考29109-测得2);
 *      2023.06.12: 优化取得同级场景的条数,避免条数太多导致卡 (参考30022-优化3);
 */
+(NSDictionary*) getVImportanceDic:(AIShortMatchModel*)inModel {
    //1. 数据准备;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    BOOL debugMode = false;
    NSMutableDictionary *cutIndexOfConFo = [[NSMutableDictionary alloc] init]; //收集所有同级fo的cutIndex
    
    //2. 逐个收集pFos的同级(抽象的具象)->抽象部分 (参考29105-方案改);
    NSMutableArray *allConPorts1 = [self collectAbsFosThenConFos:inModel.matchPFos outCutIndexDic:cutIndexOfConFo];
    
    //6. 排序,并取前20% (参考29105-todo2);
    NSArray *sortOfStrong3 = [SMGUtils sortBig2Small:allConPorts1 compareBlock:^double(AIPort *obj) {
        return obj.strong.value;
    }];
    NSInteger goodLimit = MIN(30, sortOfStrong3.count * 0.2f);
    NSArray *goodPorts4 = ARR_SUB(sortOfStrong3, 0, goodLimit);
    
    //7. 分别根据protoV找到在goodPorts4中最相近的那一条,最接近那条的强度即算做protoV的强度 (参考29105-todo3-方案4);
    NSMutableString *zunjieLog = [[NSMutableString alloc] init];
    for (AIKVPointer *protoV_p in inModel.protoAlg.content_ps) {
        //8. 节约性能: 全程只有一个固定值的打酱油码,不做处理 (参考29105-todo4);
        AIValueInfo *info = [AINetIndex getValueInfo:protoV_p.algsType ds:protoV_p.dataSource isOut:protoV_p.isOut];
        if (info.span == 0) continue;
        
        //9. 求出全部xy轴;
        NSDictionary *xyDic = [self convertConFoPorts2XYDic:goodPorts4 cutIndexDic:cutIndexOfConFo protoV:protoV_p];
        if (!DICISOK(xyDic)) continue;
        
        //10. 均匀取样100份,求出平均值 (参考29106-解均值);
        double sumTemplateY = 0;//所有样本总Y值;
        NSMutableArray *quXianYArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < 100; i++) {
            double itemSpan = info.span / 100;
            double curX = (i + 0.5f) * itemSpan;
            CGFloat curY = [self getY:xyDic checkX:curX at:protoV_p.algsType ds:protoV_p.dataSource isOut:protoV_p.isOut vInfo:info];
            sumTemplateY += curY;
            [quXianYArr addObject:@(curY)];
        }
        double averageY = sumTemplateY / 100;
        
        //11. 根据protoV的值,求出protoV的Y轴强度值;
        double protoV = NUMTOOK([AINetIndex getData:protoV_p]).doubleValue;
        CGFloat protoY = [self getY:xyDic checkX:protoV at:protoV_p.algsType ds:protoV_p.dataSource isOut:protoV_p.isOut vInfo:info];
        
        //12. debugLog
        //for (AIPort *conFoPort in goodPorts4) NSLog(@"\t\t > conFo: %@ 强度%ld",Pit2FStr(conFoPort.target_p),conFoPort.strong.value);
        int maxY = (int)protoY;
        for (NSNumber *item in quXianYArr) {
            if (maxY < (int)item.doubleValue) maxY = (int)item.doubleValue;
        }
        for (int row = maxY; row >= 1; row--) {//一行行打印
            NSMutableString *line = [[NSMutableString alloc] init];
            if (row % 2 == 1) continue;//高度缩小为50%;
            for (int column = 0; column < quXianYArr.count; column++) {
                int quXianY = NUMTOOK(ARR_INDEX(quXianYArr, column)).doubleValue;
                double protoX = (protoV / info.span) * 100; //protoX需要由真实v值,转为0-100的x轴值;
                BOOL isProto = fabs(row - protoY) <= 2 && fabs(column - protoX) <= 1;//放大proto点打印(更显眼)
                BOOL border = column == 0;
                NSString *spc = isProto ? @"●" : border ? @"|" : @" ";
                NSString *dot = isProto ? @"●" : row / 2 == ((int)averageY) / 2 ? @"-" : @"o";
                [line appendString:quXianY >= row ? dot : spc];
            }
            if (debugMode) NSLog(@"%@",line);
        }
        
        //13. 算出当前码的重要性 (参考29105-todo5);
        double vImportance = protoY / averageY;
        if (debugMode) NSLog(@"------------------------------------------ %@ 重要性:%.3f ------------------------------------------\n",Pit2FStr(protoV_p),vImportance);
        [zunjieLog appendFormat:@"%@ = %.3f; ",Pit2FStr(protoV_p),vImportance];
        [result setObject:@(vImportance) forKey:protoV_p.identifier];
    }
    NSLog(@"重要性结果: %@",zunjieLog);
    
    //14. 缩放处理并返回 (参考29107-步骤1);
    return [self scala4ImportanceDic:result];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------收集pFos的同层fos (抽象后具象)--------------------
 *  @param outCutIndexDic 将结果对应的cutIndex也返回;
 *  @version
 *      2023.06.11: 返回结果防重,提前防重性能好 (参考30022-优化1);
 *  @result notnull
 */
+(NSMutableArray*) collectAbsFosThenConFos:(NSArray*)pFoModels outCutIndexDic:(NSMutableDictionary*)outCutIndexDic{
    //1. 数据检查;
    BOOL debugMode = false;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    pFoModels = ARRTOOK(pFoModels);
    
    //2. 依次对pFo取同层;
    for (AIMatchFoModel *pFoM in pFoModels) {
        AIFoNodeBase *pFo = [SMGUtils searchNode:pFoM.matchFo];
        NSArray *abs_ps = Ports2Pits([AINetUtils absPorts_All:pFo]);
        if (debugMode) NSLog(@"from pFo: %@",Fo2FStr(pFo));
        for (AIKVPointer *abs_p in abs_ps) {
            //3. 判断抽象中有对应的cutIndex帧;
            NSDictionary *indexDic = [pFo getAbsIndexDic:abs_p];
            NSNumber *absCutIndexKey = ARR_INDEX([indexDic allKeysForObject:@(pFoM.cutIndex)], 0);
            if (!absCutIndexKey) continue;
            
            //4. 逐个收集pFos的同级(抽象的具象)->具象部分 (参考29105-方案改);
            AIFoNodeBase *absFo = [SMGUtils searchNode:abs_p];
            if (!absFo.cmvNode_p) continue;//无mv指向则略过;
            if (debugMode) NSLog(@"\t > absFo: %@->%@",Pit2FStr(abs_p),Pit2FStr(absFo.cmvNode_p));
            NSArray *conPorts = [AINetUtils conPorts_All:absFo];
            for (AIPort *conPort in conPorts) {
                //4. 防重 (根据outCutIndexDic防重,性能更好) (参考29105-todo1);
                if ([outCutIndexDic objectForKey:@(conPort.target_p.pointerId)]) continue;
                
                //4. 防无效;
                NSDictionary *indexDic2 = [absFo getConIndexDic:conPort.target_p];
                NSNumber *conCutIndexValue = [indexDic2 objectForKey:absCutIndexKey];
                if (!conCutIndexValue) continue;
                
                //5. 分别收集同级port,和记录它的conCutIndex;
                [outCutIndexDic setObject:conCutIndexValue forKey:@(conPort.target_p.pointerId)];
                [result addObject:conPort];
            }
        }
    }
    return result;
}

/**
 *  MARK:--------------------将conFoPorts转成xy轴数据 (x轴为v值,y轴为强度) (参考29106-解曲线)--------------------
 *  @version
 *      2023.06.12: 性能优化,将protoDataDic和protoIdentifier在for循环外复用 (参考30022);
 */
+(NSDictionary*) convertConFoPorts2XYDic:(NSArray*)conFoPorts cutIndexDic:(NSDictionary*)cutIndexDic protoV:(AIKVPointer*)protoV_p {
    //1. 数据准备;
    BOOL debugMode = false;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSDictionary *protoDataDic = [AINetIndexUtils searchDataDic:protoV_p.algsType ds:protoV_p.dataSource isOut:protoV_p.isOut];//为性能,在for中复用
    NSString *protoIdentifier = protoV_p.identifier;//为性能,在for中复用
    
    //2. 转成conFo中对应的概念帧conAlg;
    for (AIPort *conFoPort in conFoPorts) {
        AIFoNodeBase *conFo = [SMGUtils searchNode:conFoPort.target_p];
        NSInteger conCutIndex = NUMTOOK([cutIndexDic objectForKey:@(conFo.pId)]).integerValue;
        AIKVPointer *conAlg_p = ARR_INDEX(conFo.content_ps, conCutIndex);
        AIAlgNodeBase *conAlg = [SMGUtils searchNode:conAlg_p];
        
        //3. 在conAlg中找着同区码 (用来取xy轴);
        AIKVPointer *findSameIdenConValue_p = [SMGUtils filterSingleFromArr:conAlg.content_ps checkValid:^BOOL(AIKVPointer *conValue_p) {
            return [protoIdentifier isEqualToString:conValue_p.identifier];
        }];
        if (!findSameIdenConValue_p) continue;
        
        //4. 得出xy轴值,用于计算特征强度曲线 (参考29106-解曲线);
        double x = NUMTOOK([AINetIndex getData:findSameIdenConValue_p fromDataDic:protoDataDic]).doubleValue;
        NSInteger y = conFoPort.strong.value;
        [result setObject:@(y) forKey:@(x)];
    }
    return result;
}

/**
 *  MARK:--------------------根据xyDic和x值计算出y值 (参考29106-解曲线)--------------------
 *  @param vInfo notnull 为性能好,提前取好valueInfo传过来复用;
 *  @version
 *      2023.05.30: 增强竞争: 将辐射由50%改为33%,环境温度由30%改为10% (参考29106-todo7.1);
 *      2023.05.30: 增强竞争: 加上可视化曲线后,边调整边看曲线,调整为辐射50%,环境温度5% (后再激烈点,调成3%);
 */
+(CGFloat) getY:(NSDictionary*)xyDic checkX:(double)checkX at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut vInfo:(AIValueInfo*)vInfo{
    CGFloat resultY = 0;
    for (NSNumber *key in xyDic.allKeys) {
        //1. 数据准备;
        double templateX = key.doubleValue;
        NSInteger y = NUMTOOK([xyDic objectForKey:key]).integerValue;
        
        //2. 已冷却时长;
        double delta = [AINetIndexUtils deltaWithValueA:templateX valueB:checkX at:at ds:ds vInfo:vInfo];
        
        //3. span的50%时冷却完成,环境温度30% (参考29106-解曲线);
        CGFloat cooledValue = [MathUtils getCooledValue:vInfo.span / 4 pastTime:delta finishValue:0.005f];
        
        //4. 将checkX的强度值累计起来,用于返回;
        resultY += y * cooledValue;
    }
    return resultY;
}

/**
 *  MARK:--------------------字典缩放处理--------------------
 *  @desc 缩放至最小值为1 (参考29107-步骤1);
 */
+(NSDictionary*) scala4ImportanceDic:(NSDictionary*)importanceDic {
    //1. 数据检查;
    importanceDic = DICTOOK(importanceDic);
    
    //2. 缩放重要性字典: 找到最小值 (参考29107-步骤1);
    double min = MAXFLOAT;
    for (NSNumber *value in importanceDic.allValues) {
        if (min > value.doubleValue) min = value.doubleValue;
    }
    
    //3. 缩放重要性字典: 缩放至最小值为1 (参考29107-步骤1);
    for (NSString *key in importanceDic.allKeys) {
        double value = NUMTOOK([importanceDic objectForKey:key]).doubleValue;
        [importanceDic setValue:@(value / min) forKey:key];
    }
    return importanceDic;
}

/**
 *  MARK:--------------------GT定责末尾淘汰（参考37071）。--------------------
 *  @status 关闭：四项分别定责过滤的太狠，四项综合定责，与GT竞争因子综合竞争功能又重复了，所以关掉。
 */
+(NSMutableArray*) filter4ZonHe:(NSMutableArray*)allGTGroups {
    // 取整体均值。
    CGFloat jun1 = allGTGroups.count == 0 ? 0 : [SMGUtils sumOfArr:allGTGroups convertBlock:^double(GTZiJvModelV2 *gtModel) {
        return gtModel.gtMatchValue;
    }] / allGTGroups.count;
    CGFloat jun2 = allGTGroups.count == 0 ? 0 : [SMGUtils sumOfArr:allGTGroups convertBlock:^double(GTZiJvModelV2 *gtModel) {
        return gtModel.allBestCount;
    }] / allGTGroups.count;
    CGFloat jun3 = allGTGroups.count == 0 ? 0 : [SMGUtils sumOfArr:allGTGroups convertBlock:^double(GTZiJvModelV2 *gtModel) {
        return gtModel.matchCountRatioV2;
    }] / allGTGroups.count;

    // 按责任淘汰。
    allGTGroups = [SMGUtils filterArr:allGTGroups checkValid:^BOOL(GTZiJvModelV2 *gtModel) {
        return [TCLearningUtil noZeRenForPingJun:gtModel.gtMatchValue bigerMatchValue:jun1];
    }];
    allGTGroups = [SMGUtils filterArr:allGTGroups checkValid:^BOOL(GTZiJvModelV2 *gtModel) {
        return [TCLearningUtil noZeRenForPingJun:gtModel.allBestCount bigerMatchValue:jun2];
    }];
    allGTGroups = [SMGUtils filterArr:allGTGroups checkValid:^BOOL(GTZiJvModelV2 *gtModel) {
        return [TCLearningUtil noZeRenForPingJun:gtModel.matchCountRatioV2 bigerMatchValue:jun3];
    }];
    return allGTGroups;
}

@end
