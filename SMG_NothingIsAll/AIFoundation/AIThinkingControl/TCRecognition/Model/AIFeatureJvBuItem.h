//
//  AIFeatureJvBuItem.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/7.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------单特征识别V2算法模型：三级--------------------
 */
@interface AIFeatureJvBuItem : NSObject

+(id) new:(CGRect)bestGVAtProtoTRect outerShapeMatchValue:(CGFloat)outerShapeMatchValue matchDegree:(CGFloat)matchDegree innerEigenMatchValue:(CGFloat)innerEigenMatchValue baseGV_p:(AIKVPointer*)baseGV_p;

//每一条bestGV都可以把rect存下来（可用于计算bestGVsAtProtoTRect）。
@property (assign, nonatomic) CGRect bestGVAtProtoTRect;
//GV外形匹配度（37033-TODO2）。
@property (assign, nonatomic) CGFloat outerShapeMatchValue;
//每个bestGV的符合度。
@property (assign, nonatomic) CGFloat matchDegree;
//GV内征匹配度（37033-TODO3）。
@property (assign, nonatomic) CGFloat innerEigenMatchValue;
// baseGV
@property (strong, nonatomic) AIKVPointer *baseGV_p;
// 四个稀疏码各自的相似度 <K: dataSource, V: NSNumber(0-1)>
@property (strong, nonatomic) NSDictionary *baseGVIndex;
// 切图结果：gvIndex索引字典。
@property (strong, nonatomic) NSDictionary *protoGVIndex;

@end
