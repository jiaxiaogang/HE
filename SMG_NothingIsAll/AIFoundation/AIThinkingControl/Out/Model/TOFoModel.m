//
//  TOFoModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2019/1/30.
//  Copyright © 2019年 XiaoGang. All rights reserved.
//

#import "TOFoModel.h"

@interface TOFoModel()

@property (strong, nonatomic) NSMutableArray *subModels;
@property (strong, nonatomic) NSMutableArray *subDemands; //(self是fo时,subDemands中放着R子任务subRDemands)

/**
 *  MARK:--------------------OutSP强度值反馈记录--------------------
 *  @说明 用于检查:避免重复&避免冲突 (仅放在内存中,不持久化,避免它重复计SP值,或者计了S又计P的冲突);
 */
@property (strong, nonatomic) SPMemRecord *spMemRecord;

@end

@implementation TOFoModel

+(TOFoModel*) newForRCansetFo:(AIKVPointer*)fCanset
                         base:(TOModelBase<ITryActionFoDelegate>*)base basePFoOrTargetFoModel:(id)basePFoOrTargetFoModel baseSceneModel:(AISceneModel*)baseSceneModel
                sceneCutIndex:(NSInteger)sceneCutIndex cansetCutIndex:(NSInteger)cansetCutIndex
            cansetTargetIndex:(NSInteger)cansetTargetIndex sceneFromTargetIndex:(NSInteger)sceneFromTargetIndex {
    TOFoModel *model = [[TOFoModel alloc] init];
    
    //1. 原CansetModel相关赋值;
    model.fCanset = fCanset;
    model.basePFoOrTargetFoModel = basePFoOrTargetFoModel;
    model.baseSceneModel = baseSceneModel;//R任务时,即R任务的RSceneModel;
    model.sceneCutIndex = sceneCutIndex;
    model.initCansetCutIndex = cansetCutIndex;
    model.cansetCutIndex = cansetCutIndex;//R任务时,cansetCutIndex其实是顺着scene找上一帧有映射的 (参考TOUtils.goBackToFindConIndexByAbsIndex());
    model.cansetTargetIndex = cansetTargetIndex;
    model.sceneTargetIndex = sceneFromTargetIndex;//R任务时,其实rScene的目标就是最后一帧 (即目标 = rScene.count);
    model.alreadyActionActIndex = -1;
    
    //2. TOFoModel相关赋值;
    model.content_p = fCanset;
    model.status = TOModelStatus_Runing;
    if (base) [base.actionFoModels addObject:model];
    model.baseOrGroup = base;
    return model;
}

+(TOFoModel*) newForHCansetFo:(AIKVPointer*)fCanset base:(TOModelBase<ITryActionFoDelegate>*)base
               cansetCutIndex:(NSInteger)cansetCutIndex sceneCutIndex:(NSInteger)sceneCutIndex
            cansetTargetIndex:(NSInteger)cansetTargetIndex sceneTargetIndex:(NSInteger)sceneTargetIndex
       basePFoOrTargetFoModel:(id)basePFoOrTargetFoModel baseSceneModel:(AISceneModel*)baseSceneModel {
    TOFoModel *model = [[TOFoModel alloc] init];
    
    //1. 原CansetModel相关赋值;
    model.fCanset = fCanset;
    model.basePFoOrTargetFoModel = basePFoOrTargetFoModel;
    model.baseSceneModel = baseSceneModel;//H任务时,其实是复用了R任务的RSceneModel;
    model.initCansetCutIndex = cansetCutIndex;
    model.cansetCutIndex = cansetCutIndex;//H任务时,cansetCutIndex其实是顺着scene找上一帧有映射的 (参考TOUtils.goBackToFindConIndexByAbsIndex());
    model.cansetTargetIndex = cansetTargetIndex;
    model.sceneCutIndex = sceneCutIndex;
    model.sceneTargetIndex = sceneTargetIndex;//H任务时,其实hScene的目标就是hScene的下一帧 (即目标 = hScene.cutIndex + 1);
    model.alreadyActionActIndex = -1;
    
    //2. TOFoModel相关赋值;
    model.content_p = fCanset;
    model.status = TOModelStatus_Runing;
    if (base) [base.actionFoModels addObject:model];
    model.baseOrGroup = base;
    return model;
}

//MARK:===============================================================
//MARK:                     < CansetIndexDic映射部分 >
//写此处代码起因:  在TI中,早就有realMaskFo和realDeltaTimes的做法,并且indexDic映射也够用,但在TO中,测出了构建RHCanset时,其indexDic或不准,或为空的问题;
//              而写这个realCansetToIndexDic,就是为了整理这一流程,将其数据整理过来,使之相关代码看着顺当简洁,也解决TO中indexDic不准等问题;
//MARK:===============================================================

-(NSMutableDictionary *)realCansetToIndexDic {
    if (!_realCansetToIndexDic) _realCansetToIndexDic = [[NSMutableDictionary alloc] init];
    return _realCansetToIndexDic;
}

/**
 *  MARK:--------------------Real映射第1步: 初始数据 (参考31154-方案2-todo1)--------------------
 *  @本算法示图: https://github.com/jiaxiaogang/HELIX_THEORY/blob/master/手稿/assets/717_Canset%E7%9A%84%E5%88%9D%E5%A7%8BIndexDic%E5%88%86%E6%9E%90.png?raw=true
 *             说明: 此图说明了,此方法中base和self的关系,及初始indexDic计算方式
 *  @desc 在xvModel赋值后执行: 在TO中,cansetFo迁移xv之后(xvModel赋值后),将sceneTo和cansetTo已发生部分的映射存下来 (参考31154-方案2-todo1);
 *        另注: 在TI中,时序识别预测后,也会将预测matchFo和实际发生maskFo中已发生的部分存下来 (不在此方法中,在AIMatchFoModel的realMaskFo和indexDic2中);
 *  @调用说明: 在xvModel执行后,执行这里;
 */
