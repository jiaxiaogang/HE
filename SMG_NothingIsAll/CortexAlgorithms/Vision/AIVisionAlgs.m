//
//  AIVisionAlgs.m
//  SMG_NothingIsAll
//
//  Created by jiaxiaogang on 2018/11/15.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "AIVisionAlgs.h"
#import "AIVisionAlgsModel.h"
#import "XGRedis.h"
#import "UIView+Extension.h"
#import "NSObject+Extension.h"

@implementation AIVisionAlgs

/**
 *  MARK:--------------------新视觉帧--------------------
 *  @version
 *      2021.09.07: 取消rect限制 (因为木棒或鸟都有可能飞出屏幕);
 *      2021.09.14: 废弃速度,因为HE视觉是离散的,速度不重要 (参考24017-问题1);
 *      2022.06.04: 废弃X值和方向,新增X距 (参考26196);
 *      2022.06.05: 回退26196-方案3 (参考26196-尝试1);
 *      2023.03.08: 废除客观特征posXY (参考28161-方案5);
 *      2023.03.13: 用距离和方向替代XY距 (参考28173-方案3);
 */
+(void) commitView:(UIView*)selfView targetView:(UIView*)targetView rect:(CGRect)rect{
    //1. 数据准备;
    if (!selfView || !targetView) {
        return;
    }
    NSMutableArray *dics = [[NSMutableArray alloc] init];
    NSMutableArray *views = [targetView subViews_AllDeep];//subViews_AllDeepWithRect:rect];
    views = [SMGUtils filterArr:views checkValid:^BOOL(UIView *item) {
        return item.tag == visibleTag && item.alpha > 0;
    }];
    if (ARRISOK(views)) ISTitleLog(@"感官算法");
    
    //2. 生成model
    for (HEView *curView in views) {
        BOOL curViewIsShow = curView.alpha > 0 && !curView.hidden;
        if (curView.tag == visibleTag && curViewIsShow) {
            
            //3. 当坚果时，改由多码视觉V2输入之（参考34111-测试点3）。
            if (ISOK(curView, FoodView.class)) {
                FoodView *food = (FoodView*)curView;
                [AIVisionAlgsV2 commitInputV2:food.imgView.image logDesc:food.imgName cropRect:CGRectMake(0, 0, 1, 1)];
                return;
            }
            
            AIVisionAlgsModel *model = [[AIVisionAlgsModel alloc] init];
            //model.sizeWidth = [self sizeWidth:curView];
            model.sizeHeight = [self sizeHeight:curView];
            //model.colorRed = [self colorRed:curView];
            //model.colorGreen = [self colorGreen:curView];
            //model.colorBlue = [self colorBlue:curView];
            //model.radius = [self radius:curView];
            //model.speed = [self speed:curView];
            model.direction = [self direction:selfView target:curView];
            model.distance = [self distance:selfView target:curView];
            //model.distanceX = [self distanceX:selfView target:curView];
            //model.distanceY = [self distanceY:selfView target:curView];
            model.border = [self border:curView];
            //model.posX = [self posX:curView];
            //model.posY = [self posY:curView];
            //NSLog(@"视觉目标 [距离:%ld 角度:%f 宽:%f 高:%f 皮:%f 圆角:%f]",(long)model.distance,model.direction,model.sizeWidth,model.sizeHeight,model.border,model.radius);
            NSLog(@"视觉目标 [方向:%ld 距离:%ld 高:%ld 皮:%ld]",model.direction,model.distance,model.sizeHeight,model.border);
            NSMutableDictionary *modelDic = [NSObject getDic:model containParent:true];
            //for (NSString *key in modelDic.allKeys) {
            //    if ([NUMTOOK([modelDic objectForKey:key]) isEqualToNumber:@(0)]) {
            //        [modelDic removeObjectForKey:key];
            //    }
            //}
            [dics addObject:modelDic];
        }
    }
    
    //3. 传给thinkingControl
    [theTC commitInputWithModelsAsync:dics algsType:NSStringFromClass(self)];
}

//MARK:===============================================================
//MARK:                     < 视觉算法 >
//MARK:===============================================================

