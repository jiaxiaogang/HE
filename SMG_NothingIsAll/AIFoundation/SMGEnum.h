//
//  SMGEnum.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/4/8.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

/**
 *  MARK:--------------------充电状态--------------------
 */
typedef NS_ENUM(NSInteger, HungerState) {
    HungerState_Unknown     = 0,
    HungerState_Unplugged   = 1,//未充电
    HungerState_Charging    = 2,//充电中
};


typedef NS_ENUM(NSInteger, AIMoodType) {
    AIMoodType_Anxious      = 1,//焦急
    AIMoodType_Satisfy      = 2,//满意
};

/**
 *  MARK:--------------------IMVType(输入imv信号)--------------------
 */
typedef NS_ENUM(NSInteger, MVType) {
    MVType_None     = 0,
    MVType_Hunger   = 1,
    MVType_Anxious  = 2,
    MVType_Hurt  = 3,//痛觉
    MVType_Unknown = 4,//未知恐惧
};

/**
 *  MARK:--------------------CustomInputType(自定义输入信号)--------------------
 */
typedef NS_ENUM(NSInteger, CustomInputType) {
    CustomInputType_Charge     = 1,
};

/**
 *  MARK:--------------------MV目标类型--------------------
 */
//typedef NS_ENUM(NSInteger, AITargetType) {
//    AITargetType_None   = 0,//不变
//    AITargetType_Up     = 1,//增涨(欲望)
//    AITargetType_Down   = 2,//下降(饥饿,焦急,疼痛)
//    AITargetType_Repeat = 3,//重复(快乐)
//};


/**
 *  MARK:--------------------顺逆方向--------------------
 */
typedef NS_ENUM(NSInteger, MVDirection) {
    MVDirection_None        =-1,//无
    MVDirection_Negative    = 0,//负
    MVDirection_Positive    = 1,//正
};

/**
 *  MARK:--------------------类比类型(大小有无同异)--------------------
 *  @version
 *      2021.10.12: SP的定义由顺逆改为好坏 (参考24054-方案2);
 *      2022.10.28: 除了ATPlus和ATSub用来标记好坏外,此枚举早已弃用;
 */
typedef NS_ENUM(NSInteger,  AnalogyType) {
    ATDefault   = 0,            //默认
    ATGreater   = INT_MAX - 47, //2147483600    内类比_变大 (已弃用);
    ATLess      = INT_MIN + 48, //-2147483600   内类比_变小 (已弃用)
    ATHav       = INT_MAX,      //2147483647    内类比_变有 (已弃用)
    ATNone      = INT_MIN,      //-2147483648   内类比_变无 (已弃用)
    ATPlus      = INT_MAX - 147,//2147483500    反省_好
    ATSub       = INT_MIN + 148,//-2147483500   反省_坏
    ATSame      = INT_MAX - 247,//2147483400    正向外类比 (仅用于表示是否指向实mv,不做为节点类型使用) (已弃用)
    ATDiff      = INT_MIN + 247,//-2147483400   反向外类比 (即用于表示是否指向虚mv,也做为节点类型使用) (已弃用)
};

/**
 *  MARK:--------------------Output通知前后枚举--------------------
 */
typedef NS_ENUM(NSInteger,  OutputObserverType) {
    OutputObserverType_UseTime = -1,//取行为动作使用时间 (只负责将现实世界行为动作所需时间传回给主线程和TO线程用,禁止UI操作);
    OutputObserverType_Front   = 0,//前 (动作输出);
    OutputObserverType_Back    = 1,//后 (世界变化处理 & 价值触发处理);
};

/**
 *  MARK:--------------------识别类型--------------------
 *  @desc 优先级说明: self > fuzzy > abs > seem
 *  @version
 *      2020.10.22: TIR_Alg同时支持matchAlg和seemAlg的返回,fuzzy已废弃,所以不再需要MatchType枚举 (参考:21091);
 */
//typedef NS_ENUM(NSInteger, MatchType) {
//    MatchType_None  = 0,//无效
//    MatchType_Seem  = 1,//局部相似
//    MatchType_Abs   = 2,//全含
//    MatchType_Fuzzy = 3,//模糊匹配
//    MatchType_Self  = 4,//自身
//};

/**
 *  MARK:--------------------LogHeaderMode--------------------
 */
typedef NS_ENUM(NSInteger, LogHeaderMode) {
    LogHeaderMode_None  = 0,//无header
    LogHeaderMode_First = 1,//仅首行
    LogHeaderMode_All   = 2,//所有行
};

/**
 *  MARK:--------------------TOModelStatus--------------------
 *  @title 输出模型状态
 *  @todo 考虑支持ScorePK,即迟疑时,尝试别的方案,与当前方案进行竞争;
 *  @version
 *      2021.12.23: 废弃Wait状态,由Runing替代;
 */
typedef NS_ENUM(NSInteger, TOModelStatus) {
    TOModelStatus_Runing   = 1,//运行中 (其subModel正在尝试行为化中);
    TOModelStatus_ActYes   = 2,//行为化成功 (等待外循环结果,等待反馈) (预测);
    TOModelStatus_ActNo    = 3,//行为化失败 (等待条件满足时继续);
    TOModelStatus_ScoreNo  = 4,//评价失败而中止 (不想干,彻底挂掉,除非demandModel变的更迫切);
    TOModelStatus_OuterBack= 5,//外循环结果返回符合的标记 (用于actYes);
    TOModelStatus_Finish   = 6,//最终成功 (完成后向下帧跳转,发生在事实发生之后,即新的input匹配到);
    TOModelStatus_WithOut  = 7,//TCSolution无计可施标记,没S解决方案了;
};

typedef NS_ENUM(NSInteger, CansetStatus) {
    CS_None                 = 0,//CansetModels池子里
    CS_Besting              = 1,//正在行为化中
    CS_Bested               = 2,//行为化过
};

/**
 *  MARK:--------------------TIModelStatus--------------------
 *  @title 输入模型状态
 *  @version
 *      2022.09.04: 虚mv早已废弃:所以删除TIModelStatus_OutBackDiffDelta(4),//反馈反向delta (用于虚mv)
 */
typedef NS_ENUM(NSInteger, TIModelStatus) {
    TIModelStatus_Default           = 0,//默认值
    TIModelStatus_LastWait          = 1,//等待下帧(末位时即等待mv) (相当于TO的ActYes状态) (如0是LastWait状态其实是在等待1的反馈);
    TIModelStatus_OutBackReason     = 2,//反馈理性结果 (用于理性反馈)
    TIModelStatus_OutBackSameDelta  = 3,//反馈同向delta (用于实mv)
    TIModelStatus_OutBackNone       = 5,//无反馈
};

/**
 *  MARK:--------------------TOType--------------------
 *  @title 决策类型 (其实只有P-和R-存在,另外两个不构成需求);
 */
//typedef NS_ENUM(NSInteger, TOType) {
//    TO_PerceptSub = 0,//P- (必须完成,才算完成)
//    TO_PerceptPlus= 1,//P+ (开心,无需求,暂废弃)
//    TO_ReasonPlus = 2,//R+ (顺应即可,顺不成也算完成,无需求,暂废弃)
//    TO_ReasonSub  = 3,//R- (只要阻止,就算完成)
//};

/**
 *  MARK:--------------------SceneType (参考29069-todo1)--------------------
 */
typedef NS_ENUM(NSInteger,  SceneType) {
    SceneTypeI         = 0,
    SceneTypeFather    = 1,
    SceneTypeBrother   = 2
};
