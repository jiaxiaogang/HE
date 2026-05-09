//
//  RLTPanel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/4/15.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "RLTPanel.h"
#import "MASConstraint.h"
#import "View+MASAdditions.h"
#import "TOMVisionItemModel.h"
#import "PINDiskCache.h"
#import "TVideoWindow.h"
#import "TVUtil.h"
#import "XGDebugTV.h"
#import "XGLabCell.h"
#import "FoodView.h"

@interface RLTPanel () <UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITableView *tv;
@property (weak, nonatomic) IBOutlet XGDebugTV *debugTV;
@property (weak, nonatomic) IBOutlet UILabel *mvScoreLab;
@property (weak, nonatomic) IBOutlet UILabel *spScoreLab;
@property (weak, nonatomic) IBOutlet UILabel *sStrongLab;
@property (weak, nonatomic) IBOutlet UILabel *pStrongLab;
@property (weak, nonatomic) IBOutlet UILabel *solutionLab;
@property (weak, nonatomic) IBOutlet UILabel *progressLab;
@property (weak, nonatomic) IBOutlet UILabel *timeLab;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (strong, nonatomic) NSArray *tvDatas;
@property (assign, nonatomic) NSInteger tvIndex;
@property (weak, nonatomic) IBOutlet UIButton *custom1Btn;

@end

@implementation RLTPanel

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
    [self setAlpha:0.7f];
    CGFloat width = 350;//ScreenWidth * 0.667f;
    [self setFrame:CGRectMake(ScreenWidth - width - 20, 64, width, ScreenHeight - 128)];
    
    //containerView
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
    }];
    [self.containerView.layer setCornerRadius:8.0f];
    [self.containerView.layer setBorderWidth:1.0f];
    [self.containerView.layer setBorderColor:UIColorWithRGBHex(0x000000).CGColor];
    
    //tv
    self.tv.delegate = self;
    self.tv.dataSource = self;
    [self.tv.layer setBorderWidth:1.0f];
    [self.tv.layer setBorderColor:UIColorWithRGBHex(0x0000FF).CGColor];
    [self.tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"spaceCell"];
    [self.tv registerClass:[XGLabCell class] forCellReuseIdentifier:@"queueCell"];
    
    //debugTV
    [self.debugTV.layer setBorderWidth:1.0f];
    [self.debugTV.layer setBorderColor:UIColorWithRGBHex(0x0000FF).CGColor];
    
    // 自定义1
    [self.custom1Btn setTitle:@"视觉训练" forState:UIControlStateNormal];
    [self.custom1Btn addTarget:self action:@selector(trainerMinst0_9:) forControlEvents:UIControlEventTouchUpInside];
}

-(void) initData{
    self.playing = false;
}

-(void) initDisplay{
    [self close];
}

-(void) refreshDisplay{
    //1. 取数据
    self.tvDatas = ARRTOOK([self.delegate rltPanel_getQueues]);
    self.tvIndex = [self.delegate rltPanel_getQueueIndex];
    
    //2. tv
    [self.tv reloadData];
    if (self.tvIndex < self.tvDatas.count) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tv scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.tvIndex inSection:1] atScrollPosition:UITableViewScrollPositionMiddle animated:true];
        });
    }
    
    //3. progressLab
    self.progressLab.text = STRFORMAT(@"%ld / %ld",self.tvIndex,self.tvDatas.count);
    
    //4. 使用时间;
    double useTimed = [self.delegate rltPanel_getUseTimed];
    double totalTime = self.tvIndex == 0 ? 0 : useTimed * self.tvDatas.count / self.tvIndex;
    int useT = (int)useTimed, totT = (int)totalTime;
    NSString *timeStr = STRFORMAT(@"%d:%d / %d:%d", useT / 60, useT % 60, totT / 60, totT % 60);
    [self.timeLab setText:timeStr];
    
    //5. 综评分;
    NSString *scoreStr = [self mvScoreStr];
    [self.mvScoreLab setText:scoreStr];
    
    //6. 稳定性 & 平均SP强度;
    __block typeof(self) weakSelf = self;
    [self spStr:^(CGFloat rateSPScore, CGFloat rateSStrong, CGFloat ratePStrong) {
        [weakSelf.spScoreLab setText:STRFORMAT(@"%.1f",rateSPScore)];
        [weakSelf.sStrongLab setText:STRFORMAT(@"%.1f",rateSStrong)];
        [weakSelf.pStrongLab setText:STRFORMAT(@"%.1f",ratePStrong)];
    }];
    
    //7. 有解率;
    CGFloat rateSolution = [self solutionStr];
    [self.solutionLab setText:STRFORMAT(@"%.0f％",rateSolution * 100)];
    
    //8. 性能分析;
    [self.debugTV updateModels];
}

