//
//  ImgTrainerPreview.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/27.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "ImgTrainerPreview.h"
#import "HSBColor.h"

@implementation ImgTrainerPreview

-(id) init {
    self = [super init];
    if (self) {
        [self initView];
        [self initData];
        [self initDisplay];
    }
    return self;
}

-(void) initView {
    //self
    [self setFrame:CGRectMake(0, 0, 100, 115)];
    [self.layer setBorderWidth:1];
    [self.layer setBorderColor:UIColor.redColor.CGColor];

    //lab
    self.lab = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, 100, 15)];
    [self.lab setFont:[UIFont boldSystemFontOfSize:8]];
    [self.lab setBackgroundColor:UIColor.blueColor];
    [self.lab setTextColor:UIColor.whiteColor];
    [self.lab setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:self.lab];
    
    //透明图层
    for (NSInteger i = 0; i < 20; i++) {
        for (NSInteger j = 0; j < 20; j++) {
            if (i % 2 == j % 2) {
                UIView *block = [[UIView alloc] initWithFrame:CGRectMake(i * 5, j * 5, 5, 5)];
                [block setBackgroundColor:UIColorWithRGBHex(0xDDDDDD)];
                [self addSubview:block];
            }
        }
    }
}

-(void) initData {
    self.lightDic = [NSMutableDictionary new];
    self.hsbDic = [NSMutableDictionary new];
}

-(void) initDisplay {
    
}

/**
 *  MARK:--------------------特征可视化--------------------
 *  @param indexes 传值时，仅显示indexes中有的下标。
 */
-(void) setData:(AIFeatureNode*)tNode indexes:(NSArray*)indexes lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top {
    NSArray *gvModels = [tNode convert2GVModels:indexes];
    [self setData:tNode gvModels:gvModels lab:lab left:left top:top];
}
-(void) setData:(AIFeatureNode*)tNode gvModels:(NSArray*)gvModels lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top {
    //0. top,left处理。
    for (InputGroupValueModel *item in gvModels) {
        CGRect newRect = item.rect;
        newRect.origin.x += left;
        newRect.origin.y += top;
        item.rect = newRect;
    }
    
    //1. 数据准备。
    NSString *at = tNode.at;
    NSString *ds = tNode.ds;
    
    //2. 三个单码索引序列。
    NSDictionary *directionDataDic = [AINetIndexUtils searchDataDic:at ds:STRFORMAT(@"%@_direction",ds) isOut:false];
    NSDictionary *diffDataDic = [AINetIndexUtils searchDataDic:at ds:STRFORMAT(@"%@_diff",ds) isOut:false];
    NSDictionary *junDataDic = [AINetIndexUtils searchDataDic:at ds:STRFORMAT(@"%@_jun",ds) isOut:false];
    
    //3. 按level从粗到细排序（因为细粒度优先级更高：粗粒度先显示，细粒度再复写它）（参考34176-TODO2.1）。
    gvModels = [SMGUtils sortBig2Small:gvModels compareBlock:^double(InputGroupValueModel *item) {
        return item.rect.size.width;
    }];
    
    //4. 过滤重复。
    gvModels = [SMGUtils removeRepeat:gvModels convertBlock:^id(InputGroupValueModel *obj) {
        return @(obj.rect);
    }];
    
    //11. 每个rect分别可视化。
    for (InputGroupValueModel *item in gvModels) {
        AIKVPointer *gv_p = item.groupValue_p;
        
        //12. 三个索引的指针地址：均值、差值、方向。
        AIGroupValueNode *gvNode = [SMGUtils searchNode:gv_p];
        AIKVPointer *directionV_p = [SMGUtils filterSingleFromArr:gvNode.content_ps checkValid:^BOOL(AIKVPointer *item) {
            return [item.dataSource isEqualToString:STRFORMAT(@"%@_direction",ds)];
        }];
        AIKVPointer *diffV_p = [SMGUtils filterSingleFromArr:gvNode.content_ps checkValid:^BOOL(AIKVPointer *item) {
            return [item.dataSource isEqualToString:STRFORMAT(@"%@_diff",ds)];
        }];
        AIKVPointer *junV_p = [SMGUtils filterSingleFromArr:gvNode.content_ps checkValid:^BOOL(AIKVPointer *item) {
            return [item.dataSource isEqualToString:STRFORMAT(@"%@_jun",ds)];
        }];
        double directionData = [NUMTOOK([AINetIndex getData:directionV_p fromDataDic:directionDataDic]) doubleValue];
        double diffData = [NUMTOOK([AINetIndex getData:diffV_p fromDataDic:diffDataDic]) doubleValue];
        double junData = [NUMTOOK([AINetIndex getData:junV_p fromDataDic:junDataDic]) doubleValue];
        
        //13. 用这三个索引值，生成当前特征通道的九宫每像素色值。
        [self createItemLight:item.rect directionData:directionData diffData:diffData junData:junData ds:ds];
    }
    
    //20. 局部特征边框可视化。
    if (PitIsGroupFeature(tNode.p)) {
        CGFloat dotWH = self.width / powf(3, VisionMaxLevel);
        for (NSInteger i = 0; i < tNode.count; i++) {
            CGRect rect = VALTOOK(ARR_INDEX(tNode.rects, i)).CGRectValue;
            UIView *sub = [[UIView alloc] initWithFrame:CGRectMake(rect.origin.x * dotWH, rect.origin.y * dotWH, rect.size.width * dotWH, rect.size.height * dotWH)];
            if (i % 4 == 0) [sub.layer setBorderColor:UIColor.purpleColor.CGColor];
            else if (i % 4 == 1) [sub.layer setBorderColor:UIColor.cyanColor.CGColor];
            else if (i % 4 == 2) [sub.layer setBorderColor:UIColor.redColor.CGColor];
            else if (i % 4 == 3) [sub.layer setBorderColor:UIColor.blueColor.CGColor];
            [sub.layer setBorderWidth:0.9f];
            [sub setBackgroundColor:UIColorWithRGBA(0, 0, 0, 0)];
            [self addSubview:sub];
        }
    }
    
    //21. lab
    [self.lab setText:lab];
}

