//
//  AIHeader.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/5/21.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "SMGEnum.h"
#import "SMGUtils.h"
#import "SMGUtils+General.h"
#import "SMGConfig.h"
#import "AINodeBase.h"
#import "AIFoNodeBase.h"
#import "AICMVNodeBase.h"
#import "NVHeader.h"
#import "AIInput.h"
#import "AINet.h"
#import "HeLogHeader.h"
#import "AIKVPointer.h"
#import "AIThinkingControl.h"
#import "NSString+Extension.h"
#import "NSFile+Extension.h"
#import "AsyncMutableArray.h"
#import "AsyncMutableDictionary.h"
#import "AIScore.h"
#import "XGDelegate.h"
#import "TOModelVision.h"
#import "TOMVision2.h"
#import "RTQueueModel.h"
#import "XGWedis.h"
#import "CortexAlgorithmsUtil.h"
#import "MapModel.h"
#import "ImgTrainerView.h"
#import "XGRedisUtil.h"
#import "DDic.h"

//Util
#import "ThinkingUtils.h"
#import "TOUtils.h"
#import "TIUtils.h"
#import "TCSolutionUtil.h"
#import "TCRecognitionUtil.h"
#import "NVViewUtil.h"
#import "MathUtils.h"
#import "XGDebug.h"
#import "TCDebug.h"
#import "TVUtil_Short.h"
#import "TVUtil.h"
#import "HeLogUtil.h"
#import "TOModelVisionUtil.h"
#import "TCLearningUtil.h"

//任务池
#import "ReasonDemandModel.h"
#import "PerceptDemandModel.h"
#import "HDemandModel.h"
#import "DemandManager.h"
#import "AIMatchFoModel.h"
#import "AIMatchAlgModel.h"
#import "AIMatchCansetModel.h"
#import "AIMatchModel.h"
#import "AIFeatureNextGVRankItem.h"
#import "AIFeatureAllBestGVModel.h"
#import "AIGroupValueNextVModel.h"
#import "AIRecognitionCache.h"
#import "AIFeatureZenTiItem_Rect.h"
#import "AIFeatureZenTiModel.h"
#import "AIFeatureZenTiModels.h"
#import "AIFeatureJvBuItem.h"
#import "AIFeatureJvBuModel.h"
#import "AIFeatureJvBuModels.h"

//短时记忆
#import "TOAlgModel.h"
#import "TOFoModel.h"
#import "AIShortMatchModel.h"
#import "AIShortMatchModel_Simple.h"
#import "ShortMatchManager.h"
#import "AISceneModel.h"
#import "TCTransferXvModel.h"
#import "TCResult.h"
#import "HEResult.h"
#import "DirectIndexDic.h"

//网络
#import "AINetUtils.h"
#import "AINetIndex.h"
#import "AINetGroupValueIndex.h"
#import "AINetIndexUtils.h"
#import "AIPort.h"
#import "AITransferPort.h"
#import "AIGroupValueNode.h"
#import "AIFeatureNode.h"
#import "AIGroupFeatureNode.h"
#import "AIAbsAlgNode.h"
#import "AIAlgNodeBase.h"
#import "AIFrontOrderNode.h"
#import "AIFoNodeBase.h"
#import "AINetAbsFoNode.h"
#import "AICMVNode.h"
#import "AIAbsCMVNode.h"
#import "AIMvFoManager.h"
#import "AIGeneralNodeCreater.h"

//其它: 类比器,评价器,触发器,防重器,输入,输出
#import "AIImvAlgs.h"
#import "ImvAlgsModelBase.h"
#import "AIAnalyst.h"
#import "AIAnalogy.h"
#import "AITime.h"
#import "OutputModel.h"
#import "Output.h"
#import "AINoRepeatRun.h"
#import "AIRank.h"
#import "AIFilter.h"
#import "InputGroupValueModel.h"
#import "InputGroupFeatureModel.h"
#import "AIVisionAlgsModelV2.h"
#import "AIVisionAlgsV2.h"