//MARK:===============================================================
//MARK:                     < getset >
//MARK:===============================================================
-(void)setPlaying:(BOOL)playing{
    _playing = playing;
    [self.playBtn setTitle: self.playing ? @"暂停" : @"播放" forState:UIControlStateNormal];
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================
-(void) reloadData{
    [self refreshDisplay];
}
-(void) open{
    [self setHidden:false];
    [self.superview bringSubviewToFront:self];
}
-(void) close{
    [self setHidden:true];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(NSString*) cellStr:(RTQueueModel*)queue {
    if ([kGrowPageSEL isEqualToString:queue.name]) {
        return @"进入成长页";
    }else if ([kFlySEL isEqualToString:queue.name]) {
        if (NUMISOK(queue.arg0)) {
            return STRFORMAT(@"%@飞",[NVHeUtil fly2Str:NUMTOOK(queue.arg0).longValue / 8.0f]);
        }
        return @"随机飞";
    }else if ([kWoodLeftSEL isEqualToString:queue.name]) {
        return @"扔木棒";
    }else if ([kWoodRdmSEL isEqualToString:queue.name]) {
        return @"随机扔木棒";
    }else if ([kMainPageSEL isEqualToString:queue.name]) {
        return @"回主页";
    }else if ([kClearTCSEL isEqualToString:queue.name]) {
        return @"重启";
    }else if ([kBirthPosRdmSEL isEqualToString:queue.name]) {
        return @"出生地随机";
    }else if ([kBirthPosRdmCentSEL isEqualToString:queue.name]) {
        return @"出生地随机偏路中";
    }else if ([kBirthPosCentSEL isEqualToString:queue.name]) {
        return @"出生在中间";
    }else if ([kBirthPosRdmSafeSEL isEqualToString:queue.name]) {
        return @"出生在随机安全地带";
    }else if ([kHungerSEL isEqualToString:queue.name]) {
        return @"饿";
    }else if ([kFoodRdmSEL isEqualToString:queue.name]) {
        return @"随机投食";
    }else if ([kFoodRdmNearSEL isEqualToString:queue.name]) {
        return @"附近投食";
    }else if ([kFoodDirectlySEL isEqualToString:queue.name]) {
        return @"直投";
    }else if ([kThinkModeSEL isEqualToString:queue.name]) {
        if (NUMTOOK(queue.arg0).intValue == 0) {
            return @"动物模式";
        }else if (NUMTOOK(queue.arg0).intValue == 1) {
            return @"认知模式";
        }else if (NUMTOOK(queue.arg0).intValue == 2) {
            return @"植物模式";
        }
    } else if ([kImgTrainerSelect isEqualToString:queue.name]) {
        return STRFORMAT(@"选图(%d)",NUMTOOK(queue.arg0).intValue);
    } else if ([kImgTrainerPlay isEqualToString:queue.name]) {
        return @"看一张图";
    }
    return @"";
}

-(CGFloat) queueCellHeight{
    CGFloat maskHeight = 10.0f;//大概计算10左右高;
    int size = (int)(self.tv.height / maskHeight);
    size = size / 2 * 2 + 1;
    return self.tv.height / size;
}

-(CGFloat) spaceCellHeight{
    CGFloat cellH = [self queueCellHeight];
    return (self.tv.height - cellH) * 0.5f;
}

-(NSString*) mvScoreStr {
    //1. 数据准备;
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    NSMutableString *mStr = [[NSMutableString alloc] init];
    
    //2. 分别对每个根任务,进行评分;
    for (DemandModel *root in roots) {
        
        //3. 取最佳解决方案;
        CGFloat score = [AIScore progressScore4Demand_Out:root];
        
        //5. 收集结果;
        [mStr appendFormat:@"%.1f ",score];
    }
    return mStr;
}

-(void) spStr:(void(^)(CGFloat rateSPScore, CGFloat rateSStrong, CGFloat ratePStrong))complete{
    //0. 数据准备;
    NSMutableArray *spScoreArr = [[NSMutableArray alloc] init];
    NSMutableArray *spStrongArr = [[NSMutableArray alloc] init];
    
    //1. 收集根下所有树枝;
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    NSArray *branchs = [TVUtil collectAllSubTOModelByRoots:roots];
    NSArray *solutions = [SMGUtils filterArr:branchs checkValid:^BOOL(TOModelBase *item) {
        return ISOK(item, TOFoModel.class);
    }];
    
    //2. 逐一对任务,的解决方案树枝进行sp计算;
    for (TOFoModel *solution in solutions) {
        
        //3. 计算spIndex;
        AIFoNodeBase *fo = [SMGUtils searchNode:solution.content_p];
        NSInteger spIndex = -1;
        if (ISOK(solution.baseOrGroup, HDemandModel.class)) {
            HDemandModel *hDemand = (HDemandModel*)solution.baseOrGroup;
            AIAlgNodeBase *hAlg = [SMGUtils searchNode:hDemand.baseOrGroup.content_p];
            spIndex = [TOUtils indexOfConOrAbsItem:hAlg.pointer atContent:fo.content_ps layerDiff:1 startIndex:0 endIndex:NSUIntegerMax];
        }else if(ISOK(solution.baseOrGroup, ReasonDemandModel.class)){
            spIndex = fo.count;
        }
        
        //4. 根据spIndex计算稳定性和SP统计;
        if (spIndex > 0) {
            
            //5. 计入sp分;
            CGFloat checkSPScore = [TOUtils getSPScore:fo startSPIndex:0 endSPIndex:spIndex];
            [spScoreArr addObject:@(checkSPScore)];
            
            //6. 计入sp值;
            for (NSInteger i = 0; i <= spIndex; i++) {
                AISPStrong *spStrong = [fo.spDic objectForKey:@(i)];
                if (spStrong) {
                    [spStrongArr addObject:spStrong];
                }
            }
        }
    }
    
    //7. 得出平均结果,并返回;
    CGFloat sumSPScore = 0,sumSStrong = 0,sumPStrong = 0;
    for (NSNumber *item in spScoreArr){
        sumSPScore += item.floatValue;
    }
    for (AISPStrong *item in spStrongArr){
        sumSStrong += item.sStrong;
        sumPStrong += item.pStrong;
    }
    CGFloat rateSPScore = spScoreArr.count == 0 ? 0 : sumSPScore / spScoreArr.count;
    CGFloat rateSStrong = spStrongArr.count == 0 ? 0 : sumSStrong / spStrongArr.count;
    CGFloat ratePStrong = spStrongArr.count == 0 ? 0 : sumPStrong / spStrongArr.count;
    complete(rateSPScore,rateSStrong,ratePStrong);
}

-(CGFloat) solutionStr{
    //1. 收集根下所有树枝;
    NSArray *roots = [theTC.outModelManager.getAllDemand copy];
    NSArray *branchs = [TVUtil collectAllSubTOModelByRoots:roots];
    NSArray *demands = [SMGUtils filterArr:branchs checkValid:^BOOL(TOModelBase *item) {
        return ISOK(item, DemandModel.class);
    }];
    
    //2. 统计有解率;
    NSInteger havSolutionCount = 0;
    for (DemandModel *demand in demands) {
        if (ARRISOK(demand.actionFoModels)) {
            havSolutionCount++;
        }
    }
    return demands.count > 0 ? (float)havSolutionCount / demands.count : 0;
}

//MARK:===============================================================
//MARK:                     < onclick >
//MARK:===============================================================
- (IBAction)playBtnOnClick:(id)sender {
    self.playing = !self.playing;
}

- (IBAction)stopBtnOnClick:(id)sender {
    [self.delegate rltPanel_Stop];
}

- (IBAction)closeBtnOnClick:(id)sender {
    [self close];
}

//MARK:===============================================================
//MARK:                     < 防撞训练 >
//MARK:===============================================================

/**
 *  MARK:--------------------第1步 学被撞--------------------
 *  @desc
 *      1. 说明: 学被撞 (出生随机位置,被随机扔出的木棒撞 x 300);
 *      2. 作用: 主要用于训练识别功能 (耗时约50min) (参考26197-1);
 *  @version
 *      2022.06.05: 调整 (参考26197-1&2);
 */
- (IBAction)loadHitBtnOnClick:(id)sender {
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kWoodRdmSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:200];
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kWoodLeftSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:100];
}

