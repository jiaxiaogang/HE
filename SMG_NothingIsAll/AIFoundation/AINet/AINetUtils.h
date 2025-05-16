//
//  AINetUtils.h
//  SMG_NothingIsAll
//
//  Created by jiaxiaogang on 2018/9/30.
//  Copyright © 2018年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AIAbsAlgNode,AINetAbsFoNode,AIAbsCMVNode,AISPStrong,AIGroupValueNode,AIFeatureNode;
@interface AINetUtils : NSObject

//MARK:===============================================================
//MARK:                     < CanOutput >
//MARK:===============================================================

/**
 *  MARK:--------------------检查是否可以输出algsType&dataSource--------------------
 *  1. 有过输出记录,即可输出;
 */
+(BOOL) checkCanOutput:(NSString*)dataSource;


/**
 *  MARK:--------------------标记canout--------------------
 *  @param identify     : 输出标识 (algsType不需要,因为都是Output)
 */
+(void) setCanOutput:(NSString*)identify ;

//MARK:===============================================================
//MARK:                     < Other >
//MARK:===============================================================

/**
 *  MARK:--------------------检查conAlgs指针isOut都是true--------------------
 */
+(BOOL) checkAllOfOut:(NSArray*)conAlgs;

/**
 *  MARK:--------------------获取具象关联最强的强度--------------------
 */
+(NSInteger) getConMaxStrong:(AINodeBase*)node;
+(NSInteger) getMaxStrong:(NSArray*)ports;

/**
 *  MARK:--------------------获取absNode被conNode指向的强度--------------------
 */
+(NSInteger) getStrong:(AINodeBase*)absNode atConNode:(AINodeBase*)conNode type:(AnalogyType)type;

/**
 *  MARK:--------------------是否虚mv--------------------
 */
+(BOOL) isVirtualMv:(AIKVPointer*)mv_p;

/**
 *  MARK:--------------------获取mv的delta--------------------
 */
+(NSInteger) getDeltaFromMv:(AIKVPointer*)mv_p;


//MARK:===============================================================
//MARK:                     < 取at&ds&type >
//MARK:===============================================================

/**
 *  MARK:--------------------从conNodes中取at&ds&type--------------------
 */
+(AnalogyType) getTypeFromConNodes:(NSArray*)conNodes;
+(NSString*) getDSFromConNodes:(NSArray*)conNodes type:(AnalogyType)type;
+(NSString*) getATFromConNodes:(NSArray*)conNodes type:(AnalogyType)type;

//MARK:===============================================================
//MARK:                     < pointer >
//MARK:===============================================================
+(BOOL) equal4PitA:(AIPointer*)pitA pitB:(AIPointer*)pitB;
+(BOOL) equal4Mv:(AIKVPointer*)mv_p alg_p:(AIKVPointer*)alg_p;

@end



@interface AINetUtils (Insert)

//MARK:===============================================================
//MARK:                     < 引用插线 (外界调用,支持alg/fo/mv) >
//MARK:===============================================================

/**
 *  MARK:--------------------通用ref插线方法--------------------
 */
+(void) insertRefPorts_General:(AIKVPointer*)node_p content_ps:(NSArray*)content_ps difStrong:(NSInteger)difStrong header:(NSString*)header;

/**
 *  MARK:--------------------概念_引用_微信息--------------------
 *  @desc               : 将algNode插线到value_ps的refPorts
 *  @param algNode_p    : 引用微信息的algNode
 *  @param content_ps   : 微信息组 (需要去重)
 *  @paramer ps         : 生成md5的ps (需要有序)
 *  @param difStrong    : 构建具象alg时,默认为1,构建抽象时,默认为具象节点数(这个以后不合理再改规则,比如改为平均,或者具象强度之和等);
 */
+(void) insertRefPorts_AllAlgNode:(AIKVPointer*)algNode_p content_ps:(NSArray*)content_ps difStrong:(NSInteger)difStrong;


/**
 *  MARK:--------------------时序_引用_概念--------------------
 *  @desc               : 将algNode插线到value_ps的refPorts
 *  @param foNode_p     : 引用algNode的foNode
 *  @param order_ps     : orders节点组 (需要去重)
 *  @param ps           : 生成md5的ps (本来就有序)
 */
+(void) insertRefPorts_AllFoNode:(AIKVPointer*)foNode_p order_ps:(NSArray*)order_ps ps:(NSArray*)ps;
+(void) insertRefPorts_AllFoNode:(AIKVPointer*)foNode_p order_ps:(NSArray*)order_ps ps:(NSArray*)ps difStrong:(NSInteger)difStrong;