//size
+(NSInteger) sizeWidth:(UIView*)target{
    if (target) return (int)target.showW;
    return 0;
}
+(NSInteger) sizeHeight:(UIView*)target{
    if (target) return (int)target.showH;
    return 0;
}

//color
+(NSInteger) colorRed:(UIView*)target{
    if (target) return target.backgroundColor.red * 255.0f;
    return 0;
}
+(NSInteger) colorGreen:(UIView*)target{
    if (target){
        return target.backgroundColor.green * 255.0f;
    }
    return 0;
}
+(NSInteger) colorBlue:(UIView*)target{
    if (target) return target.backgroundColor.blue * 255.0f;
    return 0;
}

//radius
+(NSInteger) radius:(UIView*)target{
    if (target) return (int)(target.layer.cornerRadius * 100);//精度100
    return 0;
}

/**
 *  MARK:--------------------速度--------------------
 *  @desc 目前简单粗暴两桢差值 (随后有需要改用微积分)
 *  @version
 *      2020.07.07: 将主观速度,改为客观速度 (因为主观速度对识别略有影响,虽可克服,但懒得设计训练步骤,正好改成客观速度更符合今后的设计);
 *      2020.08.06: 将lastXY位置记录,加上initTime,因为ios的复用机制,会导致复用已销毁同内存地址的view (参考20151-BUG11);
 *      2021.09.14: 废弃速度,因为HE视觉是离散的,速度不重要 (参考24017-问题1);
 */
//+(NSInteger) speed:(HEView*)target{
//    //>> 主观速度代码;
//    //CGFloat speed = 0;
//    //CGPoint targetPoint = [UIView convertWorldPoint:target];
//    //CGPoint selfPoint = [UIView convertWorldPoint:selfView];
//    //CGFloat distanceX = (targetPoint.x - selfPoint.x);
//    //CGFloat distanceY = (targetPoint.y - selfPoint.y);
//    //CGFloat distance = sqrt(powf(distanceX, 2) + powf(distanceY, 2));
//    //
//    //NSString *key = STRFORMAT(@"lastDistanceOf_%p_%p",selfView,target);
//    //NSObject *lastDistanceNum = [[XGRedis sharedInstance] objectForKey:key];
//    //if (ISOK(lastDistanceNum, NSNumber.class)) {
//    //    CGFloat lastDistance = [((NSNumber*)lastDistanceNum) floatValue];
//    //    speed = distance - lastDistance;
//    //}
//    //[[XGRedis sharedInstance] setObject:[NSNumber numberWithFloat:distance] forKey:key time:cRTDefault];
//    //return (NSInteger)speed;
//
//    //1. 当前位置
//    CGFloat speed = 0;
//    CGPoint targetPoint = [UIView convertWorldPoint:target];
//    //2. 上帧位置
//    NSString *lastXKey = STRFORMAT(@"lastX_%p_%lld",target,target.initTime);
//    NSString *lastYKey = STRFORMAT(@"lastY_%p_%lld",target,target.initTime);
//    NSObject *lastXObj = [[XGRedis sharedInstance] objectForKey:lastXKey];
//    NSObject *lastYObj = [[XGRedis sharedInstance] objectForKey:lastYKey];
//    if (ISOK(lastXObj, NSNumber.class) && ISOK(lastYObj, NSNumber.class)) {
//        CGFloat lastX = [((NSNumber*)lastXObj) floatValue];
//        CGFloat lastY = [((NSNumber*)lastYObj) floatValue];
//
//        //3. 计算位置差
//        CGFloat distanceX = (targetPoint.x - lastX);
//        CGFloat distanceY = (targetPoint.y - lastY);
//        speed = sqrt(powf(distanceX, 2) + powf(distanceY, 2));
//    }
//
//    //4. 存位置下帧用
//    [[XGRedis sharedInstance] setObject:[NSNumber numberWithFloat:targetPoint.x] forKey:lastXKey time:cRTDefault];
//    [[XGRedis sharedInstance] setObject:[NSNumber numberWithFloat:targetPoint.y] forKey:lastYKey time:cRTDefault];
//
//    //5. 返回结果 (保留整数位)
//    return (NSInteger)speed;
//}