-(void) initRealCansetToDic {
    //===================== base是pFo时 =====================
    NSDictionary *realSceneToDic = nil;
    if (!self.isH) {
        //第1步. 在basePFo中取到indexDic2 (matchFo与real的映射,也即当前sceneTo与real的映射) (参考31155-第1步);
        //结构说明: matchFo(pFo)是当前的sceneTo;
        AIMatchFoModel *pFo = self.basePFo;
        realSceneToDic = [SMGUtils filterDic:pFo.indexDic2 checkValid:^BOOL(NSNumber *key, id value) {
            //a. 并过滤已发生部分 (参考31155-第1b步);
            return key.integerValue <= pFo.cutIndex;
        }];
    }
    
    //===================== base就是HCanset时 =====================
    else {
        //第1步. 在base中取到realCansetToIndexDic (base.cansetTo与real的映射,也即当前sceneTo与real的映射) (参考31155-第1步);
        //结构说明: base.cansetTo就是当前的sceneTo;
        //过滤说明: 无需过滤已发生部分,因为base.realCansetToIndexDic里包含的,就一定是已经发生的;
        TOFoModel *baseTargetFoModel = self.basePFoOrTargetFoModel;
        realSceneToDic = baseTargetFoModel.realCansetToIndexDic;
    }
    
    //第2步. 在当前xvModel中取到sceneTo与cansetTo的映射 (参考31155-第2步);
    NSDictionary *sceneToCansetToDic = self.transferXvModel.sceneToCansetToIndexDic;
    
    //第3步. 计算: 根据以上两个映射,计算出: 当前cansetTo和real的映射 (参考31155-第3步);
    DirectIndexDic *dic1 = [DirectIndexDic newOkToAbs:sceneToCansetToDic];
    DirectIndexDic *dic2 = [DirectIndexDic newNoToAbs:realSceneToDic];
    [self.realCansetToIndexDic setDictionary:[TOUtils zonHeIndexDic:@[dic1,dic2]]];
    //NSLog(@"test3435配套日志：此日志用于查RealCansetToIndexDic重复的BUG，如果test34和35再出现问题，那么打开此日志查下原因 %p %p RealCansetToIndexDic更新1 %@",self.basePFo.realMaskFo,self.realCansetToIndexDic,CLEANSTR(self.realCansetToIndexDic));
    [AITest test34:self.realCansetToIndexDic];
}

/**
 *  MARK:--------------------补上因层层传递求综合映射,导致前段错漏的映射 (参考33086-TODO1)--------------------
 *  @desc 在不打乱realCansetToIndexDic在init后的映射基础上,把前段别的条件帧判断下,有mIsC有映射的补上映射关系;
 *  @desc 说明: 本方法把前段的canset从前往后,一帧帧从realMaskFo中,找映射 (在已有映射的间隔间,找找有没有mIsC能匹配上的,追加到映射中);
 */
-(void) fixRealCansteToDic {
    //1. 前段逐帧判断有没映射,有映射的跳过,无映射的尝试通过mIsC补充;
    NSArray *oldDic = [self.realCansetToIndexDic copy];
    NSInteger realProgress = -1;
    NSArray *realMaskFo = self.basePFo.realMaskFo;
    for (NSInteger i = 0; i < self.cansetActIndex; i++) {
        
        //2. 优先判断现有映射;
        BOOL cansetToAlgHavDic = [self.realCansetToIndexDic.allKeys containsObject:@(i)];
        if (cansetToAlgHavDic) {
            realProgress = NUMTOOK([self.realCansetToIndexDic objectForKey:@(i)]).integerValue;
            continue;
        }
        
        //3. 然后判断mIsC;
        AIShortMatchModel_Simple *item = ARR_INDEX(self.transferXvModel.cansetToOrders, i);
        AIKVPointer *cansetToAlg_p = item.alg_p;
        
        for (NSInteger j = realProgress + 1; j < realMaskFo.count; j++) {
            
            //4. 如果j有映射,则打断 (因为已经有映射了,不能再追加成别的mIsC映射了);
            BOOL realAlgHavDic = [self.realCansetToIndexDic.allValues containsObject:@(j)];
            if (realAlgHavDic) {
                realProgress = j;
                break;
            }
            
            //5. 如果j没映射,则可以追加判断mIsC (参考feedbackTOR判断,这里应该用[proto.absAlgs contains:cansetToAlg]来表示mIsC成立);
            AIKVPointer *realMaskAlg = ARR_INDEX(realMaskFo, j);
            NSArray *realMaskAlgAbs_ps = Ports2Pits([AINetUtils absPorts_All:[SMGUtils searchNode:realMaskAlg]]);
            if ([realMaskAlgAbs_ps containsObject:cansetToAlg_p]) {
                //6. 成功发现新映射;
                [self.realCansetToIndexDic setObject:@(j) forKey:@(i)];
                //NSLog(@"test3435配套日志：此日志用于查RealCansetToIndexDic重复的BUG，如果test34和35再出现问题，那么打开此日志查下原因 %p %p RealCansetToIndexDic更新2 %@ K:%ld V:%ld",self.basePFo.realMaskFo,self.realCansetToIndexDic,CLEANSTR(self.realCansetToIndexDic),i,j);
                [AITest test34:self.realCansetToIndexDic];
                realProgress = j;
                break;
            }
            
            //7. 最终也没找着映射 (realProgress不变,下一帧继续从它开始找);
        }
    }
    
    //8. log
    BOOL logSwitch = true;
    if (self.realCansetToIndexDic.count > oldDic.count && logSwitch) {
        BOOL frontDicIsOk = self.realCansetToIndexDic.count >= self.cansetCutIndex + 1;
        NSLog(@"F%ld补映射前:%@ => 后:%@ (前段通过:%d)",self.fCanset.pointerId,CLEANSTR(oldDic),CLEANSTR(self.realCansetToIndexDic),frontDicIsOk);
        NSLog(@"\t1. 前段cansetTo:%@",Pits2FStr([SMGUtils convertArr:self.transferXvModel.cansetToOrders convertBlock:^id(AIShortMatchModel_Simple *obj) {return obj.alg_p;}]));
        NSLog(@"\t2. 前段realMaskFo:%@",Pits2FStr([self.basePFo.realMaskFo copy]));
    }
}

