//
//  TVUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/26.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TVUtil.h"
#import "TOModelVisionUtil.h"
#import "UnorderItemModel.h"
#import "TOMVisionItemModel.h"

@implementation TVUtil

/**
 *  MARK:--------------------获取所有帧工作记忆的两两更新比对--------------------
 *  @desc 注: 包括首帧时,也要和-1帧nil比对;
 *  @result notnull;
 *      1. 类型: DIC<K:后帧下标, V:变化数组>
 *      2. 范围: key范围为:"0 -> models.count-1";
 */
+(NSMutableDictionary*) getChange_List:(NSArray*)models {
    //1. 数据检查;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    if (!ARRISOK(models)) return result;
    
    //2. 两两比对;
    for (NSInteger b = 0; b < models.count; b++) {
        TOMVisionItemModel *itemB = ARR_INDEX(models, b);
        TOMVisionItemModel *itemA = ARR_INDEX(models, b - 1);
        NSArray *itemChanges = [self getChange_Item:itemA itemB:itemB];
        [result setObject:itemChanges forKey:@(b)];
    }
    return result;
}

/**
 *  MARK:--------------------获取两帧工作记忆的更新处--------------------
 *  @result itemB中新增的变化数 notnull;
 */
+(NSArray*) getChange_Item:(TOMVisionItemModel*)itemA itemB:(TOMVisionItemModel*)itemB{
    //1. 数据准备;
    NSArray *subsA = itemA ? [self collectAllSubTOModelByRoots:itemA.roots] : [NSArray new];
    NSArray *subsB = itemB ? [self collectAllSubTOModelByRoots:itemB.roots] : [NSArray new];
    
    //2. 将更新返回 (second包含 & first不包含);
    return [SMGUtils filterArr:subsB checkValid:^BOOL(id item) {
        return ![subsA containsObject:item];
    }];
}

//收集roots下面所有的枝叶 notnull;
+(NSMutableArray*) collectAllSubTOModelByRoots:(NSArray*)roots {
    //1. 数据准备;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    roots = ARRTOOK(roots);
    
    //2. 收集
    for (DemandModel *root in roots) {
        NSMutableArray *unorderModels = [TOModelVisionUtil convertCur2Sub2UnorderModels:root];
        [result addObjectsFromArray:[SMGUtils convertArr:unorderModels convertBlock:^id(UnorderItemModel *obj) {
            return obj.data;
        }]];
    }
    return result;
}

/**
 *  MARK:--------------------changeDic的变化总数--------------------
 *  @result 取值为1-length
 */
+(NSInteger) countOfChangeDic:(NSDictionary*)changeDic{
    //1. 数据准备;
    changeDic = DICTOOK(changeDic);
    NSInteger result = 0;
    
    //2. 累计changeCount;
    for (NSArray *value in changeDic.allValues) {
        result += MAX(1, value.count);
    }
    return result;
}

/**
 *  MARK:--------------------changeIndex转index--------------------
 *  @result 返回NSRange的第1位表示mainIndex,第2位表示subIndex
 *      1. 未找到结果时为-1;
 *      2. 其中mainIndex和subIndex的范围都是: 0 -> count-1;
 */
+(NSInteger) mainIndexOfChangeIndex:(NSInteger)changeIndex changeDic:(NSDictionary*)changeDic{
    return [self indexOfChangeIndex:changeIndex changeDic:changeDic].location;
}
+(NSInteger) subIndexOfChangeIndex:(NSInteger)changeIndex changeDic:(NSDictionary*)changeDic{
    return [self indexOfChangeIndex:changeIndex changeDic:changeDic].length;
}
+(NSRange) indexOfChangeIndex:(NSInteger)changeIndex changeDic:(NSDictionary*)changeDic {
    //1. 数据准备;
    changeDic = DICTOOK(changeDic);
    NSInteger sumChangeCount = 0;
    
    //2. 累计changeCount (key范围参考getChange_List()的key范围说明);
    for (NSInteger k = 0; k < changeDic.count; k++) {
        NSArray *value = [changeDic objectForKey:@(k)];
        
        //3. 目标为changeIndex+1,当前sum+valueCount小于目标时,说明仍未达到,累计并继续for向下找;
        if (sumChangeCount + MAX(1, value.count) < changeIndex + 1) {
            sumChangeCount += MAX(1, value.count);
        }else {
            
            //4. 否则,说明要找的目标就在当前key中;
            NSInteger mainIndex = k;
            NSInteger subIndex = value.count ? changeIndex - sumChangeCount : -1;
            return NSMakeRange(mainIndex, subIndex);
        }
    }
    return NSMakeRange(-1, -1);
}