/**
 *  MARK:--------------------direction--------------------
 *  @version
 *      2023.03.13: 打开方向码 (参考28174-todo1);
 */
+(NSInteger) direction:(UIView*)selfView target:(UIView*)target{
    //1. 取距离
    CGPoint distanceP = [UIView distancePoint:selfView target:target];
    
    //2. 将距离转成角度-PI -> PI (从左顺时针一圈为-3.14到3.14)。
    CGFloat rads = atan2f(distanceP.y,distanceP.x);
    
    //3. 将(-PI到PI) 转换成 (0到1)
    float protoParam = (rads / M_PI + 1) / 2;
    
    //4. 8向(0-1)版本: 返回8向:
    ////4. 将(0到1)转成四舍五入整数(0-8);
    //int paramInt = (int)roundf(protoParam * 8.0f);
    //
    ////5. 如果是8,也是0;
    //return (paramInt % 8) / 8.0f;
    
    //4. 360向(0-360)版本: 返回360向;
    NSInteger result = (NSInteger)roundf(protoParam * 360.0f);
    if (Log4CortexAlgs) NSLog(@"视觉目标 方向角度:%.2f (%.2f) 返回:%ld",rads / M_PI * 180,protoParam,result);
    return result;
}

/**
 *  MARK:--------------------distance--------------------
 *  @version
 *      2021.05.07: 有时距离明明是0,但却吃不到 (小鸟是方的不是圆的,所以在距离判断上,与eat方法保持一致) (无笔记,怀疑是此处导致就改了);
 */
+(NSInteger) distance:(UIView*)selfView target:(UIView*)target{
    CGPoint disPoint = [UIView distancePoint:selfView target:target];
    CGFloat disFloat = sqrt(powf(disPoint.x, 2) + powf(disPoint.y, 2));
    NSInteger distance = (NSInteger)(disFloat / 3.0f);
    //与身体重叠,则距离为0;
    if (fabs(disPoint.x) <= 15.0f && fabs(disPoint.y) <= 15.0f) {
        distance = 0;
    }
    return distance;
}

/**
 *  MARK:--------------------distanceY--------------------
 *  @version
 *      2021.01.23: 改为返回真实距离 (什么距离可以被撞到,由反省类比自行学习);
 *      2021.01.24: 真实距离导致DisY在多向飞行的VRS评价容易为否,所以先停掉 (随时防撞训练时,需要再打开,因为多向飞行向上下飞,应该可以不怕此问题);
 *      2021.01.24: 经分析评价为否是因为很少经历多变的DisY,所以将直投到乌鸦身上的位置更随机些,此处又改为真实距离了 (经训练多向飞行ok);
 */
+(NSInteger) distanceY:(UIView*)selfView target:(UIView*)target{
    return selfView.showY - target.showY;
    //1. 数据准备;
    //CGFloat selfY = [UIView convertWorldRect:selfView].origin.y;
    //CGFloat selfMaxY = selfY + selfView.height;
    //CGFloat targetY = [UIView convertWorldRect:target].origin.y;
    //CGFloat targetMaxY = targetY + target.height;
    //
    ////2. self在下方时;
    //if (selfY > targetMaxY) {
    //    return selfY - targetMaxY;
    //}else if(targetY > selfMaxY){
    //    //3. self在上方时;
    //    return targetY - selfMaxY;
    //}
    ////4. 有重叠时,直接返回0;
    //return 0;
}
+(NSInteger) distanceX:(UIView*)selfView target:(UIView*)target{
    return selfView.showX - target.showX;
}

//border
+(NSInteger) border:(UIView*)target{
    if (target) return (int)(target.layer.borderWidth * 100);//精度100
    return 0;
}

//posX
+(NSInteger) posX:(UIView*)target{
    if (target) return (NSInteger)[UIView convertWorldPoint:target].x;
    return 0;
}

//posY
+(NSInteger) posY:(UIView*)target{
    if (target) return (NSInteger)[UIView convertWorldPoint:target].y;
    return 0;
}

@end