/**
 *  MARK:--------------------Real映射第2步: 逐帧更新 (参考31154-方案2-todo2)--------------------
 *  @desc feedbackTOR反馈匹配时: 为R/HCanset更新self.realCansetToIndexDic(cansetTo匹配上的帧 与 realMask相应匹配的实际发生)的映射 (参考31154-方案2-todo2 && 31155-后注);
 *      另. 在TI中,每一次feedbackTIR反馈后,更新pFo中的indexDic2映射 (这一条在feedbackPushFrame()中实现,不在此方法中);
 *  @调用说明: 在feedbackTOR匹配成功时,调用这里更新下映射;
 */
-(void) updateRealCansetToDic {
    //"pFo的最后一帧下标"  与  "现cutIndex下一帧(在等待反馈帧)"  之间因为匹配成功而=>  "追加映射";
    AIMatchFoModel *pFo = self.basePFo;
    [AITest test35:self.realCansetToIndexDic newK:self.cansetActIndex newV:pFo.realMaskFo.count - 1];
    [self.realCansetToIndexDic setObject:@(pFo.realMaskFo.count - 1) forKey:@(self.cansetActIndex)];
    //NSLog(@"test3435配套日志：此日志用于查RealCansetToIndexDic重复的BUG，如果test34和35再出现问题，那么打开此日志查下原因 %p %p RealCansetToIndexDic更新3 %@ K:%ld V:%ld (有效:%d)",self.basePFo.realMaskFo,self.realCansetToIndexDic,CLEANSTR(self.realCansetToIndexDic),self.cansetActIndex,pFo.realMaskFo.count-1,pFo.isExpired);
    [AITest test34:self.realCansetToIndexDic];
}

/**
 *  MARK:--------------------每层第一名之和分值--------------------
 *  @desc 跨fo的综合评分,
 *          1. 比如打篮球去?还是k歌去,打篮球考虑到有没有球,球场是否远,自己是否累,天气是否好, k歌也考虑到自己会唱歌不,嗓子是否舒服;
 *          2. 当对二者进行综合评分,选择时,涉及到结构化下的综合评分;
 *          3. 目前用不着,以后可能也用不着;
 *
 */
//-(CGFloat) allNiceScore{
//    //TOModelBase *subModel = [self itemSubModels];
//    //if (subModel) {
//    //    return self.score + [subModel allNiceScore];
//    //}
//    //1. 从当前cutIndex
//    //2. 找itemSubModels下
//    //3. 所有status未中止的
//    //4. 那些时序的评分总和
//    return self.score;
//}

-(NSMutableArray *)subModels {
    if (_subModels == nil) _subModels = [[NSMutableArray alloc] init];
    return _subModels;
}
-(NSMutableArray *)subDemands{
    if (_subDemands == nil) _subDemands = [[NSMutableArray alloc] init];
    return _subDemands;
}

//MARK:===============================================================
//MARK:                     < feedbackMv部分 >
//MARK:===============================================================
-(BOOL) feedbackMvAndPlus {
    return self.feedbackMv && [AIScore score4MV:self.feedbackMv ratio:1.0f] > 0;
}

-(BOOL) feedbackMvAndSub {
    return self.feedbackMv && [AIScore score4MV:self.feedbackMv ratio:1.0f] < 0;
}

/**
 *  MARK:--------------------将每帧反馈转成orders,以构建protoFo--------------------
 *  @param fromRegroup : 从TCRegroup调用时未发生部分也取, 而用于canset抽象时仅取已发生部分;
 *  @version
 *      2022.11.25: 转regroupFo时收集默认content_p内容(代码不变),canset再类比时仅获取feedback反馈的alg (参考27207-1);
 *      2023.02.12: 返回改为: matchFo的前段+执行部分反馈帧 (参考28068-方案1);
 */
-(NSArray*) getOrderUseMatchAndFeedbackAlg:(BOOL)fromRegroup {
    //1. 数据准备 (收集除末位外的content为order);
    NSMutableArray *order = [[NSMutableArray alloc] init];
    NSArray *feedbackIndexArr = [self getIndexArrIfHavFeedback];
    NSInteger maxIndex = fromRegroup ? self.transferXvModel.cansetToOrders.count - 1 : self.cansetCutIndex;
    
    //2. 将fo逐帧收集真实发生的alg;
    for (NSInteger i = 0; i <= maxIndex; i++) {
        //3. 找到当前帧alg_p;
        AIShortMatchModel_Simple *cansetToSimple = ARR_INDEX(self.transferXvModel.cansetToOrders, i);
        
        //4. 如果有反馈feedbackAlg,则优先取反馈;
        AIKVPointer *findAlg_p = cansetToSimple.alg_p;
        if ([feedbackIndexArr containsObject:@(i)]) {
            findAlg_p = [self getFeedbackAlgWithSolutionIndex:i];
        }
        
        //5. 生成时序元素 (不管有没有feedbackAlg,deltaTime都延用xvModel.order中的时间);
        if (findAlg_p) {
            [order addObject:[AIShortMatchModel_Simple newWithAlg_p:findAlg_p inputTime:cansetToSimple.inputTime isTimestamp:cansetToSimple.isTimestamp]];
        }
    }
    return order;
}

