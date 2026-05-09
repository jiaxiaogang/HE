//
//  RTModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/31.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "RTModel.h"
#import "DeviceUtil.h"

#define TimerInterval 0.6f

@interface RTModel ()

@property (strong, nonatomic) NSMutableDictionary *dic;     //技能字典
@property (strong, nonatomic) NSMutableArray *queues;       //训练队列
@property (assign, nonatomic) NSInteger queueIndex;         //训练进度
@property (strong, nonatomic) NSTimer *timer;               //间隔计时器
@property (assign, nonatomic) long long lastOperCount;      //思维操作计数
@property (assign, nonatomic) long long useTimed;           //已使用时间
@property (assign, nonatomic) long long lastStartTime;      //最后一次开始时间
@property (strong, nonatomic) NSString *invokingName;       //当前执行中name;
@property (strong, nonatomic) NSMutableArray *pauseNames;   //需要停下等待的命令;
@property (assign, nonatomic) int cpuContinuousIdleNum;     //CPU还需要再闲次数。

@end

@implementation RTModel

-(id) init {
    self = [super init];
    if(self != nil){
        [self initData];
    }
    return self;
}

-(void) initData{
    self.dic = [[NSMutableDictionary alloc] init];
    self.queues = [[NSMutableArray alloc] init];
    self.pauseNames = [[NSMutableArray alloc] init];
    dispatch_async(dispatch_get_main_queue(), ^{
       self.timer = [NSTimer scheduledTimerWithTimeInterval:TimerInterval target:self selector:@selector(timeBlock) userInfo:nil repeats:true];
    });
}

//MARK:===============================================================
//MARK:                     < getset >
//MARK:===============================================================
-(NSMutableArray *)queues{
    return _queues;
}

