//
//  AIMatchFoModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/1/23.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------单条matchFo模型--------------------
 *  @version
 *      2021.06.29: 将cutIndex拆分为lastMatchIndex和cutIndex两个,即新增cutIndex已发生截点 (参考23152);
 *      2022.09.06: 将匹配度matchFoValue改成单存分子分母两个值,更新时分母+1,分子计算当前的相近度即可 (参考27095-8);
 *      2022.09.15: 因为maskFo(本体为protoFo/regroupFo),它其实在反省推进时会变化的,所以改成realMaskFo (参考27097);
 */
@class AIFoNodeBase;
@interface AIMatchFoModel : NSObject

+(AIMatchFoModel*) newWithMatchFo:(AIKVPointer*)matchFo protoOrRegroupFo:(AIKVPointer*)protoOrRegroupFo sumNear:(CGFloat)sumNear nearCount:(NSInteger)nearCount indexDic:(NSDictionary*)indexDic cutIndex:(NSInteger)cutIndex sumRefStrong:(NSInteger)sumRefStrong baseFrameModel:(AIShortMatchModel*)baseFrameModel;

@property (weak, nonatomic) ReasonDemandModel *baseRDemand; //记录其挂载在哪个R任务下 (weak不允许序列化,避免循环序列化);
//@property (weak, nonatomic) AIShortMatchModel *baseFrameModel;//记录其挂载在哪个frameModel下;

@property (strong, nonatomic) AIKVPointer *matchFo;     //匹配时序

/**
 *  MARK:--------------------识别时为protoFo,反思时为regroupFo--------------------
 *  @title 实际经历;
 *  @desc 状态: 启用,初始化时为maskFo,但后续可随着反省触发器和cutIndex的推进更新;
 *  @desc 元素初始化时为protoFo/regroupFo的content_ps,后续随着更新附加到尾部;
 */
@property (strong, nonatomic) NSMutableArray *realMaskFo; //List<protoAlg_p>
@property (strong, nonatomic) NSMutableArray *realDeltaTimes; //List<deltaTime> (用来完全时序时,构建protoFo时使用);
@property (assign, nonatomic) NSTimeInterval lastFrameTime; // 最后一帧的时间 (用来记录上一帧,以记录下(新)帧时的deltaTime值);

@property (assign, nonatomic) CGFloat sumNear;          //时序元素相近度总和
@property (assign, nonatomic) NSInteger nearCount;      //时序元素相近数
@property (assign, nonatomic) BOOL isExpired;           //过期状态 (参考n27p09)

//MARK:===============================================================
//MARK:                     < status每帧状态 >
//MARK:===============================================================

/**
 *  MARK:--------------------状态--------------------
 *  @desc 最后一帧(mv反馈状态)传cutIndex: matchFo.count - 1;
 *  @version
 *      2022.09.17: status迭代为每帧一个 (参考27098-todo1);
 */
@property (strong, nonatomic) NSMutableDictionary *status;//每帧状态 <K:cutIndex, V:TIModelStatus>
-(TIModelStatus) getStatusForCutIndex:(NSInteger)cutIndex;
-(void) setStatus:(TIModelStatus)status forCutIndex:(NSInteger)cutIndex;

/**
 *  MARK:--------------------匹配下标映射--------------------
 *  @desc 其描述了match(pFo)与mask(实际反馈)匹配到的每一位的下标映射 <K:matchFoIndex,V:maskFoIndex>;
 *  @caller
 *      1. 当为瞬时识别时,lastMatchIndex与已发生cutIndex同值 (因为瞬时时,判断的本来就是当前已经发生的事);
 *      2. 当为反思识别时,lastMatchIndex与已发生cutIndex不同值 (因为反思是一种假设,并判断假设这么做会怎么样);
 *  @version
 *      2022.06.11: 将lastMatchIndex迭代成indexDic,即从末位改成记录所有 (参考26232-TODO2);
 */
@property (strong, nonatomic) NSMutableDictionary *indexDic2;

/**
 *  MARK:--------------------初始化时的截点--------------------
 *  @desc 用于今后取indexDic时,可以根据这个截点,取已发生部分;
 */
@property (assign, nonatomic) NSInteger initCutIndex;

/**
 *  MARK:--------------------已发生截点--------------------
 *  @desc 已发生与预测的截点 (0开始,已发生含cutIndex);
 *          1. 识别时为indexDic的长度-1,即全已发生;
 *          2. 反思时为-1,无效数据 (反思要从foModel.actionIndex随变随取);
 */
@property (assign, nonatomic) NSInteger cutIndex;

/**
 *  MARK:--------------------时序识别中被引用强度--------------------
 *  @version
 *      2022.12.28: 改为indexDic匹配已发生部分的综合强度 (参考2722f-todo13);
 */
@property (assign, nonatomic) NSInteger sumRefStrong;

/**
 *  MARK:--------------------AIMatchFoModel的评分(懒加载)缓存--------------------
 *  @desc 初始未计算时 = NSNotFound;
 *  @version
 *      2022.08.19: 初版,因为demand评分常慢(>1s),跑会训练就卡的很,所以加了这个评分缓存 (参考27065);
 */
@property (assign, nonatomic) CGFloat scoreCache;


//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================

//有反馈且匹配当前帧
-(void) feedbackPushFrame:(AIKVPointer*)fbProtoAlg;

//有反馈但不匹配当前帧
-(void) feedbackOtherFrame:(AIKVPointer*)otherProtoAlg;

//匹配度计算;
-(CGFloat) matchFoValue;

//推进帧结束(完全帧)时总结 (参考27201-5);
-(void) pushFrameFinish:(NSString*)log except4SP2F:(NSMutableArray*)except4SP2F;

/**
 *  MARK:--------------------获取强度--------------------
 *  @desc 获取概念引用强度,求出平均值 (参考2722d-todo4);
 */
-(CGFloat) strongValue;

/**
 *  MARK:--------------------在发生完全后,构建完全protoFo时使用获取orders--------------------
 */
-(NSArray*) convertOrders4NewCansetV2;

/**
 *  MARK:--------------------inSP更新器--------------------
 */
-(void) checkAndUpdateReasonInRethink:(NSInteger)cutIndex type:(AnalogyType)type except4SP2F:(NSMutableArray*)except4SP2F;
-(void) checkAndUpdatePerceptInRethink:(AnalogyType)type except4SP2F:(NSMutableArray*)except4SP2F;

@end
