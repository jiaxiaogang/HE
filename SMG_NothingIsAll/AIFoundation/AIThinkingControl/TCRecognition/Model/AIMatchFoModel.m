//
//  AIMatchFoModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/1/23.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "AIMatchFoModel.h"

@interface AIMatchFoModel ()

/**
 *  MARK:--------------------当前反馈帧的相近度--------------------
 *  @desc 比对feedback输入的protoAlg和当前等待反馈的itemAlg之间相近度,并存到此值下;
 *  @callers
 *      1. 有反馈时,计算并赋值;
 *      2. 跳转下帧时,恢复默认值0;
 */
@property (assign, nonatomic) CGFloat feedbackNear;
@property (strong, nonatomic) SPMemRecord *spMemRecord;

@end

@implementation AIMatchFoModel

+(AIMatchFoModel*) newWithMatchFo:(AIKVPointer*)matchFo protoOrRegroupFo:(AIKVPointer*)protoOrRegroupFo sumNear:(CGFloat)sumNear nearCount:(NSInteger)nearCount indexDic:(NSDictionary*)indexDic cutIndex:(NSInteger)cutIndex sumRefStrong:(NSInteger)sumRefStrong baseFrameModel:(AIShortMatchModel*)baseFrameModel{
    AIFoNodeBase *protoOrRegroupFoNode = [SMGUtils searchNode:protoOrRegroupFo];
    AIMatchFoModel *model = [[AIMatchFoModel alloc] init];
    //model.baseFrameModel = baseFrameModel;
    model.matchFo = matchFo;
    [model.realMaskFo addObjectsFromArray:protoOrRegroupFoNode.content_ps];
    //NSLog(@"test3435配套日志：此日志用于查RealCansetToIndexDic重复的BUG，如果test34和35再出现问题，那么打开此日志查下原因 %p RealMaskFo更新1 COUNT:%ld",model.realMaskFo,model.realMaskFo.count);
    [model.realDeltaTimes addObjectsFromArray:protoOrRegroupFoNode.deltaTimes];
    model.lastFrameTime = [[NSDate date] timeIntervalSince1970];
    model.sumNear = sumNear;
    model.nearCount = nearCount;
    model.indexDic2 = [[NSMutableDictionary alloc] initWithDictionary:indexDic];
    model.initCutIndex = cutIndex;
    model.cutIndex = cutIndex;
    model.sumRefStrong = sumRefStrong;
    model.scoreCache = defaultScore; //评分缓存默认值;
    return model;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================
-(NSMutableArray *)realMaskFo {
    if (!_realMaskFo) _realMaskFo = [[NSMutableArray alloc] init];
    return _realMaskFo;
}

-(NSMutableArray *)realDeltaTimes {
    if (!_realDeltaTimes) _realDeltaTimes = [[NSMutableArray alloc] init];
    return _realDeltaTimes;
}

-(NSMutableDictionary *)status {
    if (!_status) _status = [[NSMutableDictionary alloc] init];
    return _status;
}

-(TIModelStatus) getStatusForCutIndex:(NSInteger)cutIndex {
    return NUMTOOK([self.status objectForKey:@(cutIndex)]).integerValue;
}

-(void) setStatus:(TIModelStatus)status forCutIndex:(NSInteger)cutIndex {
    [self.status setObject:@(status) forKey:@(cutIndex)];
}

-(SPMemRecord *)spMemRecord {
    if (!_spMemRecord) _spMemRecord = [[SPMemRecord alloc] init];
    return _spMemRecord;
}

/**
 *  MARK:--------------------在发生完全后,构建完全protoFo时使用获取orders--------------------
 *  @version
 *      xxxx.xx.xx: v1版,从realMaskFo中取protoAlg组成;
 *      2023.03.23: v2版,优先从matchFo中取,缺帧的再取protoAlg (参考29025-21&22);
 */
-(NSArray*) convertOrders4NewCansetV1 {
    [AITest test15:self];
    NSMutableArray *order = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.realMaskFo.count; i++) {
        AIKVPointer *itemA_p = ARR_INDEX(self.realMaskFo, i);
        NSTimeInterval itemDeltaTime = NUMTOOK(ARR_INDEX(self.realDeltaTimes, i)).doubleValue;
        [order addObject:[AIShortMatchModel_Simple newWithAlg_p:itemA_p inputTime:itemDeltaTime isTimestamp:false]];
    }
    return order;
}
-(NSArray*) convertOrders4NewCansetV2 {
    //1. 数据准备;
    [AITest test15:self];
    NSMutableArray *order = [[NSMutableArray alloc] init];
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    
    //2. 依次收集protoAlg;
    for (NSInteger i = 0; i < self.realMaskFo.count; i++) {
        NSNumber *matchKey = ARR_INDEX([self.indexDic2 allKeysForObject:@(i)], 0);
        AIKVPointer *itemA_p = nil;
        if (matchKey) {
            //3. 如果找着matchIndex则优先从matchFo取;
            itemA_p = ARR_INDEX(matchFo.content_ps, matchKey.integerValue);
        } else {
            //4. 其次则从realMaskFo中取protoAlg;
            itemA_p = ARR_INDEX(self.realMaskFo, i);
        }
        
        //5. 算出当前帧deltaTime;
        NSTimeInterval itemDeltaTime = NUMTOOK(ARR_INDEX(self.realDeltaTimes, i)).doubleValue;
        [order addObject:[AIShortMatchModel_Simple newWithAlg_p:itemA_p inputTime:itemDeltaTime isTimestamp:false]];
    }
    return order;
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================

/**
 *  MARK:--------------------有反馈且匹配当前帧--------------------
 *  @param fbProtoAlg : 瞬时记忆新帧,反馈feedback来的protoAlg;
 *  @version
 *      2022.09.15: 更新indexDic & realMaskFo (参考27097);
 *      2022.09.18: 将反馈处理和推进下一帧,集成到同一个方法执行 (参考27095-9 & 27098-todo3)
 *      2022.11.03: alg复用相似度 (参考27175-1);
 */
-(void) feedbackPushFrame:(AIKVPointer*)fbProtoAlg {
    //----------------当前帧处理----------------
    //1. 数据准备;
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    AIKVPointer *waitAlg_p = ARR_INDEX(matchFo.content_ps, self.cutIndex + 1);
    AIAlgNodeBase *waitAlg = [SMGUtils searchNode:waitAlg_p];
    
    //2. 更新status & near & realMaskFo;
    [self setStatus:TIModelStatus_OutBackReason forCutIndex:self.cutIndex];
    self.feedbackNear = [waitAlg getConMatchValue:fbProtoAlg];
    [self.realMaskFo addObject:fbProtoAlg];
    //NSLog(@"test3435配套日志：此日志用于查RealCansetToIndexDic重复的BUG，如果test34和35再出现问题，那么打开此日志查下原因 %p RealMaskFo更新2 COUNT:%ld",self.realMaskFo,self.realMaskFo.count);
    
    //2. 更新realDeltaTimes和lastFrameTime;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [self.realDeltaTimes addObject:@(now - self.lastFrameTime)];
    self.lastFrameTime = now;
    
    //3. 取到反馈fbProtoAlg的index(应该就是realMaskFo.count)
    NSInteger maskIndex = self.realMaskFo.count - 1;
    
    //4. 取当前waitAlg的index (应该就是cutIndex + 1)
    NSInteger matchIndex = self.cutIndex + 1;
    
    //5. 更新indexDic (V: 末位maskIndex, K: matchIndex);
    [self.indexDic2 setObject:@(maskIndex) forKey:@(matchIndex)];
    
    //----------------推进至下帧----------------
    //1. 推进到下一帧_更新: cutIndex & sumNear(匹配度分子) & nearCount(匹配度分母);
    self.cutIndex ++;
    self.sumNear *= self.feedbackNear;
    self.nearCount ++;
    
    //2. 推进到下一步_重置: status & 失效状态 & 反馈相近度 & scoreCache(触发重新计算mv评分);
    [self setStatus:TIModelStatus_LastWait forCutIndex:self.cutIndex];
    self.isExpired = false;
    self.feedbackNear = 0;
    self.scoreCache = defaultScore;
    
    //3. 触发器 (非末帧继续R反省,末帧则P反省);
    [TCForecast forecast_Single:self];
}

/**
 *  MARK:--------------------有反馈但不匹配当前帧--------------------
 *  @desc 不匹配的新帧也要记录 (参考28063-方案);
 *  @template 比如: matchFo是被撞,protoAlg无关帧可能是上飞躲避,它与matchFo确实无关,但却是事实经历中的一帧;
 *  @作用: pushFrameFinish中自然未发生时,会生成新canset时需要用;
 *  @version
 *      2023.02.08: 初版,用于修复解决方案没后段的问题 (事实经历缺帧) (参考28063);
 *  @callers : 在feedbackTIR中,只要没调用到pushFrame,就调用此方法记录protoA;
 */
-(void) feedbackOtherFrame:(AIKVPointer*)otherProtoAlg {
    //----------------仅记录当前帧----------------
    //1. 更新realMaskFo;
    [self.realMaskFo addObject:otherProtoAlg];
    //NSLog(@"test3435配套日志：此日志用于查RealCansetToIndexDic重复的BUG，如果test34和35再出现问题，那么打开此日志查下原因 %p RealMaskFo更新3 COUNT:%ld",self.realMaskFo,self.realMaskFo.count);
    
    //2. 更新realDeltaTimes和lastFrameTime;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    [self.realDeltaTimes addObject:@(now - self.lastFrameTime)];
    self.lastFrameTime = now;
}

/**
 *  MARK:--------------------匹配度计算--------------------
 *  @version
 *      2023.01.18: 相似度改为相乘 (参考28035-todo2);
 */
-(CGFloat) matchFoValue {
    return self.sumNear;
    //return self.nearCount > 0 ? self.sumNear / self.nearCount : 1;
}

/**
 *  MARK:--------------------推进帧结束(完全帧)时总结 (参考27201-5)--------------------
 *  @desc 触发及功能说明: 当解决方案有效解决了需求时,此处构建具象canset或进行canset再类比抽象;
 *  @desc 另 (方案无效时): 当阻止失败时,不应触发canset再类比 (本方法不做解决失败的处理,仅记录下逻辑说明在此);
 *              a. 在feedbackTIP中反馈负mv后: pFo.status=TIModelStatus_OutBackSameDelta;
 *              b. 在feedbackTOP中反馈负mv后: cansetS.status=TOModelStatus_OuterBack;
 *  @version
 *      2022.11.28: 自然未发生则生成protoCanset,行为有作用则触发再类比生成absCanset (参考27206c-R任务);
 *      2022.12.09: BUG_当解决方案实际执行0条时,不触发canset再类比 (如果触发,会导致抽象为nil,闪退);
 *      2022.12.09: 无论是否进行抽象,都生成具象canset (参考27228);
 *      2023.02.14: BUG_canset再类比几乎不触发的问题 (参考28071);
 *      2023.02.15: BUG_修复被撞到还"生成canset及外类比"的问题 (参考28077);
 *      2023.03.17: 支持新canset的场景内识别 (参考28184-方案1);
 *      2023.03.20: 将新Canset挂在所有pFos下 (参考2818a-TODO);
 *      2023.03.21: 回滚代码,由挂在所有pFos下改回仅挂在selfPFo下 (参考29012-回测失败);
 *      2023.03.23: 生成新Canset时,优先从场景matchFo中取元素 (参考29025-21&22);
 *      2023.09.01: 打开newCanset时调用canset识别类比,并eff+1 (参考30124-todo1&todo2);
 *      2023.11.06: 预想与实际类比的protoFo采用newRCanset (参考30154-todo1);
 *      2023.12.09: 预想与实际类比构建absCanset以场景内防重 (参考3101b-todo6);
 *      2024.07.29: 不再检查OutBackNone状态,调用者在调用此方法时,自行确定好当前发现了新解,不必再此处判断状态;
 */
-(void) pushFrameFinish:(NSString*)log except4SP2F:(NSMutableArray*)except4SP2F {
    //1. =================自然未发生(新方案): 无actYes的S时,归功于自然未发生,则新增protoCanset (参考27206c-R任务)=================
    //a. 数据准备;
    AIFoNodeBase *pFo = [SMGUtils searchNode:self.matchFo];//此处matchFo和pFo都是sceneTo
    
    //b. 用realMaskFo & realDeltaTimes生成protoFo (参考27201-1 & 5);
    NSArray *newRCansetOrders = [self convertOrders4NewCansetV2];
    NSLog(@"Canset演化> NewRCanset:%@ toScene:%@ (原因:%@)",Pits2FStr(Simples2Pits(newRCansetOrders)),ShortDesc4Node(pFo),log);
    
    //2024.11.03: 在挂载新的Canset时,实时推举 & 并防重(只有新挂载的canset,才有资格实时调用推举,并推举spDic都到父场景中) (参考33112);
    NSDictionary *iNewRCansetISceneIndexDic = [self.indexDic2 copy];
    NSMutableDictionary *initOutSPDic = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < newRCansetOrders.count; i++) [initOutSPDic setObject:[AISPStrong newWithS:0 P:1] forKey:@(i)];
    [TCTransfer transferTuiJv_RH_V3:pFo iCansetOrders:newRCansetOrders iCansetISceneIndexDic:iNewRCansetISceneIndexDic isH:false sceneFromCutIndex:pFo.count-1 initOutSPDic:initOutSPDic baseSceneContent_ps:pFo.content_ps];
    
    //2. =================解决方案执行有效(再类比): 有actYes的时,归功于解决方案,执行canset再类比 (参考27206c-R任务)=================
    //TODO待查BUG20231028: 应该是在feedbackTOR中和hCanset一样,已经被改成了OuterBack状态,导致这里执行不到 (参考3014a-问题3);
    NSArray *actionFoModels = [self.baseRDemand.actionFoModels copy];
    for (TOFoModel *solutionModel in actionFoModels) {
        //b. 非当前pFo下的解决方案,不做canset再类比;
        if (![solutionModel.basePFoOrTargetFoModel isEqual:self]) continue;
        
        //1. 判断处在actYes状态的解决方案 && 解决方案是属性当前pFo决策取得的 (参考27206c-综上&多S问题);
        //a. 非actYes和runing状态的不做canset再类比;
        //2023.11.03: 即使失败也可以触发"预想与实际"的类比抽象;
        //2024.04.17: 非激活状态的也不构建AbsRCanset (它都没激活,我们没必要喂饭吃 (避免强行经验带来场景不符合等问题),毕竟有迁移后续也不怕缺canset用);
        //2024.04.21: 改成没激活过(没转实)的,不进行类比 (为了触发更多的类比);
        if (solutionModel.cansetStatus == CS_None) continue;
        
        //c. 数据准备;
        NSArray *solutionOrders = solutionModel.transferXvModel.cansetToOrders;
        AIFoNodeBase *pFo = [SMGUtils searchNode:solutionModel.basePFo.matchFo];//此处pFo和matchFo都是sceneTo
        
        //2024.09.13: rCanset类比启用新的canset类比算法 (参考33052-TODO2);
        HEResult *analogyResult = [AIAnalogy analogyCansetFoV3:newRCansetOrders oldCansetOrders:solutionOrders oldCansetISceneIndexDic:solutionModel.transferXvModel.sceneToCansetToIndexDic];
        NSArray *absCansetOrders = analogyResult.data;
        NSDictionary *iAbsCansetISceneIndexDic = [analogyResult get:@"absISceneDic"];
        NSDictionary *absCansetOldCansetIndexDic = [analogyResult get:@"absOldDic"];
        [AITest test101:absCansetOrders newCansetOrders:newRCansetOrders oldCansetOrder:solutionOrders];
        NSLog(@"%@%@Canset演化> AbsRCanset:%@ fromNewRCanset:[%@] toScene:%@",FltLog4CreateRCanset(4),FltLog4YonBanYun(4),Pits2FStr(Simples2Pits(absCansetOrders)),Pits2FStr(Simples2Pits(newRCansetOrders)),ShortDesc4Node(pFo));
        
        //2024.11.03: 在挂载新的Canset时,实时推举 & 并防重(只有新挂载的canset,才有资格实时调用推举,并推举spDic都到父场景中) (参考33112);
        //2024.11.05: 当targetFoModel是R任务时,才推举,以后这里需要支持下,不断向base找到R为止,因为H可能有多层,而推举是必须找到并借助R来实现的 (参考n33p12);
        //推举是从I推举到F（而pFo就是I层，所以sceneFrom就是pFo）。
        //16. 算出absCanset的默认itemOutSPDic (参考33062-TODO4);
        AIFoNodeBase *basePFo = [SMGUtils searchNode:solutionModel.basePFo.matchFo];
        AIFoNodeBase *fCanset = [SMGUtils searchNode:solutionModel.fCanset];
        NSArray *baseSceneContent_ps = Simples2Pits([solutionModel getBaseSceneToOrders]);
        //初始OutSPDic从fCanset对baseScene取（其实取的就是cansetTo的OutSPDic）。
        NSDictionary *initOutSPDic = [AINetUtils getInitOutSPDicForAbsCanset:fCanset baseSceneContent_ps:baseSceneContent_ps oldSolutionAbsCansetIndexDic:absCansetOldCansetIndexDic];
        [TCTransfer transferTuiJv_RH_V3:basePFo iCansetOrders:absCansetOrders iCansetISceneIndexDic:iAbsCansetISceneIndexDic isH:true sceneFromCutIndex:basePFo.count-1 initOutSPDic:initOutSPDic baseSceneContent_ps:baseSceneContent_ps];
    }
}