+(NSString*) distanceYDesc:(CGFloat)distanceY{
    //1. 中间点是35,转成中间点为0;
    CGFloat centerDistanceY = distanceY - 50 + 15;
    
    //2. 出屏
    if(centerDistanceY < -ScreenHeight * 0.5f){
        return STRFORMAT(@"上出屏%.0f",centerDistanceY + ScreenHeight * 0.5f);
    }else if(centerDistanceY > ScreenHeight * 0.5f) {
        return STRFORMAT(@"下出屏%.0f",centerDistanceY - ScreenHeight * 0.5f);
    }
    
    //2. 屏内
    CGFloat yPos = [self onRoadDistanceY:distanceY];
    if (yPos > 1) {
        return STRFORMAT(@"路下%.1f",yPos);
    }else if (yPos > 0) {
        return STRFORMAT(@"偏下%.1f",yPos);
    }else if (yPos == 0) {
        return @"正中";
    }else if (yPos > -1) {
        return STRFORMAT(@"偏上%.1f",-yPos);
    }else{
        return STRFORMAT(@"路上%.1f",-yPos);
    }
}

/**
 *  MARK:--------------------路上的位置: 偏上或偏下--------------------
 *  @result -1到1 (正偏下,负偏上);
 */
+(CGFloat) onRoadDistanceY:(CGFloat)distanceY{
    //1. 中间点是35,转成中间点为0;
    CGFloat centerDistanceY = distanceY - 50 + 15;
    
    //2. 出路距离;
    CGFloat roadH = 100,birdH = 30;
    CGFloat outRoadDistance = (roadH + birdH) * 0.5f;
    
    //2. 偏上为0到-1,偏下为0到1 (0为中心,1和-1是路边缘点);
    CGFloat result = centerDistanceY / outRoadDistance;
    return result;
}

//MARK:===============================================================
//MARK:                     < 节点描述 >
//MARK:===============================================================

+(NSString*) getLightStr4Ps:(NSArray*)node_ps header:(BOOL)header{
    //1. 数据检查
    NSMutableString *result = [[NSMutableString alloc] init];
    node_ps = ARRTOOK(node_ps);
    
    //2. 拼接返回
    for (AIKVPointer *item_p in node_ps){
        NSString *str = [self getLightStr:item_p header:header];
        if (STRISOK(str)) {
            [result appendFormat:@"%@%@",str,PitIsValue(item_p) ? @"_" : @","];
        }
    }
    return SUBSTRToIndex(result, result.length - 1);
}

+(NSString*) getLightStr:(AIKVPointer*)node_p {
    return [self getLightStr:node_p header:true];
}
+(NSString*) getLightStr:(AIKVPointer*)node_p header:(BOOL)header{
    NSString *lightStr = @"";
    if (ISOK(node_p, AIKVPointer.class)) {
        if (PitIsValue(node_p)) {
            lightStr = [self getLightStr_ValueP:node_p];
        }else if (PitIsGroupValue(node_p)) {
            lightStr = @"";
        }else if (PitIsFeature(node_p)) {
            AIFeatureNode *tNode = [SMGUtils searchNode:node_p];
            lightStr = STRFORMAT(@"T%ld%@",tNode.pId,CLEANSTR(tNode.logDesc.allKeys));
        }else if (PitIsAlg(node_p)) {
            AIAlgNodeBase *algNode = [SMGUtils searchNode:node_p];
            if (algNode) {
                lightStr = [self getLightStr4Ps:algNode.content_ps header:header];
            }
        }else if(PitIsFo(node_p)){
            AIFoNodeBase *foNode = [SMGUtils searchNode:node_p];
            if (foNode) {
                lightStr = [self getLightStr4Ps:foNode.content_ps header:header];
            }
        }else if(PitIsMv(node_p)){
            CGFloat score = [AIScore score4MV:node_p ratio:1.0f];
            lightStr = STRFORMAT(@"%@%@%@",Mvp2DeltaStr(node_p),Class2Str(NSClassFromString(node_p.algsType)),Double2Str_NDZ(score));
        }
    }
    //2. 返回;
    if (header) lightStr = [self decoratorHeader:lightStr node_p:node_p];
    return lightStr;
}

