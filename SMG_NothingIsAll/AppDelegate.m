//
//  AppDelegate.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/7.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AppDelegate.h"
#import "MainPage.h"
#import "AINet.h"
#import "NSObject+Extension.h"
#import "AIKVPointer.h"
#import "NVDelegate_He.h"
#import "HeLogView.h"
#import <UMCommon/UMCommon.h>
#import "MemManagerWindow.h"
#import "MASConstraint.h"
#import "View+MASAdditions.h"

@interface AppDelegate ()

@property (strong, nonatomic) UILabel *tipLogLab;
@property (strong, nonatomic) UIView *refreshDot;//因为模拟器下的UI动画老不刷新,所以写个闪动点,来推动UI被动刷新;
@property (strong, nonatomic) MemManagerWindow *memManagerWindow;
@property (assign, nonatomic) int waitReset;//0默认或成功 1等待重启 (2,3..N)fps<3连续n次

//思维状态
@property (strong, nonatomic) NSTimer *timer;               //间隔计时器
@property (assign, nonatomic) long long lastOperCount;
@property (strong, nonatomic) UILabel *thinkFPSLab;

@property (strong, nonatomic) UIButton *thinkModeBtn;
@property (strong, nonatomic) UIButton *resetBtn;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //0. 初始化UMeng
    [UMConfigure initWithAppkey:@"5f06fadaed3b4408234905b8" channel:@"default"];
    [UMConfigure setLogEnabled:true];
    
    //1. Path
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSLog(@"%@",paths[0]);
    
    //2. 初始化UI
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    MainPage *page = [[MainPage alloc] init];
    UINavigationController *naviC = [[UINavigationController alloc] initWithRootViewController:page];
    [self.window setRootViewController:naviC];
    [self.window makeKeyAndVisible];
    
    //3. heLogView打开按钮
    [self createNavBtn:1 title:@"经历" action:@selector(openHeLogBtnOnClick:) bg:0];
    
    //3. 被动UI刷新
    self.refreshDot = [[UIView alloc] initWithFrame:CGRectMake(ScreenWidth - 40, 8, 5, 5)];
    [self.refreshDot setBackgroundColor:UIColorWithRGBHex(0x00FF00)];
    [self.refreshDot.layer setCornerRadius:2.5f];
    [self.refreshDot.layer setMasksToBounds:true];
    [self.window addSubview:self.refreshDot];
    [self startRefreshDotAnimation];
    
    //3. 记忆管理按钮
    [self createNavBtn:2 title:@"记忆" action:@selector(memManagerBtnOnClick:) bg:0];
    
    //3. 工作记忆按钮
    [self createNavBtn:3 title:@"思维" action:@selector(tvBtnOnClick:) bg:0];
    
    //3. 思维状态
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(timeBlock) userInfo:nil repeats:true];
    
    //3. 思维状态显示
    self.thinkFPSLab = [[UILabel alloc] init];
    [self.thinkFPSLab setTextColor:[UIColor blackColor]];
    [self.thinkFPSLab setFont:[UIFont fontWithName:@"PingFang SC" size:8.0f]];
    self.thinkFPSLab.lineBreakMode = NSLineBreakByCharWrapping;
    [self.thinkFPSLab setNumberOfLines:0];
    [self.window addSubview:self.thinkFPSLab];
    [self.thinkFPSLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.window).offset(-145);
        make.top.mas_equalTo(self.window).offset(10);
    }];
    
    //3. 强化训练按钮
    [self createNavBtn:4 title:@"强训" action:@selector(rtBtnOnClick:) bg:0];
    
    //3. 强化训练配置->鸟出生地点;
    [theRT regist:kBirthPosRdmCentSEL target:self selector:@selector(setBirthPosMode_RdmCent)];
    [theRT regist:kBirthPosRdmSEL target:self selector:@selector(setBirthPosMode_Rdm)];
    [theRT regist:kBirthPosCentSEL target:self selector:@selector(setBirthPosMode_Cent)];
    [theRT regist:kBirthPosRdmSafeSEL target:self selector:@selector(setBirthPosMode_RdmSafe)];
    
    //3. 强行停止思考能力按钮
    NSString *thinkStr = [self getThinkBtnStr];
    self.thinkModeBtn = [self createNavBtn:5 title:thinkStr action:@selector(stopThinkBtnOnClick:) bg:1];
    
    //3. 模拟重启
    self.resetBtn = [self createNavBtn:6 title:@"重启" action:@selector(resetBtnOnClick:) bg:0];
    
    //3. 持久化
    [self createNavBtn:7 title:@"2DB" action:@selector(wedisSaveBtnOnClick:) bg:0];
    
    //3. 临时
    [self createNavBtn:8 title:@"库图" action:@selector(imageNetTrainerBtnOnClick:) bg:0];
    
    //3. 视觉训练工具
    [self createNavBtn:9 title:@"自图" action:@selector(customImagesTrainerBtnOnClick:) bg:0];
    
    //4. 神经网络可视化
    self.nvView = [[NVView alloc] initWithDelegate:[NVDelegate_He new]];
    [self.nvView setAlpha:0.9f];
    [self.window addSubview:self.nvView];
    
    //5. heLogView
    self.heLogView = [[HeLogView alloc] init];
    [self.window addSubview:self.heLogView];
    
    //6. tipLogLab
    self.tipLogLab = [[UILabel alloc] init];
    [self.tipLogLab setTextColor:[UIColor redColor]];
    [self.tipLogLab setFont:[UIFont fontWithName:@"PingFang SC" size:8.0f]];
    self.tipLogLab.lineBreakMode = NSLineBreakByCharWrapping;
    [self.tipLogLab setNumberOfLines:0];
    [self.window addSubview:self.tipLogLab];
    [self.tipLogLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.window).offset(40);
        make.trailing.mas_equalTo(self.window);
        make.bottom.mas_equalTo(self.window);
    }];
    
    //7. 记忆管理器
    self.memManagerWindow = [[MemManagerWindow alloc] init];
    [self.window addSubview:self.memManagerWindow];
    
    //8. 工作记忆可视化
    self.tv = [[TOMVision2 alloc] init];
    [self.window addSubview:self.tv];
    
    //9. 初始化XGConfig
    [XGConfig.instance initConfig];
    
    //10. 视觉训练工具
    self.imgTrainerView = [[ImgTrainerView alloc] init];
    [self.window addSubview:self.imgTrainerView];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(UIViewController*) getTopDisplayViewController{
    UINavigationController *navC = (UINavigationController*)[self.window rootViewController];    
    NSArray *controllers = navC.viewControllers;
    UIViewController *controller = [controllers lastObject];
    return controller;
}

