//
//  AIThinkingControl.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/11/12.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AIThinkingControl.h"
#import "NSObject+Extension.h"

/**
 *  MARK:--------------------思维控制器--------------------
 *
 *
 *  >> assExp
 *  1. 在联想中,遇到的数据,都存到thinkFeedCache;
 *  2. 在联想中,遇到的mv,都叠加到当前demand下;
 *
 */
@interface AIThinkingControl()

@property (strong, nonatomic) DemandManager *demandManager;         //OUT短时记忆 (输出数据管理器);
@property (strong, nonatomic) ShortMatchManager *shortMatchManager; //IN短时记忆 (输入数据管理器);
@property (assign, nonatomic) long long operCount;                  //思维操作计数;
@property (assign, nonatomic) long long tiLoopId;                     //思维循环Id;
@property (assign, nonatomic) long long toLoopId;                   //TO循环Id;

@property (strong, nonatomic) NSTimer *tiLoopTimer;                 //TI执行检查器;
@property (assign, nonatomic) BOOL tiRuning1;                       //TI执行中
@property (assign, nonatomic) BOOL tiRuning2;                       //TI执行中
@property (assign, nonatomic) BOOL tiRuning3;                       //TI执行中

@property (strong, nonatomic) NSMutableArray *tempModels;            //测试，临时存前几个输入的models

/**
 *  MARK:--------------------当前能量值--------------------
 *  1. 激活: mv输入时激活;
 *  2. 消耗: 思维的循环中消耗;
 *      1. 构建"概念节点"消耗0.1;
 *      2. 构建"时序节点"消耗1;
 *
 *  3. 范围: 0-20;
 */
@property (assign, nonatomic) CGFloat energy;

@end

@implementation AIThinkingControl

static AIThinkingControl *_instance;
+(AIThinkingControl*) shareInstance{
    if (_instance == nil) {
        _instance = [[AIThinkingControl alloc] init];
    }
    return _instance;
}

-(id) init{
    self = [super init];
    if (self) {
        [self initData];
        [self initDisplay];
    }
    return self;
}

/**
 *  MARK:--------------------initData--------------------
 *  @version
 *      2023.07.19: tc线程由串行改为并行,因为虚拟世界输入信号是随时的,不应该排队 (如果TC在忙,大可在思维中因为优先级不够而中断,但确不该排队) (参考30083-todo4);
 */
-(void) initData{
    self.tiQueue = dispatch_queue_create([tiQueueLab UTF8String], DISPATCH_QUEUE_SERIAL);
    self.toQueue = dispatch_queue_create([toQueueLab UTF8String], DISPATCH_QUEUE_SERIAL);
    self.demandManager = [[DemandManager alloc] init];
    self.shortMatchManager = [[ShortMatchManager alloc] init];
    [theRT regist:kClearTCSEL target:self selector:@selector(clear)];
    [theRT regist:kThinkModeSEL target:self selector:@selector(updateThinkMode:)];
    self.tiTCDebug = [[TCDebug alloc] init];
    self.toTCDebug = [[TCDebug alloc] init];
}

-(void) initDisplay {
    //1. TiLoop (因为TI要用到TiQueue和MainQueue两个线程,然后有三个commitInput,所以没法占用TiQueue跑while来做);
    dispatch_async(dispatch_get_main_queue(), ^{
       self.tiLoopTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(runTiLoop) userInfo:nil repeats:true];
    });
    
    //2. ToLoop
    [self runToLoop];
}

//MARK:===============================================================
//MARK:                     < 输入流程 >
//MARK:===============================================================

/**
 *  MARK:--------------------TI循环--------------------
 *  @desc 每间隔一段时间,就调用一帧视觉输入;
 *  @version
 *      2024.07.18: 初版 (参考32102-todo1);
 */
-(void) runTiLoop {
    //1. 有TI在执行中,则跳过本次执行;
    if (self.tiRuning1 || self.tiRuning2 || self.tiRuning3) return;
    
    //2. 植物模式,则不执行认知;
    if (self.thinkMode == 2) return;
    
    //3. 用通知跑一下下帧感官 (视觉输入) (参考32102-TODO1);
    [[NSNotificationCenter defaultCenter] postNotificationName:kInputObserver object:nil];
}

