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

+(id) new:(AIFeatureNode*)assT;

//refPort.target。
@property (weak, nonatomic) AIFeatureNode *assT;
//每个assT在proto中的rect（用于组特征识别）。
@property (assign, nonatomic) CGRect bestGVsAtProtoTRect;
//每条最佳gv的数据：List<AIFeatureJvBuItem>
@property (strong, nonatomic) NSMutableArray *bestGVs;

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
-(CGFloat) getSTMatch;
-(CGFloat) getGTMatch;
-(NSString*) getSTMatchDesc;
-(NSString*) getGTMatchDesc;

@property (assign, nonatomic) NSInteger areaRankSum; // 排名名次之和。
@property (assign, nonatomic) NSInteger areaRankNum; // 排名考试次数。
-(CGFloat) areaRankScore; // 平均名次（越小越靠前越好）。
-(void) run4ItemAreaRankScore:(NSArray*)stModels;

// 用分区均衡排名后，归一化，得到的排名优秀度（从不好到最优秀值范围0-1）。
@property (assign, nonatomic) CGFloat areaMatchRatio;

// 当前bestGVs.count的归一化，用于防止过度抽象（越长的越好，越短的越孬，值范围0-1）。
@property (assign, nonatomic) CGFloat bestGVsCountRatio;

// item.assT.absLevel抽象度，归一化计算（用于在稳定层里优先抽象层）。
@property (assign, nonatomic) CGFloat absLevelRatio;

@end