//2021新TC架构
#import "TCInput.h"
#import "TCRegroup.h"
#import "TCRecognition.h"
#import "TCLearning.h"
#import "TCFeedback.h"
#import "TCForecast.h"
#import "TCDemand.h"
#import "TCPlan.h"
#import "TCScene.h"
#import "TCCanset.h"
#import "TCSolution.h"
#import "TCRefrection.h"
#import "TCTransfer.h"
#import "TCAction.h"
#import "TCActYes.h"
#import "TCOut.h"

//MARK:===============================================================
//MARK:                         < 内核宏 >
//MARK:===============================================================

/**
 *  MARK:--------------------PathNameKey (kPH)--------------------
 */

#define kCachePath [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]

#define kPN_GROUPVALUE_NODE       @"PN_GROUPVALUE_NODE"
#define kPN_FEATURE_NODE       @"PN_FEATURE_NODE"
#define kPN_GROUPFEATURE_NODE       @"PN_GROUPFEATURE_NODE"

//algNode
#define kPN_ALG_NODE           @"PN_ALG_NODE"          //Alg节点根目录;(白质)
#define kPN_ALG_ABS_NODE       @"PN_ALG_ABS_NODE"      //AbsAlg节点根目录;(白质)

//foNode
#define kPN_FRONT_ORDER_NODE   @"PN_FRONT_ORDER_NODE"  //frontOrder节点根目录;(白质)
#define kPN_FO_ABS_NODE        @"PN_FO_ABS_NODE"       //神经网络根目录;(白质)

//cmv
#define kPN_CMV_NODE           @"PN_CMV_NODE"          //cmv节点根目录;(白质)
#define kPN_ABS_CMV_NODE       @"PN_ABS_CMV_NODE"      //cmv抽象节点根目录;(白质)
#define kPN_DIRECTION(mvDir)   STRFORMAT(@"PN_DIRECTION_%ld",mvDir)//mv顺逆方向引用序列(以Path为各mv的分区,cmvNode和absCMVNode都指向此direction)

//reference
#define kPN_REFERENCE          @"PN_REFERENCE"         //神经网络"引用序列"根目录;(海马体)
#define kPN_CEREBEL_CANOUT     @"PN_CEREBEL_CANOUT"    //小脑可输出标识序列

#define kPN_INDEX              @"PN_INDEX"             //索引序列
#define kPN_GV_INDEX           @"PN_GV_INDEX"          //索引序列
#define kPN_DATA               @"PN_DATA"              //微信息值字典
#define kPN_VALUE              @"PN_VALUE"             //微信息单条值

/**
 *  MARK:--------------------FileNameKey (kFN)--------------------
 *  @version
 *      2022.10.09: 废弃isMem内存单独存的key (参考27124-todo3);
 */
#define kFNNode @"node"               //节点
//#define kFNValue @"value"             //微信息
#define kFNRefPorts @"refPorts"       //微信息的reference序列文件名;
#define kFNIndex(isOut) STRFORMAT(@"index_%d",isOut) //in微信息索引(数组) / out小脑微信息(数组)
#define kFN_GV_Index(itemIndex) STRFORMAT(@"GVIndex_%ld",itemIndex)
#define kFNData(isOut) STRFORMAT(@"data_%d",isOut) //in微信息值 / out小脑微信息值 (dic)
#define kFNDirectionIndex(mvDirection) STRFORMAT(@"directionIndex_%ld",mvDirection) //mv的顺逆方向索引序列地址

#define kFNReference_ByPointer @"reference_ByPointer" //微信息引用(pointer序)
#define kFNReference_ByPort @"reference_ByPort"       //微信息引用(port序)
#define kFNDefault @" "                               //默认文件名; (例如:小脑canout序列)