/**
 *  MARK:--------------------数据输入--------------------
 *  说明: 单model (普通算法模型 或 imv模型)
 *  @version
 *      2022.10.09: 新输入直接存硬盘而不是isMem内存 (参考27124-todo6);
 */
-(void) commitInputAsync:(NSObject*)algsModel {
    __block NSObject *weakAlgsModel = algsModel;
    dispatch_async(self.tiQueue, ^{//30083去异步
        self.tiRuning1 = true;
        [self commitInput:weakAlgsModel];
        self.tiRuning1 = false;
    });
}
-(void) commitInput:(NSObject*)algsModel{
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return;
    //0. 将algModel转为modelDic;
    NSDictionary *modelDic = [NSObject getDic:algsModel containParent:true];
    NSString *algsType = NSStringFromClass(algsModel.class);
    
    //1. 装箱(除mv有两个元素外一般仅有一个元素)
    NSArray *algsArr = [theNet algModelConvert2Pointers:modelDic algsType:algsType];
    
    //2. 检测imv
    BOOL findMV = [ThinkingUtils dataIn_CheckMV:algsArr];
    
    //3. 分流_mv时
    if (findMV) {
        //1. 打包cmvNode;
        AICMVNodeBase *mvNode = [theNet createConMv:algsArr];
        
        //2. 加入瞬时记忆 & 生成时序指向mv等;
        [TCInput pInput:mvNode];
    }else{
        //1. 打包成algTypeNode;
        AIAlgNodeBase *algNode = [theNet createAbsAlg_NoRepeat:algsArr conAlgs:nil isOut:false at:nil ds:nil type:ATDefault];
        
        //2. 加入瞬时记忆 & 识别等;
        [TCInput rInput:algNode except_ps:nil];
    }
}

/**
 *  MARK:--------------------现用于输入（多粒度）二维概念，如视觉图像，目前用于测支持多码特征--------------------
 *  @desc 为了方便开发，开发阶段不将Object转成Dictionary输入，后开发完成后下版本再转。
 */
-(void) commitInputWithSplitAsync:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc {
    __block AIVisionAlgsModelV2 *weakAlgsModel = algsModel;
    dispatch_async(self.tiQueue, ^{//30083去异步
        self.tiRuning1 = true;
        [self commitInputWithSplit:weakAlgsModel algsType:algsType logDesc:logDesc];
        self.tiRuning1 = false;
    });
}
-(void) commitInputWithSplit:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc {
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return;
    
    //2. 装箱（稀疏码的：单码层 和 组码层 和 构建具象特征）。
    MapModel *createResult = [self createSplitFor9Block:algsModel algsType:algsType logDesc:logDesc];
    AIFeatureNode *hFeature = createResult.v1;
    AIFeatureNode *sFeature = createResult.v2;
    AIFeatureNode *bFeature = createResult.v3;
    
    //4、构建具象概念。
    AIAlgNodeBase *algNode = [theNet createAbsAlg_NoRepeat:@[hFeature.pointer,sFeature.pointer,bFeature.pointer] conAlgs:nil isOut:false at:nil ds:nil type:ATDefault];
    [algNode updateLogDescItem:logDesc];
    
    //5、装箱打包完毕，输入到rInput：进瞬时序列和识别等。
    [TCInput rInput:algNode except_ps:nil];
}

/**
 *  MARK:--------------------V2自适应粒度--------------------
 */
