//
//  TCRecognitionBootstrapper.h
//  SMG_NothingIsAll
//
//  识别自举器 - 基于需求37021：草书奇异性锚点计算优化
//
//  核心思路（需求文档摘要）：
//  ============================================================================
//  问题：草书这种奇异性很大的情况，锚点也切不对地方。
//        比如"式"字的长勾，可能写很长，记忆里没见过这么长的怎么办？
//        要试多少回才能准确的从proto上切到它？
//
//  方案：把选手1和选手2结合起来
//        - 选手1 (assGT): 用itemGV之间的位置关系算出大致切图方向范围
//                         （比如两个锚点规定可左不可右，两个规定>20之外切多远都行）
//        - 选手2 (protoST): 在选手1指定的方向范围内，找出高亮的点
//                           （意在告诉选手1这个范围能有效切到内容）
//
//  总结：即Ass告诉Proto我大致要切哪，Proto再告诉Ass你切的范围内哪里有内容，哪里是空白的切不到内容。
//  ============================================================================
//
//  Created by jia on 2026/04/08.
//  Copyright © 2026年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AIHeader.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  MARK:--------------------识别自举器--------------------
 *  @desc 基于需求37021的新版自举算法，结合assGT和protoST的位置关系进行锚点计算
 *        解决草书等奇异性大的情况下锚点切图不准的问题
 */
@interface TCRecognitionBootstrapper : NSObject

#pragma mark - 单例访问

/**
 *  MARK:--------------------获取单例--------------------
 */
+ (instancetype)sharedInstance;

#pragma mark - 核心自举接口

/**
 *  MARK:--------------------GV自举（新算法）--------------------
 *  @desc 结合assGT和protoST的位置关系进行锚点计算
 *  @param assGT 选手1: assGT节点，提供itemGV之间的位置关系，计算大致切图方向范围
 *  @param protoST 选手2: protoST节点，提供protoGV之间的位置关系，找出高亮点
 *  @param new_Proto 新的proto切图区域
 *  @param newGV 新的GV指针
 *  @param olds_Proto 上一个proto切图区域（用于计算锚点）
 *  @param colorDic 颜色字典
 *  @param ds 数据源
 *  @return 自举结果项，失败返回nil
 */
+ (AIFeatureJvBuItem*) gvZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                              protoST:(AIFeatureNode*)protoST
                            new_Proto:(CGRect)new_Proto
                                newGV:(AIKVPointer*)newGV
                           olds_Proto:(CGRect)olds_Proto
                             colorDic:(NSDictionary*)colorDic
                                   ds:(NSString*)ds;

/**
 *  MARK:--------------------ST自举（新算法）--------------------
 *  @param assGT 选手1: assGT节点
 *  @param protoST 选手2: protoST节点
 *  @param curIndex 当前GV索引
 *  @param assT assT节点
 *  @param lastProtoRect 上一个proto切图区域
 *  @param lastAtAssRect 上一个ass切图区域
 *  @param colorDic 颜色字典
 *  @param ds 数据源
 *  @return 自举结果项，失败返回nil
 */
+ (AIFeatureJvBuItem*) stZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                                protoST:(AIFeatureNode*)protoST
                               curIndex:(NSInteger)curIndex
                                   assT:(AIFeatureNode*)assT
                          lastProtoRect:(CGRect)lastProtoRect
                          lastAtAssRect:(CGRect)lastAtAssRect
                               colorDic:(NSDictionary*)colorDic
                                     ds:(NSString*)ds;

/**
 *  MARK:--------------------GT自举（新算法）--------------------
 *  @param assGT 选手1: assGT节点
 *  @param protoST 选手2: protoST节点
 *  @param targetGT 目标GT节点
 *  @param beginIndex 开始索引
 *  @param beginSTModel 开始的ST模型
 *  @param colorDic 颜色字典
 *  @param ds 数据源
 *  @return GT自举模型
 */
+ (GTZiJvModelV2*) gtZiJvWithAssGT:(AIGroupFeatureNode*)assGT
                           protoST:(AIFeatureNode*)protoST
                          targetGT:(AIGroupFeatureNode*)targetGT
                        beginIndex:(NSInteger)beginIndex
                      beginSTModel:(AIFeatureJvBuModel*)beginSTModel
                          colorDic:(NSDictionary*)colorDic
                                ds:(NSString*)ds;

#pragma mark - 缓存管理

/**
 *  MARK:--------------------清空缓存--------------------
 */
+ (void) clearCache;

@end

NS_ASSUME_NONNULL_END
