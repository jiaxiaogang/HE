//
//  AIFeatureJvBuModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

// 废弃：cOuterShapeWeight 和 cInnerEigenWeight 已随外形内征废弃。
#define cTotalCountWeight 1.0       // 中：自由竞争（用线性权重）。
#define cBestsCountWeight 1.0       // 中：自由竞争（用线性权重）。
#define cAverStrongWeight 0.0       // 弱：末尾淘汰（可废弃，在广入时，已淘汰强度低的）。

/**
 *  MARK:--------------------单特征识别V2算法模型：二级--------------------
 */
@interface AIFeatureJvBuModel : NSObject

+(id) new:(AIFeatureNode*)assT beginAssIndex:(NSInteger)beginAssIndex beginGV_ProtoRect:(CGRect)beginGV_ProtoRect;

//refPort.target。
@property (strong, nonatomic) AIFeatureNode *assT;
// 切入帧（参考35126-TODO1）。
@property (assign, nonatomic) NSInteger beginAssIndex;
// 切入帧对应ProtoRect（参考35126-TODO1）。
@property (assign, nonatomic) CGRect beginGV_ProtoRect;
//每个assT在proto中的rect（用于组特征识别）。
@property (assign, nonatomic) CGRect bestGVsAtProtoTRect;
//每个bestGVs在ass中的rect。
@property (assign, nonatomic) CGRect bestGVsAtAssTRect;
// 每条最佳gv的数据：Dic<assIndex,AIFeatureJvBuItem>
// 2025.12.25: 复用时，bestGV可能在别的assST 与 当前assST中的assIndex不同，所以改成jvBuModel直接用字典的key来存assIndex（参考35124）。
@property (strong, nonatomic) NSMutableDictionary *bestGVs;

//在ST类比后，把构建absST的bestGVs存下来，后面构建protoGT时要用。
@property (strong, nonatomic) NSArray *bestGVs4NoZeRen;
//在ST类比后，把构建absST的指针存下来，后面构建protoGT时要用。
@property (strong, nonatomic) AIKVPointer *abs_p;

//用bestGVs每一条gv求平均得出匹配度。
@property (assign, nonatomic) CGFloat matchValue;            // ST统一匹配度。
@property (assign, nonatomic) CGFloat directionMatchValue;  // 方向匹配度。
@property (assign, nonatomic) CGFloat junMatchValue;        // 均色值匹配度。
@property (assign, nonatomic) CGFloat diffMatchValue;       // 色差匹配度。
@property (assign, nonatomic) CGFloat sepMatchValue;        // 分隔点匹配度。
//用bestGVs每一条gv求平均得出符合度。
@property (assign, nonatomic) CGFloat matchDegree;
//用bestGVs条数得出健全度。
@property (assign, nonatomic) CGFloat matchAssProtoRatio;
//用bestGVs条数/assT总长度=得出匹配率。
@property (assign, nonatomic) CGFloat matchAssRatio;
//protoRect和assRect视角匹配度（用于调试日志用）。
@property (assign, nonatomic) CGFloat matchRectValue;

-(void) run4MatchValue;
-(void) run4DirectionMatchValue;
-(void) run4JunMatchValue;
-(void) run4DiffMatchValue;
-(void) run4SepMatchValue;
-(void) run4BestGvsAtProtoTRect;
-(void) run4BestGvsAtAssTRect;

@property (assign, nonatomic) CGFloat areaRankSum; // 考试名次之和（越大越好）。
@property (assign, nonatomic) NSInteger areaRankNum; // 考试次数（用于计算均排名）。
-(CGFloat) areaRankScore; // 平均名次（越大越好）。
-(void) run4ItemAreaRankScore:(NSArray*)stModels;

// 用分区均衡排名后，归一化，得到的排名优秀度（从不好到最优秀值范围0-1）。
@property (assign, nonatomic) CGFloat areaRankRatio;

// 当前bestGVs.count的归一化，用于防止过度抽象（越长的越好，越短的越孬，值范围0-1）。
@property (assign, nonatomic) CGFloat bestGVsCountRatio;

// item.assT.absLevel抽象度，归一化计算（用于在稳定层里优先抽象层）。
// 废弃：因为它与直接bests.count竞争力没区别。
@property (assign, nonatomic) CGFloat modelMatchCountScore;

// item.assT.conPorts.sum(strong) 计算总强度，和归一化后的强度竞争力。
@property (assign, nonatomic) NSInteger sumConPortStrong;
@property (assign, nonatomic) CGFloat modelMatchRatioScore;

-(AIFeatureJvBuItem*) getBestGVByAssIndex:(NSInteger)assIndex;
// bestGVs新收集一条时，都要先判断下是否比旧的更best，再收集，如果没旧的好，则直接跳过（参考35105-TODO6.2 & TODO6.4）。
-(void) updateBestGVs:(AIFeatureJvBuItem*)newBestGV assIndex:(NSInteger)assIndex;

// 计算assIndex对应的ProtoRect中范围（用beginIndex来推算）（参考35126-TODO2）。
-(CGRect) getItemGV_ProtoRect:(NSInteger)itemAssIndex;
// 计算整个assST_ProtoRect
@property (assign, nonatomic) CGRect assST_ProtoRect;
-(CGRect) run4AssST_ProtoRect;

// 末尾淘汰
-(void) filter4BestGVs;

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
@property (strong, nonatomic) NSArray *validAbsSTPorts;
-(NSArray *) allValidAbsST_ps;

// 相邻度（参考36032-方案）。
-(void) run4AdjacentScore;
@property (assign, nonatomic) CGFloat adjacentScore;

// 中心度（参考36033-方案）。
-(void) run4CenterScore;
@property (assign, nonatomic) CGFloat centerScore;

// assST的抽象强度归一化。
@property (assign, nonatomic) CGFloat absPortStrongScore;

// 匹配率
-(CGFloat)modelMatchRatio;

/**
 *  MARK:--------------------辅因子：完整性（参考36144-方案2）--------------------
 */
-(void) run4IntactRate;
@property (assign, nonatomic) CGFloat intactRate;

/**
 *  MARK:--------------------辅因子：稳定性（参考36145-方案）--------------------
 */
-(void) run4AverageContentStrong;
@property (assign, nonatomic) CGFloat averageContentStrong;
@property (assign, nonatomic) CGFloat averageContentStrongScore;

/**
 *  MARK:--------------------辅因子：匹配数 & 总数--------------------
 */
@property (assign, nonatomic) CGFloat bestsCountScore;
@property (assign, nonatomic) CGFloat totalCountScore;

// bestGVs的色差总值（替代bestGVs.count，用于递进淘汰法第一层）。
-(void) run4BestGVsSumDiff;
@property (assign, nonatomic) CGFloat bestGVsSumDiff;
-(void) run4BestGVsSumArea;
@property (assign, nonatomic) CGFloat bestGVsSumArea;

// assT所有gvs的色差总值（diff * 面积 累加）。
-(void) run4AllGVsSumDiff;
@property (assign, nonatomic) CGFloat allGVsSumDiff;
-(void) run4AllGVsSumArea;
@property (assign, nonatomic) CGFloat allGVsSumArea;

// ST综合竞争分（用于ST识别竞争）。
-(CGFloat) stScore;
-(NSString*) stScoreDesc;

@end