-(void) commitInputWithSplitAsyncV2:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc {
    __block AIVisionAlgsModelV2 *weakAlgsModel = algsModel;
    dispatch_async(self.tiQueue, ^{//30083去异步
        self.tiRuning1 = true;
        [self commitInputWithSplitV2:weakAlgsModel algsType:algsType logDesc:logDesc];
        //[self testZiJv:weakAlgsModel algsType:algsType logDesc:logDesc];
        self.tiRuning1 = false;
    });
}
-(void) commitInputWithSplitV2:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc {
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return;
    
    //2. 对未切粒度的color字典进行自适应粒度并识别。
    //202x.xx.xx: 方便测试，只开放b试下。
    NSArray *dsArr = @[@"hColors", @"sColors", @"bColors"];
    for (NSString *ds in dsArr) {
        //2. 装箱（稀疏码的：单码层 和 组码层）。
        NSArray *hsbGroupModels = [self createSplitFor9BlockV2_Step1:algsModel algsType:algsType ds:ds logDesc:logDesc];
        
        //2025.10.18: 自动改成有内容的(hsbGroupModels.count > 5)再跑识别类比等。
        if (hsbGroupModels.count > 5) [TCRecognitionInvoke recognitionFeatureV2_Step0:algsModel.bColors whSize:algsModel.whSize at:algsType ds:@"bColors" logDesc:logDesc];
        
        //3、构建具象特征。
        //3. 异步构建一下默认三分粒度的protoT，不过不用于识别，只用于以后被识别。
        //TODO: 可以加上遗忘机制，冷却一段时间后，还没被识别到，就遗忘清理掉（如无性能问题，只保持现做法：在竞争中不激活也行）。
        [self createSplitFor9BlockV2_Step2:hsbGroupModels at:algsType ds:ds logDesc:logDesc];
    }
}

//自举算法的单元测试。
-(void) testZiJv:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)at logDesc:(NSString*)logDesc {
    //1. 0到9调用createSplitFor9Block先生成并收集起来。
    if (!self.tempModels) {
        self.tempModels = [NSMutableArray new];
    }
    NSArray *splitLogDesc = [SMGUtils strToArr:logDesc sep:@"_"];
    NSString *logFront = ARR_INDEX(splitLogDesc, 0);
    NSInteger logBack = STRTOOK(ARR_INDEX(splitLogDesc, 1)).integerValue;
    if ([logFront isEqual:@"Mnist0"] && logBack < 10) {
        MapModel *createResult = [self createSplitFor9Block:algsModel algsType:at logDesc:logDesc];
        AIFeatureNode *bFeature = createResult.v3;
        [self.tempModels addObject:bFeature];
        NSLog(@"构建itemT %@ success",logDesc);
        return;
    }
    
    //2. 第10个分别与前面的测试自举识别算法：数据准备。
    NSMutableArray *result = [NSMutableArray new];
    NSString *ds = @"bColors";
    NSDictionary *colorDic = algsModel.bColors;
    BOOL isOut = false;
    
    //6. 提前加载好vInfo & dataDic缓存，后面复用。
    // [TCRecognitionInvoke resetPool];
    // TODO: 随后此方法 要启用的话，需要先把那些resetPool然后valueDS的缓存池加载一下。
    
    //3. 循环分别进行：自举识别：每个assT一条条自举自身的gv。
    for (NSInteger i = 0; i < self.tempModels.count; i++) {
        AIFeatureNode *passedT = ARR_INDEX(self.tempModels, i);
        AIFeatureJvBuModel *model = [AIFeatureJvBuModel new:passedT];
        for (NSInteger j = 0; j < passedT.count; j++) {
            //4. 这里就先直接由assT的GV来自举测试下，因为切入点不太好找，测试时，没必要真去找切入点。
            //4. 从passedT中一个个gv与protoColorDic做自举。
            NSValue *passedRectV = ARR_INDEX(passedT.rects, j);
            CGRect passedRect = passedRectV.CGRectValue;
            
            //5. 用passedT的gv从proto切块。
            NSArray *subDots = [ThinkingUtils getSubDots:colorDic gvRect:passedRect];
            NSDictionary *gvIndex = [AINetGroupValueIndex convertGVIndexData:subDots ds:ds];
            
            //7. 收集起来自举算法结果。
            AIFeatureJvBuItem *bestItem = [TCRecognitionInvoke ziJvItem:j assT:passedT lastProtoRect:passedRect lastAtAssRect:passedRect protoColorDic:colorDic ds:ds model:model];
            if (!bestItem) continue;
            [model.bestGVs addObject:bestItem];
        }
        //8. 收集
        [result addObject:model];
    }
    
    //43. 处理匹配度，符合度
    for (AIFeatureJvBuModel *model in result) {
        [model run4MatchValueAndMatchDegreeAndMatchAssProtoRatio];
    }
    
    //53. 排序
    NSArray *validResult = [SMGUtils sortBig2Small:result compareBlock:^double(AIFeatureJvBuModel *obj) {
        return obj.getGTMatch;
    }];
    
    //61. 更新: ref强度 & 相似度 & 抽具象 & 映射 & conPort.rect;
    for (AIFeatureJvBuModel *model in validResult) {
        
        //52. debug (\t符合度:%.1f\t健全度:%.1f)
        NSLog(@"%ld. 单特征识别结果:T%ld%@\t 匹配条数:%ld/ass%ld %@",[validResult indexOfObject:model],model.assT.pId,CLEANSTR([model.assT getLogDesc:true]),model.bestGVs.count,model.assT.count,model.getSTMatchDesc);
    }
    
    //3. 首先，这个protoRect是从protoColorDic切入来的，这个是不是有问题？这个要做为切入点，切assT用的。。。
    //  a. 首先它性能不佳。
    //  b. 再次它切入点可能很不准确（因为它的信息量不明确，不像createSplitFor9Block里那种处理过的，用来表达protoT的信息量更精准）。
    //4. ST用组码切入还好，但GT识别，可以改成由ST识别结果来做切入点。
    
    //用0识别0确实准一些，但单纯的这样自举肯定不太够，gt也采用自举算法效果差强人意（参考35069）。
}

