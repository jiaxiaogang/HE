//
//  TCRecognitionBootstrapper.m
//  SMG_NothingIsAll
//
//  识别自举器 - 基于需求37021：草书奇异性锚点计算优化
//
//  核心思路：
//  选手1 (assGT): 用itemGV之间的位置关系计算大致切图方向范围
//  选手2 (protoST): 用protoGV之间的位置关系在指定范围内找出高亮点
//  结合: Ass告诉Proto大致要切哪，Proto再告诉Ass切的范围内哪里有内容
//
//  Created by jia on 2026/04/08.
//  Copyright © 2026年 XiaoGang. All rights reserved.
//

#import "TCRecognitionBootstrapper.h"

// MARK: ===============================================================
// MARK: < 数据模型 >
// MARK: ===============================================================

/**
 *  MARK:--------------------锚点方向范围模型--------------------
 *  @desc 选手1(assGT)计算出的切图方向范围
 */
@interface AnchorDirectionRange : NSObject
@property (nonatomic, assign) CGFloat minX;      // X方向最小偏移
@property (nonatomic, assign) CGFloat maxX;      // X方向最大偏移
@property (nonatomic, assign) CGFloat minY;      // Y方向最小偏移
@property (nonatomic, assign) CGFloat maxY;      // Y方向最大偏移
@property (nonatomic, assign) BOOL canLeft;      // 是否可向左切
@property (nonatomic, assign) BOOL canRight;     // 是否可向右切
@property (nonatomic, assign) BOOL canUp;        // 是否可向上切
@property (nonatomic, assign) BOOL canDown;      // 是否可向下切
@property (nonatomic, assign) CGFloat minScale;  // 最小缩放比例
@property (nonatomic, assign) CGFloat maxScale;  // 最大缩放比例
@end

@implementation AnchorDirectionRange
@end

/**
 *  MARK:--------------------高亮点模型--------------------
 *  @desc 选手2(protoST)在指定范围内找到的有效内容点
 */
@interface HighlightPoint : NSObject
@property (nonatomic, assign) CGPoint point;           // 高亮点位置
@property (nonatomic, assign) CGFloat confidence;      // 置信度(0-1)
@property (nonatomic, assign) CGRect validRect;        // 有效切图区域
@property (nonatomic, assign) CGFloat matchValue;      // 匹配度
@property (nonatomic, strong) AIKVPointer *protoGV_p;  // 对应的protoGV指针
@end

@implementation HighlightPoint
@end

/**
 *  MARK:--------------------自举结果模型--------------------
 *  @desc 结合选手1和选手2后的最终自举结果
 */
@interface BootstrapResult : NSObject
@property (nonatomic, assign) CGRect finalRect;           // 最终切图区域
@property (nonatomic, assign) CGFloat matchValue;         // 匹配度
@property (nonatomic, assign) CGFloat matchDegree;        // 符合度
@property (nonatomic, strong) AIKVPointer *baseGV_p;      // 基础GV指针
@property (nonatomic, strong) NSArray<HighlightPoint*> *highlightPoints; // 高亮点集合
@property (nonatomic, assign) BOOL isValid;               // 是否有效
@end

@implementation BootstrapResult
@end

// MARK: ===============================================================
// MARK: < 识别自举器实现 >
// MARK: ===============================================================

@interface TCRecognitionBootstrapper()

// 缓存池
@property (nonatomic, strong) NSMutableDictionary *directionRangeCache;  // 方向范围缓存
@property (nonatomic, strong) NSMutableDictionary *highlightPointCache;    // 高亮点缓存
@property (nonatomic, strong) NSMutableDictionary *bootstrapResultCache;   // 自举结果缓存

@end

@implementation TCRecognitionBootstrapper

