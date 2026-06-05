//
//  BirdView.m
//  SMG_NothingIsAll
//
//  Created by jiaxiaogang on 2018/11/7.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import "BirdView.h"
#import "FoodView.h"
#import "AIReactorControl.h"
#import "NVHeUtil.h"

@interface BirdView ()

@property (strong,nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLab;

@end

@implementation BirdView

-(id) init {
    self = [super init];
    if(self != nil){
        [self initView];
        [self initData];
        [self initDisplay];
    }
    return self;
}

-(void) initView{
    //self
    [self setBackgroundColor:[UIColor clearColor]];
    [self setFrame:CGRectMake(100, 100, 30, 30)];
    
    //containerView
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self addSubview:self.containerView];
    [self.containerView setFrame:CGRectMake(0, 0, 30, 30)];
}

-(void) initData{
}

-(void) initDisplay{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputObserver:) name:kOutputObserver object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(inputObserver:) name:kInputObserver object:nil];
}

-(void) viewWillDisappear {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================

/**
 *  MARK:--------------------飞--------------------
 *  @version
 *      2023.05.20: 改为物理仿真飞行 (为了碰撞检测用物理仿真更准确,而用了后飞行就必须也用) (参考29096-问题2-另外);
 *      2023.05.21: v2物理仿真: "飞行卡循环,木棒扔不全",所以切回v1 (参考29097);
 *      2023.06.24: 飞过坚果检测,交把结果存下来,以便触发"吃行为"后将其吃掉 (参考30041-记录3);
 */
-(void) flyAction:(CGFloat)value {
    [self flyActionV1:value];
}

-(void) flyActionV1:(CGFloat)value{
    //1. 数据检查
    value = MAX(MIN(1, value), 0);
    
    //2. 将从左顺时针: "0至1",转换为: "-1至1";
    CGFloat value_F1_1 = value * 2 - 1;
    
    //3. 将"-1至1",转为: "-180至180度";
    CGFloat angle = value_F1_1 * M_PI;
    
    //4. 用sin计算对边Y,cos计算邻边X;
    NSLog(@"fly >> %@ angle:%.0f",[NVHeUtil getLightStr_Value:value algsType:FLY_RDS dataSource:@""],value_F1_1 * 180);
    CGFloat duration = 0.15f;
    [self.delegate birdView_FlyAnimationBegin:duration];
    CGRect birdStart = self.frame;
    [UIView animateWithDuration:duration animations:^{
        [self setX:self.x + (cos(angle) * 30.0f)];
        [self setY:self.y + (sin(angle) * 30.0f)];
    }completion:^(BOOL finished) {
        //5. 飞完动画时,要调用下碰撞检测 (因为UIView动画后,不会立马执行frame更新);
        [self.delegate birdView_FlyAnimationFinish];
        //5. 飞后与坚果碰撞检测 (参考28172-todo2.2 & 30041-记录3);
        self.hitFoods = [self.delegate birdView_GetFoodOnHit:birdStart birdEnd:self.frame caller:@"eat"];
        if (ARRISOK(self.hitFoods)) {
            
            //6. 如果飞到坚果上,则触发吃掉 (参考28172-todo2.1);
            [self touchMouth];
        }
        //7. 强训飞完报告;
        [theRT invoked:kFlySEL];
    }];
}

-(void) flyResult:(CGFloat)value{
    //1. 飞后视觉
    [self see:[self.delegate birdView_GetPageView] fromObserver:false];
}

-(void) see:(UIView*)view fromObserver:(BOOL)fromObserver {
    if (self.delegate && [self.delegate respondsToSelector:@selector(birdView_GetSeeRect)]) {
        //1. 将视觉范围下,的视觉信息输入大脑;
        CGRect rect = [self.delegate birdView_GetSeeRect];
        [AIInput commitView:self targetView:view rect:rect fromObserver:fromObserver];
    }
}

//MARK:===============================================================
//MARK:                     < onclick >
//MARK:===============================================================
- (IBAction)mouchOnClick:(id)sender {
    DemoLog(@"鸟嘴 吸吮反射");
    [self touchMouth];
}

//MARK:===============================================================
//MARK:                     < 摸反射 >
//MARK:===============================================================

//被动吃
-(void) touchMouth{
    //2. 吃
    [AIReactorControl commitReactor:EAT_RDS];
}

/**
 *  MARK:--------------------摸翅膀--------------------
 *  @param direction 从左顺时针,8个方向,分别为0-7;
 */
-(void) touchWing:(long)direction {
    //1. 飞前视觉
    //[self see:[self.delegate birdView_GetPageView]];
    
    //2. 飞行
    float data = direction / 8.0f;
    [AIReactorControl commitReactor:FLY_RDS datas:@[@(data)]];
}

/**
 *  MARK:--------------------摸脚--------------------
 *  @param direction 从左顺时针,8个方向,分别为0-7;
 */
-(void) touchFoot:(long)direction {
    float data = direction / 8.0f;
    [AIReactorControl commitReactor:KICK_RDS datas:@[@(data)]];
}

/**
 *  MARK:--------------------痛--------------------
 *  @version
 *      2021.01.25: 加大痛感,否则不痛不痒的思维没活力 (乌鸦不care);
 *      2023.06.29: 增强痛感 (参考30044-BUG1);
 */
-(void) hurt{
    DemoLog(@"痛感");
    [AIInput commitIMV:MVType_Hurt from:8.0f to:9.0f];
    [self.titleLab setTextColor:UIColor.redColor];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.titleLab setTextColor:UIColor.whiteColor];
    });
}

