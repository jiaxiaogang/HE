//
//  ThinkingUtils.m
//  SMG_NothingIsAll
//
//  Created by jia on 2018/3/23.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "ThinkingUtils.h"
#import "ImvGoodModel.h"
#import "ImvBadModel.h"
#import "ImvAlgsHungerModel.h"
#import "ImvAlgsHurtModel.h"

@implementation ThinkingUtils

@end


//MARK:===============================================================
//MARK:                     < ThinkingUtils (CMV) >
//MARK:===============================================================
@implementation ThinkingUtils (CMV)

+(BOOL) isBadWithAT:(NSString*)algsType{
    algsType = STRTOOK(algsType);
    if ([NSClassFromString(algsType) isSubclassOfClass:ImvBadModel.class]) {//饥饿感等
        return true;
    }else if ([NSClassFromString(algsType) isSubclassOfClass:ImvGoodModel.class]) {//爽感等;
        return false;
    }
    return false;
}

//是否有向下需求 (目标为下,但delta却+) (饿感上升)
+(BOOL) havDownDemand:(NSString*)algsType delta:(NSInteger)delta {
    BOOL isBad = [ThinkingUtils isBadWithAT:algsType];
    return isBad && delta > 0;
}

//是否有向上需求 (目标为上,但delta却-) (快乐下降)
+(BOOL) havUpDemand:(NSString*)algsType delta:(NSInteger)delta {
    BOOL isGood = ![ThinkingUtils isBadWithAT:algsType];
    return isGood && delta < 0;
}

//是否有任意需求 (坏增加 或 好减少);
+(BOOL) havDemand:(NSString*)algsType delta:(NSInteger)delta{
    return [self havDownDemand:algsType delta:delta] || [self havUpDemand:algsType delta:delta];
}
+(BOOL) havDemand:(AIKVPointer*)cmvNode_p{
    if (!cmvNode_p) return false;
    AICMVNodeBase *cmvNode = [SMGUtils searchNode:cmvNode_p];
    NSInteger delta = [NUMTOOK([AINetIndex getData:cmvNode.delta_p]) integerValue];
    return [self havDemand:cmvNode_p.algsType delta:delta];
}

+(MVDirection) getDemandDirection:(NSString*)algsType delta:(NSInteger)delta {
    BOOL downDemand = [self havDownDemand:algsType delta:delta];
    BOOL upDemand = [self havUpDemand:algsType delta:delta];
    if (downDemand) {
        return MVDirection_Negative;
    }else if(upDemand){
        return MVDirection_Positive;
    }else{
        return MVDirection_None;
    }
}

//获取索引方向 (有了索引方向后,可供目标方向取用)
+(MVDirection) getMvReferenceDirection:(NSInteger)delta {
    //目前的索引就仅是按照delta正负来构建的;
    if (delta < 0) return MVDirection_Negative;
    else if(delta > 0) return MVDirection_Positive;
    else return MVDirection_None;
}

/**
 *  MARK:--------------------解析algsMVArr--------------------
 *  cmvAlgsArr->mvValue
 */
+(void) parserAlgsMVArrWithoutValue:(NSArray*)algsArr success:(void(^)(AIKVPointer *delta_p,AIKVPointer *urgentTo_p,NSString *algsType))success{
    //1. 数据
    AIKVPointer *delta_p = nil;
    AIKVPointer *urgentTo_p = 0;
    NSString *algsType = DefaultAlgsType;
    
    //2. 数据检查
    for (AIKVPointer *pointer in algsArr) {
        if ([NSClassFromString(pointer.algsType) isSubclassOfClass:ImvAlgsModelBase.class]) {
            if ([@"delta" isEqualToString:pointer.dataSource]) {
                delta_p = pointer;
            }else if ([@"urgentTo" isEqualToString:pointer.dataSource]) {
                urgentTo_p = pointer;
            }
        }
        algsType = pointer.algsType;
    }
    
    //3. 逻辑执行
    if (success) success(delta_p,urgentTo_p,algsType);
}

