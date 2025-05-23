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
        self.tiRuning1 = false;
    });
}
-(void) commitInputWithSplitV2:(AIVisionAlgsModelV2*)algsModel algsType:(NSString*)algsType logDesc:(NSString*)logDesc {
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return;
    
    //2. 对未切粒度的color字典进行自适应粒度并识别。
    //方便测试，只开放b试下。
    //[self commitInputWithSplitV2_Single_TonDao:algsModel.hColors whSize:algsModel.whSize at:algsType ds:@"hColors" logDesc:logDesc];
    //[self commitInputWithSplitV2_Single_TonDao:algsModel.sColors whSize:algsModel.whSize at:algsType ds:@"sColors" logDesc:logDesc];
    [self commitInputWithSplitV2_Single_TonDao:algsModel.bColors whSize:algsModel.whSize at:algsType ds:@"bColors" logDesc:logDesc];
    
    //3. 异步构建一下默认三分粒度的protoT，不过不用于识别，只用于以后被识别。
    //TODO: 可以加上遗忘机制，冷却一段时间后，还没被识别到，就遗忘清理掉（如无性能问题，只保持现做法：在竞争中不激活也行）。
    [self createSplitFor9Block:algsModel algsType:algsType logDesc:logDesc];
}

//单通道
-(void) commitInputWithSplitV2_Single_TonDao:(NSDictionary*)colorDic whSize:(CGFloat)whSize at:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc {
    //1. 对未切粒度的color字典进行自适应粒度并识别。
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    NSMutableDictionary *gvRectExcept = [NSMutableDictionary new];// <K=rect V=gv_ps>
    DDic *excepts = [DDic new];
    
    //11. 最粗粒度为size/3切，下一个为size/1.3切（参考35026-1）。
    CGFloat dotSize = whSize / 3.0f;
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    while (dotSize > 1) {
        AIFeatureJvBuModels *jvBuModel = [AIFeatureJvBuModels new:colorDic.hash];
        //2025.05.20: 为了防止宏观识别太多，导致更细粒度没机会，改为dotSize层级单独进行防重。
        NSMutableArray *beginRectExcept = [NSMutableArray new];// 被成功匹配过切入点GV区域防重。
        NSMutableArray *assRectExcept = [NSMutableArray new];// 被成功匹配过所有GV区域防重。
        
        //2025.05.20: 从粗到细，识别十条局部特征即可。
        //2025.05.20: BUG-protoGT经常不全：比如有时只识别了0的上半部分，没下半部分，因为这里达到限制条数中断导致的，先关掉，不然肯定有识别一半就中断的情况。
        //if (jvBuModel.models.count >= 10) break;
        
        AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
        //12. 从0-2开始，下一个是1-3...分别偏移切gv（嵌套两个for循环，row和column都这么切）。
        int length = (int)(whSize / dotSize) - 2;//最后两格时，向右不足取3格了，所以去掉-2。
        for (NSInteger startX = 0; startX < length; startX++) {
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            for (NSInteger startY = 0; startY < length; startY++) {
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                //13. 把前面循环已识别过的：结果中已识别到的gv.rect收集起来，如果已包含，则在双for循环中直接continue防重掉（参考35026-防重)。
                //2025.05.07: 此处先仅根据assT防重，以后再考虑根据已收集的rect来防重（目前是通过jvBuModel在局部特征识别算法中实现防重的）。
                CGRect curRect = CGRectMake(startX * dotSize, startY * dotSize, dotSize * 3, dotSize * 3);
                
                //14. 切出当前gv：九宫。
                NSArray *subDots = [ThinkingUtils getSubDots:colorDic gvRect:CGRectMake(startX * dotSize, startY * dotSize, dotSize * 3, dotSize * 3)];
                if (!ARRISOK(subDots)) continue;
                NSDictionary *gvIndex = [AINetGroupValueIndex convertGVIndexData:subDots ds:ds];
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
                
                //21. 局部识别特征：通过组码识别。
                [TIUtils recognitionFeature_JvBu_V2_Step1:gvIndex at:at ds:ds isOut:false protoRect:curRect protoColorDic:colorDic decoratorJvBuModel:jvBuModel excepts:excepts gvRectExcept:gvRectExcept beginRectExcept:beginRectExcept assRectExcept:assRectExcept];
                AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
            }
            AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
        }
        AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
        
        //22. 下一层粒度（再/1.3倍）。
        NSLog(@"第1步、当前dotSize:%.2f 识别结束时条数:%ld",dotSize,jvBuModel.models.count);
        [self commitInputWithSplitV2_Single_DotSize:at ds:ds logDesc:logDesc jvBuModel:jvBuModel dotSize:dotSize];
        dotSize /= 1.3f;
    }
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    PrintDebugCodeBlock_Key(TCDebugKey4AutoSplit);
}