//MARK:===============================================================
//MARK:                     < privateMthod >
//MARK:===============================================================

/**
 *  MARK:--------------------获取当前solution中有反馈的下标数组--------------------
 *  @result <K:有反馈的下标,V:有反馈的feedbackAlg_p>
 */
-(NSMutableArray*) getIndexArrIfHavFeedback {
    //1. 数据准备;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. 将fo逐帧收集有反馈的conIndex (参考27207-7);
    for (NSInteger i = 0; i < self.transferXvModel.cansetToOrders.count; i++) {
        AIShortMatchModel_Simple *canstToSimple = ARR_INDEX(self.transferXvModel.cansetToOrders, i);
        for (TOAlgModel *item in self.subModels) {
            if (item.status == TOModelStatus_OuterBack && [item.content_p isEqual:canstToSimple.alg_p] && item.feedbackAlg) {
                [result addObject:@(i)];
                break;
            }
        }
    }
    return result;
}

/**
 *  MARK:--------------------根据solutionIndex取feedbackAlg--------------------
 */
-(AIKVPointer*) getFeedbackAlgWithSolutionIndex:(NSInteger)solutionIndex {
    //1. 数据准备;
    AIShortMatchModel_Simple *cansetToSimple = ARR_INDEX(self.transferXvModel.cansetToOrders, solutionIndex);
    
    //2. 找出反馈返回;
    for (TOAlgModel *item in self.subModels) {
        if (item.status == TOModelStatus_OuterBack && [item.content_p isEqual:cansetToSimple.alg_p] && item.feedbackAlg) {
            return item.feedbackAlg;
        }
    }
    return nil;
}

//递归取basePFo (即使是H任务的basePFoOrTargetFoModel再basePFoOrTargetFoModel不断递归能找到最终R任务的pFo);
-(AIMatchFoModel*) basePFo {
    if (ISOK(self.basePFoOrTargetFoModel, AIMatchFoModel.class)) {
        return self.basePFoOrTargetFoModel;
    }
    return ((TOFoModel*)self.basePFoOrTargetFoModel).basePFo;
}

//MARK:===============================================================
//MARK:                     < for 三级场景 >
//MARK:===============================================================

/**
 *  MARK:--------------------有iCanset直接返回进行行为化等 (参考29069-todo9 & todo10.1b)--------------------
 */
-(AIKVPointer *)content_p {
    return self.fCanset;
}

- (NSInteger)cansetActIndex {
    return self.cansetCutIndex + 1;
}

/**
 *  MARK:--------------------下帧初始化 (可接受反馈) (参考31073-TODO2g)--------------------
 *  @desc 上帧推进完成时调用: 1.更新cutIndex++ 2.挂载下帧TOAlgModel
 *  @version
 *      2024.01.25: 初版: 此方法逻辑与TCAction一致,只是为了允许被反馈和记录feedbackAlg,所以把这些代码前置了 (参考31073-TODO2g);
 *      2024.04.21: 下帧行为化,只能以迁移后的cansetTo为准 (原来的有取cansetFrom是不对的);
 */
-(void) pushNextFrame {
    //1. 如果已经彻底完成,则没有下一帧了;
    if (self.cansetCutIndex >= self.cansetTargetIndex) return;
    
    //2. 取下帧alg数据 (下帧即已发生+1);
    AIShortMatchModel_Simple *nextCansetTo = ARR_INDEX(self.transferXvModel.cansetToOrders, self.cansetActIndex);
    AIKVPointer *nextCansetTo_p = nextCansetTo.alg_p;
    
    //3. 挂载TOAlgModel;
    if (self.cansetActIndex < self.cansetTargetIndex) {
        //6. 转下帧: 理性帧则生成TOAlgModel;
        [TOAlgModel newWithAlg_p:nextCansetTo_p group:self];
    }else{
        if(ISOK(self.baseOrGroup, HDemandModel.class)){
            //9. H目标帧只需要等 (转hActYes) (参考25031-9);
            [TOAlgModel newWithAlg_p:nextCansetTo_p group:self];
        } else {
            //R任务的最后一帧nextCansetTo_p是nil,不需要algModel;
        }
    }
}

/**
 *  MARK:--------------------获取当前正在推进中的帧--------------------
 */
-(TOAlgModel*) getCurFrame {
    //1. 已行为化完成,即mv帧,则返回nil;
    if (self.cansetActIndex >= self.transferXvModel.cansetToOrders.count) return nil;
    
    //方法1. 从subModels中找出cutIndex对应的那一条返回 (cutIndex是已发生,推进中是+1);
    AIShortMatchModel_Simple *curCansetTo = ARR_INDEX(self.transferXvModel.cansetToOrders, self.cansetActIndex);
    return [SMGUtils filterSingleFromArr:self.subModels checkValid:^BOOL(TOAlgModel *item) {
        return [item.content_p isEqual:curCansetTo.alg_p];
    }];
    
    //方法2. 直接取subModels的最后一条 (按道理最后一条就是当前正在推进中的,但严谨上说目前不太确定,所以先用方法1)
    //return ARR_INDEX_REVERSE(self.subModels, 0);
}

/**
 *  MARK:--------------------feedbackTOR反馈时触发,用于每个cansetFo都可以接受持续反馈推进--------------------
 */