//cmvAlgsArr->mvValue
+(void) parserAlgsMVArr:(NSArray*)algsArr success:(void(^)(AIKVPointer *delta_p,AIKVPointer *urgentTo_p,NSInteger delta,NSInteger urgentTo,NSString *algsType))success{
    //1. 解析
    [self parserAlgsMVArrWithoutValue:algsArr success:^(AIKVPointer *delta_p, AIKVPointer *urgentTo_p, NSString *algsType) {
        
        //2. 转换格式
        NSInteger delta = [NUMTOOK([AINetIndex getData:delta_p]) integerValue];
        NSInteger urgentTo = [NUMTOOK([AINetIndex getData:urgentTo_p]) integerValue];
        
        //3. 回调
        if (success) success(delta_p,urgentTo_p,delta,urgentTo,algsType);
    }];
}

//判断mv是否为持续价值 (比如:饥饿是持续性,疼痛是单发的) (参考32041-TODO1);
+(BOOL) isContinuousWithAT:(NSString*)algsType {
    algsType = STRTOOK(algsType);
    if ([NSStringFromClass(ImvAlgsHungerModel.class) isEqualToString:algsType]) {//持续价值:饿感等;
        return true;
    }else if ([NSStringFromClass(ImvAlgsHurtModel.class) isEqualToString:algsType]) {//单发价值:痛感等;
        return false;
    }
    return false;
}

//判断当前节点的父RDemand任务是不是持续性价值;
+(BOOL) baseRDemandIsContinuousWithAT:(TOModelBase*)subModel {
    ReasonDemandModel *baseRDemand = [SMGUtils filterSingleFromArr:[TOUtils getBaseOutModels_AllDeep:subModel] checkValid:^BOOL(id item) {
        return ISOK(item, ReasonDemandModel.class);
    }];
    if (!baseRDemand) return false;
    return [ThinkingUtils isContinuousWithAT:baseRDemand.algsType];
}

@end


//MARK:===============================================================
//MARK:                     < ThinkingUtils (In) >
//MARK:===============================================================
@implementation ThinkingUtils (In)

+(BOOL) dataIn_CheckMV:(NSArray*)algResult_ps{
    for (AIKVPointer *pointer in ARRTOOK(algResult_ps)) {
        if ([NSClassFromString(pointer.algsType) isSubclassOfClass:ImvAlgsModelBase.class]) {
            return true;
        }
    }
    return false;
}

/**
 *  MARK:--------------------在主线程跑act--------------------
 */
+(void) runAtTiThread:(Act0)act {
    [self runAtThread:theTC.tiQueue act:act];
}
+(void) runAtToThread:(Act0)act {
    [self runAtThread:theTC.toQueue act:act];
}
+(void) runAtMainThread:(Act0)act {
    [self runAtThread:dispatch_get_main_queue() act:act];
}
+(void) runAtThread:(dispatch_queue_t)queue act:(Act0)act {
    __block Act0 weakAct = act;
    dispatch_async(queue, ^{
        weakAct();
    });
}

+(NSMutableDictionary*) copySPDic:(NSDictionary*)protoSPDic {
    protoSPDic = DICTOOK(protoSPDic);
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for (id key in protoSPDic.allKeys) {
        AISPStrong *value = [protoSPDic objectForKey:key];
        [result setObject:value.copy forKey:key];
    }
    return result;
}

/**
 *  MARK:--------------------按绝对xy坐标对InputGroupValueModels进行排序--------------------
 */
+(NSArray*) sortInputGroupValueModels:(NSArray*)models levelNum:(NSInteger)levelNum {
    //1. 数据检查：当levelNum未知时，传-1，此时默认为最大层级。
    if (levelNum < 0) levelNum = VisionMaxLevel;
    
    //2. 分别按x/y排序，然后转成排好的index数组返回。
    return [SMGUtils sortSmall2Big:models compareBlock1:^double(InputGroupValueModel *obj) {
        NSInteger radio = powf(3, levelNum - obj.level);//差几层，就乘3的几次方。
        return obj.y * radio;//把x,y都换算到maxLevel层，因为同层的位置才是等价的。
    } compareBlock2:^double(InputGroupValueModel *obj) {
        NSInteger radio = powf(3, levelNum - obj.level);//差几层，就乘3的几次方。
        return obj.x * radio;//把x,y都换算到maxLevel层，因为同层的位置才是等价的。
    } compareBlock3:^double(InputGroupValueModel *obj) {
        return obj.level;
    }];
}