//所有文件夹数组
#define kFN_ALL @[/*mvNode*/kPN_CMV_NODE,kPN_ABS_CMV_NODE,/*mv索引*/kPN_DIRECTION(MVDirection_None),kPN_DIRECTION(MVDirection_Negative),kPN_DIRECTION(MVDirection_Positive),/*foNode*/kPN_FRONT_ORDER_NODE,kPN_FO_ABS_NODE,/*algNode*/kPN_ALG_NODE,kPN_ALG_ABS_NODE,kPN_FEATURE_NODE,kPN_GROUPVALUE_NODE,/*小脑*/kPN_CEREBEL_CANOUT,/*稀疏码索引*/kPN_INDEX,kPN_GV_INDEX,kPN_DATA,kPN_VALUE]

#define cNOW [[NSDate date] timeIntervalSince1970] * 1000

/**
 *  MARK:--------------------数据检查--------------------
 */

//String
#define STRISOK(s) [SMGUtils strIsOk:s]                                 //是否空字符串
#define STRTOOK(s) [SMGUtils strToOk:s]                                 //string强检查
#define STRFORMAT(s, ...) [NSString stringWithFormat:s, ##__VA_ARGS__]  //String.format
#define SUBSTR2INDEX(s,index) [SMGUtils subStr:s toIndex:index]         //subStr_toIndex
#define STRTOARR(str, sep) [SMGUtils strToArr:str sep:sep]              //str分隔成arr
#define CLEANSTR(s) [SMGUtils cleanStr:s]

//Array
#define ARRISOK(a) [SMGUtils arrIsOk:a]                                 //是否空数组
#define ARRTOOK(a) [SMGUtils arrToOk:a]                                 //数组强检查
#define ARR_INDEX(a,i) [SMGUtils arrIndex:a index:i]                    //数组取子防闪
#define ARR_INDEX_REVERSE(a,i) [SMGUtils arrTransIndex:a index:i]       //数组反序取子防闪
#define ARR_INDEXISOK(a,i) [SMGUtils arrIndexIsOk:a index:i]            //数组可移除i
#define ARR_SUB(a,s,l) [SMGUtils arrSub:a start:s length:l]             //数组截取 (arr start length) (含前不含后)
#define ARRTOSTR(arr,mPre,mSep) [SMGUtils arrToStr:arr prefix:mPre sep:mSep]         //数组接成字符串

//NSNumber
#define NUMISOK(n) [SMGUtils numIsOk:n]                                 //是否有效NSNumber
#define NUMTOOK(n) [SMGUtils numToOk:n]                                 //number强检查
#define VALTOOK(n) [SMGUtils valToOk:n]                                 //NSValue强检查
#define NUMTOOK_DV(n,dv) [SMGUtils numToOk:n defaultValue:dv]

//Dic
#define DICISOK(d) [SMGUtils dicIsOk:d]                                 //是否空字典
#define DICTOOK(d) [SMGUtils dicToOk:d]                                 //dictionary强检查

//AIPointer
#define POINTERISOK(p) [SMGUtils pointerIsOk:p]                         //指针强检查
#define PitIsValue(p) [NVHeUtil isValue:p]                              //是否稀疏码
#define PitIsGroupValue(p) [NVHeUtil isGroupValue:p]
#define PitIsFeature(p) [NVHeUtil isFeature:p]
#define PitIsGroupFeature(p) [NVHeUtil isGroupFeature:p]
#define PitIsAlg(p) [NVHeUtil isAlg:p]                                  //是否概念
#define PitIsFo(p) [NVHeUtil isFo:p]                                    //是否时序
#define PitIsMv(p) [NVHeUtil isMv:p]                                    //是否价值
#define PitIsAbs(p) [NVHeUtil isAbs:p]                                  //是否抽象节点
#define Demand2Pit(demand) [HeLogUtil demandLogPointer:demand]          //任务转指针

//ISOK
#define ISOK(o, c) [SMGUtils isOk:o class:c]                            //obj强检查 (object class)