-(void) setTipLog:(NSString*)tipLog{
    [self.tipLogLab setText:STRTOOK(tipLog)];
}

/**
 *  MARK:--------------------无日志模式--------------------
 *  @version
 *      2022.08.17: 调试训练卡顿是因为theTV的帧记录导致的 (参考27065);
 */
-(void)setNoLogMode:(BOOL)noLogMode{
    [theTV setStop:noLogMode];
    [theHeLog setStop:noLogMode];
    //cNSLogSwitch = noLogMode;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(void) openHeLogBtnOnClick:(id)btn{
    [self.heLogView open];
}

-(void) memManagerBtnOnClick:(id)btn{
    [self.memManagerWindow open];
}

-(void) tvBtnOnClick:(id)btn{
    [self.tv open];
}

-(void) rtBtnOnClick:(id)btn{
    [theRT open];
}

-(void) stopThinkBtnOnClick:(UIButton*)btn{
    theTC.thinkMode++;
    theTC.thinkMode %= 3;
    [btn setTitle:[self getThinkBtnStr] forState:UIControlStateNormal];
}

-(void) wedisSaveBtnOnClick:(UIButton*)btn{
    [[XGWedis sharedInstance] save];
    //成功提示
    UIColor *bakColor = btn.titleLabel.textColor;
    [btn setTitleColor:UIColor.greenColor forState:UIControlStateNormal];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [btn setTitleColor:bakColor forState:UIControlStateNormal];
    });
}

-(void) resetBtnOnClick:(UIButton*)btn{
    if (self.waitReset == 0) {
        self.waitReset = 1;
        [btn setTitle:@"等待" forState:UIControlStateNormal];
    }
}