-(BOOL) commit4FeedbackTOR:(NSArray*)feedbackMatchAlg_ps protoAlg:(AIKVPointer*)protoAlg_p except4SP2F:(NSMutableArray*)except4SP2F {
    //1. 反馈判断,无反馈直接return (参考31073-TODO2);
    BOOL feedbackValid = [self step1_CheckFeedbackTORIsValid:feedbackMatchAlg_ps protoAlg:protoAlg_p];
    if (!feedbackValid) return false;
    
    //2. SP计数之三(R正): 中间帧反馈成功时,直接计outSPDic为SP+1 (参考32012-TODO5);
    [self checkAndUpdateOutSPStrong_Reason:1 type:ATPlus debugMode:true caller:@"中间帧反馈" except4SP2F:except4SP2F];//3b. 只要反馈成功的,都进行P+1;
    
    //2. 反馈有效: 构建hCanset;
    [self step2_FeedbackThenNewHCanset:protoAlg_p except4SP2F:except4SP2F];
    
    //3. 反馈成立,更新已发生;
    self.cansetCutIndex ++;
    
    //3. 并推进到下帧 (参考31073-TODO2g-3);
    [self pushNextFrame];
    return true;
}

/**
 *  MARK:--------------------检查feedbackTOR反馈是否对此CansetModel有效 (参考31073-TODO2)--------------------
 */
-(BOOL) step1_CheckFeedbackTORIsValid:(NSArray*)feedbackMatchAlg_ps protoAlg:(AIKVPointer*)protoAlg_p {
    //2024.01.11: 此处可以考虑支持持续反馈 (参考31063-todo1);
    //2024.01.25: 现在应该能支持仅靠匹配度来竞争了,因为CansetModels已经支持实时竞争了,但现在接受一次反馈后,就会pushNextFrame,是不支持以往帧持续反馈的,随后再改支持吧);
    //AIKVPointer *oldFeedbackAlg = curAlgModel.feedbackAlg;//新旧反馈用匹配度竞争一下: 更匹配则替换等 | 否则则把oldFeedbackAlg改回去;
    
    //1. 未达到cansetTargetIndex才接受反馈;
    if (self.cansetCutIndex >= self.cansetTargetIndex) return false;
    feedbackMatchAlg_ps = ARRTOOK(feedbackMatchAlg_ps);
    
    //2. 判断反馈mIsC是否有效 (比如找锤子,看到锤子了 & 再如吃,确定自己是否真吃了);
    AIShortMatchModel_Simple *cansetToSimple = ARR_INDEX(self.transferXvModel.cansetToOrders, self.cansetActIndex);
    BOOL mIsC = [feedbackMatchAlg_ps containsObject:cansetToSimple.alg_p];
    if (!mIsC) return false;
    NSString *fltLog = self.cansetStatus != CS_None && !self.isH ? FltLog4XueQuPi(2) : @"";
    NSString *fltLog2 = [Pit2FStr(protoAlg_p) containsString:@"皮果"] ? FltLog4HDemandOfYouPiGuo(@"4") : @"";
    NSString *fltLog3 = self.cansetStatus != CS_None ? FltLog4YonBanYun(2) : @"";
    NSString *fltLog4 = FltLog4CreateHCanset(2);
    if (Switch4FeedbackTOR) NSLog(@"%@%@%@%@%@%@ feedbackTOR反馈成立:%@ 匹配:%d baseCansetFrom:%@ 状态:%@",FltLog4AbsHCanset(self.isH, 2),fltLog,fltLog2,fltLog3,fltLog4,self.isH?@"H":@"R",Pit2FStr(cansetToSimple.alg_p),mIsC,Pit2FStr(self.fCanset),CansetStatus2Str(self.cansetStatus));
    
    //3. 有效时: 记录feedbackAlg;
    TOAlgModel *curAlgModel = [self getCurFrame];
    curAlgModel.feedbackAlg = protoAlg_p;
    curAlgModel.status = TOModelStatus_OuterBack;
    self.status = TOModelStatus_Runing;
    
    //5. 反馈成立,更新映射;
    [self updateRealCansetToDic];
    return true;
}

/**
 *  MARK:--------------------feedback有效后: 构建newHCanset和absHCanset (参考31073-TODO7)--------------------
 *  @desc 此方法代码是从feedbackTOR搬过来的,原来的代码有点乱,整理了下使之易读些,并搬到了这里 (参考31073-TODO7);
 *  @param protoAlg_p feedbackTOR方法中的protoAlg传过来;
 */