//NSData
#define OBJ2DATA(obj) [NSKeyedArchiver archivedDataWithRootObject:obj]
#define DATA2OBJ(data) [NSKeyedUnarchiver unarchiveObjectWithData:data]
#define DATAS2OBJS(datas) [SMGUtils datas2Objs:datas]
#define CopyByCoding(obj) DATA2OBJ(OBJ2DATA(obj))

//指针转字符串
#define Pit2FStr(p) [NVHeUtil getLightStr:p simple:false header:true]
#define Pits2FStr(ps) [NVHeUtil getLightStr4Ps:ps simple:false header:true sep:@","]
#define Pits2FStr_MultiLine(ps) [NVHeUtil getLightStr4Ps:ps simple:false header:true sep:@"\n"]

#define Pit2SStr(p) [NVHeUtil getLightStr:p]
#define Pits2SStr(ps) [NVHeUtil getLightStr4Ps:ps]

//节点转字符串
#define Alg2FStr(a) [NVHeUtil getLightStr:a.pointer simple:false header:true]
#define Fo2FStr(f) [NVHeUtil getLightStr:f.pointer simple:false header:true]
#define Mv2FStr(m) [NVHeUtil getLightStr:m.pointer simple:false header:true]

#define AlgP2FStr(a_p) [NVHeUtil getLightStr:a_p simple:false header:true]
#define FoP2FStr(f_p) [NVHeUtil getLightStr:f_p simple:false header:true]
#define Mvp2Str(m_p) [NVHeUtil getLightStr:m_p simple:false header:true]

#define FeatureDesc(t_p,s) [TVUtil getFeatureDesc:t_p sizeFenMu:s]

//节点转字符串 (短)
#define ShortDesc4Node(n) [TVUtil_Short desc4Node:n]
#define ShortDesc4Pit(p) [TVUtil_Short desc4Pit:p]

//稀疏码值转字符串
#define Data2FStr(data,at,ds) [NVHeUtil getLightStr_Value:data algsType:at dataSource:ds]

//xxx转指针
#define Ports2Pits(ports) [SMGUtils convertPointersFromPorts:ports]
#define Nodes2Pits(nodes) [SMGUtils convertPointersFromNodes:nodes]
#define Simples2Pits(simples) [SMGUtils convertPointersFromSimples:simples]

//Type转字符串
#define ATType2Str(type) [NSLog_Extension convertATType2Desc:type]
#define TOStatus2Str(status) [NSLog_Extension convertTOStatus2Desc:status]
#define TIStatus2Str(status) [NSLog_Extension convertTIStatus2Desc:status]
#define CansetStatus2Str(status) [NSLog_Extension convertCansetStatus2Desc:status]
#define Class2Str(c) [NSLog_Extension convertClass2Desc:c]
#define ClassName2Str(c) [NSLog_Extension convertClassName2Desc:c]
#define Mvp2DeltaStr(mv_p) [NSLog_Extension convertMvp2DeltaDesc:mv_p]
#define SceneType2Str(type) [NSLog_Extension convertSceneType2Desc:type simple:true]

//Double转Str
#define Double2Str_NDZ(value) [NSString double2Str_NoDotZero:value]

//思维控制器相关转换
#define Mvp2Delta(mv_p) [AINetUtils getDeltaFromMv:mv_p]
#define Mvp2Score(mv_p,ratio) [AIScore score4MV:mv_p ratio:ratio]

//短时记忆转字符串
#define TOModel2Root2Str(sub) [TOModelVision cur2Root:sub]
#define TOModel2Sub2Str(cur) [TOModelVision cur2Sub:cur]

//强训工具
#define Queue(name) [RTQueueModel newWithName:name arg0:nil arg1:nil arg2:nil]
#define Queue0(name,a0) [RTQueueModel newWithName:name arg0:a0 arg1:nil arg2:nil]
#define Queue1(name,a0,a1) [RTQueueModel newWithName:name arg0:a0 arg1:a1 arg2:nil]
#define Queue2(name,a0,a1,a2) [RTQueueModel newWithName:name arg0:a0 arg1:a1 arg2:a2]