/**
 *  MARK:--------------------第2步 学飞躲--------------------
 *  @desc
 *      1. 说明: 学飞躲 (出生随机偏中位置,左棒,随机飞x2,左棒 x 100);
 *      2. 作用: 从中习得防撞能力,躲避危险;
 *  @version
 *      2022.08.07: 将原100轮,拆分为10轮x10次 (参考27061-更新);
 *      2022.10.10: 测着比较稳了,改回些,改成33轮x3次 (参考27142-步骤2);
 *      2022.12.15: 改回100轮x1次 (参考2722c-步骤2);
 *      2023.02.11: 学飞躲改即刻执行: 改为扔出木棒,然后随机5次飞 (参考28066-todo1);
 */
//步骤参考26029-加长版强化加训 (参考26031-2);
- (IBAction)loadFlyBtnOnClick:(id)sender {
    //0. 无日志模式;
    //[theApp setNoLogMode:true];
    
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    
    //0. 出生在随机偏中位置 (以方便训练被撞和躲开经验);
    [theRT queue1:Queue(kBirthPosRdmCentSEL)];
    
    //0. 加长版训练100轮
    for (int j = 0; j < 100; j++) {
        
        //1. 进入训练页
        NSMutableArray *queues = [[NSMutableArray alloc] init];
        [queues addObject:Queue(kGrowPageSEL)];
        [queues addObject:Queue(kWoodLeftSEL)];
        
        //2. 随机飞或扔木棒,五步;
        //6. 屏中,任意方向;
        NSNumber *flyDirection = @(arc4random() % 8);
        for (int i = 0; i < 3; i++) {
            [queues addObject:Queue0(kFlySEL, flyDirection)];
        }
        
        //3. 退到主页,模拟重启;
        [queues addObjectsFromArray:@[Queue(kMainPageSEL),Queue(kClearTCSEL)]];
        
        //4. 训练names;
        [theRT queueN:queues count:1];
    }
    
    //5. 正常模式
    [theRT queue1:Queue0(kThinkModeSEL, @(0))];
}

