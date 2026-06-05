//
//  DemandModel.h
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/8/2.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "TOModelBase.h"
#import "ITryActionFoDelegate.h"

/**
 *  MARK:--------------------思维控制器中任务序列的_数据模型--------------------
 *  @version
 *      2020-05-22 : 将demandModel下直接挂载Fo,然后Fo下,再挂载subFo (Fo和subFo都用TOModelBase模型);
 *      2021-01-21 : 支持P和R两个子类;
 *      2021-01-27 : 支持二级排序initTime;
 */
@interface DemandModel : TOModelBase <ITryActionFoDelegate>

@property (assign, nonatomic) NSInteger urgentTo;   //一级排序因素 (高在前)
@property (assign, nonatomic) NSInteger delta;
@property (strong, nonatomic) NSString *algsType;   //mv的标识
@property (assign, nonatomic) double initTime;      //二级排序因素 (新在前)

/**
 *  MARK:--------------------取出besting/bested的解决方案--------------------
 */
-(NSArray*) bestCansets;

/**
 *  MARK:--------------------获取当前最强的outSubModel--------------------
 *  @result 返回TOModelBase或其子类型;
 */
//-(id) getCurSubModel;

/**
 *  MARK:--------------------更新时间衰减--------------------
 *  1. 懒衰减,什么时候取order,什么时候进行衰减;
 *  2. 衰减规则:
 *      > 1分钟内加10;
 *      > 10分钟内持平;
 *      > 10分钟后-10;
 *      > 小于0则销毁;
 */
@property (assign, nonatomic) double updateTime;

@property (assign, nonatomic) BOOL alreadyInitCansetModels;

@end
