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
    //[self commitInputWithSplitV2_SingleTonDao:algsModel.hColors whSize:algsModel.whSize at:algsType ds:@"hColors" logDesc:logDesc algsModel:algsModel];
    //[self commitInputWithSplitV2_SingleTonDao:algsModel.sColors whSize:algsModel.whSize at:algsType ds:@"sColors" logDesc:logDesc algsModel:algsModel];
    [self commitInputWithSplitV2_SingleTonDao:algsModel.bColors whSize:algsModel.whSize at:algsType ds:@"bColors" logDesc:logDesc algsModel:algsModel];
}

//单通道
//TODO: 连续优化方案：连续视觉之间复用未变化视角区域的图像识别结果给下一帧视觉（比如屏幕上显示一堆代码，如果有一个地方变化了，我们按ctrlz就能看出来哪里变化了，其实可以没变的地方不重新识别，只有变化的重新识别）。
//连续视觉的优化，可以直接复用gtZiJvGTPool和gtZiJvSTPool，如果AtProtoRect变化不大，直接复用即可。
-(void) commitInputWithSplitV2_SingleTonDao:(NSDictionary*)colorDic whSize:(CGFloat)whSize at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc algsModel:(AIVisionAlgsModelV2*)algsModel {
    // step1. 装箱（稀疏码的：单码层 和 组码层）。
    NSArray *hsbGroupModels = [self createSplitFor9BlockV2_Step1:algsModel algsType:at ds:ds logDesc:logDesc];
    if (hsbGroupModels.count < 5) return; // 2025.10.18: 自动改成有内容的(hsbGroupModels.count > 5)再跑识别类比等。
    
    // step2. 构建具象特征。
    // 异步构建一下默认三分粒度的protoT，不过不用于识别，只用于以后被识别。
    // TODO: 可以加上遗忘机制，冷却一段时间后，还没被识别到，就遗忘清理掉（如无性能问题，只保持现做法：在竞争中不激活也行）（必须是留一段时间，发现在稳定性上竞争太靠后的时候，才应该遗忘，新的不允许就遗忘掉）。
    AIFeatureNode *protoST = [self createSplitFor9BlockV2_Step2:hsbGroupModels at:at ds:ds logDesc:logDesc];
    
    // TODOTOMORROW20260502: 测到有6000多条gv的ST，扔个坤就能复现（参考37114）。
    if ([logDesc isEqualToString:@"鸡_0"]) {
        NSLog(@"%ld",protoST.count);
        NSLog(@"");
    }
    
    // step3. 识别初始化。
    [TCRecognitionInvoke recognitionInit:algsModel.bColors whSize:algsModel.whSize at:at ds:ds logDesc:logDesc];
    
    // step4. 视觉注意力专注范围递归：调用递归（参考37101-方案4）。
    AIFeatureJvBuModels *jvBuModel = [AIFeatureJvBuModels new:colorDic.hash];
    jvBuModel.debug = [GroupDebug new];
    [self commitInputWithSplitV2_DepthRect:algsModel.bColors canvasRect:CGRectMake(0, 0, algsModel.whSize, algsModel.whSize) at:at ds:ds logDesc:logDesc protoST:protoST depth:1 jvBuModel:jvBuModel canvasExcepts:[NSMutableArray new]];
    
    // step5. 竞争 & 类比。
    [self commitInputWithSplitV2_RankAndAnalogy:at ds:ds logDesc:logDesc protoST:protoST jvBuModel:jvBuModel];
}

