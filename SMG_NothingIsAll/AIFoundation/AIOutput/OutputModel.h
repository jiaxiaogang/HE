//
//  OutputModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2019/1/9.
//  Copyright © 2019年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------输出模型--------------------
 */
@interface OutputModel : NSObject

/**
 *  MARK:--------------------通知标识符--------------------
 *  注: 目前输出是单值的,所以此处rds其实就是algsType,比如EAT_RDS,以后有了结构化后,再细分拆开;
 */
@property (strong,nonatomic) NSString *identify;

//参数值 (NSNumber数组) 。
@property (strong,nonatomic) NSArray *datas;

//输出类型 (阶段)
@property (assign, nonatomic) OutputObserverType type;

//输出所需时间
@property (assign, nonatomic) CGFloat useTime;

@end