//获取value_p的light描述;
+(NSString*) getLightStr_ValueP:(AIKVPointer*)value_p{
    if (!value_p) return @"";
    double value = [NUMTOOK([AINetIndex getData:value_p]) doubleValue];
    NSString *valueStr = [self getLightStr_Value:value algsType:value_p.algsType dataSource:value_p.dataSource];
    if ([@"sizeHeight" isEqualToString:value_p.dataSource]) {
        if (value == 30) {
            return @"鸟";
        }else if(value == 100) {
            return @"棒";
        }else if(value == 5) {
            return @"果";
        }
        return STRFORMAT(@"高%@",valueStr);
    }else if ([@"distanceY" isEqualToString:value_p.dataSource]) {
        return [TVUtil distanceYDesc:value];
    }else if([FLY_RDS isEqualToString:value_p.algsType]){
        return STRFORMAT(@"%@",valueStr);
    }else if([KICK_RDS isEqualToString:value_p.algsType]){
        return STRFORMAT(@"%@",valueStr);
    }
    return @"";//valueStr
}

//获取value的light描述;
+(NSString*) getLightStr_Value:(double)value algsType:(NSString*)algsType dataSource:(NSString*)dataSource{
    if([FLY_RDS isEqualToString:algsType]){
        return [NVHeUtil fly2Str:value];
    }else if([@"direction" isEqualToString:dataSource]){
        return [NVHeUtil direction2Str:value];
    }else if([KICK_RDS isEqualToString:dataSource]){
        return STRFORMAT(@"踢%@",[NVHeUtil fly2Str:value]);
    }
    return Double2Str_NDZ(value);
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
+(NSString*) decoratorHeader:(NSString*)lightStr node_p:(AIKVPointer*)node_p{
    NSString *pIdStr = node_p ? STRFORMAT(@"%ld",node_p.pointerId) : @"";
    if (PitIsAlg(node_p)) {
        return lightStr;
    }else if(PitIsFo(node_p)){
        return STRFORMAT(@"[%@]",lightStr);
    }else if(PitIsMv(node_p)){
        return STRFORMAT(@"M%@{%@}",pIdStr,lightStr);
    }
    return lightStr;
}

//MARK:===============================================================
//MARK:                     < UI与View相关 >
//MARK:===============================================================

/**
 *  MARK:--------------------点在框内--------------------
 */
+(BOOL) inRect:(CGRect)rect point:(CGPoint)point{
    BOOL inX = point.x >= CGRectGetMinX(rect) && point.x <= CGRectGetMaxX(rect);
    BOOL inY = point.y >= CGRectGetMinY(rect) && point.y <= CGRectGetMaxY(rect);
    return inX && inY;
}

/**
 *  MARK:--------------------特征日志--------------------
 *  @param sizeFenMu 尺寸分母，传1打印100%全尺寸，传2打印50%中尺寸，传3打印33%小尺寸。
 *  @version
 *      2025.04.14: 迭代v2-简化代码逻辑，直接针对rect来打印，不计算原来那套了，也不取GV了，直接rect在哪层，就打哪个字符。
 */
+(NSString*) getFeatureDesc:(AIKVPointer*)node_p sizeFenMu:(NSInteger)sizeFenMu {
    BOOL cSwitch = false;
    if (!cSwitch) return @"";
    
    //1. 只打BColors特征。
    //if ([node_p.dataSource isEqualToString:@"hColors"] || [node_p.dataSource isEqualToString:@"sColors"]) return @"";
    AIFeatureNode *tNode = [SMGUtils searchNode:node_p];
    
    //2. 找出最大level，避免打印的比原图像素过多或过少。
    NSInteger maxLevel = [SMGUtils filterBestScore:tNode.rects scoreBlock:^CGFloat(NSValue *item) {
        return VisionMaxLevel - [SMGUtils convertDotSize2Level:item.CGRectValue.size.width];
    }] + 1;//groupLevel+1才是真正的level
    
    //3. 需要打印的点字典。
    NSMutableDictionary *needLog = [self getFeatureNeedLogV2:tNode maxLevel:maxLevel];
    
    //4. 把需要打印的点字典转成多行多列图。
    NSMutableString *result = [[NSMutableString alloc] init];
    NSInteger width = powf(3, maxLevel);
    for (NSInteger y = 0; y < width; y++) {
        for (NSInteger x = 0; x < width; x++) {
            if (x % sizeFenMu != 0 || y % sizeFenMu != 0) continue;//日志打小点，太大太占地方。
            NSString *dot = [needLog objectForKey:STRFORMAT(@"%ld_%ld",x,y)];
            [result appendString:dot?dot:@". "];
        }
        if (y % sizeFenMu != 0) continue;//日志打小点，太大太占地方。
        [result appendString:@"\n"];
    }
    return result;
}

+(NSMutableDictionary*) getFeatureNeedLogV2:(AIFeatureNode*)tNode maxLevel:(NSInteger)maxLevel {
    //1. 数据准备。
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < tNode.count; i++) {
        //2. 取group的rect。
        CGRect groupRect = VALTOOK(ARR_INDEX(tNode.rects, i)).CGRectValue;
        
        //3. 根据level取表示这层的字符。
        NSInteger groupLevel = VisionMaxLevel - [SMGUtils convertDotSize2Level:groupRect.size.width];
        NSString *obj = nil;
        if (groupLevel == 0) {
            obj = @"* ";
        } else if (groupLevel == 1) {
            obj = @"- ";
        } else if (groupLevel == 2) {
            obj = @"  ";
        } else if (groupLevel == 3) {
            obj = @"o ";
        } else if (groupLevel == 4) {
            obj = @"+ ";
        } else {
            obj = @"x ";
        }
        
        //4. 多余层不打印处理（一张图的像素分辨率未必 > VisionMaxLevel层）。
        //============= 不展开打组码细节 =============
        //NSInteger maxLevel2GVMaxLevelRadio = powf(3, VisionMaxLevel - maxLevel);
        //NSInteger logWidth = groupRect.size.width / maxLevel2GVMaxLevelRadio;
        //NSInteger logMinX = groupRect.origin.x / maxLevel2GVMaxLevelRadio;
        //NSInteger logMinY = groupRect.origin.y / maxLevel2GVMaxLevelRadio;
        ////5. 需要打印的每个dot宽高每像素，都收集打印。
        //for (NSInteger x = logMinX; x < logWidth + logMinX; x++) {
        //    for (NSInteger y = logMinY; y < logWidth + logMinY; y++) {
        //        [result setObject:obj forKey:STRFORMAT(@"%ld_%ld",x,y)];
        //    }
        //}
        
        //============= 展开打组码细节 =============
        //5. 因为组码要展开打印，所以+1减少一层循环（用subDots的xy来加上）（不要组码时可去掉）。
        NSInteger maxLevel2GVMaxLevelRadio = powf(3, VisionMaxLevel - maxLevel);
        NSInteger size = groupRect.size.width / maxLevel2GVMaxLevelRadio;//像素宽（比如Mnist图为27）
        NSInteger marginX = groupRect.origin.x / maxLevel2GVMaxLevelRadio;//marginX
        NSInteger marginY = groupRect.origin.y / maxLevel2GVMaxLevelRadio;//marginY
        
        //6. 每个组码，都要再拆分成九格来打印（以提高精度）。
        NSMutableDictionary *subDots = [self getGroupValueNeedLog:ARR_INDEX(tNode.content_ps, i)];
        
        //7. 每个像素都循环到。
        for (NSInteger x = 0; x < size; x++) {
            for (NSInteger y = 0; y < size; y++) {
                
                //8. 将当前GV内的xy值，转成在整个特征中的realXY值。
                NSInteger realX = marginX + x;
                NSInteger realY = marginY + y;
                
                //9. 取当前xy在gv中的区间 (将27转成0-8=0,9-17=1,18-26=2。
                NSInteger xQuJian = x / (size / 3);
                NSInteger yQuJian = y / (size / 3);
                
                //10. 当前区间可显示，则显示，不可显示则continue。
                if (![subDots objectForKey:@"temp"]) continue;
                
                //10. 因为组码要展开打印，所以每点打三格，每格以实际+subDots.xy坐标来打印。
                [result setObject:obj forKey:STRFORMAT(@"%ld_%ld",realX,realY)];
            }
        }
    }
    return result;
}

/**
 *  MARK:--------------------把黑色xy数组返回--------------------
 */
+(NSMutableDictionary*) getGroupValueNeedLog:(AIKVPointer*)node_p {
    //不要组码时此处可直接返回@[x0y0]一条元素即可。
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    AIGroupValueNode *gNode = [SMGUtils searchNode:node_p];
    for (NSInteger i = 0; i < gNode.count; i++) {
        AIKVPointer *value_p = ARR_INDEX(gNode.content_ps, i);
        double value = [NUMTOOK([AINetIndex getData:value_p]) doubleValue];
        if (value > 0.3) [result setObject:@"" forKey:@"temp"];
    }
    return result;
}

@end