/**
 *  MARK:--------------------mv_引用_微信息--------------------
 *  @param difStrong    : mvNode的方向索引序列传urgent正相关值 / delta和urgent传1;
 *  @param value_p      : 有三种值; 1:delta 2:urgent 3:DirectionReference地址;
 *  注:目前在使用NetRefrence,所以此处不用;
 */
+(void) insertRefPorts_AllMvNode:(AICMVNodeBase*)mvNode value_p:(AIPointer*)value_p difStrong:(NSInteger)difStrong;

//MARK:===============================================================
//MARK:                     < 找出port >
//MARK:===============================================================
+(AIPort*) findPort:(AIKVPointer*)pointer fromPorts:(NSArray*)fromPorts findParams:(NSDictionary*)findParams;

//MARK:===============================================================
//MARK:                     < 抽具象关联 Relate (外界调用,支持alg/fo) >
//MARK:===============================================================

/**
 *  MARK:--------------------关联具象部分--------------------
 *  @param absNode  : 抽象概念
 *  @param conNodes : 具象概念们
 *  注: 抽具象的difStrong默认都为1;
 */
+(void) relateFeatureAbs:(AIFeatureNode*)absNode conNodes:(NSArray*)conNodes isNew:(BOOL)isNew;
+(void) relateAlgAbs:(AIAlgNodeBase*)absNode conNodes:(NSArray*)conNodes isNew:(BOOL)isNew;
+(void) relateFoAbs:(AIFoNodeBase*)absNode conNodes:(NSArray*)conNodes isNew:(BOOL)isNew;
+(void) relateMvAbs:(AIAbsCMVNode*)absNode conNodes:(NSArray*)conNodes isNew:(BOOL)isNew;

+(void) relateFoAbs:(AINetAbsFoNode*)absNode conNodes:(NSArray*)conNodes isNew:(BOOL)isNew strongPorts:(NSArray*)strongPorts;
+(void) relateGeneralAbs:(AINodeBase*)absNode absConPorts:(NSMutableArray*)absConPorts conNodes:(NSArray*)conNodes isNew:(BOOL)isNew difStrong:(NSInteger)difStrong;

/**
 *  MARK:--------------------关联抽象通用方法 (参考29031-todo3)--------------------
 */
+(void) relateGeneralCon:(AINodeBase*)conNode absNodes:(NSArray*)absNode_ps;

//MARK:===============================================================
//MARK:                     < 关联mv基本模型 >
//MARK:===============================================================
+(void) relateFo:(AIFoNodeBase*)foNode mv:(AICMVNodeBase*)mvNode;

@end


//MARK:===============================================================
//MARK:                     < Port >
//MARK:===============================================================
@interface AINetUtils (Port)

/**
 *  MARK:--------------------取hdAbsPorts + memAbsPorts--------------------
 *  @result notnull
 */
+(NSArray*) absPorts_All:(AINodeBase*)node;
+(NSArray*) absPorts_All_Normal:(AINodeBase*)node;
+(NSArray*) absPorts_All:(AINodeBase*)node type:(AnalogyType)type;
+(NSArray*) absPorts_All:(AINodeBase*)node havTypes:(NSArray*)havTypes noTypes:(NSArray*)noTypes;

/**
 *  MARK:--------------------返回abs+自己的指针数组--------------------
 */
+(NSArray*) absAndMePits:(AINodeBase*)node;

/**
 *  MARK:--------------------取hdConPorts + memConPorts--------------------
 *  @result notnull
 */
+(NSArray*) conPorts_All:(AINodeBase*)node;
+(NSArray*) conPorts_All_Normal:(AINodeBase*)node;
+(NSArray*) conPorts_All:(AINodeBase*)node havTypes:(NSArray*)havTypes noTypes:(NSArray*)noTypes;

/**
 *  MARK:--------------------取hdRefPorts + memRefPorts--------------------
 *  @desc 目前仅支持alg,对于微信息的支持,随后再加;
 *  @result notnull
 */
+(NSArray*) refPorts_All4Alg:(AIAlgNodeBase*)node;
+(NSArray*) refPorts_All4Alg_Normal:(AIAlgNodeBase*)node;
+(NSArray*) refPorts_All4Value:(AIKVPointer*)value_p;
+(NSArray*) refPorts_All:(AIKVPointer*)node_p;