// 视觉注意力专注范围递归：执行递归（参考37101-方案4）return 执行完成。
-(BOOL) commitInputWithSplitV2_DepthRect:(NSDictionary*)colorDic canvasRect:(CGRect)canvasRect at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc protoST:(AIFeatureNode*)protoST depth:(int)depth jvBuModel:(AIFeatureJvBuModels*)jvBuModel canvasExcepts:(NSMutableArray*)canvasExcepts {
    // excepts防重：已经调用过的与当前canvasRect有80%交集时，不重复执行。
    for (NSValue *canvasExcept in canvasExcepts) {
        if ([SMGUtils rate4IntersectionRectV2:canvasExcept.CGRectValue bRect:canvasRect] > 0.8f) return false;
    }
    [canvasExcepts addObject:@(canvasRect)];
    
    // 视觉注意力专注范围递归：退出递归（最多递归2层）（参考37101-方案4）。
    if (depth > 5) return true;
    NSLog(@"depthRect:%d 画布:%@ begin =============>",depth,Rect2Str(canvasRect));
    
    //1. 对未切粒度的color字典进行自适应粒度并识别。
    NSMutableDictionary *gvRectExcept = [NSMutableDictionary new];// <K=rect V=gv_ps>
    DDic *excepts = [DDic new];
    NSMutableDictionary *beginGVExcept = [NSMutableDictionary new]; // 类似范围的同一个gv只切入一次（防重）<K=gvId,V=[ProtoRect]>。
    
    // 进行覆盖防重：因为粗粒度全扫过，细粒度肯定得重来，不能粗的扫过，细的就没资格切入了。
    AIFeatureJvBuModels *depthModel = [AIFeatureJvBuModels new:colorDic.hash];
    
    // 切GV范围为3-whSize/2，粒度太小切分组20%都不够，太大则只有轮廓而已，二者意义都不明，还浪费很多性能 (参考35126-方案2 & 36034-方案2)。
    // GV全是正方形的九宫，所以也按正方形切图来切入（宽高取一致）。
    CGFloat dotSize = MIN(canvasRect.size.width / 6.0f, canvasRect.size.height / 6.0f);
    CGFloat dotSizeW = dotSize;
    CGFloat dotSizeH = dotSize;
    
    // 每次DepthRect只展开三个粒度层（参考37102-TODO1）。
    int whileNum = 0;
    while (dotSizeW > 1 && dotSizeH > 1 && whileNum < 1) {
        whileNum ++;
        //2025.05.20: 为了防止宏观识别太多，导致更细粒度没机会，改为dotSize层级单独进行防重。
        NSMutableArray *beginRectExcept = [NSMutableArray new];// 被成功匹配过切入点GV区域防重。
        
        //12. 从0-2开始，下一个是1-3...分别偏移切gv（嵌套两个for循环，row和column都这么切）。
        int lengthX = (int)(canvasRect.size.width / dotSizeW) - 2;//最后两格时，向右不足取3格了，所以去掉-2。
        int lengthY = (int)(canvasRect.size.height / dotSizeH) - 2;//最后两格时，向右不足取3格了，所以去掉-2。
        int hit = 0,total = 0;
        for (NSInteger startX = 0; startX < lengthX; startX++) {
            for (NSInteger startY = 0; startY < lengthY; startY++) {
                //13. 把前面循环已识别过的：结果中已识别到的gv.rect收集起来，如果已包含，则在双for循环中直接continue防重掉（参考35026-防重)。
                //2025.05.07: 此处先仅根据assT防重，以后再考虑根据已收集的rect来防重（目前是通过jvBuModel在单特征识别算法中实现防重的）。
                CGRect curRect = CGRectMake(canvasRect.origin.x + startX * dotSizeW, canvasRect.origin.y + startY * dotSizeH, dotSizeW * 3, dotSizeH * 3);
                
                // 切入点防重：识别过区域覆盖防重（通过连续视觉注视可重启）。
                NSInteger repeatNum = 0;
                
                // 第一种：根据gt识别结果防重。
                //for (GTZiJvModelV2 *gtGroup in dotSizeResults) {
                //    for (STZiJvModelV2 *stGroup in gtGroup.bestSTs.allValues) {
                //        for (AIFeatureJvBuItem *gvItem in stGroup.bestGVs.allValues) {
                //            if (CGRectContainsRect(gvItem.bestGVAtProtoTRect, curRect)) {
                //                repeatNum ++;
                //            }
                //            if (repeatNum >= 2) break;
                //        }
                //        if (repeatNum >= 2) break;
                //    }
                //    if (repeatNum >= 2) break;
                //}
                
                // 第二种：根据st识别结果防重。
                for (AIFeatureJvBuModel *stItem in depthModel.stModels) {
                    for (AIFeatureJvBuItem *gvItem in stItem.bestGVs.allValues) {
                        if (CGRectContainsRect(gvItem.bestGVAtProtoTRect, curRect)) repeatNum ++;
                        if (repeatNum >= 1) break;
                    }
                    if (repeatNum >= 1) break;
                }
                total++;
                if (repeatNum >= 1) {
                    hit++;
                    continue;
                }
                
                // 调用识别。
                NSArray *itemResults = [TCRecognitionInvoke recognition:at ds:ds colorDic:colorDic excepts:excepts curRect:curRect beginGVExcept:beginGVExcept gvRectExcept:gvRectExcept jvBuModel:jvBuModel protoST:protoST logDesc:logDesc];
                
                // 切入点防重：相近的地方切入识别的gv避免重复进行识别循环（参考35042-TODO4）（未启用）。
                if (itemResults) [depthModel.stModels addObjectsFromArray:itemResults];
                [beginRectExcept addObject:@(curRect)];
            }
        }
        NSLog(@"\t当前粒度层识别结果：W%.2f H%.2f 识别st数：%ld 防重命中率：%.2f%% (%d/%d)",dotSizeW,dotSizeH,depthModel.stModels.count,(float)hit/total*100,hit,total);
        
        //22. 下一层粒度/1.3（参考35026-1）。
        dotSizeW /= 1.3f;
        dotSizeH /= 1.3f;
    }
    
    // 对识别结果进行竞争排序。
    [TCRecognitionInvoke recognitionFeatureV2_Step2:depthModel ds:ds logDesc:logDesc protoST:protoST justRank:true];
    
    // 递归。
    int runed = 0;
    for (AIFeatureJvBuModel *stModel in depthModel.stModels) {
        runed += [self commitInputWithSplitV2_DepthRect:colorDic canvasRect:stModel.bestGVsAtProtoTRect at:at ds:ds logDesc:logDesc protoST:protoST depth:depth+1 jvBuModel:jvBuModel canvasExcepts:canvasExcepts];
        if (runed >= 3) break;
    }
    return true;
}

