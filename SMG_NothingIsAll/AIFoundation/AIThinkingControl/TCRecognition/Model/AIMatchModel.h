//
//  AIMatchModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/19.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------单条识别结果--------------------
 */
@interface AIMatchModel : NSObject

-(id) initWithMatch_p:(AIKVPointer*)match_p;

@property (strong, nonatomic) AIKVPointer *match_p; //匹配概念
@property (strong, nonatomic) AINodeBase *matchNode; //匹配ass节点（不一定存，用时要注意是否有值）。

@property (assign, nonatomic) CGFloat matchValue;   //相似度（乘积，默认为1）
@property (assign, nonatomic) NSInteger matchCount; //相似条数
@property (assign, nonatomic) CGFloat sumMatchValue;//总相似度（求平均相似度时，才会用到，乘积相似度用不着这个）
@property (assign, nonatomic) CGFloat matchDegree;   //位置符合度
@property (assign, nonatomic) NSInteger sumRefStrong;//总强度，没什么用，后续再删吧。

@property (strong, nonatomic) NSDictionary *indexDic; //匹配到的映射 (k为assIndex,v为protoIndex)
@property (strong, nonatomic) NSDictionary *degreeDic;// <K=assIndex,V=matchDegree值>
@property (assign, nonatomic) CGFloat sumMatchDegree;//总符合度

@property (assign, nonatomic) CGRect rect;//存当前ass_p在proto_p中的rect。
@property (assign, nonatomic) NSInteger assCount;//match_p的总长度。
@property (assign, nonatomic) NSInteger protoCount;//proto_p的总长度。
@property (assign, nonatomic) CGFloat matchAssProtoRatio;   //健全度：assCount/protoCount（因为特征识别结果往往GV太少，加这一要素）。
@property (assign, nonatomic) NSInteger sumConStrong;       //ass被抽象的总强度，从conPort中取sumStrong（为了找出更稳定的显著的特征，在特征识别竞争中，加这一要素）。
@property (assign, nonatomic) CGFloat matchConStrongRatio;  //显著度：被抽象强度程度（越高越好，因为它是更显著的特征）。

@end