-(void) step2_FeedbackThenNewHCanset:(AIKVPointer*)protoAlg_p except4SP2F:(NSMutableArray*)except4SP2F {
    //1. 数据准备;
    TOAlgModel *curAlgModel = [self getCurFrame];
    
    //========== 第1部分: 当R任务有理性帧推进时,生成newHCanset ==========
    //"行为输出" 和 "demand.ActYes" 和 "静默成功 的有效判断
    //此处有两种frameAlg,第1种是isOut为true的行为反馈,第2种是hDemand.baseAlg;
    //2024.04.21: 激活过(转实)的就能类比 (原则是: 有si即有预期,在此基础上尽可能多的为其构建NewHCanset经验);
    if (!self.isH && self.cansetStatus != CS_None) {
        //2. 旧有那些改状态status的代码,整理在此处 (参考31073-TODO7-4);
        //3. 当waitModel为hDemand.targetAlg时,此处提前反馈了,hDemand改为finish状态 (参考26185-TODO6);
        HDemandModel *subHDemand = [SMGUtils filterSingleFromArr:curAlgModel.subDemands checkValid:^BOOL(id item) {
            return ISOK(item, HDemandModel.class);
        }];
        //注: 此处非CS_None状态的cansetModel,subHDemand一般为nil;
        if (subHDemand) subHDemand.status = TOModelStatus_Finish;
        if (Log4OPushM) NSLog(@"RCansetA有效:M(A%ld) C(A%ld) CAtFo:%@",protoAlg_p.pointerId,curAlgModel.content_p.pointerId,Pits2FStr(Simples2Pits(self.transferXvModel.cansetToOrders)));
        self.status = TOModelStatus_Runing;
        
        //4. 收集真实发生realMaskFo,收集成hCanset (参考30131-todo1 & 30132-方案);
        //2023.12.29: mcIsBro=true时,生成新hCanset (做31026-第2步时临时起意改的);
        NSArray *cansetToContent_ps = Simples2Pits(self.transferXvModel.cansetToOrders);
        AIMatchFoModel *basePFo = self.basePFo;
        NSArray *newHCansetOrders = [basePFo convertOrders4NewCansetV2];
        AIFoNodeBase *pFo = [SMGUtils searchNode:basePFo.matchFo];
        
        //5. 调试和日志。
        //2025.03.02: 挂在rCanset下，改成挂在rScene（pFo）下（参考33171-TODO1）。
        if (self.realCansetToIndexDic.count == 0) {
            NSLog(@"NewHCanset Dic Is Nil");
        }
        AIKVPointer *actIndexAlg_p = ARR_INDEX(cansetToContent_ps, self.cansetActIndex);
        NSString *fltLog = FltLog4CreateHCanset(3);
        NSLog(@"%@%@%@%@Canset演化> NewHCanset:%@ 反馈到rCanset:%@ 的%ld帧:%@",FltLog4XueQuPi(3),FltLog4HDemandOfYouPiGuo(@"5"),FltLog4XueBanYun(2),fltLog,Pits2FStr(Simples2Pits(newHCansetOrders)),Pits2FStr(cansetToContent_ps),self.cansetActIndex,Pit2FStr(actIndexAlg_p));
        
        //2024.11.03: 在挂载新的Canset时,实时推举 & 并防重(只有新挂载的canset,才有资格实时调用推举,并推举spDic都到父场景中) (参考33112);
        //6. 推举是从I推举到F（而pFo就是I层，所以sceneFrom就是pFo）。
        NSDictionary *iNewCansetISceneIndexDic = [basePFo.indexDic2 copy];
        NSArray *baseSceneContent_ps = Simples2Pits([self getBaseSceneToOrders]);
        NSMutableDictionary *initOutSPDic = [[NSMutableDictionary alloc] init];
        for (NSInteger i = 0; i < newHCansetOrders.count; i++) [initOutSPDic setObject:[AISPStrong newWithS:0 P:1] forKey:@(i)];
        [TCTransfer transferTuiJv_RH_V3:pFo iCansetOrders:newHCansetOrders iCansetISceneIndexDic:iNewCansetISceneIndexDic isH:true sceneFromCutIndex:basePFo.cutIndex initOutSPDic:initOutSPDic baseSceneContent_ps:baseSceneContent_ps];
            
        //7. rCanset的actIndex匹配了,就相当于它curAlgModel的HDemand,下的所有的subHCanset的targetAlg全反馈匹配上了 (参考32119-TODO1);
        HDemandModel *curHDemand = ARR_INDEX(curAlgModel.subDemands, 0);
        if (!curHDemand) return;
        for (TOFoModel *hCanset in curHDemand.actionFoModels) {
            [hCanset step3_FeedbackThenAbsHCanset:newHCansetOrders];
        }
    }
}

/**
 *  MARK:--------------------反馈上后: 触发类比抽象出AbsHCanset--------------------
 *  @desc 反馈匹配到targetAlg时,会触发AbsHCanset类比抽象 (可能一帧帧过来,也可能提前直接反馈target) (参考32119-TODO1);
 *  @param newHCansetOrders 2024.07.29: 复用NewHCanset的生成在此处 (不必再单独生成NewHCanset);
 */
