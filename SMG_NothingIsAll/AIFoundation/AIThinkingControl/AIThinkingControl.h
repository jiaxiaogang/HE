//
//  AIThinkingControl.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/11/12.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define tiQueueLab @"ThinkInQueue"
#define toQueueLab @"ThinkOutQueue"

/**
 *  MARK:--------------------思维控制器--------------------
 *  1. 主要负责思维 (前额叶) 功能;
 *  2. 次要负责分发激活等 (丘脑) 功能;
 */
@class ShortMatchManager,DemandManager,TCDebug,OutputModel;
@interface AIThinkingControl : NSObject

+(AIThinkingControl*) shareInstance;
@property (strong, nonatomic) TCDebug *tiTCDebug;
@property (strong, nonatomic) TCDebug *toTCDebug;
@property (strong, nonatomic) dispatch_queue_t tiQueue; //TI异步线程
@property (strong, nonatomic) dispatch_queue_t toQueue; //TO异步线程

/**
 *  MARK:--------------------思维模式--------------------
 *  @desc 0动物模式(IO都启), 1认知模式(I启O停), 2植物模式(IO都停);
 *  @desc 强行停止思维工作 (参考27084-TODO4);
 *          1. TO通过energyValid返false阻断TCSolution来实现;
 *          2. TI通过阻断Input感知来实现;
 */
@property (assign, nonatomic) int thinkMode;

//MARK:===============================================================
//MARK:                     < 输入流程 >
//MARK:===============================================================

/**
 *  MARK:--------------------流入input--------------------
 */
-(void) commitInputAsync:(NSObject*)algsModel;
-(void) commitInputWithSplitAsyncV2:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc;//输入无粒度，以支持自适应粒度
-(void) commitInputWithModelsAsync:(NSArray*)dics algsType:(NSString*)algsType;
/**
 *  MARK:--------------------输出的日志入网(输入小脑)--------------------
 *  @param outputModel : 输出内容(如:eat)
 *  注: 大脑为引,小脑为行
 */
-(void) commitOutputLogAsync:(OutputModel*)outputModel;


//MARK:===============================================================
//MARK:                     < 短时记忆 >
//MARK:===============================================================
-(ShortMatchManager*) inModelManager;
-(DemandManager*) outModelManager;


//MARK:===============================================================
//MARK:                     < 活跃度 >
//MARK:===============================================================

/**
 *  MARK:--------------------消耗活跃度--------------------
 */
-(void) updateEnergyDelta:(CGFloat)delta;

/**
 *  MARK:--------------------设新活跃度--------------------
 *  @desc 只有当新的更大时,才有效;
 */
-(void) updateEnergyValue:(CGFloat)value;
-(BOOL) energyValid;

//MARK:===============================================================
//MARK:                     < 操作计数 >
//MARK:===============================================================
-(void) updateOperCount:(NSString*)operater;
-(void) updateOperCount:(NSString*)operater min:(NSInteger)min;
-(long long) getOperCount;

//MARK:===============================================================
//MARK:                     < 循环Id >
//MARK:===============================================================
-(void) updateLoopId;
-(long long) getLoopId;

//MARK:===============================================================
//MARK:                     < 清思维 >
//MARK:===============================================================
-(void) clear;

//MARK:===============================================================
//MARK:                     < 更新TCDebug读写次数 >
//MARK:===============================================================
-(void) updateTCDebugLastRCount;
-(void) updateTCDebugLastWCount;

//MARK:===============================================================
//MARK:                     < QueueMethod >
//MARK:===============================================================
+(NSString*) getCurQueueLab;

@end
