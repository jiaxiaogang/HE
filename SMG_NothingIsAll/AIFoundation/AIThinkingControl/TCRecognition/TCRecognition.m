//
//  TCRecognition.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "TCRecognition.h"

@implementation TCRecognition

/**
 *  MARK:--------------------瞬时时序识别--------------------
 *  @param model : 当前帧输入期短时记忆;
 *  @version
 *      20200414 - protoFo由瞬时proto概念组成,改成瞬时match概念组成 (本方法中,去掉proto概念层到match层的联想);
 *      20200717 - 换上新版partMatching_FoV2时序识别算法;
 *      20210119 - 支持预测-触发器和反向反馈类比 (22052-1&3);
 *      20210124 - In反省类比触发器,支持多时序识别matchFos (参考22073-todo3);
 *      20210413 - TIRFoFromShortMem的参数由matchAFo改为protoFo (参考23014-分析2);
 *      20210414 - 将TIRFo参数改为matchAlg有效则protoFo,否则matchAFo (参考23015);
 *      20210421 - 加强RFos的抽具象关联,对rFo与protoFo进行类比抽象;
 *      20210422 - 将absRFo收集到inModel中 (用于GL联想assFo时方便使用,参考23041-示图);
 *  @bug
 *      2020.11.10: 在21141训练第一步,发现外类比不执行BUG,因为传入无用的matchAlg参数判空return了 (参考21142);
 *  @todo
 *      2021.12.12: 随后把时序识别的代码移过来,现在旧有反思代码在调用,就先不移了;
 */
+(void) rRecognition:(AIShortMatchModel*)model{
    //1. 数据准备;
    NSArray *except_ps = @[model.protoFo.pointer,model.matchAFo.pointer];
    AIFoNodeBase *protoFo = ARRISOK(model.matchAlgs_Si) ? model.protoFo : model.matchAFo;
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"rInput时序识别", @"\nprotoFo:%@->%@",Fo2FStr(protoFo),Mvp2Str(protoFo.cmvNode_p));
    
    //2. 调用通用时序识别方法 (checkItemValid: 可考虑写个isBasedNode()判断,因protoAlg可里氏替换,目前仅支持后两层)
    [TCRecognitionInvoke recognitionFoStep1:protoFo except_ps:except_ps decoratorInModel:model fromRegroup:false matchAlgs:model.matchAlgs_Si protoOrRegroupCutIndex:protoFo.count - 1 debugMode:true];
    
    //3. 识别二次过滤器;
    [AIFilter secondRecognitionFilter:model];
    
    //4. 二次过滤后,进行时序抽具象关联 (参考3313b-TODO4);
    [TCRecognitionInvoke recognitionFoStep2:protoFo inModel:model debugMode:true];
    DebugE();
}

+(void) pRecognition:(AIShortMatchModel*)model{
    NSArray *except_ps = @[model.protoFo.pointer,model.protoFo4PInput.pointer];
    AIFoNodeBase *protoFo = model.protoFo4PInput;
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"pInput时序识别", @"\nprotoFo4PInput:%@",Fo2FStr(protoFo));
    [TCRecognitionInvoke recognitionFoStep1:protoFo except_ps:except_ps decoratorInModel:model fromRegroup:false matchAlgs:nil protoOrRegroupCutIndex:protoFo.count - 1 debugMode:true];
    
    //2. 二次过滤后,进行时序抽具象关联 (参考3313b-TODO4);
    [TCRecognitionInvoke recognitionFoStep2:protoFo inModel:model debugMode:true];
    DebugE();
}