/**
 *  MARK:--------------------计算assTo是否在其该出现的位置（返回符合度）--------------------
 *  @desc 公式：推测下一组码的xy位置 : 与真实assTo的xy位置比较 = 得出位置符合预期程度（参考34053-新方案）。
 *  @version
 *      2025.04.10: v2-改为用rect来计算位置符合度（参考34133）。
 *  @result 为保证精度准确，结果以最大粒度层的绝对坐标进行返回。
 */
+(CGFloat) checkAssToMatchDegree:(AIFeatureNode*)protoFeature protoIndex:(NSInteger)protoIndex assGVModels:(NSArray*)assGVModels checkRefPort:(AIPort*)checkRefPort debugMode:(BOOL)debugMode {
    //1. 取出上个ass匹配帧;
    AIFeatureNextGVRankItem *lastAssModel = ARR_INDEX_REVERSE(assGVModels, 0);
    if (!lastAssModel) return 1;
    CGPoint assFrom = CGPointMake(lastAssModel.refPort.x, lastAssModel.refPort.y);
    NSInteger assToLevel = checkRefPort.level;
    NSInteger assToX = checkRefPort.x;
    NSInteger assToY = checkRefPort.y;
    
    //2. 取出lastProto;
    NSInteger lastProtoIndex = lastAssModel.matchOfProtoIndex;
    CGPoint protoFrom = CGPointMake(NUMTOOK(ARR_INDEX(protoFeature.xs, lastProtoIndex)).integerValue, NUMTOOK(ARR_INDEX(protoFeature.ys, lastProtoIndex)).integerValue);
    CGPoint protoTo = CGPointMake(NUMTOOK(ARR_INDEX(protoFeature.xs, protoIndex)).integerValue, NUMTOOK(ARR_INDEX(protoFeature.ys, protoIndex)).integerValue);
    NSInteger protoFromLevel = NUMTOOK(ARR_INDEX(protoFeature.levels, lastProtoIndex)).integerValue;
    NSInteger protoToLevel = NUMTOOK(ARR_INDEX(protoFeature.levels, protoIndex)).integerValue;
    
    //3. 计算checkRefPort对于当前assGVModels来说,是否符合位置;
    return [self checkAssToMatchDegree:protoFrom protoFromLevel:protoFromLevel protoTo:protoTo protoToLevel:protoToLevel assFrom:assFrom assFromLevel:lastAssModel.refPort.level assTo:CGPointMake(assToX, assToY) assToLevel:assToLevel debugMode:debugMode];
}