/**
 *  MARK:--------------------快捷建对象--------------------
 */

//NSArray
//#define SMGArrayMake(arg) \
//NSMutableArray *array = [NSMutableArray arrayWithObject:arg];\
//va_list args;\
//va_start(args, arg);\
//id next = nil;\
//while ((next = va_arg(args,id))) {\
//[array addObject:next];\
//}\
//va_end(args);\

/**
 *  MARK:--------------------快捷访问对象--------------------
 */
//2017.11.13后启用N8规则DOP架构;
#define theNet [AINet sharedInstance]
#define theTC [AIThinkingControl shareInstance]

/**
 *  MARK:--------------------OutputObserverKey--------------------
 */
//OutputObserverKey
#define kOutputObserver   @"kOutputObserver"
#define kInputObserver   @"kInputObserver"

//OutputObjectKey (2021.02.05: 改为直接用OutputModel做obj);
//#define kOOIdentify @"identify" //输出行为标识
//#define kOOParam @"param"       //输出行为参数值
//#define kOOType @"type"         //广播类型
//#define kOOUseTime @"useTime"   //反馈需用时

//Identify标识 (内核方)
#define TEXT_RDS @"TEXT_RDS" //字符输出反射标识
#define ANXIOUS_RDS @"ANXIOUS_RDS" //焦急情绪输出标识
#define SATISFY_RDS @"SATISFY_RDS" //满意情绪输出标识

/**
 *  MARK:--------------------AlgsType & DataSource--------------------
 */
#define DefaultAlgsType @" "    //默认AlgsType
#define DefaultDataSource @" "  //默认DataSource
#define AlgNodeAlgsType(pId) STRFORMAT(@"%ld",(long)pId)   //概念节点AlgsType

/**
 *  MARK:--------------------LOG--------------------
 */
//日志默认header模式 (当前为首行显示)
#define DefaultHeaderMode 2
//当前类名
#define FILENAME [[NSString stringWithUTF8String:__FILE__] lastPathComponent]
//errorLog
#define ELog(fmt, ...) NSLog((@"<错误> " fmt), ##__VA_ARGS__);
//warnLog
#define WLog(fmt, ...) NSLog((@"<警告> " fmt), ##__VA_ARGS__);
//demoLog (Demo交互信息)
#define DemoLog(fmt, ...) NSLog((@"\n******************************* " fmt @" *******************************"), ##__VA_ARGS__);
//titleLog (控制台日志组块title) (其实S为简化版,F为全版,I为输入期,O为输出期);
#define ISTitleLog(title) IFTitleLog(title,@"")
#define IFTitleLog(title,fmt, ...) [SMGUtils inTitle:title log:[NSString stringWithFormat:fmt, ##__VA_ARGS__] fileName:FILENAME]
#define OSTitleLog(title) OFTitleLog(title,@"")
#define OFTitleLog(title,fmt, ...) [SMGUtils outTitle:title log:[NSString stringWithFormat:fmt, ##__VA_ARGS__] fileName:FILENAME]
//groupLog (每轮循环之始可用)
#define ISGroupLog(title) IFGroupLog(title,@"")
#define IFGroupLog(title,fmt, ...) NSLog((@"\n\n#########################################################################################################\n                                                <" title @"> \n#########################################################################################################"fmt), ##__VA_ARGS__);