/**
 *  MARK:--------------------数据输入--------------------
 *  @param dics : 多model (models仅含普通算法model -> 目前没有imv和普通信息掺杂在models中的情况;)
 *  步骤说明:
 *  1. 先构建具象parent节点,再构建抽象sub节点;
 *  2. 仅parent添加到瞬时记忆;
 *  3. 每个subAlg都要单独进行识别操作;
 *
 *  @version
 *      2020.07.19: 空场景时,不将空场景概念加到瞬时记忆序列中 (因为现在的内类比HN已经不再使用空场景做任何参考,所以其存在无意义,反而会影响到时序全含判断,因为记忆时序中的空场景,往往无法被新的时序包含);
 *      2022.10.09: 新输入直接存硬盘而不是isMem内存 (参考27124-todo6);
 *      2023.02.01: 不可识别自身,因为此处自身几乎全是新概念,识别自身似乎目前没啥用 (参考28041-BUG1-思路1-修复);
 *
 *  TODOWAIT:
 *  1. 默认为按边缘(ios的view层级)分组,随后可扩展概念内类比,按别的维度分组; 参考: n16p7
 */
-(void) commitInputWithModelsAsync:(NSArray*)dics algsType:(NSString*)algsType {
    __block NSArray *weakDics = dics;
    __block NSString *weakAT = algsType;
    dispatch_async(self.tiQueue, ^{//30083去异步
        self.tiRuning2 = true;
        [self commitInputWithModels:weakDics algsType:weakAT];
        self.tiRuning2 = false;
    });
}
-(void) commitInputWithModels:(NSArray*)dics algsType:(NSString*)algsType{
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return;
    //1. 数据检查 (小鸟不能仅传入foodView,而要传入整个视角场景)
    dics = ARRTOOK(dics);
    if (ARRISOK(dics)) ISTitleLog(@"皮层输入");
    
    //2. 收集所有具象父概念的value_ps
    NSMutableArray *parentValue_ps = [[NSMutableArray alloc] init];
    NSMutableArray *subValuePsArr = [[NSMutableArray alloc] init];//2维数组
    for (NSDictionary *item in dics) {
        NSArray *item_ps = [theNet algModelConvert2Pointers:item algsType:algsType];
        [parentValue_ps addObjectsFromArray:item_ps];
        [subValuePsArr addObject:item_ps];
    }
    
    //3. 构建父概念 & 将空场景加入瞬时记忆;
    //2024.04.27: BUG: 这里的parentAlg会输出两个向,两个距的概念 (修复: 把parentAlg去掉,等下版本写多码特征时再说,现在搞这个没意义);
    //AIAbsAlgNode *parentAlgNode = [theNet createAbsAlg_NoRepeat:parentValue_ps conAlgs:nil isOut:false at:nil ds:nil type:ATDefault];
    //if (parentValue_ps.count == 0) [self.delegate aiThinkIn_AddToShortMemory:parentAlgNode.pointer isMatch:false];
    //if (Log4TCInput) NSLog(@"---> 构建InputParent节点:%@",Alg2FStr(parentAlgNode));
    
    //4. 收集本组中,所有概念节点;
    NSMutableArray *fromGroup_ps = [[NSMutableArray alloc] init];
    
    //5. 构建子概念 (抽象概念,并嵌套);
    for (NSArray *subValue_ps in subValuePsArr) {
        AIAbsAlgNode *subAlgNode = [theNet createAbsAlg_NoRepeat:subValue_ps conAlgs:@[/*parentAlgNode*/] at:nil ds:nil type:ATDefault];
        [fromGroup_ps addObject:subAlgNode.pointer];
        
        //6. 将所有子概念添加到瞬时记忆 (2020.08.17: 由短时记忆替代);
        NSLog(@"InputSub:%@",Alg2FStr(subAlgNode));
    }
    
    //6. NoMv处理;
    for (AIKVPointer *alg_p in fromGroup_ps) {
        [TCInput rInput:[SMGUtils searchNode:alg_p] except_ps:fromGroup_ps];
    }
}