/**
 *  MARK:--------------------训练识别 (参考28034)--------------------
 */
- (IBAction)loadRecognitionBtnClick:(id)sender {
    //0. 训练300轮 (每条训练项都包含: 进入训练页 & 退出主页);
    for (NSInteger i = 0; i < 300; i++) {
        //1. 随机出生位置;
        [theRT queue1:Queue(kBirthPosRdmSEL)];
        
        //2. 随机位置扔木棒;
        [theRT queueN:@[Queue(kGrowPageSEL),Queue(kWoodRdmSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:1];
        
        //3. 左侧扔木棒;
        [theRT queueN:@[Queue(kGrowPageSEL),Queue(kWoodLeftSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:1];
        
        //4. 随机偏中出生位置;
        [theRT queue1:Queue(kBirthPosRdmCentSEL)];
        
        //5. 随机飞或扔木棒,五步;
        [theRT queue1:Queue(kGrowPageSEL)];
        for (int i = 0; i < 5; i++) {
            NSArray *randomNames = @[Queue(kFlySEL),Queue(kWoodLeftSEL)];
            int randomIndex = arc4random() % 2;
            NSString *randomName = ARR_INDEX(randomNames, randomIndex);
            [theRT queue1:Queue(randomName)];
        }
        [theRT queueN:@[Queue(kMainPageSEL),Queue(kClearTCSEL)] count:1];
    }
}

/**
 *  MARK:--------------------第3步 试错训练--------------------
 *  @desc 与学撞训练步骤一致,此处其实就是各种撞它,让它自己尝试躲避 (类似学步婴儿尝试走路);
 */
- (IBAction)loadTryOutOfWay:(id)sender {
    [self loadHitBtnOnClick:nil];
}

- (IBAction)custom1Click:(id)sender {
    
}

//MARK:===============================================================
//MARK:                     < 训练项 >
//MARK:===============================================================
//步骤参考26011-基础版强化训练;
-(void) trainer1{
    [theRT queue1:Queue(kGrowPageSEL)];
    [theRT queueN:@[Queue(kFlySEL),Queue(kWoodLeftSEL)] count:5];
}
//步骤参考xxxxx
-(void) trainer2{
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kFlySEL),Queue(kFlySEL),Queue(kWoodLeftSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:20];
}

/**
 *  MARK:-------------------- 训练躲避 --------------------
 *  @version
 *      xxxx.xx.xx: 初版 (参考26081-2);
 *      2022.05.26: 少飞一步,变成[棒,飞,飞,棒],因为瞬时记忆只有4条;
 */
-(void) trainer5{
    //0. 出生在随机偏中位置 (以方便训练被撞和躲开经验);
    [theRT queue1:Queue(kBirthPosRdmCentSEL)];
    
    //1. 加长版训练100轮
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kWoodLeftSEL),Queue(kFlySEL),Queue(kFlySEL),Queue(kWoodLeftSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:100];
}

//MARK:===============================================================
//MARK:                     < 觅食训练 >
//MARK:===============================================================

/**
 *  MARK:--------------------第1步学饿--------------------
 *  @desc 参考28172-第1步;
 *  @version
 *      2023.06.26: 因为加了饿后视觉,重新规划学饿训练步骤 (参考30042-todo3);
 *      2023.06.27: 将昨天的改动回滚 (参考30042-todo3-回滚 & 30043-方案);
 */
- (IBAction)eat1BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    
    //2. 饥饿,随机扔个坚果 x 200次;
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kHungerSEL),Queue0(kFoodRdmSEL,@(FoodStatus_Eat)),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:50];
}