-(void) commitInputWithSplitV2_RankAndAnalogy:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc protoST:(AIFeatureNode*)protoST jvBuModel:(AIFeatureJvBuModels*)jvBuModel {
    
    // 2025.07.16：统一进行单特征竞争，类比，组特征识别，类比等（参考35056-TODO1 & TODO2）。
    [TCRecognitionInvoke recognitionFeatureV2_Step2:jvBuModel ds:ds logDesc:logDesc protoST:protoST justRank:false];
    
    // 单特征类比：借助bestGVs来类比。
    for (AIFeatureJvBuModel *model in jvBuModel.stModels) {
        [AIAnalogy analogyFeatureV2:model protoTLogDesc:logDesc prefixIndex:[jvBuModel.stModels indexOfObject:model] + 1];
    }
    NSLog(@"第1步、ST竞争:%ld & 类比 finish",jvBuModel.stModels.count);
    
    // 2025.11.28: 用absST构建ProtoGT，不然必然会各种重影（参考35074-方案v3 & TODOv4 & 35091-TODO1 & 35102-方案2）。
    NSArray *goodSTModels = ARR_SUB(jvBuModel.stModels, 0, 20);
    
    // 方案1、========== 用assST来构建ProtoGT（参考35136）==========
    //NSMutableArray *gtOrders = [SMGUtils convertArr:goodSTModels convertBlock:^id(AIFeatureJvBuModel *model) {
    //    return [InputGroupFeatureModel new:model.assT.p rect:model.assST_ProtoRect];
    //}];
    
    // 方案2、========== 用absST来构建ProtoGT ==========
    NSArray *gtOrders = [SMGUtils convertArr:goodSTModels convertBlock:^id(AIFeatureJvBuModel *model) {
        if (!ARRISOK(model.bestGVs4NoZeRen)) return nil;
        CGRect bestGVs_ProtoT = [SMGUtils convertArr2Rect:model.bestGVs4NoZeRen itemRectBlock:^CGRect(AIFeatureJvBuItem *item) {
            return item.bestGVAtProtoTRect;
        }];
        return [InputGroupFeatureModel new:model.abs_p rect:bestGVs_ProtoT];
    }];
    if (gtOrders.count == 0) return;
    
    // 有序：为增加特征content_ps的有序性：对orders按rect进行排序（特征的content是有序的，所以要先排下序）。
    gtOrders = [ThinkingUtils sortInputGroupFeatureModels:gtOrders];
    
    // 防重：orders
    gtOrders = [SMGUtils removeRepeat:gtOrders convertBlock:^id(InputGroupFeatureModel *obj) {
        return STRFORMAT(@"%ld_%@",obj.feature_p.pointerId,@(obj.rect));
    }];
    
    // TODO: 2026.03.22: 其实这里的ProtoGT已经没什么用了，后面的识别和类比全不必用它，后面删掉？可是要没有第一个ProtoGT，怎么能有后面的识别结果呢？
    // 把absSTs结果打包成protoGT（参考35072-TODO2 & 35074-方案v3 & TODOv4）。
    AIGroupFeatureNode *protoGT = [AIGeneralNodeCreater createGroupFeatureNode:gtOrders conNodes:nil at:at ds:ds isOut:false isJiao:false];
    [protoGT updateLogDescItem:logDesc];
    CGRect jvs_ProtoGTRect = [SMGUtils convertArr2Rect:gtOrders itemRectBlock:^CGRect(InputGroupFeatureModel *item) { return item.rect; }]; // ProtoGT不一定是全局，如果只是一部分，处理下显示时的marginTop和marginLeft。
    [SMGUtils runByMainQueue:^{
        [theApp.imgTrainerView setDataForFeature:protoST lab:STRFORMAT(@"protoST%ld",protoGT.pId) left:0 top:0 tvId:5];
        [theApp.imgTrainerView setDataForFeature:protoGT lab:STRFORMAT(@"protoGT%ld",protoGT.pId) left:jvs_ProtoGTRect.origin.x top:jvs_ProtoGTRect.origin.y tvId:5];
    }];
    NSLog(@"第2步、构建protoGT条数:%ld",protoGT.count);
    
    // 组特征类比V5：用子元素assSTs来类比。
    [TCRecognitionInvoke recognitionGroupFeatureV9_Step2:jvBuModel logDesc:logDesc ds:ds];
    for (GTZiJvModelV2 *assGT in jvBuModel.gtModels) {
        [AIAnalogy analogyGroupFeatureV10:ds at:at isOut:false logDesc:logDesc gtModel:assGT prefixIndex:[jvBuModel.gtModels indexOfObject:assGT] + 1];
    }
    NSLog(@"第3步、GT竞争%ld & 类比 finish",jvBuModel.gtModels.count);
    AddDebugCodeBlock_KeyV3();
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