/**
 *  MARK:--------------------行为输出转输入--------------------
 *  @desc 目前行为进行时序识别,也进行概念识别;
 *  @version
 *      20200414 - 将输出参数集value_ps转到ThinkIn,去进行识别,保留ShortMatchModel,内类比等流程;
 */
-(void) commitOutputLogAsync:(NSArray*)outputModels {
    __block NSArray *weakOutputModels = outputModels;
    dispatch_async(self.tiQueue, ^{//30083去异步
        self.tiRuning3 = true;
        [self commitOutputLog:weakOutputModels];
        self.tiRuning3 = false;
    });
}
-(void) commitOutputLog:(NSArray*)outputModels{
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return;
    //1. 数据
    NSMutableArray *value_ps = [[NSMutableArray alloc] init];
    for (OutputModel *model in ARRTOOK(outputModels)) {
        //2. 装箱
        AIKVPointer *output_p = [theNet getOutputIndex:model.identify outputObj:model.data];
        if (output_p) {
            [value_ps addObject:output_p];
        }
        
        //4. 记录可输出canout (当前善未形成node,所以无法建议索引;(检查一下,当outLog形成node后,索引的建立))
        [AINetUtils setCanOutput:model.identify];
    }
    
    //2. 提交到ThinkIn进行识别_构建概念
    AIAbsAlgNode *outAlg = [theNet createAbsAlg_NoRepeat:value_ps conAlgs:nil isOut:true at:nil type:ATDefault];
    
    //3. 提交到ThinkIn进行识别_加瞬时记忆 & 进行识别
    [TCInput rInput:outAlg except_ps:nil];
}

//MARK:===============================================================
//MARK:                     < 输出流程 >
//MARK:===============================================================

/**
 *  MARK:--------------------TO循环--------------------
 *  @desc 无论当前轮是否成功执行,都调用下轮循环继续TO线程;
 *  @version
 *      2023.07.22: 初版 (参考30084-todo2);
 */
-(void) runToLoop {
    //1. 启动TO线程 (参考30084-方案);
    dispatch_async(_toQueue, ^{
        while (true) {
            if (self.thinkMode == 1 || self.thinkMode == 2) {
                [NSThread sleepForTimeInterval:1];
            }else{
                TCResult *result = [TCPlan planFromTOQueue];
                if (result.step > 21) {
                    NSLog(@"TO上轮:%@ 等待:%.1f 下轮:%lld 消息:%@",result.success?@"成功":@"失败",result.delay,++self.toLoopId,result.msg);
                }
                [NSThread sleepForTimeInterval:1 + result.delay];
            }
        }
    });
}


