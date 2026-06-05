//
//  Output.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/27.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "Output.h"
#import "OutputUtils.h"

@implementation Output

/**
 *  MARK:--------------------思维行为输出--------------------
 *  @version
 *      2021.02.05: 将概念嵌套的代码注掉,因为概念嵌套早已废弃;
 */
+(TCResult*) output_FromTC:(AIKVPointer*)algNode_p {
    //1. 数据
    AIAlgNodeBase *algNode = [SMGUtils searchNode:algNode_p];
    if (!ISOK(algNode, AIAlgNodeBase.class)) {
        return [[[TCResult new:false] mkMsg:@"output 输出非alg类型错误"] mkStep:51];
    }
    
    //2. 循环微信息组
    NSMutableArray *valids = [[NSMutableArray alloc] init];
    for (AIKVPointer *value_p in algNode.content_ps) {
        
        //3. 取dataSource & algsType
        NSString *identify = value_p.algsType;
        if (!value_p.isOut) {
            identify = [OutputUtils convertOutType2dataSource:value_p.algsType];
            WLog(@"调试下,何时会输出isOut=false的内容");
        }
        
        //4. 检查可输出"某数据类型"并收集
        if ([AINetUtils checkCanOutput:identify]) {
            OutputModel *model = [[OutputModel alloc] init];
            model.identify = identify;
            model.data = NUMTOOK([AINetIndex getData:value_p]);
            [valids addObject:model];
        }
    }
    
    //5. 执行输出
    if (ARRISOK(valids)) {
        return [self output_General:valids logBlock:^{
            //6. 将输出入网
            [theTC commitOutputLogAsync:valids];
        }];
    }
    return [[[TCResult new:false] mkMsg:@"output输出无效而失败"] mkStep:52];
}

+(void) output_FromReactor:(NSString*)identify datas:(NSArray*)datas{
    //1. 转为outModel
    NSMutableArray *models = [[NSMutableArray alloc] init];
    for (id data in ARRTOOK(datas)) {
        OutputModel *model = [[OutputModel alloc] init];
        model.identify = STRTOOK(identify);
        model.data = data;
        [models addObject:model];
    }

    //2. 传递到output执行
    if (ARRISOK(models)) {
        [Output output_General:models logBlock:^{
            //3. 将输出入网
            [theTC commitOutputLogAsync:models];
        }];
    }
}

/**
 *  MARK:--------------------情绪反射--------------------
 *  @todo
 *      2021.02.05: 将AIMoodType_Satisfy改为调用output_General()输出;
 */
+(void) output_FromMood:(AIMoodType)type{
    if (type == AIMoodType_Anxious) {
        //1. 生成outputModel
        OutputModel *model = [[OutputModel alloc] init];
        model.identify = ANXIOUS_RDS;
        model.data = @(1);
        
        //2. 输出
        [self output_General:@[model] logBlock:^{
            //3. 将输出mood提交给tc
            [AIInput commitIMV:MVType_Anxious from:10 to:3];
        }];
    }else if(type == AIMoodType_Satisfy){
        OutputModel *model = [[OutputModel alloc] init];
        model.identify = SATISFY_RDS;
        [[NSNotificationCenter defaultCenter] postNotificationName:kOutputObserver object:model];
    }
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------actions输出--------------------
 *  @desc 含: 反射被动输出 和 TC主动输出
 *  @param outputModels : OutputModel数组;
 *  如: 吸吮,抓握
 *  注: 先天,被动
 *  @version
 *      2021.02.05: 改为front取回useTime触发行为开始,到back再执行行为后视觉等触发 (参考22117);
 *      2021.02.26: 将timer改为SEL方式,因为block方式在模拟器运行会闪退;
 *      2023.07.22: 行为执行所需要时间返回到TCResult (参考30084-todo1);
 */
+(TCResult*) output_General:(NSArray*)outputModels logBlock:(void(^)())logBlock{
    //0. 输出行为输出到UI时,重新调用回主线程;
    __block NSArray *weakOutputModels = outputModels;
    __block Act0 weakLogBlock = logBlock;
    __block double useTime = 0;//从同步主线程取回所需要时间;
    
    //1. 取useTime
    for (OutputModel *model in ARRTOOK(weakOutputModels)) {
        model.type = OutputObserverType_UseTime;
        [[NSNotificationCenter defaultCenter] postNotificationName:kOutputObserver object:model];
        useTime = MAX(model.useTime, useTime);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //1. 广播执行行为开始 (执行行为动画,返回执行用时);
        for (OutputModel *model in ARRTOOK(weakOutputModels)) {
            model.type = OutputObserverType_Front;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOutputObserver object:model];
        }
        
        //2. 行为输出完成后;
        [NSTimer scheduledTimerWithTimeInterval:useTime target:self selector:@selector(notificationTimer:) userInfo:^(){
            //3. 将输出入网
            weakLogBlock();
            
            //4. 广播执行输出后 (现实世界处理 & 飞后视觉 & 价值触发等);
            for (OutputModel *model in ARRTOOK(weakOutputModels)) {
                model.type = OutputObserverType_Back;
                [[NSNotificationCenter defaultCenter] postNotificationName:kOutputObserver object:model];
            }
        } repeats:false];
    });
    return [[[[TCResult new:true] mkMsg:@"output输出成功"] mkDelay:useTime] mkStep:61];
}

+(void)notificationTimer:(NSTimer*)timer{
    Act0 invokeBlock = timer.userInfo;
    invokeBlock();
}

@end
