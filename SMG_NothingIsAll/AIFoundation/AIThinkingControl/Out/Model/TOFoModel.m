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
@property (strong, nonatomic) NSMutableArray *subDemands;

@end

@implementation TOFoModel

+(TOFoModel*) newWithCansetFo:(AIKVPointer*)cansetFo sceneFo:(AIKVPointer*)sceneFo base:(TOModelBase<ITryActionFoDelegate>*)base
           protoFrontIndexDic:(NSDictionary *)protoFrontIndexDic matchFrontIndexDic:(NSDictionary *)matchFrontIndexDic
              frontMatchValue:(CGFloat)frontMatchValue frontStrongValue:(CGFloat)frontStrongValue
               midEffectScore:(CGFloat)midEffectScore midStableScore:(CGFloat)midStableScore
                 backIndexDic:(NSDictionary*)backIndexDic backMatchValue:(CGFloat)backMatchValue backStrongValue:(CGFloat)backStrongValue
                     cutIndex:(NSInteger)cutIndex sceneCutIndex:(NSInteger)sceneCutIndex
                  targetIndex:(NSInteger)targetIndex sceneTargetIndex:(NSInteger)sceneTargetIndex
       basePFoOrTargetFoModel:(id)basePFoOrTargetFoModel baseSceneModel:(AISceneModel*)baseSceneModel {
    TOFoModel *model = [[TOFoModel alloc] init];
    
    //1. 原CansetModel相关赋值;
    model.cansetFo = cansetFo;
    model.sceneFo = sceneFo;
    model.basePFoOrTargetFoModel = basePFoOrTargetFoModel;
    model.baseSceneModel = baseSceneModel;
    model.protoFrontIndexDic = protoFrontIndexDic;
    model.matchFrontIndexDic = matchFrontIndexDic;
    model.frontMatchValue = frontMatchValue;
    model.frontStrongValue = frontStrongValue;
    model.midEffectScore = midEffectScore;
    model.midStableScore = midStableScore;
    model.backMatchValue = backMatchValue;
    model.backStrongValue = backStrongValue;
    model.cutIndex = cutIndex;
    model.targetIndex = targetIndex;
    model.sceneTargetIndex = sceneTargetIndex;
    
    //2. TOFoModel相关赋值;
    model.content_p = cansetFo;
    model.status = TOModelStatus_Runing;
    if (base) [base.actionFoModels addObject:model];
    model.baseOrGroup = base;
    return model;
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

/**
 *  MARK:--------------------将每帧反馈转成orders,以构建protoFo--------------------
 *  @param fromRegroup : 从TCRegroup调用时未发生部分也取, 而用于canset抽象时仅取已发生部分;
 *  @version
 *      2022.11.25: 转regroupFo时收集默认content_p内容(代码不变),canset再类比时仅获取feedback反馈的alg (参考27207-1);
 *      2023.02.12: 返回改为: matchFo的前段+执行部分反馈帧 (参考28068-方案1);
 */
-(NSArray*) getOrderUseMatchAndFeedbackAlg:(BOOL)fromRegroup {
    //1. 数据准备 (收集除末位外的content为order);
    AIFoNodeBase *fo = [SMGUtils searchNode:self.content_p];
    NSMutableArray *order = [[NSMutableArray alloc] init];
    NSArray *feedbackIndexArr = [self getIndexArrIfHavFeedback];
    NSInteger max = fromRegroup ? fo.count : self.cutIndex;
    
    //2. 将fo逐帧收集真实发生的alg;
    for (NSInteger i = 0; i < max; i++) {
        //3. 找到当前帧alg_p;
        AIKVPointer *matchAlg_p = ARR_INDEX(fo.content_ps, i);
        
        //4. 如果有反馈feedbackAlg,则优先取反馈;
        AIKVPointer *findAlg_p = matchAlg_p;
        if ([feedbackIndexArr containsObject:@(i)]) {
            findAlg_p = [self getFeedbackAlgWithSolutionIndex:i];
        }
        
        //5. 生成时序元素;
        if (findAlg_p) {
            NSTimeInterval inputTime = [NUMTOOK(ARR_INDEX(fo.deltaTimes, i)) doubleValue];
            [order addObject:[AIShortMatchModel_Simple newWithAlg_p:findAlg_p inputTime:inputTime isTimestamp:false]];
        }
    }
    return order;
}

/**
 *  MARK:--------------------算出新的indexDic--------------------
 *  @desc 用旧indexDic和feedbackAlg计算出新的indexDic (参考27206d-方案2);
 */
-(NSDictionary*) convertOldIndexDic2NewIndexDic:(AIKVPointer*)targetOrPFo_p {
    //1. 数据准备;
    AIFoNodeBase *targetOrPFo = [SMGUtils searchNode:targetOrPFo_p];
    AIKVPointer *solutionFo = self.content_p;
    
    //2. 将fo逐帧收集有反馈的conIndex (参考27207-7);
    NSArray *feedbackIndexArr = [self getIndexArrIfHavFeedback];
    
    //3. 取出solutionFo旧有的indexDic (参考27207-8);
    NSDictionary *oldIndexDic = [targetOrPFo getConIndexDic:solutionFo];
    
    //4. 筛选出有反馈的absIndex数组 (参考27207-9);
    NSArray *feedbackAbsIndexArr = [SMGUtils filterArr:oldIndexDic.allKeys checkValid:^BOOL(NSNumber *absIndexKey) {
        NSNumber *conIndexValue = NUMTOOK([oldIndexDic objectForKey:absIndexKey]);
        return [feedbackIndexArr containsObject:conIndexValue];
    }];
    
    //5. 转成newIndexDic (参考27207-10);
    NSMutableDictionary *newIndexDic = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < feedbackAbsIndexArr.count; i++) {
        NSNumber *absIndex = ARR_INDEX(feedbackAbsIndexArr, i);
        [newIndexDic setObject:@(i) forKey:absIndex];
    }
    return newIndexDic;
}