-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/**
 *  MARK:--------------------吃--------------------
 *  @desc 无论是主动吃,还是被动吃,都要观察下吃前的视觉,吃后的视觉,以及价值上的影响;
 *  @version
 *      2020.01.20: 吃前视觉仅由被动吃时有,为解决外层死循环问题 (参考n18p5-BUG9);
 *      2023.03.11: 吃上了,不会立马感觉饱,而是不再继续更饿 (参考28171-todo2);
 *      2023.06.24: 触发吃后,吃掉碰撞到的坚果 (参考30041-记录3);
 */
-(void) eatAction:(CGFloat)value{
    //1. 吃动作
    [UIView animateWithDuration:0.3f animations:^{
        [self.containerView.layer setTransform:CATransform3DMakeRotation(M_PI_4 * 0.5f, 0, 0, 1)];
    }completion:^(BOOL finished) {
        //2. 吃完动作
        [UIView animateWithDuration:0.3f animations:^{
            [self.containerView.layer setTransform:CATransform3DIdentity];
        }completion:^(BOOL finished) {
            [theRT invoked:kEatSEL];
        }];
    }];
}

-(void) eatResult:(CGFloat)value{
    //1. 嘴附近的食物
    self.hitFoods = ARRTOOK(self.hitFoods);
    BOOL eated = false;
    
    //2. 吃掉UI (计时器触发,更饿时,发现没坚果吃,并不能解决饥饿问题,参考:18084_todo1);
    for (FoodView *foodView in self.hitFoods) {
        //3. 吃掉 (让he以吸吮反射的方式,去主动吃;并将out入网,以抽象出"吃"的节点;参考n15p6-QT1)
        if(foodView.canEat) {
            eated = true;
            [foodView removeFromSuperview];
        }else if(foodView.status == FoodStatus_Border){
            //b. 产生HurtMindValue (坚果带皮时,不仅吃不到,还得嘴疼);
            //[AIInput commitIMV:MVType_Hurt from:2.0f to:3.0f];
        }
    }
    
    //3. 吃到 或 没吃到 => 的吃后视觉 & waitEat标记;
    if (eated){
        //4. 吃完视觉 (其实啥也看不到);
        [self see:[self.delegate birdView_GetPageView] fromObserver:false];
        
        //5. 价值变化: 吃上了,不会立马感觉饱,而是不再继续更饿 (参考28171-todo2);
        DemoLog(@"吃上坚果了");
        self.waitEat = false;
        
        //6. 2024.07.22: 立马变的不饿,避免它一直吃;
        [self.delegate birdView_HungerEnd];
    }else{
        //3. 没坚果可吃 (计时器触发,更饿时,发现没坚果吃,并不能解决饥饿问题,参考:18084_todo1);
    }
}

