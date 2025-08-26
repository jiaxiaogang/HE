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

@end