-(void) step3_FeedbackThenAbsHCanset:(NSArray*)newHCansetOrders {
    //========== 第2部分: 当H任务推进到最终target时,触发预想与实际类比absHCanset ==========
    //5. H返回的有效判断
    //2024.04.21: 激活过(转实)的就能类比 (原则是: 有si即有预期,在此基础上尽可能多的触发预期与实际的类比);
    //2024.07.29: 此时,可以直接调用所有best过的hCanset来进行H类比抽象 (并且不需要isEndFrame);
    if (!self.isH || self.cansetStatus == CS_None) return;
    if (!ARRISOK(newHCansetOrders)) return;
    
    //6. HDemand即使waitModel不是actYes状态也处理反馈;
    HDemandModel *hDemand = (HDemandModel*)self.baseOrGroup;//h需求模型
    TOAlgModel *targetAlgModel = (TOAlgModel*)hDemand.baseOrGroup;   //hDemand的目标alg;
    TOFoModel *targetFoModel = (TOFoModel*)targetAlgModel.baseOrGroup;    //hDemand的目标alg所在的fo;
    
    //8. 旧有那些改状态status的代码,整理在此处 (参考31073-TODO7-4);
    //9. H反馈中段: 标记OuterBack,solutionFo继续;
    self.status = TOModelStatus_Finish;
    hDemand.status = TOModelStatus_Finish;
    targetAlgModel.status = TOModelStatus_OuterBack;
    targetFoModel.status = TOModelStatus_Runing;
    self.cansetCutIndex = self.cansetTargetIndex;//当前hTargetAlg提前反馈了,直接把cutIndex改成targetIndex;
    
    //2. 数据准备：找出basePFo和baseRDemand。
    AIMatchFoModel *basePFo = targetFoModel.basePFo;
    AIFoNodeBase *pFo = [SMGUtils searchNode:basePFo.matchFo];
    
    //10. H反馈末帧时: 做触发H"预想与实际"类比的准备;
    //11. 用realMaskFo & realDeltaTimes生成protoFo (参考30154-todo2);
    //12. H任务完成时,H当前正执行的S提前完成,并进行外类比 (参考27206c-H任务);
    //13. 数据准备 (当前sceneTo就是targetFoModel.cansetTo);
    NSArray *cansetToOrders = self.transferXvModel.cansetToOrders;
    AIFoNodeBase *iScene = [SMGUtils searchNode:self.iScene];
    
    //2024.09.14: hCanset类比启用新的canset类比算法 (参考33052-TODO2);
    HEResult *analogyResult = [AIAnalogy analogyCansetFoV3:newHCansetOrders oldCansetOrders:cansetToOrders oldCansetISceneIndexDic:self.transferXvModel.sceneToCansetToIndexDic];
    NSArray *absCansetOrders = analogyResult.data;
    NSDictionary *iAbsCansetISceneIndexDic = [analogyResult get:@"absISceneDic"];
    NSDictionary *absCansetOldCansetIndexDic = [analogyResult get:@"absOldDic"];
    [AITest test101:absCansetOrders newCansetOrders:newHCansetOrders oldCansetOrder:cansetToOrders];
    NSString *fltLog = FltLog4CreateHCanset(4);
    NSLog(@"%@%@%@%@%@%@Canset演化> AbsHCanset:%@ toScene:%@ 在%ld帧:%@",fltLog,FltLog4AbsHCanset(true, 3),FltLog4XueQuPi(3),FltLog4HDemandOfYouPiGuo(@"5"),FltLog4XueBanYun(3),FltLog4YonBanYun(4),Pits2FStr(Simples2Pits(absCansetOrders)),ShortDesc4Node(iScene),self.cansetActIndex,Pit2FStr(self.getCurFrame.content_p));
    ELog(@"此处断点停下时,测下hCanset的类比是否正常!!!!!!!!!!!!!!! (参考33052-待断点测试项)");
    
    //2024.11.03: 在挂载新的Canset时,实时推举 & 并防重(只有新挂载的canset,才有资格实时调用推举,并推举spDic都到父场景中) (参考33112);
    //2024.11.05: 当targetFoModel是R任务时,才推举,以后这里需要支持下,不断向base找到R为止,因为H可能有多层,而推举是必须找到并借助R来实现的 (参考n33p12);
    //推举是从I推举到F（而pFo就是I层，所以sceneFrom就是pFo）。
    //16. 算出absCanset的默认itemOutSPDic (参考33062-TODO4);
    AIFoNodeBase *fCanset = [SMGUtils searchNode:self.fCanset];
    NSArray *baseSceneContent_ps = Simples2Pits([self getBaseSceneToOrders]);
    //初始OutSPDic从fCanset对baseScene取（其实取的就是cansetTo的OutSPDic）。
    NSDictionary *initOutSPDic = [AINetUtils getInitOutSPDicForAbsCanset:fCanset baseSceneContent_ps:baseSceneContent_ps oldSolutionAbsCansetIndexDic:absCansetOldCansetIndexDic];
    [TCTransfer transferTuiJv_RH_V3:pFo iCansetOrders:absCansetOrders iCansetISceneIndexDic:iAbsCansetISceneIndexDic isH:true sceneFromCutIndex:basePFo.cutIndex initOutSPDic:initOutSPDic baseSceneContent_ps:baseSceneContent_ps];    
}

/**
 *  MARK:--------------------此方案是用于什么任务 (true=H false=R)--------------------
 */
-(BOOL) isH {
    //目前判断方式为: pFo的任务是R,targetFoM的任务是H;
    return !ISOK(self.basePFoOrTargetFoModel, AIMatchFoModel.class);
    //return self.cansetTargetIndex < self.cansetFo.count; //用目标帧位置来判断;
    //return ISOK(self.baseOrGroup, HDemandModel.class); //用baseIsRDemand来判断;
}

/**
 *  MARK:--------------------迁移源--------------------
 */
-(AIKVPointer*) fScene {
    return self.baseSceneModel.getFatherScene;
}

-(AIKVPointer*) iScene {
    return self.baseSceneModel.getIScene;
}

//MARK:===============================================================
//MARK:                     < OutSP反馈部分 >
//MARK:===============================================================

-(SPMemRecord *)spMemRecord {
    if (!_spMemRecord) _spMemRecord = [[SPMemRecord alloc] init];
    return _spMemRecord;
}

/**
 *  MARK:--------------------检查更新OutSPDic强度值--------------------
 *  @desc 起因: 因为测得SP计值一直重复执行,每一次负mv反馈,都计一次S,导致重复计数,或者计了S又计P,导致混乱,所以写这个方法,来解决这BUG;
 *  @desc 比单纯的更新强度值,多出以下几个功能:
 *      1. 避免重复 (保证最终真正执行的仅1次,比如多次跑S,只记一次);
 *      2. 避免冲突 (比如:先S后P,以最后一条P为准 => 先把S回滚了,再把P执行了);
 */