+(CGFloat) checkAssToMatchDegree:(CGPoint)protoFrom protoFromLevel:(NSInteger)protoFromLevel
                         protoTo:(CGPoint)protoTo protoToLevel:(NSInteger)protoToLevel
                         assFrom:(CGPoint)assFrom assFromLevel:(NSInteger)assFromLevel
                           assTo:(CGPoint)assTo assToLevel:(NSInteger)assToLevel debugMode:(BOOL)debugMode {
    //1. 求出proto在最大粒度层的xy差值。
    NSInteger protoFromRadio = powf(3, VisionMaxLevel - protoFromLevel);
    NSInteger protoToRadio = powf(3, VisionMaxLevel - protoToLevel);
    CGFloat deltaX = protoTo.x * protoToRadio - protoFrom.x * protoFromRadio;
    CGFloat deltaY = protoTo.y * protoToRadio - protoFrom.y * protoFromRadio;
    
    //2. 根据assFrom的坐标，和上面求出的差值，推测assTo应该出现的位置范围。
    NSInteger assFromRadio = powf(3, VisionMaxLevel - assFromLevel);
    CGFloat assFromX = assFrom.x * assFromRadio;
    CGFloat assFromY = assFrom.y * assFromRadio;
    
    //2025.03.22: BUG：为避免：像x81,y162,w54,h-54这种wh有为负的情况，当h为负时，转为绝对值，然后把y减掉这个宽高（w为负亦然）。
    CGFloat w = deltaX * 2, h = deltaY * 2;
    if (w < 0) {
        w = -w;
        assFromX -= w;
    }
    if (h < 0) {
        h = -h;
        assFromY -= h;
    }
    
    //3. 求出assTo应该出现的合理范围（移一倍deltaXY相当于从assFrom到精准推测的assTo中心点，再延伸了一倍deltaXY距离，相当于围绕精准推测位置，画一个deltaXY的范围矩形）。
    //> 所以真实的assTo出现在这个范围矩形的：中心准确=100%，边缘为0%）。
    CGRect targetRect = CGRectMake(assFromX, assFromY, w, h);
    
    //4. 真实assTo的位置。
    NSInteger assToRadio = powf(3, VisionMaxLevel - assToLevel);
    CGFloat assToX = assTo.x * assToRadio;
    CGFloat assToY = assTo.y * assToRadio;
    CGPoint assToPoint = CGPointMake(assToX, assToY);
    
    //5. 判断下是否在合理范围内，并算出符合度。
    //6. 计算targetRect的中心点
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(targetRect), CGRectGetMidY(targetRect));
    
    //7. 计算assToPoint到中心点的距离
    CGFloat distanceX = fabs(assToPoint.x - centerPoint.x);
    CGFloat distanceY = fabs(assToPoint.y - centerPoint.y);
    
    //8. 计算从中心到边缘的最大距离
    CGFloat maxDistanceX = targetRect.size.width / 2.0f;
    CGFloat maxDistanceY = targetRect.size.height / 2.0f;
    
    //9. 如果点在矩形外,返回空矩形
    if (distanceX > maxDistanceX || distanceY > maxDistanceY) {
        if (debugMode) NSLog(@"出界返0：protoFrom:%.0f,%.0f -> to:%.0f,%.0f \t assFrom:%.0f,%.0f -> to:%.0f,%.0f",protoFrom.x,protoFrom.y,protoTo.x,protoTo.y,assFrom.x,assFrom.y,assTo.x,assTo.y);
        return 0;
    }
    
    //10. 计算x和y方向上的符合度(0-1之间)
    CGFloat matchX = 1.0f - (maxDistanceX == 0 ? 0 : (distanceX / maxDistanceX));
    CGFloat matchY = 1.0f - (maxDistanceY == 0 ? 0 : (distanceY / maxDistanceY));
    
    //11. 取x,y方向符合度的平均值作为总体符合度
    CGFloat matchDegree = (matchX + matchY) / 2.0f;
    
    //12. 返回结果矩形,使用符合度作为宽高
    if (debugMode) NSLog(@"符合度%.2f：protoFrom:%.0f,%.0f -> to:%.0f,%.0f \t assFrom:%.0f,%.0f -> to:%.0f,%.0f",matchDegree,protoFrom.x,protoFrom.y,protoTo.x,protoTo.y,assFrom.x,assFrom.y,assTo.x,assTo.y);
    return matchDegree;
}

