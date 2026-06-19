//
//  AIFeatureJvBuModels.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PRJSModel;

/**
 *  MARK:--------------------单特征识别V2算法模型：一级--------------------
 *  @desc 现在单特征识别不再依赖protoT了，也没indexDic映射结果了，所以写下此模型，用于存识别中的数据，用于随后的组特征识别和单特征类比中要用。
 *  @desc 一级：没有protoT了，不过要为每个proto编号，在类比时避免类比错是哪一次识别的结果（可以用protoT.protoImgColorDic的hash编号）。
 *  @desc 二级：refPort.target、及每个targetAssT的最佳匹配到的gv数据bestGVs、存每个assT在proto中的rect（用于组特征识别）。
 *  @desc 三级：存每一个匹配上的assIndex对应的：匹配度、符合度（用于类比）。
 */
@interface AIFeatureJvBuModels : NSObject

+(id) new:(NSInteger)hash;

//protoT.protoImgColorDic的hash编号
@property (assign, nonatomic) NSInteger protoTHash;

//存识别结果：PRJSModel（psArr/rsArr均为List<AIFeatureJvBuModel>，P/R两组各自竞争，参考38065-TODO1）。
@property (strong, nonatomic) PRJSModel *stModels;
@property (strong, nonatomic) NSMutableArray *gtModels;

// stModels的psArr+rsArr合并视图（用于不需要区分P/R的下游消费方，如GT识别、类比、mostClear等）。
-(NSArray*) stModelsAll;

@property (strong, nonatomic) GroupDebug *debug;

// 分区竞争匹配度：计算每条item的rankScore和rankRatio。
-(void) run4AreaRankRatioV2;

// item.bestGVs.count防止过度抽象，归一化计算。
-(void) run4BestGVsCountRatio;

// 匹配数，归一化防过抽（参考35141-方案1）。
-(void) run4ModelMatchCountScore;

// 匹配率（健全度），归一化防过具竞争力（参考35141-方案3）。
-(void) run4ModelMatchRatioScore;

// 计算stModel的抽象强度得分。
-(void) run4AbsPortStrongScore;

// 计算强度归一化得分。
-(void) run4AverageContentStrongScore;

// 匹配数归一化得分：依据排名。
-(void) run4BestsCountScore:(NSInteger)protoCount;
-(void) run4TotalCountScore:(NSInteger)protoCount;

// 每个条件都末尾淘汰20%（参考35138-TODO1）。
-(void) filter4ZonHe;

@end