/**
 *  MARK:--------------------重组时序识别--------------------
 *  @desc 即以前的反思,
 *  _param protoAlg_ps : RTFo
 *      1. 传入原始瞬时记忆序列 90% ,还是识别后的概念序列 10%;
 *      2. 传入行为化中的rethinkLSP重组fo;
 *  _param baseDemand : 参数fo所处的r任务 (有可能非R任务,或者为nil,所以此参数用前需先做防错判断);
 *  @desc 向性:
 *      1. ↑
 *      2. →
 *
 *  @desc 代码步骤:
 *      1. 用内类比的方式,发现概念的变化与有无; (理性结果)
 *      2. 用外类比的方式,匹配出靠前limit个中最相似抽象时序,并取到预测mv结果; (感性结果)
 *      3. 根据时序相似性 与 微信息差异度 得出 修正mv的紧迫度; (综合预测)
 *      4. 将fixMv添加到任务序列demandManager,做TOR处理;
 *
 *  @desc 举例步骤:
 *      1. 通过,内类比发现有一物体:方向不变 & 越来越近;
 *      2. 通过,识别概念,发现此物体是汽车; (注:已识别过,可以直接查看抽象指向);
 *      3. 通过,外类比,发现以此下去,"汽车距离变0"会撞到疼痛;
 *      4. 通过,"车-0-撞-疼"来计算时序相似度x% 与 通过"车距"y 计算= zMv;
 *      5. 将zMv提交给demandManager,做TOR处理;
 *  @version
 *      2020.04.03 : 将assFoIndexAlg由proto.lastIndex改为replaceMatchAlg来代替 (因为lastAlg索引失败率太高);
 *      2020.07.17 : 换上新版partMatching_FoV2时序识别算法;
 *      2021.04.13 : 将装饰AIShortMatchModel改为result返回 & 参数由order直接改为fo传入;
 *      2021.07.07 : 反思时,cutIndex全部返-1 (参考23156);
 *      2023.01.21 : regroupFo调用时序识别,传入反馈帧概念识别的结果matchAlgs (参考28103-2.2);
 *  @todo :
 *      2020.04.03: 支持识别到多个时序 T;
 *      2020.04.03: 以识别到的多个时序,得到多个价值预测 (支持更多元的评价);
 *  @status
 *      1. 输出反思已废弃;
 *      2. 输入反思功能整合回正向识别中 (即由重组,来调用识别实现);
 */
+(void) feedbackRecognition:(AIFoNodeBase*)regroupFo foModel:(TOFoModel*)foModel feedbackFrameOfMatchAlgs:(NSArray*)feedbackFrameOfMatchAlgs{
    //1. 数据检查
    AIShortMatchModel *result = [[AIShortMatchModel alloc] init];
    result.regroupFo = regroupFo;
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"feedback时序识别", @"\nprotoFo:%@",Fo2FStr(regroupFo));
    
    //2. 调用通用时序识别方法 (checkItemValid: 可考虑写个isBasedNode()判断,因protoAlg可里氏替换,目前仅支持后两层)
    [TCRecognitionInvoke recognitionFoStep1:regroupFo except_ps:@[regroupFo.pointer] decoratorInModel:result fromRegroup:true matchAlgs:feedbackFrameOfMatchAlgs protoOrRegroupCutIndex:foModel.cansetCutIndex debugMode:false];
    //NSLog(@"反思时序: Finish >> %@",Fo2FStr(result.matchFo));
    
    //2. 二次过滤后,进行时序抽具象关联 (参考3313b-TODO4);
    [TCRecognitionInvoke recognitionFoStep2:regroupFo inModel:result debugMode:false];
    
    //3. 调用更新到短时记忆树 (不用学习和反馈,直接构建子任务);
    DebugE();
    [TCDemand subDemand:result foModel:foModel];
}

/**
 *  MARK:--------------------行为化前反思识别--------------------
 *  @desc 在行为化输出前,先反思识别一下,如果这么做,会导致什么子任务 (参考30054-另外2&todo4);
 *  @version
 *      2023.07.13: 支持二次行为化前反思识别过滤器 (参考30059);
 */
+(void) actionRecognition:(AIFoNodeBase*)regroupFo baseActionFo:(TOFoModel*)baseActionFo {
    //1. 数据检查
    AIShortMatchModel *result = [[AIShortMatchModel alloc] init];
    result.regroupFo = regroupFo;
    [theTC updateOperCount:kFILENAME];
    Debug();
    IFTitleLog(@"行为化前 反思识别", @"\nregroupFo:%@",Fo2FStr(regroupFo));
    
    //2. 调用通用时序识别方法 (checkItemValid: 可考虑写个isBasedNode()判断,因protoAlg可里氏替换,目前仅支持后两层) (参考30054-todo4);
    [TCRecognitionInvoke recognitionFoStep1:regroupFo except_ps:@[regroupFo.pointer] decoratorInModel:result fromRegroup:true matchAlgs:nil protoOrRegroupCutIndex:regroupFo.count - 1 debugMode:false];
    
    //3. 识别二次过滤器;
    [AIFilter secondActionRecognitionFilter:result];
    
    //2. 二次过滤后,进行时序抽具象关联 (参考3313b-TODO4);
    [TCRecognitionInvoke recognitionFoStep2:regroupFo inModel:result debugMode:false];
    
    //3. 调用更新到短时记忆树 (不用学习和反馈,直接构建子任务) (参考30054-todo5);
    DebugE();
    [TCDemand subDemand:result foModel:baseActionFo];
}

@end