/**
 *  MARK:--------------------算出新的spDic--------------------
 *  @desc 用旧spDic和feedbackAlg计算出新的spDic (参考27211-todo1);
 *  @version
 *      2023.04.01: 修复算出的S可能为负的BUG,改为直接从conSolution继承对应帧的SP值 (参考27214);
 *  @result notnull (建议返回后,检查一下spDic和absCansetFo的长度是否一致,不一致时来查BUG);
 */
-(NSDictionary*) convertOldSPDic2NewSPDic {
    //1. 数据准备 (收集除末位外的content为order) (参考27212-步骤1);
    AIFoNodeBase *solutionFo = [SMGUtils searchNode:self.content_p];
    NSArray *feedbackIndexArr = [self getIndexArrIfHavFeedback];
    NSMutableDictionary *newSPDic = [[NSMutableDictionary alloc] init];
    
    //2. sulutionIndex都是有反馈的帧,
    for (NSInteger i = 0; i < feedbackIndexArr.count; i++) {
        //3. 数据准备: 有反馈的帧,在solution对应的index (参考27212-步骤1);
        NSNumber *solutionIndex = ARR_INDEX(feedbackIndexArr, i);
        
        //4. 取得具象solutionFo的spStrong (参考27213-2&3);
        AISPStrong *conSPStrong = [solutionFo.spDic objectForKey:@(solutionIndex.integerValue)];
        
        //5. 直接继承solutionFo对应帧的SP值 (参考27214-方案);
        AISPStrong *absSPStrong = conSPStrong ? conSPStrong : [[AISPStrong alloc] init];
        [AITest test19:absSPStrong];
        
        //6. 新的spDic收集一帧: 抽象canset的帧=i (因为比如有3帧有反馈,那么这三帧就是0,1,2) (参考27207-10);
        NSInteger absCansetIndex = i;
        [newSPDic setObject:absSPStrong forKey:@(absCansetIndex)];
    }
    return newSPDic;
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
    AIFoNodeBase *solutionFo = [SMGUtils searchNode:self.content_p];
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //2. 将fo逐帧收集有反馈的conIndex (参考27207-7);
    for (NSInteger i = 0; i < solutionFo.count; i++) {
        AIKVPointer *solutionAlg_p = ARR_INDEX(solutionFo.content_ps, i);
        for (TOAlgModel *item in self.subModels) {
            if (item.status == TOModelStatus_OuterBack && [item.content_p isEqual:solutionAlg_p] && item.feedbackAlg) {
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
    AIFoNodeBase *solutionFo = [SMGUtils searchNode:self.content_p];
    AIKVPointer *solutionAlg_p = ARR_INDEX(solutionFo.content_ps, solutionIndex);
    
    //2. 找出反馈返回;
    for (TOAlgModel *item in self.subModels) {
        if (item.status == TOModelStatus_OuterBack && [item.content_p isEqual:solutionAlg_p] && item.feedbackAlg) {
            return item.feedbackAlg;
        }
    }
    return nil;
}

//MARK:===============================================================
//MARK:                     < for 三级场景 >
//MARK:===============================================================

/**
 *  MARK:--------------------有iCanset直接返回进行行为化等 (参考29069-todo9 & todo10.1b)--------------------
 */
-(AIKVPointer *)content_p {
    if (_i) return _i.canset;
    return super.content_p;
}

/**
 *  MARK:--------------------返回需用于反省或有效统计的cansets (参考29069-todo11 && todo11.2)--------------------
 *  @result notnull
 */
-(NSArray*) getRethinkEffectCansets {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //1. father和i两级canset有值时,收集 (参考29069-todo11.2);
    if (self.father) [result addObject:self.father];
    if (self.i) [result addObject:self.i];
    
    //2. 三级canset都无值时,默认返回content_p;
    if (!ARRISOK(result)) [result addObject:[AITransferModel newWithScene:[self getContentScene] canset:self.content_p]];
    return result;
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

-(AIKVPointer*) getContentScene {
    //1. R任务时,返回content所在的scene;
    if (ISOK(self.baseOrGroup, ReasonDemandModel.class)) {
        AIMatchFoModel *pFo = (AIMatchFoModel*)self.basePFoOrTargetFoModel;
        return pFo.matchFo;
    }
    
    //2. H任务时,返回content所在的scene;
    if (ISOK(self.baseOrGroup, HDemandModel.class)) {
        HDemandModel *hDemand = (HDemandModel*)self.baseOrGroup;
        TOFoModel *targetFo = (TOFoModel*)hDemand.baseOrGroup.baseOrGroup;
        return targetFo.content_p;
    }
    return nil;
}

//MARK:===============================================================
//MARK:                     < CansetModel >
//MARK:===============================================================
//在TCTransfer中暂时不用这个,现在直接取base.base...在取用;
//-(AIKVPointer*) getIScene {
//    if (self.baseSceneModel.type == SceneTypeI) {
//        return self.sceneFo;
//    } else if (self.baseSceneModel.type == SceneTypeFather) {
//        return self.baseSceneModel.base.scene;
//    } else if (self.baseSceneModel.type == SceneTypeBrother) {
//        return self.baseSceneModel.base.base.scene;
//    }
//    return nil;
//}
//
//-(AIKVPointer*) getFatherScene {
//    if (self.baseSceneModel.type == SceneTypeFather) {
//        return self.baseSceneModel.scene;
//    } else if (self.baseSceneModel.type == SceneTypeBrother) {
//        return self.baseSceneModel.base.scene;
//    }
//    return nil;
//}
//
//-(AIKVPointer*) getBrotherScene {
//    if (self.baseSceneModel.type == SceneTypeBrother) {
//        return self.baseSceneModel.scene;
//    }
//    return nil;
//}

/**
 *  MARK:--------------------下帧初始化 (可接受反馈) (参考31073-TODO2g)--------------------
 *  @desc 上帧推进完成时调用: 1.更新cutIndex++ 2.挂载下帧TOAlgModel
 *  @version
 *      2024.01.25: 初版: 此方法逻辑与TCAction一致,只是为了允许被反馈和记录feedbackAlg,所以把这些代码前置了 (参考31073-TODO2g);
 */
-(TOAlgModel*) pushNextFrame {
    //1. 数据准备;
    AIFoNodeBase *cansetFo = [SMGUtils searchNode:self.content_p];
    
    //2. 更新cutIndex;
    self.cutIndex ++;
    BOOL isH = ISOK(self.baseOrGroup, HDemandModel.class);
    NSInteger endActionIndex = isH ? self.targetIndex - 1 : self.targetIndex - 2;//只执行
    
    //3. 挂载TOAlgModel;
    if (self.cutIndex < self.targetIndex - 1) {
        //6. 转下帧: 理性帧则生成TOAlgModel;
        AIKVPointer *nextCansetA_p = ARR_INDEX(cansetFo.content_ps, self.cutIndex);
        return [TOAlgModel newWithAlg_p:nextCansetA_p group:self];
    }else{
        if (ISOK(self.baseOrGroup, ReasonDemandModel.class)) {
            return nil;
        }else if(ISOK(self.baseOrGroup, HDemandModel.class)){
            //9. H目标帧只需要等 (转hActYes) (参考25031-9);
            AIKVPointer *hTarget_p = ARR_INDEX(cansetFo.content_ps, self.cutIndex);
            return [TOAlgModel newWithAlg_p:hTarget_p group:self];
        }
    }
    return nil;
}

/**
 *  MARK:--------------------feedbackTOR有反馈,看是否对这个CansetModel有效 (参考31073-TODO2)--------------------
 */
-(void) check4FeedbackTOR:(NSArray*)feedbackMatchAlg_ps {
    //1. 未达到targetIndex才接受反馈;
    if (self.cutIndex >= self.targetIndex) return;
    feedbackMatchAlg_ps = ARRTOOK(feedbackMatchAlg_ps);
    
    //2. 判断反馈mIsC是否有效;
    AIFoNodeBase *cansetFo = [SMGUtils searchNode:self.cansetFo];
    AIKVPointer *cansetWaitAlg_p = ARR_INDEX(cansetFo.content_ps, self.cutIndex + 1);
    BOOL mIsC = [feedbackMatchAlg_ps containsObject:cansetWaitAlg_p];
    if (!mIsC) return;
    
    //TODOTOMORROW20240124:
    //1. 有效时,推进cutIndex+1等;
    //2. 为了方便记录feedbackAlg,应该需要提前生成TOAlgModel;
    //3. 完后把整个feedbackTOR迭代一下,因为这些改动挺大的,看下应该可以重构一下feedbackTOR,使之代码更简单些;
    
    
}

/**
 *  MARK:--------------------NSCoding--------------------
 */
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.subModels = [aDecoder decodeObjectForKey:@"subModels"];
        self.cutIndex = [aDecoder decodeIntegerForKey:@"cutIndex"];
        self.targetIndex = [aDecoder decodeIntegerForKey:@"targetIndex"];
        self.subDemands = [aDecoder decodeObjectForKey:@"subDemands"];
        self.feedbackMv = [aDecoder decodeObjectForKey:@"feedbackMv"];
        self.brother = [aDecoder decodeObjectForKey:@"brother"];
        self.father = [aDecoder decodeObjectForKey:@"father"];
        self.i = [aDecoder decodeObjectForKey:@"i"];
        self.refrectionNo = [aDecoder decodeBoolForKey:@"refrectionNo"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.subModels forKey:@"subModels"];
    [aCoder encodeInteger:self.cutIndex forKey:@"cutIndex"];
    [aCoder encodeInteger:self.targetIndex forKey:@"targetIndex"];
    [aCoder encodeObject:self.subDemands forKey:@"subDemands"];
    [aCoder encodeObject:self.feedbackMv forKey:@"feedbackMv"];
    [aCoder encodeObject:self.brother forKey:@"brother"];
    [aCoder encodeObject:self.father forKey:@"father"];
    [aCoder encodeObject:self.i forKey:@"i"];
    [aCoder encodeBool:self.refrectionNo forKey:@"refrectionNo"];
}

@end