-(NSInteger)queueIndex{
    return _queueIndex;
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================
-(void) regist:(NSString*)name target:(NSObject*)target selector:(SEL)selector{
    
    //1. 获得类和方法的签名
    NSMethodSignature *methodSignature = [[target class] instanceMethodSignatureForSelector:selector];
    
    //2. 反射器;
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    
    //3. 从签名获得调用对象
    [invocation setTarget:target];
    invocation.target = target;
    invocation.selector = selector;
    
    //4. 收集备用;
    [self.dic setObject:invocation forKey:name];
}

-(void) queue:(NSArray*)queues count:(NSInteger)count{
    //1. 数据检查;
    queues = ARRTOOK(queues);
    
    //2. 更新训练队列;
    for (NSInteger i = 0; i < count; i++) {
        for (RTQueueModel *queue in queues) {
            [self.queues addObject:queue];
        }
    }
}

//单步训练执行完成报告;
-(void) invoked:(NSString*)name{
    if ([STRTOOK(name) isEqualToString:self.invokingName]) {
        self.invokingName = nil;
    }
}

-(void) clear{
    [self.queues removeAllObjects];
    self.queueIndex = 0;
    self.useTimed = 0;
    self.lastStartTime = 0;
}

//返回useTimed + 现在播放中已用时;
-(long long) getTotalUseTimed{
    if (self.lastStartTime > 0) {
        long long now = [[NSDate new] timeIntervalSince1970];
        return self.useTimed + now - self.lastStartTime;
    }
    return self.useTimed;
}

//MARK:===============================================================
//MARK:               < publicMethod: 触发暂停命令 >
//MARK:===============================================================

/**
 *  MARK:--------------------增加暂停命令 (参考28172-todo1.1)--------------------
 *  @desc 用于有些预约指令需要时间等待执行,防止强训工具提前退出本次训练 (所以一般用于防止回到MainPage或模拟重启);
 */
-(void) appendPauseNames:(NSArray*)value {
    [self.pauseNames addObjectsFromArray:value];
}

-(void) clearPauseNames {
    [self.pauseNames removeAllObjects];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(void) invoke:(RTQueueModel*)queue {
    NSInvocation *invc = [self.dic objectForKey:queue.name];
    id arg0 = queue.arg0, arg1 = queue.arg1, arg2 = queue.arg2;
    if (arg0) [invc setArgument:&arg0 atIndex:2];
    if (arg1) [invc setArgument:&arg1 atIndex:3];
    if (arg2) [invc setArgument:&arg2 atIndex:4];
    @try {
        [invc invoke];
    }@catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

//暂停时,把最后一次训练用时收集到已用时:useTimed中;
-(void) pauseCollectUseTimed{
    if (self.lastStartTime > 0) {
        long long now = [[NSDate new] timeIntervalSince1970];
        self.useTimed += now - self.lastStartTime;
        self.lastStartTime = 0;
    }
}

//开始播放时,记下开始播放的时间;
-(void) playSetLastStartTime{
    if (self.lastStartTime == 0) {
        self.lastStartTime = [[NSDate new] timeIntervalSince1970];
    }
}

//MARK:===============================================================
//MARK:                     < block >
//MARK:===============================================================

/**
 *  MARK:--------------------强训执行器--------------------
 *  @version
 *      2023.02.11: 在等待上条命名,或思维空载时,kFlySEL继续执行 (参考28066-todo2);
 *      2023.02.11: BUG_多次飞的动画似乎有一点交叉,改为行为输出时,必须等上条执行完,才能执行下条;
 */
-(void) timeBlock {
    //1. 不用执行: 非播放状态,return;
    if (![self.delegate rtModel_Playing]) {
        [self pauseCollectUseTimed];
        return;
    }
    
    //2. 不用执行: 执行播放完时,return;
    if (self.queueIndex == self.queues.count){
        [self pauseCollectUseTimed];
        [self.delegate rtModel_Finished];
        return;
    }
    
    //3. 意外>count时处理;
    if (self.queueIndex > self.queues.count) return;
    [self playSetLastStartTime];
    
    //3. 暂停命令等待;
    RTQueueModel *queue = ARR_INDEX(self.queues, self.queueIndex);
    if ([self.pauseNames containsObject:queue.name]) {
        NSLog(@"----> 强化训练_遇到暂停命令 -> 等待");
        return;
    }
    
    //4. 行为输出时,会即刻执行;
    BOOL curNeedWait = ![kFlySEL isEqualToString:queue.name];
    BOOL lastNeedCurWait = [kFlySEL isEqualToString:self.invokingName];
    
    //5. (a || b) && c => 需要等待上一命令执行完;
    //  a. 这步要求等待 = curNeedWait;
    //  b. 上步要求这步等它 = lastNeedCurWait (上条命令是行为);
    //  c. 这步执行中 = STRISOK(self.invokingName);
    if ((curNeedWait || lastNeedCurWait) && STRISOK(self.invokingName)) {
        NSLog(@"----> 强化训练_上帧执行中 -> 等待");
        return;
    }
    
    //6. 非即刻执行的命令 => 等待思维空载;
    if (curNeedWait) {
        //7. 思维忙时没轮到下帧: TC忙碌状态则返回 (计数速率(负载)>10时,为忙状态);
        NSInteger operDelta = theTC.getOperCount - self.lastOperCount;
        self.lastOperCount = theTC.getOperCount;
        BOOL busyStatus = operDelta > 0;
        if (busyStatus) {
            NSLog(@"----> 强化训练_思维负载(%ld) -> 等待",operDelta);
            return;
        }
        
        // 连续3秒占用都在10%以下时，可执行下帧
        double curCpuUsage = [DeviceUtil getCpuUsage];
        self.cpuContinuousIdleNum = curCpuUsage < 10 ? self.cpuContinuousIdleNum + 1 : 0;
        if (self.cpuContinuousIdleNum < 3) {
            NSLog(@"----> 强化训练_CPU负载(%.2f%%) -> 等待",curCpuUsage);
            return;
        }
    }
    
    //8. 执行下帧;
    NSLog(@"强化训练 -> 执行:%@ (%ld/%ld)",queue.name,self.queueIndex+1,self.queues.count);
    self.queueIndex++;
    self.invokingName = queue.name;
    [self invoke:queue];
    [self.delegate rtModel_Invoked];
}

@end