//单粒度层。
-(void) commitInputWithSplitV2_Single_DotSize:(NSString*)at ds:(NSString*)ds logDesc:(NSString*)logDesc jvBuModel:(AIFeatureJvBuModels*)jvBuModel dotSize:(CGFloat)dotSize {
    //23. 局部特征过滤和竞争部分。
    [TIUtils recognitionFeature_JvBu_V2_Step2:jvBuModel];
    NSLog(@"第2步、局部特征竞争后条数:%ld",jvBuModel.models.count);
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    
    //40. 这里先直接调用下类比，先测试下识别结果的类比。
    //TODO: 2025.04.19: 必须是当前protoT识别时的zenTiModel才行，如果是往期zenTiModel不能用，会导致类比找protoT对应不上，导致取rect为Null的BUG（现在把jvBuModel和zenTiModel直接传过去的话，这个对应不上的问题应该不存在）。
    //41. 局部冷启 或 整体识别：分别进行类比（依据不同）（参考34139-TODO1）。
    //42. 特征识别step1识别到的结果，复用jvBuModel进行类比。
    NSMutableArray *groupTModels = [NSMutableArray new];
    for (AIFeatureJvBuModel *model in jvBuModel.models) {
        AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
        AIFeatureNode *itemAbsT = [AIAnalogy analogyFeature_JvBu_V2:model];
        
        //============== 此处有absTAtAssTRect，也有assTAtProtoTRect，根据这两个可以算出absTAtProtoTRect，用于构建组特征用 ==============
        //1. 计算abs在ass中的位置，以及ass在proto中的位置。
        CGRect absAtAssR = CGRectNull;
        if ([itemAbsT.p isEqual:model.assT.p]) {
            absAtAssR = [AINetUtils convertAllOfFeatureContent2Rect:itemAbsT];
        } else {
            absAtAssR = [AINetUtils getConPort:itemAbsT con:model.assT.p].rect;
        }
        CGRect assAtProtoR = model.assTAtProtoTRect;
        
        //2. 计算abs在proto中的位置。
        CGRect absAtProtoR = absAtAssR;
        absAtProtoR.origin.x += assAtProtoR.origin.x;
        absAtProtoR.origin.y += assAtProtoR.origin.y;
        
        //3. 收集为InputGroupFeatureModel。
        [groupTModels addObject:[InputGroupFeatureModel new:itemAbsT.p rect:absAtProtoR]];
        NSLog(@"%@ => %@",@(absAtProtoR),@(model.assTAtProtoTRect));
    }
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    
    //4. 构建protoGT组特征。
    AIGroupFeatureNode *protoGT = [AIGeneralNodeCreater createGroupFeatureNode:groupTModels conNodes:nil at:at ds:ds isOut:false isJiao:true];
    if (!protoGT) return;
    [protoGT updateLogDescItem:logDesc];
    [SMGUtils runByMainQueue:^{
        //[theApp.imgTrainerView setDataForFeature:protoGT lab:STRFORMAT(@"protoGT1:%ld",protoGT.pId)];
    }];
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    
    
    //TODOTOMORROW20250521: 这里应该是protoGT构建的就不准确，查下为什么刚构建就有重影问题，是不是上面局部特征识别的问题？还是类比为抽象局部特征后的问题？
    //验证下如果不做单T类比，直接收集为protoGT的效果。
    //1、继续查下rect是否都正确。
    //2、protoGT是否可以不生成？可是这样就没整体特征的冷启动了。
    //3、protoGT的生成如何尽量不失真？a、最原始是从colorDic取数据，b、再然后可从assT取数据，c、再然后也可以从absT取数据，这三种应该都不会影响protoGT生成的大致样子。
    //4、所以重影肯定是rect算错了，assT组成的protoGT没事，只有absT组成的有问题，明天继续查rect哪里算错了。尤其查下最后一个dotSize，如下日志，xy一样，wh不一样。
    //5、所以：scale应该乘到里面？
    //6、或者把局部特征类比的定责去掉，看全抽象，会打出什么？怎么感觉它全剩下15,3了？
    //NSRect: {{3.3099167688247566, 14.519501653942077}, {15, 3}} => NSRect: {{3.3099167688247566, 14.519501653942077}, {18.589657502338245, 5.1634699699716631}}
    //NSRect: {{3.3099167688247566, 14.519501653942077}, {15, 3}} => NSRect: {{3.3099167688247566, 14.519501653942077}, {18.589657502338245, 5.1634699699716631}}
    //NSRect: {{6.3099167688247562, 26.519501653942079}, {15, 3}} => NSRect: {{3.3099167688247566, 14.519501653942077}, {18.589657502338245, 5.1634699699716631}}
    
    NSMutableArray *groupTModels2 = [NSMutableArray new];
    for (AIFeatureJvBuModel *model in jvBuModel.models) {
        [groupTModels2 addObject:[InputGroupFeatureModel new:model.assT.p rect:model.assTAtProtoTRect]];
    }
    AIGroupFeatureNode *protoGT2 = [AIGeneralNodeCreater createGroupFeatureNode:groupTModels2 conNodes:nil at:at ds:ds isOut:false isJiao:true];
    [SMGUtils runByMainQueue:^{
        //[theApp.imgTrainerView setDataForFeature:protoGT2 lab:STRFORMAT(@"protoGT2:%ld",protoGT2.pId)];
    }];
    
    
    
    
    //5. debugRect
    //for (NSInteger i = 0; i < protoGT.count; i++) {
    //    AIKVPointer *item = ARR_INDEX(protoGT.content_ps, i);
    //    NSValue *itemRect = ARR_INDEX(protoGT.rects, i);
    //    AIPort *refPort = [AINetUtils getRefPort:item biger:protoGT.p refRect:itemRect.CGRectValue];
    //    //if (![itemRect isEqual:@(refPort.rect)]) NSLog(@"2025.05.27后可删aaaaa2 subT%ld:targetT%ld > %@ : %@",item.pointerId,protoGT.pId,itemRect,@(refPort.rect));
    //}
    
    //51. 整体识别特征：通过抽象局部特征做整体特征识别，把JvBu的结果传给ZenTi继续向似层识别（参考34135-TODO5）。
    NSArray *zenTiModel = [TIUtils recognitionFeature_ZenTi_V2:protoGT];
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
    
    //43. 取共同absT，借助absT进行类比（参考34139-TODO1）。
    for (AIFeatureZenTiModel *model in zenTiModel) {
        [AIAnalogy analogyFeature_ZenTi_V2:protoGT assModel:model];
    }
    AddDebugCodeBlock_KeyV2(TCDebugKey4AutoSplit);
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
    //1. 植物模式阻断感知;
    if (self.thinkMode == 2) return nil;
    
    //2. 装箱（稀疏码的：单码层 和 组码层）。
    //TODO: 这里随后转成NSDictionary后，只要判断dataSource对应的value是dic类型，也可以这么处理（到时候，改V2支持model转Dic类型输入时，自然就知道这里怎么改了）。
    NSArray *hGroupModels = [theNet algModelConvert2PointersV2:algsModel.splitHColors at:algsType ds:@"hColors" levelNum:algsModel.levelNum];
    NSArray *sGroupModels = [theNet algModelConvert2PointersV2:algsModel.splitSColors at:algsType ds:@"sColors" levelNum:algsModel.levelNum];
    NSArray *bGroupModels = [theNet algModelConvert2PointersV2:algsModel.splitBColors at:algsType ds:@"bColors" levelNum:algsModel.levelNum];
    
    //3、构建具象特征。
    AIFeatureNode *hFeature = [AIGeneralNodeCreater createFeatureNode:hGroupModels conNodes:nil at:algsType ds:@"hColors" isOut:false isJiao:false];
    AIFeatureNode *sFeature = [AIGeneralNodeCreater createFeatureNode:sGroupModels conNodes:nil at:algsType ds:@"sColors" isOut:false isJiao:false];
    AIFeatureNode *bFeature = [AIGeneralNodeCreater createFeatureNode:bGroupModels conNodes:nil at:algsType ds:@"bColors" isOut:false isJiao:false];
    [hFeature updateLogDescItem:logDesc];
    [sFeature updateLogDescItem:logDesc];
    [bFeature updateLogDescItem:logDesc];
    NSLog(@"%@ H ====================================\n%@",logDesc,FeatureDesc(hFeature.p,1));
    NSLog(@"%@ S ====================================\n%@",logDesc,FeatureDesc(sFeature.p,1));
    NSLog(@"%@ B ====================================\n%@",logDesc,FeatureDesc(bFeature.p,1));
    //[SMGUtils runByMainQueue:^{
    //    [theApp.imgTrainerView setDataForFeature:hFeature lab:STRFORMAT(@"入%@T%ld",hFeature.ds,hFeature.pId)];
    //    [theApp.imgTrainerView setDataForFeature:sFeature lab:STRFORMAT(@"入%@T%ld",sFeature.ds,sFeature.pId)];
    //    [theApp.imgTrainerView setDataForFeature:bFeature lab:STRFORMAT(@"入%@T%ld",bFeature.ds,bFeature.pId)];
    //}];
    return [MapModel newWithV1:hFeature v2:sFeature v3:bFeature];
}

@end