+(CGFloat) checkAssToMatchDegreeV2:(AIFeatureNode*)protoFeature protoIndex:(NSInteger)protoIndex assGVModels:(NSArray*)assGVModels checkRefPort:(AIPort*)checkRefPort debugMode:(BOOL)debugMode {
    //1. 取出上个ass匹配帧 & 取出lastProtoIndex;
    AIFeatureNextGVRankItem *lastAssModel = ARR_INDEX_REVERSE(assGVModels, 0);
    if (!lastAssModel) return 1;
    NSInteger lastProtoIndex = lastAssModel.matchOfProtoIndex;
    
    //2. 取出protoFromToRect & assFromToRect。
    CGRect assFromRect = lastAssModel.refPort.rect;
    CGRect assToRect = checkRefPort.rect;
    CGRect protoFromRect = NUMTOOK(ARR_INDEX(protoFeature.rects, lastProtoIndex)).CGRectValue;
    CGRect protoToRect = NUMTOOK(ARR_INDEX(protoFeature.rects, protoIndex)).CGRectValue;
    
    //10. 计算checkRefPort对于当前assGVModels来说,是否符合位置;
    //11. 求出proto在最小粒度层的xy差值。
    CGFloat deltaX = protoToRect.origin.x - protoFromRect.origin.x;
    CGFloat deltaY = protoToRect.origin.y - protoFromRect.origin.y;
    
    //12. 根据assFrom的坐标，和上面求出的差值，推测assTo应该出现的位置范围。
    CGFloat assFromX = assFromRect.origin.x;
    CGFloat assFromY = assFromRect.origin.y;
    
    //21. 2025.03.22: BUG：为避免：像x81,y162,w54,h-54这种wh有为负的情况，当h为负时，转为绝对值，然后把y减掉这个宽高（w为负亦然）。
    CGFloat w = deltaX * 2, h = deltaY * 2;
    if (w < 0) {
        w = -w;
        assFromX -= w;
    }
    if (h < 0) {
        h = -h;
        assFromY -= h;
    }
    
    //22. 求出assTo应该出现的合理范围（移一倍deltaXY相当于从assFrom到精准推测的assTo中心点，再延伸了一倍deltaXY距离，相当于围绕精准推测位置，画一个deltaXY的范围矩形）。
    //> 所以真实的assTo出现在这个范围矩形的：中心准确=100%，边缘为0%）。
    CGRect targetRect = CGRectMake(assFromX, assFromY, w, h);
    
    //23. 真实assTo的位置。
    CGPoint assToPoint = assToRect.origin;
    
    //24. 判断下是否在合理范围内，并算出符合度。
    //24. 计算targetRect的中心点
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(targetRect), CGRectGetMidY(targetRect));
    
    //31. 计算assToPoint到中心点的距离
    CGFloat distanceX = fabs(assToPoint.x - centerPoint.x);
    CGFloat distanceY = fabs(assToPoint.y - centerPoint.y);
    
    //32. 计算从中心到边缘的最大距离
    CGFloat maxDistanceX = targetRect.size.width / 2.0f;
    CGFloat maxDistanceY = targetRect.size.height / 2.0f;
    
    //33. 如果点在矩形外,返回空矩形
    if (distanceX > maxDistanceX || distanceY > maxDistanceY) {
        if (debugMode) NSLog(@"出界返0：protoFrom:%.0f,%.0f -> to:%.0f,%.0f \t assFrom:%.0f,%.0f -> to:%.0f,%.0f",protoFromRect.origin.x,protoFromRect.origin.y,protoToRect.origin.x,protoToRect.origin.y,assFromRect.origin.x,assFromRect.origin.y,assToRect.origin.x,assToRect.origin.y);
        return 0;
    }
    
    //41. 计算x和y方向上的符合度(0-1之间)
    CGFloat matchX = 1.0f - (maxDistanceX == 0 ? 0 : (distanceX / maxDistanceX));
    CGFloat matchY = 1.0f - (maxDistanceY == 0 ? 0 : (distanceY / maxDistanceY));
    
    //42. 取x,y方向符合度的平均值作为总体符合度
    CGFloat matchDegree = (matchX + matchY) / 2.0f;
    
    //43. 返回结果矩形,使用符合度作为宽高
    if (debugMode) NSLog(@"符合度%.2f：protoFrom:%.0f,%.0f -> to:%.0f,%.0f \t assFrom:%.0f,%.0f -> to:%.0f,%.0f",matchDegree,protoFromRect.origin.x,protoFromRect.origin.y,protoToRect.origin.x,protoToRect.origin.y,assFromRect.origin.x,assFromRect.origin.y,assToRect.origin.x,assToRect.origin.y);
    return matchDegree;
}

@end