//系统log (格式化)
//20220515: 将NSLog拆分成NSLog+PrintLog (为了增加noNSLog开关功能);
//#define NSLog(FORMAT, ...) fprintf(stderr,"%s",[[SMGUtils nsLogFormat:FILENAME line:__LINE__ protoLog:[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] headerMode:DefaultHeaderMode] UTF8String]);
#define NSLog(FORMAT, ...) [SMGUtils checkPrintNSLog:FILENAME line:__LINE__ protoLog:[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] headerMode:DefaultHeaderMode]
#define NSLog_CustomFileName(customFileName,FORMAT, ...) [SMGUtils checkPrintNSLog:customFileName line:__LINE__ protoLog:[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] headerMode:DefaultHeaderMode]
#define PrintLog(log) fprintf(stderr,"%s",[log UTF8String]);
//nsLog (自定义header模式)
#define NSLog_Mode(mode,FORMAT, ...) fprintf(stderr,"%s",[[SMGUtils nsLogFormat:FILENAME line:__LINE__ protoLog:[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] headerMode:mode] UTF8String]);
//heLog (持久化日志)
#define HeLog(fmt, ...) [theApp.heLogView addLog:[NSString stringWithFormat:fmt, ##__VA_ARGS__]]
//tipLog (UI弹出日志)
#define TipLog(fmt, ...) [theApp setTipLog:[NSString stringWithFormat:fmt, ##__VA_ARGS__]]
//allLog (系统 + 持久化 + UI弹出)
#define AllLog(fmt, ...) [SMGUtils allLog:[NSString stringWithFormat:fmt, ##__VA_ARGS__]]

/**
 *  MARK:--------------------LOG开关--------------------
 */
#define Log4DemoWood false
//测试模式 (功能说明: 把all关掉,然后仅会打印just中模块的日志; 使用说明: 用于测试某些模块时使用);
#define LogJustPrintTCs @[@"TCSolution"]
#define LogPrintAllTCs true
//皮层
#define Log4CortexAlgs false
//输入思维
#define Log4TCInput false
//瞬时记忆长度限制
#define Log4ShortLimit false
//识别概念
#define Log4MAlg true
//识别细节
#define Log4RecogDesc false
//模糊匹配
#define Log4FuzzyAlg false
//识别时序
#define Log4MFo false
//类比
#define Log4Ana false
#define Log4OutCansetAna true
//方向索引
#define Log4DirecRef true
//预测日志开关
#define Log4Forecast false
//外输入推进中循环
#define Log4OPushM true
#define Log4TIROPushM false
//当前可决策任务:CanDecisionDemand;
#define Log4CanDecisionDemand false
#define Log4NewDemand false
//Plan日志开关
#define Log4Plan true
//反省
#define Log4Rethink true
#define Log4OutSPDic true
#define Log4Effect false
//解决方案条件满足
#define Log4SceneIsOk false
//S过滤器
#define Log4SolutionFilter false

//Score
#define Log4Score false
#define Log4Solution true

//TCCanset日志开关
#define Log4GetCansetResult4R false
#define Log4GetCansetResult4H true

//AIRank日志开关
#define Log4AIRank true
#define Log4AIRankDebugMode false //Rank在BUG调试模式时的日志

//MARK:===============================================================
//MARK:                     < 系统模块开关 >
//MARK:===============================================================

//R决策模式
#define Switch4RS true
//P决策模式
#define Switch4PS false
//P任务开关 (20230301早没用P任务了,关掉)
#define Switch4PDemand false
//行为再输入开关 (参考28133-1 & 28137-修复)
#define Switch4IsOutReIn true
//识别排名器开关 (参考28152-方案5)
#define Switch4RecognitionRank false
//matchRFos识别开关 (参考28185-todo1)
#define Switch4RecognitionMatchRFos false
//AITest开关
#define Switch4AITest false
//Canset识别开关
//#define Switch4RecognitionCansetFo false
//Canset类比开关
#define Switch4AnalogyCansetFo true
//惰性期开关 (参考29073-方案)
#define Switch4DuoXinQi false
//反馈反思识别开关,只要把它的重组关了,后面的识别也就关了 (参考30054)
#define Switch4FeedbackRegroup false
#define Switch4ActionRegroup false
//feedbackTOR日志开关
#define Switch4FeedbackTOR true