//MARK:===============================================================
//MARK:                     < 短时记忆 >
//MARK:===============================================================
-(ShortMatchManager*) inModelManager{
    return self.shortMatchManager;
}
-(DemandManager*) outModelManager{
    return self.demandManager;
}


//MARK:===============================================================
//MARK:                     < 活跃度 >
//MARK:===============================================================

/**
 *  MARK:--------------------消耗活跃度--------------------
 */
-(void) updateEnergyDelta:(CGFloat)delta{
    self.energy = MAX(cMinEnergy, MIN(cMaxEnergy, self.energy + delta));
    NSLog(@"energy > delta:%.2f = energy:%.2f",delta,self.energy);
}

/**
 *  MARK:--------------------设新活跃度--------------------
 *  @desc 只有当新的更大时,才有效;
 */
-(void) updateEnergyValue:(CGFloat)value{
    if (value > self.energy) {
        self.energy = MAX(cMinEnergy, MIN(cMaxEnergy, value));
        NSLog(@"energy > newValue:%.2f = energy:%.2f",value,self.energy);
    }
}

/**
 *  MARK:--------------------活跃度有效判断--------------------
 *  @version
 *      2022.05.04: 工作记忆树在限宽基础上,又加上限深后,此处弃用,都返回true (参考2523c-分析代码2);
 *      2022.05.22: roots又有循环卡顿问题,此处加上强行停止思考的功能,以方便调试);
 */
-(BOOL) energyValid{
    if (self.thinkMode == 1 || self.thinkMode == 2) {
        return false;
    }
    return self.energy > 0;
}

//MARK:===============================================================
//MARK:                     < 操作计数 >
//MARK:===============================================================

/**
 *  MARK:--------------------对任何TC操作算一次操作计数--------------------
 *  @param operater : 调用者名称 (调用者方法进入时,调用此方法);
 *  @version
 *      2022.08.08: 判断卡顿状态时,转入植物模式 (参考27063);
 *      2022.08.08: 去掉<200ms的快速执行带来的影响: 仅>200ms时才统计;
 *      2022.08.17: 记录和调试实际last调用者的性能 (参考27064-跟进);
 */
-(void) updateOperCount:(NSString*)operater{
    [self updateOperCount:operater min:200];
}

-(void) updateOperCount:(NSString*)operater min:(NSInteger)min{
    self.operCount++;
    NSString *curQueueLab = [AIThinkingControl getCurQueueLab];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        [self.tiTCDebug updateOperCount:operater min:min];
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        [self.toTCDebug updateOperCount:operater min:min];
    }
}

-(long long) getOperCount{
    return _operCount;
}

//MARK:===============================================================
//MARK:                     < 循环Id >
//MARK:===============================================================

//循环Id (参考26183);
-(void) updateLoopId{
    NSString *curQueueLab = [AIThinkingControl getCurQueueLab];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        self.tiLoopId++;
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        self.toLoopId++;
    }
    [XGConfig.instance responseXGConfig2HE];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        [self.tiTCDebug updateLoopId];
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        [self.toTCDebug updateLoopId];
    }
}
-(long long) getLoopId{
    NSString *curQueueLab = [AIThinkingControl getCurQueueLab];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        return _tiLoopId;
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        return _toLoopId;
    }
    return 0;
}

//MARK:===============================================================
//MARK:                     < 清思维 >
//MARK:===============================================================

/**
 *  MARK:--------------------清思维--------------------
 *  @desc 模拟重启 (参考26014-4);
 */
-(void) clear{
    [self.inModelManager clear];
    [self.outModelManager clear];
    self.energy = 0;
    [theRT invoked:kClearTCSEL];
}

-(void) updateThinkMode:(NSNumber*)value {
    if (NUMISOK(value)) {
        self.thinkMode = value.intValue;
    }
    [theRT invoked:kThinkModeSEL];
}

