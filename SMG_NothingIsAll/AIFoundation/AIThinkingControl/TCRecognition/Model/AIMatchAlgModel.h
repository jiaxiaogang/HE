//
//  AIMatchAlgModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2022/1/15.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------单条matchAlg模型--------------------
 */
@interface AIMatchAlgModel : NSObject

//+(AIMatchAlgModel*) newWithMatchAlg:(AIKVPointer*)matchAlg matchCount:(int)matchCount sumNear:(CGFloat)sumNear nearCount:(int)nearCount sumRefStrong:(int)sumRefStrong;
@property (strong, nonatomic) AIKVPointer *matchAlg;//匹配概念
@property (assign, nonatomic) int matchCount;       //匹配数
@property (assign, nonatomic) NSInteger groupValueMatchCount;//GV匹配数
@property (assign, nonatomic) CGFloat sumNear;      //总相近度 (参考25082-公式2分子部分) (20230119改为默认1参考28035-todo1);
@property (assign, nonatomic) int nearCount;        //相近度<1的相近个数
@property (assign, nonatomic) int sumRefStrong;     //总引用强度 (稀疏码被此概念引用的强度和);

/**
 *  MARK:--------------------获取相近度--------------------
 */
-(CGFloat) matchValue;

/**
 *  MARK:--------------------获取强度--------------------
 */
-(CGFloat) strongValue;

@property (strong, nonatomic) NSMutableDictionary *indexDic;//把protoAlg和assAlg的映射存下来，用于类比。

@end