/**
 *  MARK:--------------------第2步学吃--------------------
 *  @desc 参考28172-第2步;
 */
- (IBAction)eat2BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    for (NSInteger i = 0; i < 100; i++) {
        //2. 进入训练页 & 饥饿 & 附近投坚果;
        NSMutableArray *queues = [[NSMutableArray alloc] init];
        [queues addObject:Queue(kGrowPageSEL)];
        [queues addObject:Queue(kHungerSEL)];
        [queues addObject:Queue(kFoodRdmNearSEL)];
        
        //3. 随机飞个方向连续3步;
        NSNumber *flyDirection = @(arc4random() % 8);
        for (int i = 0; i < 3; i++) {
            [queues addObject:Queue0(kFlySEL, flyDirection)];
        }
        
        //4. 退到主页,模拟重启;
        [queues addObjectsFromArray:@[Queue(kMainPageSEL),Queue(kClearTCSEL)]];
        
        //5. 训练names;
        [theRT queueN:queues count:1];
    }
}

/**
 *  MARK:--------------------第3步试错--------------------
 */
- (IBAction)eat3BtnClick:(id)sender {
    
}

//MARK:===============================================================
//MARK:                     < 直投训练 >
//MARK:===============================================================

/**
 *  MARK:--------------------第1步直接学饿--------------------
 *  @desc 参考34111-第1步;
 */
- (IBAction) directlyEat1BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    
    //2. 饥饿,随机扔个坚果 x 200次;
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kHungerSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:50];
}

/**
 *  MARK:--------------------第2步直投学吃--------------------
 *  @desc 参考34111-第2步;
 */
- (IBAction)directlyEat2BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    for (NSInteger i = 0; i < 100; i++) {
        //2. 进入训练页 & 饥饿 & 直投坚果 & 退回主页 & 模拟重启;
        NSMutableArray *queues = [[NSMutableArray alloc] init];
        [queues addObject:Queue(kGrowPageSEL)];
        [queues addObject:Queue(kHungerSEL)];
        [queues addObject:Queue2(kFoodDirectlySEL, ARR_INDEX(cCanEatMainNum, 0), @(-1),@(false))];
        [queues addObject:Queue(kMainPageSEL)];
        [queues addObject:Queue(kClearTCSEL)];
        
        //5. 训练names;
        [theRT queueN:queues count:1];
    }
}