//MARK:===============================================================
//MARK:                     < 踢 >
//MARK:===============================================================
-(void) kickAction:(OutputModel*)model{
    //1. 数据检查
    CGFloat value = [model.data floatValue];
    value = MAX(MIN(1, value), 0);
    
    //2. 将从左顺时针: "0至1",转换为: "-1至1";
    CGFloat value_F1_1 = value * 2 - 1;
    
    //3. 将"-1至1",转为: "-180至180度";
    CGFloat angle = value_F1_1 * M_PI;
    
    //4. 用sin计算对边Y,cos计算邻边X;
    NSLog(@"kick >> %@ angle:%.0f",[NVHeUtil getLightStr_Value:value algsType:KICK_RDS dataSource:@""],value_F1_1 * 180);
    CGFloat duration = model.useTime;
    CGRect birdStart = self.frame;
    
    //5. 踢动作;
    [UIView animateWithDuration:duration / 2.0f animations:^{
        [self.containerView.layer setTransform:CATransform3DMakeRotation(M_PI_4 * 1.0f, 1, 0, 0)];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:duration / 2.0f animations:^{
            [self.containerView.layer setTransform:CATransform3DIdentity];
        }completion:^(BOOL finished) {
            //6. 强训踢完报告;
            [theRT invoked:kKickSEL];
        }];
    }];
    
    //7. 坚果踢出距离;
    self.hitFoods = [self.delegate birdView_GetFoodOnHit:birdStart birdEnd:self.frame caller:@"kick"];
    if (ARRISOK(self.hitFoods)) {
        [UIView animateWithDuration:duration animations:^{
            for (UIView *foodView in self.hitFoods) {
                [foodView setX:foodView.x + (cos(angle) * 30.0f)];
                [foodView setY:foodView.y + (sin(angle) * 30.0f)];
            }
        }];
    }
}

//MARK:===============================================================
//MARK:                     < outputObserver >
//MARK:===============================================================

/**
 *  MARK:--------------------肢体输出--------------------
 *  @version
 *      2023.06.23: 输出吃时: 立马就吃到,而不是等动画结束 (参考30041-记录2);
 */
-(void) outputObserver:(NSNotification*)notification{
    if (notification && ISOK(notification.object, OutputModel.class)) {
        //1. 取数据
        OutputModel *model = (OutputModel*)notification.object;
        
        //2. 吸吮反射 / 主动吃
        if ([EAT_RDS isEqualToString:model.identify]) {
            if (OutputObserverType_UseTime == model.type) {
                model.useTime = 0.2f;
            } else if (OutputObserverType_Front == model.type) {
                //b. 吃前 => 行为动画;
                [self eatAction:[model.data floatValue]];
                
                //c. 吃后 => 世界变化 & 视觉 & 产生mv;
                [self eatResult:[model.data floatValue]];
            }else if(OutputObserverType_Back == model.type){}
        }
        //3. 扇翅膀反射
        else if([FLY_RDS isEqualToString:model.identify]){
            if (OutputObserverType_UseTime == model.type) {
                model.useTime = 0.1f;
            } else if (OutputObserverType_Front == model.type) {
                //a. 飞前 => 行为动画;
                NSLog(@"飞前视觉%p:%@",model,[NVHeUtil fly2Str:NUMTOOK(model.data).floatValue]);
                [self flyAction:[model.data floatValue]];
            }else if(OutputObserverType_Back == model.type){
                //b. 飞后 => 视觉;
                NSLog(@"飞后视觉%p:%@",model,[NVHeUtil fly2Str:NUMTOOK(model.data).floatValue]);
                [self flyResult:[model.data floatValue]];
            }
        }
        //4. 焦急反射
        else if([ANXIOUS_RDS isEqualToString:model.identify]){
            if (OutputObserverType_UseTime == model.type) {
                model.useTime = 0;
            } else {
                //1. 小鸟焦急时_扇翅膀;
                //[self see:[self.delegate birdView_GetPageView]];
                //CGFloat data = (arc4random() % 8) / 8.0f;
                //[AIReactorControl commitReactor:FLY_RDS datas:@[@(data)]];
                
                //2. 190731由飞改为叫;
                [theApp setTipLog:@"叽叽喳喳叫一叫"];
            }
        }
        //3. 脚踢反射
        else if([KICK_RDS isEqualToString:model.identify]){
            if (OutputObserverType_UseTime == model.type) {
                model.useTime = 0.1f;
            } else if (OutputObserverType_Front == model.type) {
                //a. 踢前 => 行为动画;
                NSLog(@"踢前视觉%p:%@",model,[NVHeUtil fly2Str:NUMTOOK(model.data).floatValue]);
                [self kickAction:model];
            }else if(OutputObserverType_Back == model.type){
                //b. 飞后 => 视觉;
                NSLog(@"踢后视觉%p:%@",model,[NVHeUtil fly2Str:NUMTOOK(model.data).floatValue]);
                [self see:[self.delegate birdView_GetPageView] fromObserver:false];
            }
        }
    }
}

//MARK:===============================================================
//MARK:                     < inputObserver >
//MARK:===============================================================

/**
 *  MARK:--------------------感官输入--------------------
 *  @version
 *      2023.06.23: 输出吃时: 立马就吃到,而不是等动画结束 (参考30041-记录2);
 */
-(void) inputObserver:(NSNotification*)notification {
    [self see:[self.delegate birdView_GetPageView] fromObserver:true];
}

-(void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self.delegate birdView_SetFramed];
}

@end