/**
 *  MARK:--------------------获取强度--------------------
 *  @desc 获取概念引用强度,求出平均值 (参考2722d-todo4);
 */
-(CGFloat) strongValue {
    return self.nearCount > 0 ? self.sumRefStrong / self.nearCount : 1;
}

/**
 *  MARK:--------------------inSP更新器--------------------
 *  @desc 分裂成理性反省 和 感性反省 (参考n24p02);
 *  @desc 四个feedback分别对应四个rethink反省 (参考25031-12);
 *  @version
 *      2021.12.25: TCRethink中计统计顺逆数;
 *      2023.03.04: 修复反省未保留以往帧cutIndex (参考28144-另外);
 *      2024.08.31: 废弃perceptOutRethink()和reasonOutRethink(),因为这个早被OutSPDic替代了,只是现在才删这些无用的代码);
 */

-(void) checkAndUpdateReasonInRethink:(NSInteger)cutIndex type:(AnalogyType)type except4SP2F:(NSMutableArray*)except4SP2F {
    [self checkAndUpdateGeneralInRethink:type spIndex:cutIndex + 1 except4SP2F:except4SP2F];
}

-(void) checkAndUpdatePerceptInRethink:(AnalogyType)type except4SP2F:(NSMutableArray*)except4SP2F {
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    [self checkAndUpdateGeneralInRethink:type spIndex:matchFo.count except4SP2F:except4SP2F];
}

