//
//  AIImvAlgs.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/12/21.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AIImvAlgs.h"
#import "ImvAlgsHungerModel.h"
#import "ImvAlgsHurtModel.h"
#import "ImvAlgsUnknownModel.h"

@implementation AIImvAlgs

/**
 *  MARK:--------------------输入mindValue--------------------
 *  @param from | to : 值域,转换为0-10;(例如:hunger时表示饥饿度,10为无电非常饿,0为满电不饿);
 */
+(ImvAlgsModelBase*) commitIMV:(MVType)type from:(CGFloat)from to:(CGFloat)to{
    //1. 数据准备;
    ImvAlgsModelBase *imvModel = nil;
    if (type == MVType_Hunger) {
        //2. 生成imvModel_饿感;
        imvModel = [[ImvAlgsHungerModel alloc] init];
    }else if(type == MVType_Hurt){
        //3. 生成imvModel_痛感;
        imvModel = [[ImvAlgsHurtModel alloc] init];
    }else if(type == MVType_Anxious){}
    else if(type == MVType_Unknown){
        //4. 生成imvModel_未知恐惧（参考38065-TODO1）；
        imvModel = [[ImvAlgsUnknownModel alloc] init];
    }
    
    //4. 对imvModel计算赋值;
    if (imvModel) {
        //5. 计算from to
        imvModel.urgentTo = [self getBadImvUrgentValue:to];//痛9 饿16
        CGFloat urgentFrom = [self getBadImvUrgentValue:from];//痛4 饿9
        
        //6. 计算delta (ISOK(imvModel, ImvBadModel.class))
        imvModel.delta = imvModel.urgentTo - urgentFrom;    //更痛5 更饿7;
    }
    return imvModel;
}

/**
 *  MARK:--------------------BadImv迫切度--------------------
 *  @desc 指迫切度与value在"同向"上,比如更饿,越饿迫切度越高;
 *  @status 目前,饥饿感和痛感都是采用了此种;
 */
+(CGFloat) getBadImvUrgentValue:(CGFloat)to{
    to = MAX(0, MIN(10,to));
    return to * to;
}

/**
 *  MARK:--------------------GoodImv迫切度--------------------
 *  @desc 指迫切度与valud在"反向"上,比如更饱,越饱迫切度越低;
 *  @status 目前,无GoodImv子定义,所以此处未被调用;
 */
+(CGFloat) getGoodImvUrgentValue:(CGFloat)to{
    to = MAX(0, MIN(10,to));
    return 100 - to * to;
}

@end
