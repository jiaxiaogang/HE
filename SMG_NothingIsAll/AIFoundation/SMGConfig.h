//
//  SMGConfig.h
//  SMG_NothingIsAll
//
//  Created by iMac on 2018/7/26.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

//MARK:===============================================================
//MARK:                     < redisTime >
//MARK:===============================================================

/**
 *  MARK:--------------------缓存时间--------------------
 *  @version
 *      2022.10.09: 废弃isMem内存缓存时间的配置 (因为XGRedis早就把它的功能替了,参考27124-todo2);
 */
#define cRTIndex 315360000  //常驻内存(十年)
#define cRT_GV_Index 315360000  //常驻内存(十年)
#define cRTData 315360000   //常驻内存(十年)
#define cRTReference 9999   //微信息索引序列时间;
#define cRTNode(pointer) PitIsAlg(pointer) ? cRTAlgNode : cRTOtherNode //节点缓存时间
#define cRTAlgNode 3600     //概念node时间(1小时)
#define cRTOtherNode 200    //别的node时间(200秒)
#define cRTDefault 60       //默认,例如:小脑canout序列;
#define cRTPort 200         //refPorts(概念),absPorts,conPorts的时间;
#define cRTMvRef 600        //mv方向索引时间;

//MARK:===============================================================
//MARK:                     < thinkingControl >
//MARK:===============================================================
#define cAssDataLimit 2 //应以当前整体思维活跃度,变化为1-3左右;
#define cMinEnergy 0 //思维活力限低
#define cMaxEnergy 20 //思维活力限高
#define cShortMemoryLimit 4 //瞬时记忆最多8条 (20200329训练内类比时,8->4,因为估计4条足够v2.0用了);
//#define cActiveCacheLimit 50//激活缓存最多50条; (废弃,因为改为瞬时匹配模型)

//MARK:===============================================================
//MARK:                     < ThinkOut >
//MARK:===============================================================
#define cDataOutAssFoCount 3    //在决策过程中,foScheme横向最大检索条数;
#define cDataOutAssFoDeep 3     //在决策过程中,foScheme纵向最大检索深度;

#define cDataOutAssAlgCount 5   //在决策过程中,algScheme横向最大检索条数;
#define cDataOutAssAlgDeep 2    //在决策过程中,algScheme纵向最大检索深度;

#define cHavNoneAssFoCount 5    //Hav和None在联想其fo时,最大条数 (getInnerV3迭代后,不需要refPorts了,所以废弃);
#define cGetInnerAbsLayer 2     //getInner()中,Alg纵向尝试layer层 (20210514改成2,因为1和8层也会直接抽具象关联);
#define cGetInnerAbsCount 3     //getInner()中,Alg纵向每层取limit个;
#define cGetInnerByAlgCount 3   //getInnerHN()中,type嵌套取limit条;
#define cGetInnerByFoCount 3    //getInnerGL()中,type嵌套取limit条;

#define cTOSubModelLimit 2      //在决策中,子模型limit

#define cMCValue_AbsAssLimit 10 //在MC匹配稀疏码模糊匹配时,向抽象联想个数
#define cMCValue_ConAssLimit 20 //在MC匹配稀疏码模糊匹配时,向具象联想个数
#define cPM_RefLimit 20         //在PM理性评价时,取refPorts的个数 (参考20063-A2示图)
#define cPM_CheckRefLimit 4     //在PM理性评价时,检查有效(有mv指向)refPorts的个数
#define cPM_CheckSPFoLimit 100    //在PM理性评价时,检查SP时序的个数

#define cTOPPModeConAssLimit 5  //在TOP的P模式下,下具象联想的条数

#define cRethinkActBack_AssSPFoLimit 3 //反省_联想ATSubFo的数量
#define cDemandDeepLimit 8 //短时记忆树最高demand层数;


//MARK:===============================================================
//MARK:                     < ThinkIn >
//MARK:===============================================================
#define cMvNoneIdent @"mvNone"      //mv的默认标识

/**
 *  MARK:--------------------局部匹配时,检查refPorts数--------------------
 *  @version
 *      2020.07.20: 概念经历太多时,10个太少找不到本该出现的结果,所以改成IntMax,因为无性能问题
 *      2022.06.07: V.refA取30% (参考2619j-TODO1);
 */
#define cPartMatchingCheckRefPortsLimit_Alg(refCount) MAX(refCount * 0.3f, 5)
#define cPartMatchingThreshold 0.3  //局部匹配时_匹配阀值 (相似度) 20191224ALG改为全含方式 FO懒先不改
#define cTIRFoAbsIndexLimit 5       //时序识别时,取抽象索引的条数

//MARK:===============================================================
//MARK:                     < 窄出 >
//MARK:===============================================================
#define cIndexNarrowLimit 1000  //所以每个稀疏码的精度,不允许大于1k;
#define cRFoNarrowLimit 0
#define cSolutionNarrowLimit 5

//MARK:===============================================================
//MARK:                     < third & demo >
//MARK:===============================================================
#define cWedis2DBInterval 600 //2023.07.20: 因多线程常闪退,这里先调成5测段时间;
#define cHeLog2DBInterval 20
#define heLogSwitch false //heLog默认开关;
#define tomV2Switch false //tv默认开关;
#define defaultScore NSNotFound //默认评分值 (一般用于判断评分是否已经评过,比如用于缓存时只计算一次判断);
#define defaultMatchValue NSNotFound //默认相似度

//MARK:===============================================================
//MARK:                     < 需要改变值的配置 >
//MARK:===============================================================

//不打印NSLog日志开关
static BOOL cNSLogSwitch = true;
#define cNSLogSwitchIsOpenTypes @[@"TI",@"TO",@"MA",@"OT"]