//直投不可吃的：1-9号坚果训练。
- (IBAction)directlyEat3BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    for (NSInteger subNum = 1; subNum <= 20; subNum++) {
        for (NSInteger mainNum = 1; mainNum <= 9; mainNum++) {
            //2. 进入训练页 & 饥饿 & 直投坚果 & 退回主页 & 模拟重启;
            NSMutableArray *queues = [[NSMutableArray alloc] init];
            [queues addObject:Queue(kGrowPageSEL)];
            [queues addObject:Queue(kHungerSEL)];
            [queues addObject:Queue2(kFoodDirectlySEL, STRFORMAT(@"%ld",mainNum),@(subNum),@(false))];
            [queues addObject:Queue(kMainPageSEL)];
            [queues addObject:Queue(kClearTCSEL)];
            
            //5. 训练names;
            [theRT queueN:queues count:1];
        }
    }
}

//MARK:===============================================================
//MARK:                     < 搬运训练 >
//MARK:===============================================================

/**
 *  MARK:--------------------第1步带皮果学饿--------------------
 *  @desc 参考30092-步骤1 & 30145-步骤1;
 */
- (IBAction)kick1BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    
    //2. 饥饿,随机扔个坚果 x 200次;
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kHungerSEL),Queue0(kFoodRdmSEL,@(FoodStatus_Border)),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:200];
}

/**
 *  MARK:--------------------第2步学认木棒--------------------
 *  @desc 参考30145-步骤2;
 */
- (IBAction)kick2BtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSafeSEL)];
    
    //2. 扔木棒 x 300次;
    [theRT queueN:@[Queue(kGrowPageSEL),
                    Queue(kWoodLeftSEL), //扔木棒
                    Queue(kMainPageSEL),Queue(kClearTCSEL)] count:300];
}

/**
 *  MARK:--------------------第2.5步饿了更饿--------------------
 *  @desc 参考31018-步骤2.5;
 */
- (IBAction)kickHungerThanHungerBtnClick:(id)sender {
    //0. 认知模式
    [theRT queue1:Queue0(kThinkModeSEL, @(1))];
    
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSEL)];
    
    //2. 饥饿 x 20次;
    [theRT queueN:@[Queue(kGrowPageSEL),Queue(kHungerSEL),Queue(kMainPageSEL),Queue(kClearTCSEL)] count:20];
}

/**
 *  MARK:--------------------第3步学H去皮--------------------
 *  @desc 学什么时候能压到,什么时候压不到 (参考30142-步骤3自 & 30145-步骤4);
 */
- (IBAction)kick3BtnClick:(id)sender {
    //1. 随机出生;
    [theRT queue1:Queue(kBirthPosRdmSafeSEL)];
    
    //2. 饥饿,随机扔个坚果,扔木棒 x 200次;
    [theRT queueN:@[Queue(kGrowPageSEL),
                    Queue(kHungerSEL), //饿
                    Queue0(kFoodRdmSEL,@(FoodStatus_Border)), //随机扔有皮果
                    Queue(kWoodLeftSEL), //扔木棒
                    Queue(kMainPageSEL),Queue(kClearTCSEL)] count:70];
}

//MARK:===============================================================
//MARK:                     < 视觉训练 >
//MARK:===============================================================

/**
 *  MARK:--------------------训练Mnist图0到9一轮--------------------
 */
-(void) trainerMinst0_9:(id)sender {
    [theRT queueN:@[Queue0(kImgTrainerSelect,@(13))] count:1];      // 选中Mnist0
    [theRT queueN:@[Queue(kImgTrainerPlay)] count:10];              // 依次扔10张（0-9）
}

//MARK:===============================================================
//MARK:       < UITableViewDataSource &  UITableViewDelegate>
//MARK:===============================================================
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 1) {
        return self.tvDatas.count;
    }
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    //1. 返回spaceCell
    if (indexPath.section != 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"spaceCell"];
        [cell setFrame:CGRectMake(0, 0, self.tv.width, [self spaceCellHeight])];
        return cell;
    }else {
        //2. 正常返回queueCell_数据准备;
        RTQueueModel *queue = ARR_INDEX(self.tvDatas, indexPath.row);
        NSString *cellStr = STRFORMAT(@"%ld. %@",indexPath.row+1, [self cellStr:queue]);
        BOOL trained = indexPath.row < self.tvIndex;
        UIColor *color = trained ? UIColor.blackColor : UIColor.redColor;
        
        //3. 创建cell;
        XGLabCell *cell = [tableView dequeueReusableCellWithIdentifier:@"queueCell"];
        [cell setText:cellStr color:color font:8];
        return cell;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 1) {
        return [self queueCellHeight];
    }else{
        return [self spaceCellHeight];
    }
}

@end