-(void) checkAndUpdateOutSPStrong_Reason:(NSInteger)difStrong type:(AnalogyType)type debugMode:(BOOL)debugMode caller:(NSString*)caller except4SP2F:(NSMutableArray*)except4SP2F {
    [self checkAndUpdateOutSPStrong:difStrong spIndex:self.cansetActIndex type:type debugMode:debugMode caller:caller except4SP2F:except4SP2F];
}
-(void) checkAndUpdateOutSPStrong_Percept:(NSInteger)difStrong type:(AnalogyType)type debugMode:(BOOL)debugMode caller:(NSString*)caller except4SP2F:(NSMutableArray*)except4SP2F {
    AIFoNodeBase *fCanset = [SMGUtils searchNode:self.fCanset];
    [self checkAndUpdateOutSPStrong:difStrong spIndex:fCanset.count type:type debugMode:debugMode caller:caller except4SP2F:except4SP2F];
}
-(void) checkAndUpdateOutSPStrong:(NSInteger)difStrong spIndex:(NSInteger)spIndex type:(AnalogyType)type debugMode:(BOOL)debugMode caller:(NSString*)caller except4SP2F:(NSMutableArray*)except4SP2F {
    //1. 数据检查: 未转实的不执行,它的cansetTo没构建呢 (33031b-协作 & 33062-TODO6);
    //2024.09.21: 去掉best过状态要求 (参考33065-TODO3);
    //if (self.cansetStatus == CS_None) return;
    
    //0. log
    //DemandModel *baseDemand = (DemandModel*)self.baseOrGroup;
    ReasonDemandModel *root = (ReasonDemandModel*)[TOUtils getRootDemandModelWithSubOutModel:self];
    NSInteger rootIndex = [theTC.outModelManager.getAllDemand indexOfObject:root];
    NSString *fromDSC = STRFORMAT(@"FROM<F%ld F%ld F%ld>",Demand2Pit((DemandModel*)self.baseOrGroup).pointerId,self.fScene.pointerId,self.fCanset.pointerId);
    caller = STRFORMAT(@"%@ by:%@ ROOT%ld(F%ld)",caller,fromDSC,rootIndex,Demand2Pit(root).pointerId);
    
    //1. 取得canstFrom的spStrong;
    AIFoNodeBase *fCanset = [SMGUtils searchNode:self.fCanset];
    AIFoNodeBase *iScene = [SMGUtils searchNode:self.iScene];
    NSArray *baseSceneToContent_ps = Simples2Pits([self getBaseSceneToOrders]);
    NSArray *cansetToContent_ps = Simples2Pits(self.transferXvModel.cansetToOrders);
    [self.spMemRecord update:spIndex type:type difStrong:difStrong backBlock:^(NSInteger mDifStrong, AnalogyType mType) {
        [AINetUtils updateOutSPStrong_4IF:fCanset iScene:iScene baseSceneToContent_ps:baseSceneToContent_ps cansetToContent_ps:cansetToContent_ps caller:STRFORMAT(@"%@(撤销S)",caller) spIndex:spIndex difStrong:mDifStrong type:mType debugMode:false except4SP2F:except4SP2F];
    } runBlock:^{
        [AINetUtils updateOutSPStrong_4IF:fCanset iScene:iScene baseSceneToContent_ps:baseSceneToContent_ps cansetToContent_ps:cansetToContent_ps caller:caller spIndex:spIndex difStrong:difStrong type:type debugMode:debugMode except4SP2F:except4SP2F];
    }];
}

/**
 *  MARK:--------------------取outSPDic (转实前取cansetFrom的,转实后取cansetTo的) (参考33062-正据4&TODO5)--------------------
 *  @version
 *      2024.09.21: 改回转实前就初始化outSPDic (参考33065-TODO2);
 *      2025.03.08: 改成从FCanset取baseSceneOutSPKey下的sp字典（参考33172-方案3）。
 */
-(NSDictionary*) getItemOutSPDic {
    AIFoNodeBase *fCanset = [SMGUtils searchNode:self.fCanset];
    NSArray *baseSceneOrders = [self getBaseSceneToOrders];
    NSString *key = [AINetUtils getOutSPKey:Simples2Pits(baseSceneOrders)];
    return [fCanset getItemOutSPDic:key];
}

//取self是直接最近作用于哪个base任务的（可能是H子任务，也可能是R任务）(参考33172-方案3）。
-(NSArray*) getBaseSceneToOrders {
    NSArray *baseSceneOrders = nil;
    if (ISOK(self.basePFoOrTargetFoModel, AIMatchFoModel.class)) {
        AIMatchFoModel *pFo = (AIMatchFoModel*)self.basePFoOrTargetFoModel;
        AIFoNodeBase *baseScene = [SMGUtils searchNode:pFo.matchFo];
        baseSceneOrders = baseScene.convert2Orders;
    } else {
        TOFoModel *baseScene = (TOFoModel*)self.basePFoOrTargetFoModel;
        baseSceneOrders = baseScene.transferXvModel.cansetToOrders;
    }
    return baseSceneOrders;
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.subModels = [aDecoder decodeObjectForKey:@"subModels"];
        self.initCansetCutIndex = [aDecoder decodeIntegerForKey:@"initCansetCutIndex"];
        self.cansetCutIndex = [aDecoder decodeIntegerForKey:@"cansetCutIndex"];
        self.cansetTargetIndex = [aDecoder decodeIntegerForKey:@"cansetTargetIndex"];
        self.subDemands = [aDecoder decodeObjectForKey:@"subDemands"];
        self.feedbackMv = [aDecoder decodeObjectForKey:@"feedbackMv"];
        self.transferXvModel = [aDecoder decodeObjectForKey:@"transferXvModel"];
        self.refrectionNo = [aDecoder decodeBoolForKey:@"refrectionNo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.subModels forKey:@"subModels"];
    [aCoder encodeInteger:self.initCansetCutIndex forKey:@"initCansetCutIndex"];
    [aCoder encodeInteger:self.cansetCutIndex forKey:@"cansetCutIndex"];
    [aCoder encodeInteger:self.cansetTargetIndex forKey:@"cansetTargetIndex"];
    [aCoder encodeObject:self.subDemands forKey:@"subDemands"];
    [aCoder encodeObject:self.feedbackMv forKey:@"feedbackMv"];
    [aCoder encodeObject:self.transferXvModel forKey:@"transferXvModel"];
    [aCoder encodeBool:self.refrectionNo forKey:@"refrectionNo"];
}

@end
