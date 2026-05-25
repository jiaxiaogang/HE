//
//  AINetGroupValueIndex.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/27.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AINetGroupValueIndex.h"

@implementation AINetGroupValueIndex

+(NSArray*) gvIndexKeys:(NSString*)ds {
    return @[[self directionKey:ds], [self diffKey:ds], [self junKey:ds], [self sepKey:ds]];
}

+(NSString*) directionKey:(NSString*)ds {
    return STRFORMAT(@"%@_direction",ds);
}

+(NSString*) diffKey:(NSString*)ds {
    return STRFORMAT(@"%@_diff",ds);
}

+(NSString*) junKey:(NSString*)ds {
    return STRFORMAT(@"%@_jun",ds);
}

+(NSString*) sepKey:(NSString*)ds {
    return STRFORMAT(@"%@_sep",ds);
}

// 是否内征 (dataSource是否用于内征判断，用于GV帧间平缓逻辑)
+(BOOL) isInnerEigen:(NSString*)ds {
    return [ds hasSuffix:@"_diff"] || [ds hasSuffix:@"_jun"];
}

/**
 *  MARK:--------------------根据组节点取 三个索引的数据（参考34082-方案2）--------------------
 *  @param subDots MapModel类型: v1=colorValue v2=x(0-2) v3-y(0-2)
 *  @version
 *      2025.04.27: 降低精度，以尝试优化性能。
 */
+(NSDictionary*) convertGVIndexData:(NSArray*)subDots ds:(NSString*)ds {
    int jinDu = 6;
    if ([ds isEqual:@"hColors"]) {
        jinDu = 20;//色相辨识度
    } else if ([ds isEqual:@"sColors"]) {
        jinDu = 8;//饱和度辨识度
    } else if ([ds isEqual:@"bColors"]) {
        jinDu = 6;//亮度辨识度
    }
    
    //1. 单码取值。
    NSArray *contentNums = [SMGUtils convertArr:subDots convertBlock:^id(MapModel *obj) {
        return obj.v1;
    }];
    NSArray *xs = [SMGUtils convertArr:subDots convertBlock:^id(MapModel *obj) {
        return obj.v2;
    }];
    NSArray *ys = [SMGUtils convertArr:subDots convertBlock:^id(MapModel *obj) {
        return obj.v3;
    }];
    
    //2. 求平均值（参考34082-TODO3）。
    float sumNum = [SMGUtils sumOfArr:contentNums convertBlock:^double(NSNumber *obj) {
        return obj.floatValue;
    }];
    float pinJunNum = contentNums.count == 0 ? 0 : sumNum / contentNums.count;
    
    //3. >均值 和 <均值 的下标数组。
    NSMutableArray *smallIndexs = [NSMutableArray new];
    NSMutableArray *bigerIndexs = [NSMutableArray new];
    for (NSInteger i = 0; i < contentNums.count; i++) {
        float curContentValue = NUMTOOK(ARR_INDEX(contentNums, i)).floatValue;
        if (curContentValue < pinJunNum) {
            [smallIndexs addObject:@(i)];
        } else {
            [bigerIndexs addObject:@(i)];
        }
    }
    
    //3. 平均值精度。
    pinJunNum = roundf(pinJunNum * jinDu) / jinDu;
    
    // 分隔点：直接用小区占比来（参考37033-TODO1）。
    float sepValue = (float)smallIndexs.count / subDots.count;
    
    //3. 如果纯色，直接返回四个索引：均值、差值=0、方向=0、分隔点=0.5。
    if (smallIndexs.count == 0 || bigerIndexs.count == 0) {
        return @{[self directionKey:ds]: @(0),
                 [self diffKey:ds]: @(0),
                 [self junKey:ds]: @(pinJunNum),
                 [self sepKey:ds]: @(sepValue)};
    }
    
    //4. 差值：求出大小区各自的均值（参考34082-TODO2）。
    float bigerSumNum = [SMGUtils sumOfArr:bigerIndexs convertBlock:^double(NSNumber *obj) {
        NSInteger index = obj.integerValue;
        return NUMTOOK(ARR_INDEX(contentNums, index)).floatValue;
    }];
    float bigerPinJunNum = bigerIndexs.count > 0 ? bigerSumNum / bigerIndexs.count : 0;
    float smallSumNum = [SMGUtils sumOfArr:smallIndexs convertBlock:^double(NSNumber *obj) {
        NSInteger index = obj.integerValue;
        return NUMTOOK(ARR_INDEX(contentNums, index)).floatValue;
    }];
    float smallPinJunNum = smallIndexs.count > 0 ? smallSumNum / smallIndexs.count : bigerPinJunNum;
    
    //5. 差值：计算出差值（如果是循环的，则用循环的算法）。
    float diffPinJunNum = [CortexAlgorithmsUtil deltaOfCustomV1:bigerPinJunNum v2:smallPinJunNum max:1 min:0 loop:[CortexAlgorithmsUtil dsIsLoop:ds]];
    diffPinJunNum = roundf(diffPinJunNum * jinDu) / jinDu;
    
    //5. 方向：根据大小区中心点，算出方向（参考34082-TODO1）（按左上角为0,0点算，所以要加0.5表示xy坐标的中心点位置）。
    CGFloat bigerPinJunX = [SMGUtils sumOfArr:bigerIndexs convertBlock:^double(NSNumber *index) {
        return NUMTOOK(ARR_INDEX(xs, index.integerValue)).integerValue + 0.5;
    }] / bigerIndexs.count;
    CGFloat bigerPinJunY = [SMGUtils sumOfArr:bigerIndexs convertBlock:^double(NSNumber *index) {
        return NUMTOOK(ARR_INDEX(ys, index.integerValue)).integerValue + 0.5;
    }] / bigerIndexs.count;
    CGFloat smallPinJunX = [SMGUtils sumOfArr:smallIndexs convertBlock:^double(NSNumber *index) {
        return NUMTOOK(ARR_INDEX(xs, index.integerValue)).integerValue + 0.5;
    }] / smallIndexs.count;
    CGFloat smallPinJunY = [SMGUtils sumOfArr:smallIndexs convertBlock:^double(NSNumber *index) {
        return NUMTOOK(ARR_INDEX(ys, index.integerValue)).integerValue + 0.5;
    }] / smallIndexs.count;
    
    //6. 方向：将距离转成角度-PI -> PI (从左顺时针一圈为-3.14到3.14)。
    CGFloat rads = atan2f(smallPinJunY - bigerPinJunY,smallPinJunX - bigerPinJunX);
    float protoParam = (rads / M_PI + 1) / 2;//然后归1化
    float direction = roundf(protoParam * 360) / 360;//再然后保留10度精度

    //8. 创建四个索引的指针地址：均值、差值、方向、分隔点。
    return @{[self directionKey:ds]: @(direction),
             [self diffKey:ds]: @(diffPinJunNum),
             [self junKey:ds]: @(pinJunNum),
             [self sepKey:ds]: @(sepValue)};
}

//把0-1转成0-9
+(int) convertZeroOneToZeroNine:(CGFloat)zeroOne {
    return zeroOne == 1 ? 9 : (int)(zeroOne * 10);
}

@end