-(void) checkAndUpdateGeneralInRethink:(AnalogyType)type spIndex:(NSInteger)spIndex except4SP2F:(NSMutableArray*)except4SP2F {
    //1. 数据准备;
    NSInteger difStrong = 1;//默认发生后,都计1;
    AIFoNodeBase *matchFo = [SMGUtils searchNode:self.matchFo];
    NSString *prStr = spIndex == matchFo.count ? @"P" : @"R";
    
    //2. 判断回滚 和 SP计数;
    [self.spMemRecord update:spIndex type:type difStrong:difStrong backBlock:^(NSInteger mDifStrong, AnalogyType mType) {
        [AINetUtils updateInSPStrong_4IF:matchFo conSPIndex:spIndex difStrong:mDifStrong type:mType except4SP2F:except4SP2F];
    } runBlock:^{
        NSString *spFrom = STRFORMAT(@"%@",[matchFo.spDic objectForKey:@(spIndex)]);
        [AINetUtils updateInSPStrong_4IF:matchFo conSPIndex:spIndex difStrong:difStrong type:type except4SP2F:except4SP2F];
        if (Log4Rethink) NSLog(@"I%@反省 => spIndex:%ld -> (%@) %@->%@ %@",prStr,spIndex,ATType2Str(type),spFrom,[matchFo.spDic objectForKey:@(spIndex)],Fo2FStr(matchFo));
    }];
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.matchFo = [aDecoder decodeObjectForKey:@"matchFo"];
        self.realMaskFo = [aDecoder decodeObjectForKey:@"realMaskFo"];
        self.realDeltaTimes = [aDecoder decodeObjectForKey:@"realDeltaTimes"];
        self.lastFrameTime = [aDecoder decodeDoubleForKey:@"lastFrameTime"];
        self.sumNear = [aDecoder decodeFloatForKey:@"sumNear"];
        self.nearCount = [aDecoder decodeIntegerForKey:@"nearCount"];
        self.status = [aDecoder decodeObjectForKey:@"status"];
        self.indexDic2 = [aDecoder decodeObjectForKey:@"indexDic2"];
        self.initCutIndex = [aDecoder decodeIntegerForKey:@"initCutIndex"];
        self.cutIndex = [aDecoder decodeIntegerForKey:@"cutIndex"];
        self.sumRefStrong = [aDecoder decodeIntegerForKey:@"sumRefStrong"];
        self.scoreCache = [aDecoder decodeFloatForKey:@"scoreCache"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.matchFo forKey:@"matchFo"];
    [aCoder encodeObject:self.realMaskFo forKey:@"realMaskFo"];
    [aCoder encodeObject:self.realDeltaTimes forKey:@"realDeltaTimes"];
    [aCoder encodeDouble:self.lastFrameTime forKey:@"lastFrameTime"];
    [aCoder encodeFloat:self.sumNear forKey:@"sumNear"];
    [aCoder encodeInteger:self.nearCount forKey:@"nearCount"];
    [aCoder encodeObject:self.status forKey:@"status"];
    [aCoder encodeObject:self.indexDic2 forKey:@"indexDic2"];
    [aCoder encodeInteger:self.initCutIndex forKey:@"initCutIndex"];
    [aCoder encodeInteger:self.cutIndex forKey:@"cutIndex"];
    [aCoder encodeInteger:self.sumRefStrong forKey:@"sumRefStrong"];
    [aCoder encodeFloat:self.scoreCache forKey:@"scoreCache"];
}

@end