-(void) createItemLight:(CGRect)rect directionData:(double)directionData diffData:(double)diffData junData:(double)junData ds:(NSString*)ds {
    //0. 数据检查（无差别时，直接全显示均值）。
    if (diffData == 0) {
        for (NSInteger i = 0; i < rect.size.width; i++) {
            for (NSInteger j = 0; j < rect.size.height; j++) {
                [self createItemLight:rect.origin.x + i y:rect.origin.y + j ds:ds hsbValue:junData];
            }
        }
        return;
    }
    
    //1. ========== 先上下各阔一半值，然后各分布一半格子 ==========
    //A、如果不越界，直接输出结果（如差值为4，均值为7，则Max=9，Min=5 各4.5格）。
    //B、如果上越界，下移，重新计算二元方程（如差值为8，均值为7，因7+4>9取Max=9，Min=1：然后Max*A+Min*B=63 A+B=9 得出：A=6.75格 B=2.25格）。
    //C、如果下越界，上移，重新计算二元方程（如差值为8，均值为3，因3-4<0取Min=0，Max=8：然后Max*A+Min*B=63 A+B=9 得出：A=3.375格 B=5.625格）。
    double max = junData + diffData * 0.5f;
    double min = junData - diffData * 0.5f;
    if (max > 1) {
        min -= max - 1;
        max = 1;
    } else if (min < 0) {
        max += 0 - min;
        min = 0;
    }
    double sumData = junData * 9;

    //2. ==========设min有A格，max有B格，解二元一次方程组 ==========
    // min * A + max * B = sumData
    // A + B = 9格
    // 解得: B = 9 - A
    // 代入: min * A + max * (9 - A) = sumData
    //      min * A + 9 * max - max * A = sumData
    //      (min - max) * A = sumData - 9 * max
    //      A = (sumData - 9 * max) / (min - max)
    double minNumA = (sumData - 9 * max) / (min - max);
    double maxNumB = 9 - minNumA;
    
    //3. ========== 根据方向索引 和 线经过A点 => 计算分界线 ==========
    double rad = (directionData * 2 - 1) * M_PI;//将距离转成角度-PI -> PI (从左顺时针一圈为-3.14到3.14)。
    rad += M_PI_2;//分界线为逆时针转90度（分界线的右侧为min，左侧为max）。
    if (rad > M_PI) rad -= M_PI * 2;//循环值处理（避免越界）。
    double dx = cos(rad);//方向向量
    double dy = sin(rad);//方向向量
    
    //4. ========== 按方向分界线：判断九宫每格距离分界线的距离 ==========
    //说明：直接用分界线与9点的距离来排序，按数量给色值就行，数量左右0.5的给中间值，左>0.5数量的给max值，右>0.5数量的给min值。
    NSMutableDictionary *distanceFenJieLineDic = [NSMutableDictionary new];
    for (NSInteger row = 0; row < 3; row++) {
        for (NSInteger column = 0; column < 3; column++) {
            CGFloat dotW = rect.size.width / 3.0f;
            CGFloat dotH = rect.size.height / 3.0f;
            CGFloat centerX = row * dotW + dotW * 0.5f;
            CGFloat centerY = column * dotH + dotH * 0.5f;
            
            // 求checkPoint 与 方向向量(dx,dy)经过0的线 垂直距离
            // 点到直线距离公式: (dx, dy) × (checkPoint.x, checkPoint.y) / sqrt(dx^2 + dy^2)
            double crossProd = dx * centerY - dy * centerX;
            double dirLen = sqrt(dx * dx + dy * dy);
            double perpDist = crossProd / dirLen;
            //NSLog(@"aPoint到方向rad的垂直距离: %.3f", perpDist);
            [distanceFenJieLineDic setObject:@(perpDist) forKey:STRFORMAT(@"%ld_%ld",row,column)];
        }
    }
    
    //5. ========== 按距离来判断其色值 ==========
    NSArray *sortKeysByDistances = [SMGUtils sortBig2Small:distanceFenJieLineDic.allKeys compareBlock:^double(id obj) {
        return NUMTOOK([distanceFenJieLineDic objectForKey:obj]).floatValue;
    }];
    NSArray *sortValuesByDistance = [SMGUtils sortBig2Small:distanceFenJieLineDic.allValues compareBlock:^double(NSNumber *obj) {
        return obj.floatValue;
    }];
    for (NSInteger row = 0; row < 3; row++) {
        for (NSInteger column = 0; column < 3; column++) {
            CGFloat dotW = rect.size.width / 3.0f;
            CGFloat dotH = rect.size.height / 3.0f;
            NSString *dotKey = STRFORMAT(@"%ld_%ld",row,column);
            
            //51. 显示max/min两种颜色
            NSInteger indexOfCurDot = [sortKeysByDistances indexOfObject:dotKey];
            CGFloat curDistance = NUMTOOK(ARR_INDEX(sortValuesByDistance, indexOfCurDot)).floatValue;
            
            //52. 把相似距离的格子收集起来。
            NSMutableArray *nearDotIndexes = [NSMutableArray new];
            for (NSInteger i = 0; i < 9; i++) {
                CGFloat checkDistance = NUMTOOK(ARR_INDEX(sortValuesByDistance, i)).floatValue;
                if (fabs(checkDistance - curDistance) / dotW < 0.5f) [nearDotIndexes addObject:@(i)];
            }
            
            //53. 距离类似的采取灰度显示: 对距离相邻宫格进行判断，如果色值不同，距离又很接近，就对几格的颜色进行平均。
            CGFloat hsbValue = [SMGUtils sumOfArr:nearDotIndexes convertBlock:^double(NSNumber *index) {
                return index.integerValue < maxNumB - 0.2f ? max : min;
            }] / nearDotIndexes.count;
            
            //61. 对九宫每格中的每个像素分别高亮显示。
            for (NSInteger i = 0; i < dotW; i++) {
                for (NSInteger j = 0; j < dotH; j++) {
                    CGFloat x = rect.origin.x + row * dotW + i;
                    CGFloat y = rect.origin.y + column * dotH + j;
                    
                    //62. 每次收集一个通道，三次识别后可以把全部通道累计下来，还原最终显示颜色。
                    [self createItemLight:x y:y ds:ds hsbValue:hsbValue];
                }
            }
        }
    }
}