//MARK:===============================================================
//MARK:                     < 更新TCDebug读写次数 >
//MARK:===============================================================
-(void) updateTCDebugLastRCount {
    NSString *curQueueLab = [AIThinkingControl getCurQueueLab];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        self.tiTCDebug.lastRCount++;
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        self.toTCDebug.lastRCount++;
    }
}

-(void) updateTCDebugLastWCount {
    NSString *curQueueLab = [AIThinkingControl getCurQueueLab];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        self.tiTCDebug.lastWCount++;
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        self.toTCDebug.lastWCount++;
    }
}

+(NSString*) getCurQueueLab {
    return STRFORMAT(@"%s",dispatch_queue_get_label(dispatch_get_current_queue()));
}

//构建默认九宫特征。
-(MapModel*) createSplitFor9Block:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc {
    //2. 装箱（稀疏码的：单码层 和 组码层）。
    NSArray *hGroupModels = [self createSplitFor9BlockV2_Step1:algsModel algsType:algsType ds:@"hColors" logDesc:logDesc];
    NSArray *sGroupModels = [self createSplitFor9BlockV2_Step1:algsModel algsType:algsType ds:@"sColors" logDesc:logDesc];
    NSArray *bGroupModels = [self createSplitFor9BlockV2_Step1:algsModel algsType:algsType ds:@"bColors" logDesc:logDesc];
    
    //3、构建具象特征。
    AIFeatureNode *hFeature = [self createSplitFor9BlockV2_Step2:hGroupModels at:algsType ds:@"hColors" logDesc:logDesc];
    AIFeatureNode *sFeature = [self createSplitFor9BlockV2_Step2:sGroupModels at:algsType ds:@"sColors" logDesc:logDesc];
    AIFeatureNode *bFeature = [self createSplitFor9BlockV2_Step2:bGroupModels at:algsType ds:@"bColors" logDesc:logDesc];
    return [MapModel newWithV1:hFeature v2:sFeature v3:bFeature];
}

-(NSArray*) createSplitFor9BlockV2_Step1:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType ds:(NSString*)ds logDesc:(NSString*)logDesc {
    //2. 装箱（稀疏码的：单码层 和 组码层）。
    //TODO: 这里随后转成NSDictionary后，只要判断dataSource对应的value是dic类型，也可以这么处理（到时候，改V2支持model转Dic类型输入时，自然就知道这里怎么改了）。
    if ([ds isEqualToString:@"hColors"]) {
        return [theNet algModelConvert2PointersV2:algsModel.splitHColors at:algsType ds:ds levelNum:algsModel.levelNum];
    } else if ([ds isEqualToString:@"sColors"]) {
        return [theNet algModelConvert2PointersV2:algsModel.splitSColors at:algsType ds:ds levelNum:algsModel.levelNum];
    } else if ([ds isEqualToString:@"bColors"]) {
        return [theNet algModelConvert2PointersV2:algsModel.splitBColors at:algsType ds:ds levelNum:algsModel.levelNum];
    }
    return nil;
}

-(AIFeatureNode*) createSplitFor9BlockV2_Step2:(NSArray*)hsbGroupModels at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc {
    if (!ARRISOK(hsbGroupModels)) return nil;
    
    //3、构建具象特征。
    //2025.08.07: 具象似层即使是固定粒度也是isGT（参考35062-TODO3.1）。
    AIFeatureNode *hsbFeature = [AIGeneralNodeCreater createFeatureNode:hsbGroupModels conNodes:nil at:at ds:ds isOut:false isJiao:false isGT:true];
    [hsbFeature updateLogDescItem:logDesc];
    
    NSLog(@"%@ %@ T%ld====================================\n%@",logDesc,ds,hsbFeature.pId,FeatureDesc(hsbFeature.p,1));
    //[SMGUtils runByMainQueue:^{
    //    [theApp.imgTrainerView setDataForFeature:hsbFeature lab:STRFORMAT(@"入%@T%ld",hsbFeature.ds,hsbFeature.pId)];
    //}];
    return hsbFeature;
}

@end
