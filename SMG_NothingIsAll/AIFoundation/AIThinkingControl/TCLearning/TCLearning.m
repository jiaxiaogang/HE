//
//  TCLearning.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/12/2.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCLearning.h"

@implementation TCLearning

/**
 *  MARK:--------------------学习--------------------
 *  @desc 外类比;
 *  @desc 输入mv时调用,执行OPushM + 更新P任务池 + 执行P决策;
 *  @desc 由TIP调用,执行条件为:当imv与预测mv相符时,执行类比;
 *  @desc 如: (距20,经233) 与 (距20,经244) 可类比为: (距20)->{mv};
 *  解释:
 *   1. 无需求时,找出以往同样经历,类比规律,抽象出更确切的意义;
 *   2. 注:此方法为abs方向的思维方法总入口;(与其相对的决策处
 *  步骤:
 *   > 联想->类比->规律->抽象->关联->网络
 *  @param protoFo : 传瞬时记忆的protoFo;
 *  @version
 *      2020.03.04: a.去掉外类比; b.外类比拆分为:正向类比和反向类比;
 *      2021.01.24: 支持多时序识别,更全面的触发外类比 (参考22073-todo4);
 *      2021.09.28: ATSame改为传ATDefault (参考24022-BUG5);
 *      2021.12.02: 将TCLearning独立成类 (参考24164);
 */
+(void) pLearning:(AIFoNodeBase*)protoFo{
    [theTC updateOperCount:kFILENAME];
    Debug();
    //1. 获取最近的识别模型;
    IFTitleLog(@"pLearning", @"\n输入ProtoFo:%@->%@", Fo2FStr(protoFo),Mvp2Str(protoFo.cmvNode_p));
    NSArray *inModels = [theTC.inModelManager.models copy];
    for (AIShortMatchModel *item in inModels) {
        for (AIMatchFoModel *pFo in item.fos4PLearning) {
            //2. 检查同向;
            AIFoNodeBase *matchFo = [SMGUtils searchNode:pFo.matchFo];
            BOOL isSame = [AIScore sameIdenSameScore:matchFo.cmvNode_p mv2:protoFo.cmvNode_p];
            if (!isSame) continue;
            
            //3. 正向反馈类比 (外类比);
            [AIAnalogy analogyOutside:protoFo assFo:matchFo type:ATDefault];
        }
    }
}

/**
 *  MARK:--------------------理性noMv输入处理--------------------
 *  @desc 输入noMv时调用,执行OPushM + 更新R任务池 + 执行R决策;
 *  联想网络杏仁核得来的则false;
 *  @version
 *      2020.10.19: 将add至ShortMatchManager代码前迁;
 *      2021.12.05: 将feedbackTOR前迁到概念识别之后 (参考24171-9);
 *      2021.12.26: GL和HN已全废弃了,所以删掉内类比调用 (参考Note24 & Note25);
 *      2022.01.17: BUG_找不到hSolution经验的问题,将P树R树衔接,共参与抽象 (参考25104);
 *      2022.01.18: 改成使用ATDefault类型,因为ATSame已废弃;
 *      2022.11.16: R帧为不完全时序,不进行类比 (参考27181-改动);
 */
+(void) rLearning:(AIShortMatchModel*)model protoFo:(AIFoNodeBase*)protoFo{
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"rLearning",@"\nprotoAlg: %@",Alg2FStr(model.protoAlg));
    //NSLog(@"rLearning %@",Pits2FStr_MultiLine([SMGUtils convertArr:model.matchAlgs_All convertBlock:^id(AIMatchAlgModel *obj) {
    //    return obj.matchAlg;
    //}]));
    
    //1. 学习 for prFos: 加强pFos的抽具象关联;
    //NSLog(@"\npFo外类比 =>");
    //for (AIMatchFoModel *item in model.fos4RLearning) {
    //    AIFoNodeBase *itemMFo = [SMGUtils searchNode:item.matchFo];
    //    [AIAnalogy analogyOutside:protoFo assFo:itemMFo type:ATDefault];
    //}
    
    //1. 学习 for matchAlgs：加强特征等的抽象：每多识别概念后，就触发下类比，以尽快抽象特征（34091-1触发抽象）。
    for (AIMatchAlgModel *matchModel in model.matchAlgs_All) {
        AIAlgNodeBase *absA = [AIAnalogy analogyAlg:model.protoAlg.p assA:matchModel.matchAlg];
        
        //35. 结果可视化。
        [SMGUtils runByMainQueue:^{
            //[theApp.imgTrainerView setDataForAlg:absA lab:STRFORMAT(@"类比A%ld:A%ld=A%ld",model.protoAlg.pId,matchModel.matchAlg.pointerId,absA.pId)];
        }];
    }
    DebugE();
}

@end