// x,y传绝对坐标。
-(void) createItemLight:(CGFloat)x y:(CGFloat)y ds:(NSString*)ds hsbValue:(CGFloat)hsbValue {
    //xy最大值为27，但每个都是组码，所以要转为9x9。
    CGFloat dotSize = powf(3, VisionMaxLevel);
    NSString *key = STRFORMAT(@"%.0f_%.0f",x,y);
    
    //收集HSB颜色
    HSBColor *color =  [self.hsbDic objectForKey:key];
    if (!color) {
        color = [HSBColor new];
        [self.hsbDic setObject:color forKey:key];
    }
    [color setData:ds value:hsbValue];
    
    //当前图片分为9格。
    CGFloat dotWH = self.width / dotSize;
    UIView *lightView = [self.lightDic objectForKey:key];
    if (!lightView) {
        lightView = [[UIView alloc] initWithFrame:CGRectMake(x * dotWH, y * dotWH, dotWH, dotWH)];
        [lightView setAlpha:1.0f];
        [self addSubview:lightView];
        [self.lightDic setObject:lightView forKey:key];
    }
    [lightView setBackgroundColor:color.getColor];
}

-(void) removeLightDic {
    //1. 去掉可视化lightDic。
    for (UIView *itemLight in self.lightDic.allValues) {
        [itemLight removeFromSuperview];
    }
    [self.lightDic removeAllObjects];
    [self.hsbDic removeAllObjects];
}

//方向的坐标是左下角为0，而ios坐标是左上角为0，要先转换下，再参与叉乘判断等。
//把ios的左上角为y=0 改成 数学方向判断里的左下角y=0。
-(CGFloat) convertIosYToMathY:(CGFloat)iosY height:(CGFloat)height {
    return height - iosY;//用总高减iosY即可。
}

@end