//MARK:===============================================================
//MARK:                    < flt流程日志开关 >
//MARK: @desc 用于打印关键日志，在各项训练过程中快速观察关键日志。
//MARK:===============================================================

/**
 *  MARK:--------------------flt default--------------------
 */
#define Switch4Default true
#define FltLog4Default(stepStr) FltLog4DefaultIf(true,stepStr)
#define FltLog4DefaultIf(ef,stepStr) ef && Switch4Default ? STRFORMAT(@"flt%@ ",stepStr) : @""

/**
 * @title absHCanset (参考31183-训练项2)
 * @desc 1.H解行为化 2.H的feedbackTOR成立 3.构建newHCanset
 * @example FZ944x3,按31183步骤慢训练一次,日志如下,存为FZ914x4 (说明: 可见能够执行到构建absHCanset);
 *  flt1 H行为化下标 (4/4) A5239(向85,距11,果) from时序:F5922[M1{↑饿-16},A5267(向172,距173,棒),A5239(向85,距11,果),M1{↑饿-16},A5239(向85,距11,果)]
 *  flt2 H feedbackTOR反馈成立:A5239(向85,距11,果) 匹配:1 baseCansetFrom:F5294[↑饿-16,4棒,4果,↑饿-16,4果] 状态:CS_Besting
 *  flt3 Canset演化 AbsHCanset:F5930[A13(饿16,7),A4899(距11,果),A5929(向85,果)] toScene:F4822[↑饿-16,4果,↑饿-16,4果] 在4帧
 */
#define Switch4AbsHCanset false
#define FltLog4AbsHCanset(isH,step) isH && Switch4AbsHCanset ? STRFORMAT(@"flt%d ",step) : @""

/**
 * @title 无皮果动机 (参考31183-训练项3)
 * @desc 1.习得RCanset[无皮果,吃] 2.激活RCanset[无皮果,吃] 3.生成H无皮果 (FZ944x4本来就有无皮果动机,所以这个训练步骤没用到);
 * @example FZ944x4,路下出生,点击饿,日志如下 (说明: 可见能够得到无皮果动机);
 *  flt1 R行为化下标 (3/4) A4807(向90,距11,果) from时序:F4838[M1{↑饿-16},A4807(向90,距11,果),M1{↑饿-16},A4807(向90,距11,果)]
 *  flt2 A4807(向90,距11,果)
 */
#define Switch4HDemandOfWuPiGuo false
#define FltLog4HDemandOfWuPiGuo(step) Switch4HDemandOfWuPiGuo ? STRFORMAT(@"flt%d ",step) : @""

/**
 * @title 学会去皮 (参考31183-训练项4)
 * @desc 1.在去皮动机生成H无皮果后 2.扔有皮果 3.扔棒去皮 4.feedbackTOR反馈到无皮果 5.生成扔棒去皮H经验
 * @example FZ944x4,路上出生,点击饿,在生成H无皮果后,扔有皮果,扔木棒去皮,上飞吃掉 (说明: 可见能够生成扔棒去皮H经验);
 *  flt1 A4807(向90,距11,果)
 *  flt2 R feedbackTOR反馈成立:A4807(向90,距11,果) 匹配:1 baseCansetFrom:F4838[↑饿-16,4果,↑饿-16,4果] 状态:CS_Besting
 *  flt3 Canset演化 NewHCanset:F6739[M1{↑饿-16},M1{↑饿-16},A6726(向90,距12,皮果),A6730(向16,距99,棒),A4991(向88,距27,棒),A6734(向90,距12,果)] toScene:F4838[↑饿-16,4果,↑饿-16,4果] 在3帧:A4807
 *  flt3 Canset演化 AbsHCanset:F6742[A13(饿16,7),A13(饿16,7),A6741(距10,果)] toScene:F4838[↑饿-16,4果,↑饿-16,4果] 在4帧
 * @result 存为944x5
 */
