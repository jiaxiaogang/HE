//
//  AIFeatureJvBuModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------单特征识别V2算法模型：二级--------------------
 */
@interface AIFeatureJvBuModel : NSObject

+(id) new:(AIFeatureNode*)assT beginAssIndex:(NSInteger)beginAssIndex beginGV_ProtoRect:(CGRect)beginGV_ProtoRect;

//refPort.target。
@property (weak, nonatomic) AIFeatureNode *assT;
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
@property (assign, nonatomic) CGFloat matchValue;
//用bestGVs每一条gv求平均得出符合度。
@property (assign, nonatomic) CGFloat matchDegree;
//用bestGVs条数得出健全度。
@property (assign, nonatomic) CGFloat matchAssProtoRatio;
//用bestGVs条数/assT总长度=得出匹配率。
@property (assign, nonatomic) CGFloat matchAssRatio;
//色似度：信息量-用bestGVs每一条diff求平均得出整个信息量（避免越来越趋向于识别出纯色无意义的特征结果，有时单T识别结果是全是纯黑的gvs）。
@property (assign, nonatomic) CGFloat matchDiffValue;
//protoRect和assRect视角匹配度（用于调试日志用）。
@property (assign, nonatomic) CGFloat matchRectValue;

-(void) run4MatchValueAndMatchDegreeAndMatchAssProtoRatio;
-(void) run4BestGvsAtProtoTRect;
-(void) run4BestGvsAtAssTRect;
-(CGFloat) getSTMatch;
-(CGFloat) getGTMatch;
-(NSString*) getSTMatchDesc;
-(NSString*) getGTMatchDesc;

@property (assign, nonatomic) CGFloat areaRankSum; // 考试名次之和（越大越好）。
@property (assign, nonatomic) NSInteger areaRankNum; // 考试次数（用于计算均排名）。
-(CGFloat) areaRankScore; // 平均名次（越大越好）。
-(void) run4ItemAreaRankScore:(NSArray*)stModels;

// 用分区均衡排名后，归一化，得到的排名优秀度（从不好到最优秀值范围0-1）。
@property (assign, nonatomic) CGFloat areaRankRatio;

// 当前bestGVs.count的归一化，用于防止过度抽象（越长的越好，越短的越孬，值范围0-1）。
@property (assign, nonatomic) CGFloat bestGVsCountRatio;

// item.assT.absLevel抽象度，归一化计算（用于在稳定层里优先抽象层）。
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
-(void) run4AssST_ProtoRect;

// bestGVs根据匹配度末尾淘汰20%（参考35138-TODO1）。
-(void) filter4MatchValue;

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
@property (strong, nonatomic) NSArray *validAbsST_ps;
-(void) run4ValidAbsST_ps;

// 相邻度（参考36032-方案）。
-(void) run4AdjacentScore;
@property (assign, nonatomic) CGFloat adjacentScore;

@end