#pragma mark - 单例
+ (instancetype)sharedInstance {
    static TCRecognitionBootstrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TCRecognitionBootstrapper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _directionRangeCache = [NSMutableDictionary new];
        _highlightPointCache = [NSMutableDictionary new];
        _bootstrapResultCache = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - 公开接口

/**
 *  MARK:--------------------GV自举主入口（新算法）--------------------
 *  @desc 结合assGT和protoST的位置关系进行锚点计算
 *  @param new_Proto 新的proto切图区域
 *  @param newGV 新的GV指针
 *  @param olds_Proto 上一个proto切图区域（用于计算锚点）
 *  @param colorDic 颜色字典
 *  @param ds 数据源
 *  @param assGT 选手1: assGT节点（提供itemGV位置关系）
 *  @param protoST 选手2: protoST节点（提供protoGV位置关系）
 *  @return 自举结果项
 */
+ (AIFeatureJvBuItem*) gvZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                              protoST:(AIFeatureNode*)protoST
                            new_Proto:(CGRect)new_Proto
                                newGV:(AIKVPointer*)newGV
                           olds_Proto:(CGRect)olds_Proto
                             colorDic:(NSDictionary*)colorDic
                                   ds:(NSString*)ds {
    return [[TCRecognitionBootstrapper sharedInstance] gvZiJvWithAssGT:assGT
                                                               protoST:protoST
                                                             new_Proto:new_Proto
                                                                 newGV:newGV
                                                            olds_Proto:olds_Proto
                                                              colorDic:colorDic
                                                                    ds:ds];
}

/**
 *  MARK:--------------------ST自举主入口（新算法）--------------------
 */
+ (AIFeatureJvBuItem*) stZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                                protoST:(AIFeatureNode*)protoST
                               curIndex:(NSInteger)curIndex
                                  assT:(AIFeatureNode*)assT
                         lastProtoRect:(CGRect)lastProtoRect
                         lastAtAssRect:(CGRect)lastAtAssRect
                            colorDic:(NSDictionary*)colorDic
                                  ds:(NSString*)ds {
    return [[TCRecognitionBootstrapper sharedInstance] stZiJvWithAssGT:assGT
                                                               protoST:protoST
                                                              curIndex:curIndex
                                                                 assT:assT
                                                        lastProtoRect:lastProtoRect
                                                        lastAtAssRect:lastAtAssRect
                                                               colorDic:colorDic
                                                                     ds:ds];
}

/**
 *  MARK:--------------------GT自举主入口（新算法）--------------------
 */
+ (GTZiJvModelV2*) gtZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                           protoST:(AIFeatureNode*)protoST
                          targetGT:(AIGroupFeatureNode*)targetGT
                        beginIndex:(NSInteger)beginIndex
                      beginSTModel:(AIFeatureJvBuModel*)beginSTModel
                          colorDic:(NSDictionary*)colorDic
                                ds:(NSString*)ds {
    return [[TCRecognitionBootstrapper sharedInstance] gtZiJvWithAssGT:assGT
                                                               protoST:protoST
                                                              targetGT:targetGT
                                                            beginIndex:beginIndex
                                                          beginSTModel:beginSTModel
                                                              colorDic:colorDic
                                                                    ds:ds];
}

#pragma mark - 核心算法实现

/**
 *  MARK:--------------------GV自举核心算法--------------------
 *  @desc 需求37021实现：结合assGT和protoST进行锚点计算
 */
- (AIFeatureJvBuItem*) gvZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                               protoST:(AIFeatureNode*)protoST
                             new_Proto:(CGRect)new_Proto
                                 newGV:(AIKVPointer*)newGV
                            olds_Proto:(CGRect)olds_Proto
                              colorDic:(NSDictionary*)colorDic
                                    ds:(NSString*)ds {

    // ==================== Step 1: 选手1计算 - assGT确定大致切图方向范围 ====================
    AnchorDirectionRange *directionRange = [self calculateDirectionRangeFromAssGT:assGT
                                                                           protoST:protoST
                                                                          new_Proto:new_Proto
                                                                          olds_Proto:olds_Proto];

    // ==================== Step 2: 选手2计算 - protoST在范围内找高亮点 ====================
    NSArray<HighlightPoint*> *highlightPoints = [self findHighlightPointsInProtoST:protoST
                                                                    directionRange:directionRange
                                                                          colorDic:colorDic
                                                                                ds:ds];

    // ==================== Step 3: 结合两者结果，计算最优切图区域 ====================
    BootstrapResult *result = [self combineAssAndProtoResults:directionRange
                                               highlightPoints:highlightPoints
                                                     new_Proto:new_Proto
                                                         newGV:newGV
                                                    olds_Proto:olds_Proto
                                                      colorDic:colorDic
                                                            ds:ds];

    if (!result.isValid) return nil;

    // 构建返回结果
    AIFeatureJvBuItem *item = [AIFeatureJvBuItem new:result.finalRect
                                           matchValue:result.matchValue
                                          matchDegree:result.matchDegree
                                           diffValue:0
                                           baseGV_p:result.baseGV_p];
    return item;
}

/**
 *  MARK:--------------------选手1: assGT计算锚点方向范围--------------------
 *  @desc 用assGT里的itemGV之间的位置关系，算出大致的切图方向范围
 *  例如：两个锚点规定可左不可右，两个规定>20之外切多远都行
 */
- (AnchorDirectionRange*) calculateDirectionRangeFromAssGT:(AIGroupFeatureNode*)assGT
                                                   protoST:(AIFeatureNode*)protoST
                                                  new_Proto:(CGRect)new_Proto
                                                 olds_Proto:(CGRect)olds_Proto {

    AnchorDirectionRange *range = [[AnchorDirectionRange alloc] init];

    // 1. 计算assGT中itemGV之间的相对位置关系
    NSArray *itemGVs = assGT.content_ps;
    if (itemGVs.count < 2) {
        // 只有1个itemGV时，使用默认范围
        range.minX = -new_Proto.size.width * 0.5;
        range.maxX = new_Proto.size.width * 0.5;
        range.minY = -new_Proto.size.height * 0.5;
        range.maxY = new_Proto.size.height * 0.5;
        range.canLeft = YES;
        range.canRight = YES;
        range.canUp = YES;
        range.canDown = YES;
        range.minScale = 0.8;
        range.maxScale = 1.2;
        return range;
    }

    // 2. 分析assGT中相邻itemGV的位置关系，确定方向限制
    CGFloat minDeltaX = CGFLOAT_MAX, maxDeltaX = -CGFLOAT_MAX;
    CGFloat minDeltaY = CGFLOAT_MAX, maxDeltaY = -CGFLOAT_MAX;
    CGFloat avgWidth = 0, avgHeight = 0;

    for (NSInteger i = 0; i < itemGVs.count - 1; i++) {
        AIKVPointer *gv1_p = ARR_INDEX(itemGVs, i);
        AIKVPointer *gv2_p = ARR_INDEX(itemGVs, i + 1);

        CGRect rect1 = [assGT rectByIndex:i];
        CGRect rect2 = [assGT rectByIndex:i + 1];

        CGFloat deltaX = rect2.origin.x - rect1.origin.x;
        CGFloat deltaY = rect2.origin.y - rect1.origin.y;

        minDeltaX = MIN(minDeltaX, deltaX);
        maxDeltaX = MAX(maxDeltaX, deltaX);
        minDeltaY = MIN(minDeltaY, deltaY);
        maxDeltaY = MAX(maxDeltaY, deltaY);

        avgWidth += rect1.size.width;
        avgHeight += rect1.size.height;
    }

    avgWidth /= (itemGVs.count - 1);
    avgHeight /= (itemGVs.count - 1);

    // 3. 根据位置关系确定方向范围
    // 如果assGT中itemGV主要是水平排列，则左右范围可以较大，上下范围受限
    // 如果assGT中itemGV主要是垂直排列，则上下范围可以较大，左右范围受限

    CGFloat xRange = MAX(fabs(maxDeltaX), fabs(minDeltaX));
    CGFloat yRange = MAX(fabs(maxDeltaY), fabs(minDeltaY));

    if (xRange > yRange) {
        // 主要是水平排列
        range.canLeft = minDeltaX < 0;
        range.canRight = maxDeltaX > 0;
        range.canUp = NO;  // 限制向上
        range.canDown = NO; // 限制向下

        range.minX = minDeltaX * 2;  // 可左范围
        range.maxX = maxDeltaX * 2;  // 可右范围
        range.minY = -avgHeight * 0.3; // 上下受限
        range.maxY = avgHeight * 0.3;
    } else {
        // 主要是垂直排列
        range.canLeft = NO;   // 限制向左
        range.canRight = NO;  // 限制向右
        range.canUp = minDeltaY < 0;
        range.canDown = maxDeltaY > 0;

        range.minX = -avgWidth * 0.3; // 左右受限
        range.maxX = avgWidth * 0.3;
        range.minY = minDeltaY * 2;   // 可上范围
        range.maxY = maxDeltaY * 2;   // 可下范围
    }

    // 4. 根据草书特点，特殊处理长勾等情况
    // 如果检测到可能是长勾（垂直延伸很长），放宽垂直方向限制
    CGFloat aspectRatio = new_Proto.size.height / MAX(new_Proto.size.width, 1);
    if (aspectRatio > 3) {
        // 可能是长勾，放宽垂直方向
        range.canUp = YES;
        range.canDown = YES;
        range.minY = -new_Proto.size.height * 2;
        range.maxY = new_Proto.size.height * 2;
    }

    // 5. 设置缩放范围
    range.minScale = 0.7;
    range.maxScale = 1.5;

    return range;
}

/**
 *  MARK:--------------------选手2: protoST在范围内找高亮点--------------------
 *  @desc 用protoST的protoGV之间的位置关系，在选手1指定的方向范围内找出高亮的点
 *  这些高亮点告诉选手1：这个范围能有效切到内容，哪里是空白的切不到内容
 */
- (NSArray<HighlightPoint*>*) findHighlightPointsInProtoST:(AIFeatureNode*)protoST
                                             directionRange:(AnchorDirectionRange*)directionRange
                                                   colorDic:(NSDictionary*)colorDic
                                                         ds:(NSString*)ds {

    NSMutableArray<HighlightPoint*> *points = [NSMutableArray new];

    if (!protoST || protoST.count == 0) return points;

    // 1. 分析protoST中itemGV的位置关系（绝对准确）
    for (NSInteger i = 0; i < protoST.count; i++) {
        CGRect gvRect = [protoST rectByIndex:i];
        AIKVPointer *gv_p = ARR_INDEX(protoST.content_ps, i);

        // 2. 检查这个GV是否在选手1指定的方向范围内
        if (![self isRect:gvRect inDirectionRange:directionRange]) {
            continue; // 不在范围内，跳过
        }

        
        // TODO: 在这个方向上，只是避免切到空白区域。
        // 1. 根据assGV知道自己要切的方向后，在这个方向上找出所有的protoGV，然后求出这些protoGV的最近的minDistance和最远距离的maxDistance。
        // 2. 把assGV在这个距离minDistance到maxDistance间，分成十份（这十份切图要近小远大），分别对protoImgDic进行切图，把最准的一份找出来。
        
        // 3. 计算这个点的置信度（基于颜色值等）
        CGFloat confidence = [self calculateConfidenceForGV:gv_p
                                                     rect:gvRect
                                                 colorDic:colorDic
                                                       ds:ds];

        if (confidence > 0.3) { // 置信度阈值
            HighlightPoint *point = [[HighlightPoint alloc] init];
            point.point = CGPointMake(CGRectGetMidX(gvRect), CGRectGetMidY(gvRect));
            point.confidence = confidence;
            point.validRect = gvRect;
            point.matchValue = confidence;
            point.protoGV_p = gv_p;
            [points addObject:point];
        }
    }

    // 4. 按置信度排序
    [points sortUsingComparator:^NSComparisonResult(HighlightPoint *p1, HighlightPoint *p2) {
        return [@(p2.confidence) compare:@(p1.confidence)];
    }];

    return points;
}

/**
 *  MARK:--------------------检查rect是否在方向范围内--------------------
 */
- (BOOL) isRect:(CGRect)rect inDirectionRange:(AnchorDirectionRange*)range {
    CGFloat centerX = CGRectGetMidX(rect);
    CGFloat centerY = CGRectGetMidY(rect);

    // 检查X方向
    if (centerX < range.minX || centerX > range.maxX) return NO;

    // 检查Y方向
    if (centerY < range.minY || centerY > range.maxY) return NO;

    return YES;
}

/**
 *  MARK:--------------------计算GV的置信度--------------------
 */
- (CGFloat) calculateConfidenceForGV:(AIKVPointer*)gv_p
                               rect:(CGRect)rect
                           colorDic:(NSDictionary*)colorDic
                                 ds:(NSString*)ds {

    // TODO: 这个切图要和TCRecognitionInvoke中的Pool一样，加个复用池，避免重复计算。
    
    // 1. 切图获取颜色值
    NSArray *subDots = [ThinkingUtils getSubDots:colorDic gvRect:rect];
    if (!ARRISOK(subDots)) return 0;

    NSDictionary *gvIndex = [AINetGroupValueIndex convertGVIndexData:subDots ds:ds];
    if (!DICISOK(gvIndex)) return 0;

    // 2. 计算颜色密度作为置信度
    CGFloat totalValue = 0;
    NSInteger count = 0;

    for (NSString *key in gvIndex.allKeys) {
        NSNumber *value = [gvIndex objectForKey:key];
        totalValue += value.floatValue;
        count++;
    }

    CGFloat avgValue = count > 0 ? totalValue / count : 0;
    CGFloat confidence = MIN(1.0, avgValue / 255.0); // 归一化到0-1

    return confidence;
}

/**
 *  MARK:--------------------结合选手1和选手2的结果--------------------
 *  @desc 根据assGT的方向范围和protoST的高亮点，计算最优切图区域
 */
- (BootstrapResult*) combineAssAndProtoResults:(AnchorDirectionRange*)directionRange
                                highlightPoints:(NSArray<HighlightPoint*>*)highlightPoints
                                      new_Proto:(CGRect)new_Proto
                                          newGV:(AIKVPointer*)newGV
                                     olds_Proto:(CGRect)olds_Proto
                                       colorDic:(NSDictionary*)colorDic
                                             ds:(NSString*)ds {

    BootstrapResult *result = [[BootstrapResult alloc] init];
    result.baseGV_p = newGV;
    result.highlightPoints = highlightPoints;

    // 如果没有高亮点，返回无效
    if (highlightPoints.count == 0) {
        result.isValid = NO;
        return result;
    }

    // 1. 计算锚点
    CGPoint anchor = [SMGUtils convertAnchorByOldRect:olds_Proto newRect:new_Proto];

    // 2. 在方向范围内尝试不同的缩放比例
    NSArray *scales = @[@(1), @(1.1), @(0.9), @(1.2), @(0.8), @(1.5), @(0.7)];

    CGFloat bestMatchValue = 0;
    CGRect bestRect = CGRectNull;
    CGFloat bestMatchDegree = 0;

    for (NSNumber *scaleNum in scales) {
        CGFloat scale = scaleNum.floatValue;

        // 检查缩放是否在允许范围内
        if (scale < directionRange.minScale || scale > directionRange.maxScale) continue;

        // 3. 根据锚点和缩放计算候选rect
        CGRect candidateRect = [SMGUtils convertRectByAnchor:anchor scale:scale protoRect:new_Proto];
        candidateRect = [SMGUtils rectNoDot:candidateRect];

        // 4. 检查这个候选rect是否包含高亮点
        CGFloat coverageScore = [self calculateCoverageScore:candidateRect highlightPoints:highlightPoints];

        // 5. 计算与目标GV的匹配度
        CGFloat matchValue = [self calculateMatchValue:candidateRect
                                                  newGV:newGV
                                             colorDic:colorDic
                                                   ds:ds];

        // 6. 综合评分
        CGFloat combinedScore = matchValue * 0.6 + coverageScore * 0.4;

        if (combinedScore > bestMatchValue) {
            bestMatchValue = combinedScore;
            bestRect = candidateRect;
            bestMatchDegree = MIN(1, scale) / MAX(1, scale);
        }
    }

    // 7. 设置结果
    if (!CGRectIsNull(bestRect) && bestMatchValue > 0.5) {
        result.finalRect = bestRect;
        result.matchValue = bestMatchValue;
        result.matchDegree = bestMatchDegree;
        result.isValid = YES;
    } else {
        result.isValid = NO;
    }

    return result;
}

/**
 *  MARK:--------------------计算候选rect覆盖高亮点的得分--------------------
 */
- (CGFloat) calculateCoverageScore:(CGRect)candidateRect
                   highlightPoints:(NSArray<HighlightPoint*>*)points {

    if (points.count == 0) return 0;

    CGFloat totalScore = 0;
    CGFloat totalWeight = 0;

    for (HighlightPoint *point in points) {
        CGFloat weight = point.confidence;
        totalWeight += weight;

        if (CGRectContainsPoint(candidateRect, point.point)) {
            totalScore += weight; // 完全包含
        } else {
            // 计算距离得分
            CGFloat dist = [self distanceFromPoint:point.point toRect:candidateRect];
            CGFloat distScore = MAX(0, 1 - dist / 50); // 50像素内递减
            totalScore += weight * distScore;
        }
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0;
}

/**
 *  MARK:--------------------计算点到rect的最短距离--------------------
 */
- (CGFloat) distanceFromPoint:(CGPoint)point toRect:(CGRect)rect {
    if (CGRectContainsPoint(rect, point)) return 0;

    CGFloat dx = MAX(rect.origin.x - point.x, 0);
    dx = MAX(dx, point.x - CGRectGetMaxX(rect));

    CGFloat dy = MAX(rect.origin.y - point.y, 0);
    dy = MAX(dy, point.y - CGRectGetMaxY(rect));

    return sqrt(dx * dx + dy * dy);
}

/**
 *  MARK:--------------------计算候选rect与GV的匹配度--------------------
 */
- (CGFloat) calculateMatchValue:(CGRect)candidateRect
                          newGV:(AIKVPointer*)newGV
                     colorDic:(NSDictionary*)colorDic
                           ds:(NSString*)ds {

    // 切图
    NSArray *subDots = [ThinkingUtils getSubDots:colorDic gvRect:candidateRect];
    if (!ARRISOK(subDots)) return 0;

    NSDictionary *protoGVIndex = [AINetGroupValueIndex convertGVIndexData:subDots ds:ds];
    if (!DICISOK(protoGVIndex)) return 0;

    // 计算与assGV的匹配度
    AIGroupValueNode *assGV = [SMGUtils searchNode:newGV];
    if (!assGV) return 0;

    CGFloat matchValue = 1;
    for (AIKVPointer *assV in assGV.content_ps) {
        CGFloat protoData = NUMTOOK([protoGVIndex objectForKey:assV.dataSource]).floatValue;
        AIValueInfo *vInfo = [AINetIndex getValueInfo:assV.algsType ds:assV.dataSource isOut:assV.isOut];
        double assData = [NUMTOOK([AINetIndex getData:assV]) doubleValue];

        CGFloat vMatchValue = [AIAnalyst compareCansetValue:assData
                                                     protoV:protoData
                                                         at:assV.algsType
                                                         ds:assV.dataSource
                                                      isOut:assV.isOut
                                                      vInfo:vInfo];
        matchValue *= vMatchValue;
    }

    return matchValue;
}

#pragma mark - ST自举实现

/**
 *  MARK:--------------------ST自举（新算法）--------------------
 */
- (AIFeatureJvBuItem*) stZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                               protoST:(AIFeatureNode*)protoST
                              curIndex:(NSInteger)curIndex
                                  assT:(AIFeatureNode*)assT
                         lastProtoRect:(CGRect)lastProtoRect
                         lastAtAssRect:(CGRect)lastAtAssRect
                              colorDic:(NSDictionary*)colorDic
                                    ds:(NSString*)ds {

    // 1. 数据准备
    AIKVPointer *curAssGV_p = ARR_INDEX(assT.content_ps, curIndex);
    NSValue *curAtAssRectValue = ARR_INDEX(assT.rects, curIndex);
    CGRect curAtAssRect = curAtAssRectValue.CGRectValue;

    // 2. 根据比例估算下一条protoGV的取值范围
    CGFloat wRate = lastProtoRect.size.width / lastAtAssRect.size.width;
    CGFloat hRate = lastProtoRect.size.height / lastAtAssRect.size.height;
    CGFloat assDeltaX = curAtAssRect.origin.x - lastAtAssRect.origin.x;
    CGFloat assDeltaY = curAtAssRect.origin.y - lastAtAssRect.origin.y;
    CGFloat protoDeltaX = assDeltaX * wRate;
    CGFloat protoDeltaY = assDeltaY * hRate;

    CGRect defaultCurProtoRect = CGRectMake(lastProtoRect.origin.x + protoDeltaX,
                                            lastProtoRect.origin.y + protoDeltaY,
                                            curAtAssRect.size.width * wRate,
                                            curAtAssRect.size.height * hRate);

    // 3. 使用新算法进行GV自举
    AIFeatureJvBuItem *best = [self gvZiJvWithAssGT:assGT
                                            protoST:protoST
                                          new_Proto:defaultCurProtoRect
                                              newGV:curAssGV_p
                                         olds_Proto:lastProtoRect
                                           colorDic:colorDic
                                                 ds:ds];

    // 4. 匹配度检查
    if (!best || best.matchValue < 0.5) return nil;

    return best;
}

#pragma mark - GT自举实现

/**
 *  MARK:--------------------GT自举（新算法）--------------------
 */
- (GTZiJvModelV2*) gtZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                           protoST:(AIFeatureNode*)protoST
                          targetGT:(AIGroupFeatureNode*)targetGT
                        beginIndex:(NSInteger)beginIndex
                      beginSTModel:(AIFeatureJvBuModel*)beginSTModel
                          colorDic:(NSDictionary*)colorDic
                                ds:(NSString*)ds {

    // 1. 根据切入点，推算出targetGT默认在Proto中的Rect
    AIKVPointer *beginST_p = ARR_INDEX(targetGT.content_ps, beginIndex);
    AIFeatureNode *beginST = [SMGUtils searchNode:beginST_p];
    NSArray *conPorts = [AINetUtils conPorts_All:beginST];
    AIPort *conPort = [SMGUtils filterSingleFromArr:conPorts checkValid:^BOOL(AIPort *item) {
        return [item.target_p isEqual:beginSTModel.assT.p];
    }];

    // 2. 计算beginST_Proto
    CGRect beginST_AssST = conPort.rect;
    CGRect assST_Proto = beginSTModel.assST_ProtoRect;
    CGRect beginST_Proto = [SMGUtils convertAAtCWithAAtB:beginST_AssST
                                                   bAtC:assST_Proto
                                             protoBSize:beginSTModel.assT.rect.size];

    // 3. 计算defaultTargetGT_Proto
    CGRect beginST_TargetGT = [targetGT rectByIndex:beginIndex];
    CGRect targetGTRect = targetGT.rect;
    CGRect defaultTargetGT_Proto = [SMGUtils convertNewAAtCWithAAtB:beginST_TargetGT
                                                               aAtC:beginST_Proto
                                                            newAAtB:targetGTRect];

    // 4. 依次自举所有ST
    GTZiJvModelV2 *gtResult = [GTZiJvModelV2 new];
    gtResult.baseGT = targetGT;

    for (NSInteger i = 0; i < targetGT.count; i++) {
        NSInteger stIndex = (beginIndex + i) % targetGT.count;
        AIKVPointer *itemST_p = ARR_INDEX(targetGT.content_ps, stIndex);
        AIFeatureNode *itemST = [SMGUtils searchNode:itemST_p];
        CGRect itemST_GT = [gtResult.baseGT rectByIndex:stIndex];
        CGRect itemSTRect = itemST.rect;

        // 5. 使用新算法自举ST
        STZiJvModelV2 *stResult = [self stZiJvModelWithAssGT:assGT
                                                      protoST:protoST
                                                       itemST:itemST
                                                     itemST_GT:itemST_GT
                                                   itemSTRect:itemSTRect
                                                     stIndex:stIndex
                                                      gtResult:gtResult
                                                  defaultTargetGT_Proto:defaultTargetGT_Proto
                                                      colorDic:colorDic
                                                            ds:ds];

        if (stResult.bestGVs.count > 0) {
            [gtResult.bestSTs setObject:stResult forKey:@(stIndex)];
            gtResult.hopeProtoRectByAllCache = CGRectNull;
        }
    }

    return gtResult;
}

/**
 *  MARK:--------------------ST自举模型（新算法辅助方法）--------------------
 */
- (STZiJvModelV2*) stZiJvModelWithAssGT:(AIGroupFeatureNode*)assGT
                                protoST:(AIFeatureNode*)protoST
                                 itemST:(AIFeatureNode*)itemST
                              itemST_GT:(CGRect)itemST_GT
                             itemSTRect:(CGRect)itemSTRect
                                stIndex:(NSInteger)stIndex
                               gtResult:(GTZiJvModelV2*)gtResult
                  defaultTargetGT_Proto:(CGRect)defaultTargetGT_Proto
                               colorDic:(NSDictionary*)colorDic
                                     ds:(NSString*)ds {

    STZiJvModelV2 *stResult = [STZiJvModelV2 new];
    stResult.baseST = itemST;

    // 1. 根据已收集，估算整个targetGT_Proto
    CGRect targetGT_Proto = gtResult.bestSTs.count > 0 ? gtResult.hopeProtoRectByAll : defaultTargetGT_Proto;

    
    // TODO: 这里从curAssST到下个nextAssST也有方向，然后在这个方向上找protoST，求出这个方向上protoST的高亮点，再根据高亮点的位置来计算锚点，最后再根据锚点来求下个ST的候选rect，这样会更准确。
    
    // 2. 计算缩放锚点
    CGPoint anchor = [SMGUtils convertAnchorByOldRect:itemSTRect newRect:itemST_GT];
    NSArray *scales = @[@(1), @(1.1), @(0.9), @(1.2), @(0.8)];

    STZiJvModelV2 *bestSTResult = nil;

    for (NSNumber *scale in scales) {
        // 3. 根据锚点，求出新st的rect
        CGRect itemST_GT_Scaled = [SMGUtils convertRectByAnchor:anchor scale:scale.floatValue protoRect:itemST_GT];
        itemST_GT_Scaled = [SMGUtils rectNoDot:itemST_GT_Scaled];

        STZiJvModelV2 *curSTResult = [STZiJvModelV2 new];
        curSTResult.baseST = itemST;

        // 4. 依次自举所有GV
        for (NSInteger gvIndex = 0; gvIndex < itemST.count; gvIndex++) {
            AIKVPointer *itemGV_p = ARR_INDEX(itemST.content_ps, gvIndex);
            CGRect itemGV_ST = [curSTResult.baseST rectByIndex:gvIndex];

            // 5. 计算itemGV_TargetGT
            CGRect itemGV_TargetGT = [SMGUtils convertAAtCWithAAtB:itemGV_ST
                                                              bAtC:itemST_GT
                                                        protoBSize:itemSTRect.size];

            // 6. 计算itemGV_Proto
            CGRect itemGV_Proto = [SMGUtils convertAAtCWithAAtB:itemGV_TargetGT
                                                          bAtC:targetGT_Proto
                                                    protoBSize:gtResult.baseGT.rect.size];

            // 7. 使用新算法进行GV自举
            AIFeatureJvBuItem *gvResult = [self gvZiJvWithAssGT:assGT
                                                        protoST:protoST
                                                      new_Proto:itemGV_Proto
                                                          newGV:itemGV_p
                                                     olds_Proto:targetGT_Proto
                                                       colorDic:colorDic
                                                             ds:ds];

            if (!gvResult || gvResult.matchValue < 0.5) continue;
            [curSTResult.bestGVs setObject:gvResult forKey:@(gvIndex)];
            curSTResult.hopeProtoRectByAllCache = CGRectNull;
        }

        // 8. 保留更好的stResult
        if (bestSTResult == nil || curSTResult.bestGVs.count > bestSTResult.bestGVs.count) {
            bestSTResult = curSTResult;
        }
    }

    return bestSTResult ? bestSTResult : stResult;
}

#pragma mark - 缓存管理

/**
 *  MARK:--------------------清空缓存--------------------
 */
+ (void) clearCache {
    [[TCRecognitionBootstrapper sharedInstance].directionRangeCache removeAllObjects];
    [[TCRecognitionBootstrapper sharedInstance].highlightPointCache removeAllObjects];
    [[TCRecognitionBootstrapper sharedInstance].bootstrapResultCache removeAllObjects];
}

@end