#define Switch4YaQuPi false
#define FltLog4XueQuPi(step) Switch4YaQuPi ? STRFORMAT(@"flt%d ",step) : @""

/**
 * @title 有皮果动机 (参考31183-训练项5)
 * @desc 1.饿 2.生成H无皮果 3.再H找到去皮经验 4.生成H有皮果 (注: 上一个训练项4已经学会去皮,所以此处只需要看能不能激活"去皮H经验"即可);
 * @desc 主要观察两步: 生成H无皮果 => 生成H有皮果;
 * @example FZ944x5,路下出生,点击饿,日志如下 (说明: 可见能够激活有皮果动机);
 * @步骤说明: 改为true打开后,筛选flt日志看有依次生成:
 *          1. 无皮果动机 => TCDemand.m  39] flt1 A4204(距12,果)
 *          2. 无皮果求解 => AIRank.m 189] flt3 H0. I<F4621 F5841[↑饿-16,4果皮,4棒,4棒,4果]> {0 = 0;} {3 = S0P2;2 = S0P2;1 = S0P3;4 = S0P2;} (null):(分:0.00) [CUT:0=>TAR:4]
 *          3. F5841第2帧即有皮果,又转为有皮果动机,如下:
 *          4. 有皮果动机 => TCDemand.m  39] flt1 A3955(向90,距13,皮果)
 *          5. 有皮果hSolution => TCSolution.m  39] flt2 目标:A3955(向90,距13,皮果) 已有S数:0
 */
#define Switch4HDemandOfYouPiGuo false
#define FltLog4HDemandOfYouPiGuo(stepStr) Switch4HDemandOfYouPiGuo ? STRFORMAT(@"flt%@ ",stepStr) : @""

/**
 * @title 学会搬运 (参考31183-训练项6 -> 32051 -> 32141-训练项4)
 * @desc 1.在去皮经验生成H"路上有皮果"后 2.扔"路下有皮果" 3.快速将有皮果踢到路上 4.feedbackTOR反馈到"路上有皮果" 5.生成搬运到路上H经验
 * @步骤说明: 改为true打开后,筛选flt日志看有依次生成:
 *          1. 有皮果动机 => TCDemand.m  39] flt1 A3955(向90,距13,皮果)
 *          2. 立马扔路边有皮果,并搬运到路上;
 *          3. 学会HCanset => flt2 NewHCanset 或 AbsHCanset
 */
#define Switch4XueBanYun false
#define FltLog4XueBanYun(step) Switch4XueBanYun ? STRFORMAT(@"flt%d ",step) : @""

/**
 * @title 使用搬运 (参考32061)
 * @desc `FZ977,饿,等看到距0有皮果动机后,扔距0带皮果` -> 然后看它自己把坚果踢到路上;
 * @步骤说明: 改为true打开后,筛选flt日志看有依次生成:
 *          1. 从无皮果动机 => TCDemand.m  39] flt1 A3955(向90,距13,果)
 *          2. 再到有皮果动机 => TCDemand.m  39] flt1 A3955(向90,距13,皮果)
 *          3. 再到距0有皮果动机 => TCDemand.m  39] flt1 A3955(向90,距0,皮果)
 *          4. 立马扔距0有皮果;
 *          5. 执行搬运行为化 => flt2 Axxxx(踢)
 */
#define Switch4YonBanYun false
#define FltLog4YonBanYun(step) Switch4YonBanYun ? STRFORMAT(@"flt%d ",step) : @""

/**
 *  MARK:--------------------调试构建RCanset (参考32131)--------------------
 */
#define Switch4CreateRCanset false
#define FltLog4CreateRCanset(step) Switch4CreateRCanset ? STRFORMAT(@"flt%d ",step) : @""

/**
 *  MARK:--------------------调试构建HCanset (参考32131)--------------------
 */
#define Switch4CreateHCanset false
#define FltLog4CreateHCanset(step) Switch4CreateHCanset ? STRFORMAT(@"flt%d ",step) : @""
