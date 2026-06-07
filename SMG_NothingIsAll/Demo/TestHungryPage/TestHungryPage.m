//
//  TestHungryPage.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/7/9.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "TestHungryPage.h"
#import "DemoHunger.h"
#import "DemoCharge.h"
#import "AIInput.h"
#import "Output.h"
#import "AIReactorControl.h"

@interface TestHungryPage ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *subBtn;
@property (weak, nonatomic) IBOutlet UIButton *eatStartBtn;
@property (weak, nonatomic) IBOutlet UIButton *eatStopBtn;
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;
@property (weak, nonatomic) IBOutlet UITextField *tf;
@property (weak, nonatomic) IBOutlet UISlider *hungerLevelSlider;
@property (weak, nonatomic) IBOutlet UILabel *hungerLevelLab;
@property (weak, nonatomic) IBOutlet UIButton *thinkStatusBtn;
@property (weak, nonatomic) IBOutlet UILabel *aiOutputLab;

@property (assign, nonatomic) CGFloat lastSliderValue;
@property (strong,nonatomic) NSTimer *timer;            //计时器
@property (strong, nonatomic) NSMutableString *outputMStr;

@end

@implementation TestHungryPage

-(void) initView{
    //1. self
    [super initView];
    self.title = @"充电演示";
    
    //2. tf
    self.tf.delegate = self;
    [self.tf setReturnKeyType:UIReturnKeyGo];
    
    //3. hungerLevelLab
    [self.hungerLevelLab setText:Double2Str_NDZ(self.hungerLevelSlider.value)];
    [self.hungerLevelLab setTextColor:self.hungerLevelSlider.value > 0.7 ? [UIColor greenColor] : [UIColor redColor]];
    
    //4. thinkStatusBtn
    [self.thinkStatusBtn.layer setCornerRadius:5];
    [self.thinkStatusBtn.layer setMasksToBounds:true];
}

-(void) initData{
    [super initData];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.03f target:self selector:@selector(notificationTimer) userInfo:nil repeats:YES];
    });
    self.outputMStr = [[NSMutableString alloc] init];
}

-(void) initDisplay{
    [super initDisplay];
    //1,thinkStatusBtn
    [self.thinkStatusBtn setBackgroundColor:[UIColor greenColor]];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputObserver:) name:kOutputObserver object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//MARK:===============================================================
//MARK:                     < method >
//MARK:===============================================================
-(void) refreshDisplay_HungerLevelLab{
    NSString *value = STRFORMAT(@"%.3f",self.hungerLevelSlider.value);
    [self.hungerLevelLab setText:value];
    [self.hungerLevelLab setTextColor:self.hungerLevelSlider.value > 0.7 ? [UIColor greenColor] : [UIColor redColor]];
}

- (void)notificationTimer{
    NSString *oldText = self.aiOutputLab.text;
    if (oldText.length < self.outputMStr.length) {
        [self.aiOutputLab setText:[self.outputMStr substringToIndex:oldText.length + 1]];
    }else{
        [self.aiOutputLab setText:self.outputMStr];
    }
}

/**
 *  MARK:--------------------onclick--------------------
 */
- (IBAction)addBtnOnClick:(id)sender {
    [[[DemoHunger alloc] init] commit:0.9 state:UIDeviceBatteryStateCharging];
}

- (IBAction)subBtnOnClick:(id)sender {
    [[[DemoHunger alloc] init] commit:0.7 state:UIDeviceBatteryStateUnplugged];
}

- (IBAction)eatStartBtnOnClick:(id)sender {
    [[[DemoCharge alloc] init] commit:HungerState_Charging];
}

- (IBAction)eatStopBtnOnClick:(id)sender {
    [[[DemoCharge alloc] init] commit:HungerState_Unplugged];
}

- (IBAction)confirmBtnOnClick:(id)sender {
    if (STRISOK(self.tf.text)) {
        [AIInput commitText:self.tf.text];
        self.tf.text = nil;
    }
}

- (IBAction)hungerLevelSliderValueChanged:(id)sender {
    //1. 数据
    CGFloat curValue = self.hungerLevelSlider.value;
    UIDeviceBatteryState state = self.lastSliderValue > curValue ? UIDeviceBatteryStateUnplugged : UIDeviceBatteryStateCharging;
    
    //2. 提交变化
    [[[DemoHunger alloc] init] commit:curValue state:state];
    
    //3. 记录当前值
    self.lastSliderValue = curValue;
}

- (IBAction)thinkBtnOnClick:(id)sender {
    
}

/**
 *  MARK:--------------------UITextFieldDelegate--------------------
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self confirmBtnOnClick:self.confirmBtn];
    return true;
}

//MARK:===============================================================
//MARK:                     < outputObserver >
//MARK:===============================================================
-(void) outputObserver:(NSNotification*)notification{
    if (notification && ISOK(notification.object, OutputModel.class)) {
        //1. 取数据
        OutputModel *model = (OutputModel*)notification.object;
        
        //2. 字符串反射
        if ([TEXT_RDS isEqualToString:model.identify]) {
            for (NSNumber *data in model.datas) {
                char c = [data charValue];
                [self.outputMStr appendFormat:@"%c",c];
                if (self.outputMStr.length > 100) {
                    NSString *subStr = [self.outputMStr substringFromIndex:self.outputMStr.length - 100];
                    self.outputMStr = [[NSMutableString alloc] initWithString:subStr];
                }
            }
        }else if([ANXIOUS_RDS isEqualToString:model.identify]){
            const char *chars = [@"T_T" UTF8String];
            NSMutableArray *datas = [[NSMutableArray alloc] init];
            for (NSInteger i = 0; i < 3; i++) {
                [datas addObject:@(chars[i])];
            }
            [AIReactorControl commitReactor:TEXT_RDS datas:datas];
            //chars = [@"^_^" UTF8String];
        }
    }
}

@end