/**
 *  MARK:--------------------对fo.content.refPort标记havMv--------------------
 */
+(void) maskHavMv_AlgWithFo:(AIFoNodeBase*)foNode;

@end

//MARK:===============================================================
//MARK:                     < Node >
//MARK:===============================================================
@interface AINetUtils (Node)

/**
 *  MARK:--------------------获取cutIndex--------------------
 */
+(NSInteger) getCutIndexByIndexDic:(NSDictionary*)indexDic;
+(NSInteger) getCutIndexByIndexDicV2:(NSDictionary*)indexDic protoOrRegroupCutIndex:(NSInteger)protoOrRegroupCutIndex;

/**
 *  MARK:--------------------获取near数据 (直传fo版)--------------------
 */
+(CGFloat) getMatchByIndexDic:(NSDictionary*)indexDic absFo:(AIKVPointer*)absFo_p conFo:(AIKVPointer*)conFo_p callerIsAbs:(BOOL)callerIsAbs;
+(NSArray*) getNearDataByIndexDic:(NSDictionary*)indexDic absFo:(AIKVPointer*)absFo_p conFo:(AIKVPointer*)conFo_p callerIsAbs:(BOOL)callerIsAbs;

//不传indexDic时,默认从abs和con取全部indexDic复用之;
+(CGFloat) getMatchByIndexDic:(AIKVPointer*)absFo_p conFo:(AIKVPointer*)conFo_p callerIsAbs:(BOOL)callerIsAbs;

/**
 *  MARK:--------------------获取near数据 (回调版)--------------------
 */
+(NSArray*) getNearDataByIndexDic:(NSDictionary*)indexDic getAbsAlgBlock:(AIKVPointer*(^)(NSInteger absIndex))getAbsAlgBlock getConAlgBlock:(AIKVPointer*(^)(NSInteger conIndex))getConAlgBlock callerIsAbs:(BOOL)callerIsAbs;

//MARK:===============================================================
//MARK:                     < Fo引用强度RefStrong的取值和更新 >
//MARK:===============================================================

/**
 *  MARK:--------------------获取sumRefStrong已发生部分强度--------------------
 */
+(NSInteger) getSumRefStrongByIndexDic:(NSDictionary*)indexDic matchFo:(AIKVPointer*)matchFo_p;

/**
 *  MARK:--------------------根据indexDic更新refPort强度值 (参考2722f-todo33)--------------------
 */
+(void) updateRefStrongByIndexDic:(NSDictionary*)indexDic matchFo:(AIKVPointer*)matchFo_p;

/**
 *  MARK:--------------------根据indexDic更新contentPort强度值 (参考2722f-todo32)--------------------
 */
+(void) updateContentStrongByIndexDic:(NSDictionary*)indexDic matchFo:(AIKVPointer*)matchFo_p;

//MARK:===============================================================
//MARK:                     < Alg抽具象强度ConStrong的取值和更新 >
//MARK:===============================================================

/**
 *  MARK:--------------------获取sumConStrong已发生部分强度--------------------
 */
+(NSInteger) getSumConStrongByIndexDic:(NSDictionary*)indexDic matchFo:(AIKVPointer*)matchFo_p cansetFo:(AIKVPointer*)cansetFo_p;

/**
 *  MARK:--------------------根据indexDic更新conPort和absPort强度值 (参考28086)--------------------
 */
+(void) updateConAndAbsStrongByIndexDic:(NSDictionary*)indexDic matchFo:(AIKVPointer*)matchFo_p cansetFo:(NSArray*)cansetToOrders;

//MARK:===============================================================
//MARK:                     < Alg引用强度RefStrong更新 >
//MARK:===============================================================

/**
 *  MARK:--------------------根据indexDic更新refPort强度值 (参考28103-3)--------------------
 */
+(void) updateAlgRefStrongByIndexArr:(NSArray*)indexArr foContent_ps:(NSArray*)foContent_ps;

/**
 *  MARK:--------------------类比出absFo时,此处取得具象fo与absFo的indexDic映射--------------------
 */
+(NSDictionary*) getIndexDic4AnalogyAbsFo:(NSArray*)conFoIndexes;

//MARK:===============================================================
//MARK:                     < 抽象Fo时,更新SP值 >
//MARK:===============================================================

/**
 *  MARK:--------------------absFo根据indexDic继承conFo的sp值 (参考29032-todo2.2)--------------------
 */
