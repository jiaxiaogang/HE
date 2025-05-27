//
//  AIFeatureJvBuModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------局部特征识别V2算法模型：二级--------------------
 */
@interface AIFeatureJvBuModel : NSObject

+(id) new:(AIFeatureNode*)assT;

//refPort.target。
@property (weak, nonatomic) AIFeatureNode *assT;
//每个assT在proto中的rect（用于整体特征识别）。
@property (assign, nonatomic) CGRect bestGVsAtProtoTRect;
//每条最佳gv的数据：List<AIFeatureJvBuItem>
@property (strong, nonatomic) NSMutableArray *bestGVs;

//用bestGVs每一条gv求平均得出匹配度。
@property (assign, nonatomic) CGFloat matchValue;
//用bestGVs每一条gv求平均得出符合度。
@property (assign, nonatomic) CGFloat matchDegree;
//用bestGVs每一条gv求平均得出健全度。
@property (assign, nonatomic) CGFloat matchAssProtoRatio;

-(void) run4MatchValueAndMatchDegreeAndMatchAssProtoRatio;
-(void) run4BestGvsAtProtoTRect;

@end