-(void) imageNetTrainerBtnOnClick:(UIButton*)btn {
    [self.imgTrainerView setData:2];
    [self.imgTrainerView open];
}

-(void) customImagesTrainerBtnOnClick:(UIButton*)btn {
    [self.imgTrainerView setData:1];
    [self.imgTrainerView open];
}

-(void) startRefreshDotAnimation{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.refreshDot.alpha = fabs(self.refreshDot.alpha - 1);
        [self startRefreshDotAnimation];
    });
}

-(NSString*) getThinkBtnStr {
    if (theTC.thinkMode == 0) {
        return @"动物";
    }else if(theTC.thinkMode == 1) {
        return @"认知";
    }else if(theTC.thinkMode == 2) {
        return @"植物";
    }
    return @"其它";
}

/**
 *  MARK:--------------------创建navBtn--------------------
 *  @param index : 0=40, 1=82, 2=124, 3=166, 4=208, 5=250, 6=292
 *  @param bg : 默认0绿,1红;
 */
-(UIButton*) createNavBtn:(NSInteger)index title:(NSString*)title action:(SEL)action bg:(int)bg{
    //1. 数据准备;
    CGFloat marginRight = index * 40 + 40 + index * 2;
    CGFloat x = ScreenWidth - marginRight;
    UIColor *bgColor = bg == 1 ? UIColorWithRGBHex(0xFFEEEE) : UIColorWithRGBHex(0xEEFFEE);
    
    //2. 创建btn;
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, StateBarHeight, 40, 20)];
    [btn.titleLabel setFont:[UIFont systemFontOfSize:15]];
    [btn setTitleColor:UIColorWithRGBHex(0x0000EE) forState:UIControlStateNormal];
    [btn setBackgroundColor:bgColor];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.window addSubview:btn];
    return btn;
}

//MARK:===============================================================
//MARK:                     < 小鸟出生地配置 >
//MARK:===============================================================
- (void)setBirthPosMode_Rdm{
    self.birthPosMode = 0;
    [theRT invoked:kBirthPosRdmSEL];
}
- (void)setBirthPosMode_RdmCent{
    self.birthPosMode = 1;
    [theRT invoked:kBirthPosRdmCentSEL];
}
- (void)setBirthPosMode_Cent{
    self.birthPosMode = 2;
    [theRT invoked:kBirthPosCentSEL];
}
- (void)setBirthPosMode_RdmSafe{
    self.birthPosMode = 3;
    [theRT invoked:kBirthPosRdmSafeSEL];
}

//MARK:===============================================================
//MARK:                     < block >
//MARK:===============================================================

/**
 *  MARK:--------------------每秒思维状态更新--------------------
 *  @version
 *      2023.12.01: 只有思维闲置3秒时才会重启,避免realMaskFo收集未完成导致newRCanset不全的问题 (参考31017-解答4);
 *      2023.12.01: 动物模式时FPS永远>=2,所以等待重启的条件改为: FPS3以下连续5秒;
 */
-(void) timeBlock {
    //1. FPS更新显示;
    [self.thinkFPSLab setText:STRFORMAT(@"%lld",theTC.getOperCount - self.lastOperCount)];
    
    //2. 思维模式更新显示;
    [self.thinkModeBtn setTitle:[self getThinkBtnStr] forState:UIControlStateNormal];
    
    //3. 如果在待重启状态,且思维闲时=>更新待重启状态;
    if (self.waitReset != 0) {
        if (theTC.getOperCount - self.lastOperCount <= 3) {
            self.waitReset++;
            
            //4. 连续5秒闲置后,进行重启;
            if (self.waitReset >= 6) {
                [self.resetBtn setTitle:@"成功" forState:UIControlStateNormal];
                [theTC clear];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.resetBtn setTitle:@"重启" forState:UIControlStateNormal];
                });
                self.waitReset = 0;
            }
        } else {
            //5. 如果闲置不连续,则重置为0次 (保证必须连续三次才有效);
            self.waitReset = 1;
        }
    }
    self.lastOperCount = theTC.getOperCount;
}

@end