+(void) extendSPByIndexDic:(NSDictionary*)assIndexDic assFo:(AIFoNodeBase*)assFo absFo:(AIFoNodeBase*)absFo;

/**
 *  MARK:--------------------抽象fo时: 根据protoFo增强absFo的SP值+1 (参考29032-todo2.3)--------------------
 */
+(void) updateSPByIndexDic:(NSDictionary*)conIndexDic conFo:(AIFoNodeBase*)conFo absFo:(AIFoNodeBase*)absFo;

/**
 *  MARK:--------------------初始化itemOutSPDic (在canset类比抽象时) (参考33062-TODO4)--------------------
 */
+(NSDictionary*) getInitOutSPDicForAbsCanset:(AIFoNodeBase*)fCanset baseSceneContent_ps:(NSArray*)baseSceneContent_ps oldSolutionAbsCansetIndexDic:(NSDictionary*)oldSolutionAbsCansetIndexDic;

/**
 *  MARK:--------------------取outSPDic的key (参考33065-TODO1)--------------------
 */
+(NSString*) getOutSPKey:(NSArray*)content_ps;

@end

//MARK:===============================================================
//MARK:                     < Canset >
//MARK:===============================================================
@interface AINetUtils (Canset)

/**
 *  MARK:--------------------新增迁移关联--------------------
 */
+(void) relateTransfer_R:(AIFoNodeBase*)fScene fCanset:(AIFoNodeBase*)fCanset iScene:(AIFoNodeBase*)iScene iCanset:(NSArray*)cansetToContent_ps;

/**
 *  MARK:--------------------outSP子即父--------------------
 *  @desc 子即父,推举到F层SP也+1: iCanset的outSP更新时,将它的fCanset的outSP也+1 (参考33112-TODO4.3);
 */
+(void) updateOutSPStrong_4IF:(AIFoNodeBase*)fCanset iScene:(AIFoNodeBase*)iScene baseSceneToContent_ps:(NSArray*)baseSceneToContent_ps cansetToContent_ps:(NSArray*)cansetToContent_ps caller:(NSString*)caller spIndex:(NSInteger)spIndex difStrong:(NSInteger)difStrong type:(AnalogyType)type debugMode:(BOOL)debugMode except4SP2F:(NSMutableArray*)except4SP2F;

/**
 *  MARK:--------------------inSP子即父--------------------
 */
+(void) updateInSPStrong_4IF:(AIFoNodeBase*)conFo conSPIndex:(NSInteger)conSPIndex difStrong:(NSInteger)difStrong type:(AnalogyType)type except4SP2F:(NSMutableArray*)except4SP2F;

/**
 *  MARK:--------------------根据iScene取有迁移关联的father层--------------------
 */
//取哪些canset迁移成iCanset过;
+(NSArray*) transferPorts_4Father:(AIFoNodeBase*)iScene iCansetContent_ps:(NSArray*)iCansetContent_ps;

//取从fScene迁移过来iScene哪些canset;
+(NSArray*) transferPorts_4Father:(AIFoNodeBase*)iScene fScene:(AIFoNodeBase*)fScene;

/**
 *  MARK:--------------------各类型节点的header生成规则--------------------
 */
+(NSString*) getGroupValueNodeHeader:(NSArray*)content_ps;
+(NSString*) getFeatureNodeHeader:(NSArray*)content_ps rects:(NSArray*)rects;

/**
 *  MARK:--------------------把特征的一部分content转成rect（参考34133-TODO1）--------------------
 */
+(CGRect) convertAllOfFeatureContent2Rect:(AIFeatureNode*)tNode;
+(CGRect) convertPartOfFeatureContent2Rect:(AIFeatureNode*)tNode contentIndexes:(NSArray*)contentIndexes;

/**
 *  MARK:--------------------把组码在protoT中level,x,y转成最小粒度层的范围（参考34133-TODO1.2）--------------------
 */
+(CGRect) convertGVLevelXY2Rect:(NSInteger)level x:(NSInteger)x y:(NSInteger)y;

/**
 *  MARK:--------------------补上特征的conPort存rect--------------------
 */
+(void) updateConPortRect:(AIFeatureNode*)absT conT:(AIKVPointer*)conT rect:(CGRect)rect;
+(AIPort*) getConPort:(AINodeBase*)abs con:(AIKVPointer*)con;
+(AIPort*) getRefPort:(AIKVPointer*)sub biger:(AIKVPointer*)biger refRect:(CGRect)refRect;

@end
