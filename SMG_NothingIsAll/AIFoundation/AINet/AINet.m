//
//  AINet.m
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/9/17.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import "AINet.h"
#import "AIPointer.h"
#import "AINetIndex.h"
#import "AIMvFoManager.h"
#import "AIPort.h"
#import "AIAbsFoManager.h"
#import "AINetDirectionReference.h"
#import "AIAbsCMVManager.h"
#import "AIAbsCMVNode.h"
#import "AIKVPointer.h"
#import "AIFrontOrderNode.h"
#import "AINetUtils.h"
#import "AIAlgNodeManager.h"
#import "Output.h"
#import "AIAlgNode.h"
#import "NSString+Extension.h"
#import "AIAbsAlgNode.h"
#import "ThinkingUtils.h"

@interface AINet ()

//@property (strong, nonatomic) AINetIndex *netIndex; //索引区(皮层/海马)
@property (strong, nonatomic) AIMvFoManager *mvFoManager;     //网络树根(杏仁核)
@property (strong, nonatomic) AIAbsFoManager *absFoManager; //抽象时序管理器
@property (strong, nonatomic) AINetDirectionReference *netDirectionReference;
@property (strong, nonatomic) AIAbsCMVManager *absCmvManager;//抽象mv管理器;

@end


@implementation AINet

static AINet *_instance;
+(AINet*) sharedInstance{
    if (_instance == nil) {
        _instance = [[AINet alloc] init];
    }
    return _instance;
}


-(id) init{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

-(void) initData{
    //self.netIndex = [[AINetIndex alloc] init];
    self.mvFoManager = [[AIMvFoManager alloc] init];
    self.absFoManager = [[AIAbsFoManager alloc] init];
    self.netDirectionReference = [[AINetDirectionReference alloc] init];
    self.absCmvManager = [[AIAbsCMVManager alloc] init];
}


//MARK:===============================================================
//MARK:                     < index >
//MARK:===============================================================
-(NSMutableArray*) algModelConvert2Pointers:(NSDictionary*)modelDic algsType:(NSString*)algsType{
    //1. 数据准备
    NSMutableArray *algsArr = [[NSMutableArray alloc] init];
    modelDic = DICTOOK(modelDic);

    //2. 循环装箱
    for (NSString *dataSource in modelDic.allKeys) {

        //3. 存储索引 & data;
        NSNumber *data = NUMTOOK([modelDic objectForKey:dataSource]);
        AIPointer *pointer = [AINetIndex getDataPointerWithData:data algsType:algsType dataSource:dataSource isOut:false];
        if (pointer) {
            [algsArr addObject:pointer];
        }
    }
    return algsArr;
}

/**
 *  MARK:--------------------视觉V2模型特征处理--------------------
 *  @param splitDic 粒度字典 <K=level_x_y V=Number类型（比如H或S或B色值）>
 *  @desc
 *          1、压缩说明：把粒度树里，细一级九宫相似，则移除掉，只保留父级一格（并打包成组）（参考34042-分析3）。
 *          2、组码装箱：直接把未压缩掉的，有特异性的组，打包成组码节点。
 *          3、对组码进行x,y,level的排序。
 *  _param splitDic <K=level_x_y V=HSB值>
 *  @result <InputGroupValueModels>
 */
-(NSArray*) algModelConvert2PointersV2:(NSDictionary*)splitDic at:(NSString*)at ds:(NSString*)ds levelNum:(NSInteger)levelNum {
    //0. 数据准备：（把当前at&ds稀疏码的data值字典取出）（用于取值性能优化）。
    NSMutableArray *groupModels = [NSMutableArray new];
    
    //1. level为1-4层时，组应该用0-3，因为下层9格都是以上层为组（比如：0层就是1层的9格为组）。
    for (NSInteger groupLevel = 0; groupLevel < levelNum; groupLevel++) {
        
        //2. 每层的组边长（0层1组边长1，1层9组边长3，2层81组边长9，3层27x27组边长27）。
        int groupSize = powf(3, groupLevel);
        for (NSInteger groupRow = 0; groupRow < groupSize; groupRow++) {
            for (NSInteger groupColumn = 0; groupColumn < groupSize; groupColumn++) {
                
                //3. 根据组，向子一层取子9格。
                //每九宫装成一组，生成组码，组码可全局防重（参考34041-问题2-思路）。
                NSArray *subDots = [CortexAlgorithmsUtil getSub9DotFromSplitDic:groupLevel curRow:groupRow curColumn:groupColumn splitDic:splitDic];//取出子层9格色值。
                
                //4. 判断九格的相似度：两两对比，找出最不相似的。
                //2025.03.18：BUG-循环值时对比最大最小是不对的，应该找最不相似的。
                CGFloat minMatchValue = 1;
                for (NSInteger i = 0; i < subDots.count; i++) {
                    MapModel *iDot = ARR_INDEX(subDots, i);
                    NSNumber *iNumber = iDot.v1;
                    for (NSInteger j = i + 1; j < subDots.count; j++) {
                        MapModel *jDot = ARR_INDEX(subDots, j);
                        NSNumber *jNumber = jDot.v1;
                        BOOL loop = [CortexAlgorithmsUtil dsIsLoop:ds];
                        CGFloat itemMatchValue = [CortexAlgorithmsUtil matchValueOfCustomV1:iNumber.floatValue v2:jNumber.floatValue max:1 min:0 loop:loop];
                        if (itemMatchValue < minMatchValue) {
                            minMatchValue = itemMatchValue;
                        }
                    }
                }
                //NSLog(@"%ld_%ld_%ld %.2f",groupLevel,groupRow,groupColumn,minMatchValue);
                
                //5. 如果不是第一层，且9格很相似，防重掉(压缩)。
                if (groupLevel > 0 && (minMatchValue > 0.9 || !ARRISOK(subDots))) continue;
                
                //6. 先转成三个索引值。
                NSDictionary *protoGVIndexs = [AINetGroupValueIndex convertGVIndexData:subDots ds:ds];
                
                //11. 单码装箱
                NSArray *item_ps = [self algModelConvert2Pointers:protoGVIndexs algsType:at];
                
                //12. 打包成组码。
                //2025.04.28: 加上有序，避免以后各种映射交叉之类的问题，虽然现在GV没映射，用不着，但先有序存，备不时之需。
                item_ps = [SMGUtils sortPointers:item_ps];
                AIGroupValueNode *groupValue = [AIGeneralNodeCreater createGroupValueNode:item_ps conNodes:nil at:at ds:ds isOut:false];
                CGRect groupRect = [AINetUtils convertGVLevelXY2Rect:groupLevel x:groupRow y:groupColumn];//求出各个GV在T中的rect。
                [groupModels addObject:[InputGroupValueModel new:groupValue.p rect:groupRect]];
            }
        }
    }
    
    //11. 为增加特征content_ps的有序性：对groupModels进行排序。
    NSArray *sortGroupModels = [ThinkingUtils sortInputGroupValueModels:groupModels];
    return sortGroupModels;
}

//单data装箱
-(AIKVPointer*) getNetDataPointerWithData:(id)data algsType:(NSString*)algsType dataSource:(NSString*)dataSource isOut:(BOOL)isOut{
    return [AINetIndex getDataPointerWithData:data algsType:algsType dataSource:dataSource isOut:isOut];
}

//小脑索引
-(AIKVPointer*) getOutputIndex:(NSString*)algsType outputObj:(NSNumber*)outputObj {
    if (outputObj) {
        return [AINetIndex getDataPointerWithData:outputObj algsType:algsType dataSource:DefaultDataSource isOut:true];
    }
    return nil;
}


//MARK:===============================================================
//MARK:                     < cmv >
//MARK:===============================================================
-(AIFoNodeBase*) createCMVFo:(NSTimeInterval)inputTime order:(NSArray*)order mv:(AICMVNodeBase*)mv{
    return [self.mvFoManager create:inputTime order:order mv:mv];
}
-(AICMVNodeBase*) createConMv:(NSArray*)imvAlgsArr{
    return [self.mvFoManager createConMv:imvAlgsArr];
}
-(AICMVNodeBase*) createConMv:(AIKVPointer*)urgentTo_p delta_p:(AIKVPointer*)delta_p at:(NSString*)at {
    return [self.mvFoManager createConMv:urgentTo_p delta_p:delta_p at:at];
}


//MARK:===============================================================
//MARK:                     < conFo >
//MARK:===============================================================
/**
 *  MARK:--------------------构建conFo--------------------
 *  @result notnull
 */
-(AIFoNodeBase*) createConFo_NoRepeat:(NSArray*)order{
    return [AIMvFoManager createConFo_NoRepeat:order noRepeatArea_ps:nil difStrong:1];
}

-(AIFoNodeBase*) createConFoForCanset:(NSArray*)order sceneFo:(AIFoNodeBase*)sceneFo sceneTargetIndex:(NSInteger)sceneTargetIndex {
    return [AIMvFoManager createConFoForCanset:order sceneFo:sceneFo sceneTargetIndex:sceneTargetIndex];
}


//MARK:===============================================================
//MARK:                     < absFo >
//MARK:===============================================================
//-(AINetAbsFoNode*) createAbsFo_General:(NSArray*)conFos content_ps:(NSArray*)content_ps difStrong:(NSInteger)difStrong ds:(NSString*)ds{
//    return [self.absFoManager create:conFos orderSames:content_ps difStrong:difStrong dsBlock:^NSString *{
//        return ds;
//    }];
//}
-(HEResult*) createAbsFo_NoRepeat:(NSArray*)content_ps protoFo:(AIFoNodeBase*)protoFo assFo:(AIFoNodeBase*)assFo difStrong:(NSInteger)difStrong type:(AnalogyType)type protoIndexDic:(NSDictionary*)protoIndexDic assIndexDic:(NSDictionary*)assIndexDic outConAbsIsRelate:(BOOL*)outConAbsIsRelate noRepeatArea_ps:(NSArray*)noRepeatArea_ps{
    return [self.absFoManager create_NoRepeat:content_ps protoFo:protoFo assFo:assFo difStrong:difStrong type:type protoIndexDic:protoIndexDic assIndexDic:assIndexDic outConAbsIsRelate:outConAbsIsRelate noRepeatArea_ps:noRepeatArea_ps];
}

//MARK:===============================================================
//MARK:                     < directionReference >
//MARK:===============================================================

-(NSArray*) getNetNodePointersFromDirectionReference:(NSString*)mvAlgsType direction:(MVDirection)direction limit:(int)limit {
    return [self.netDirectionReference getNodePointersFromDirectionReference:mvAlgsType direction:direction limit:limit];
}

-(NSArray*) getNetNodePointersFromDirectionReference:(NSString*)mvAlgsType direction:(MVDirection)direction filter:(NSArray*(^)(NSArray *protoArr))filter{
    return [self.netDirectionReference getNodePointersFromDirectionReference:mvAlgsType direction:direction filter:filter];
}

-(void) setMvNodeToDirectionReference:(AICMVNodeBase*)cmvNode difStrong:(NSInteger)difStrong {
    //1. 数据检查
    if (cmvNode) {

        //2. 取方向(delta的正负)
        NSInteger delta = [NUMTOOK([AINetIndex getData:cmvNode.delta_p]) integerValue];
        MVDirection direction = [ThinkingUtils getMvReferenceDirection:delta];
        
        //3. 取mv方向索引;
        AIKVPointer *mvReference_p = [SMGUtils createPointerForDirection:cmvNode.pointer.algsType direction:direction];

        //4. 将mvNode地址,插入到强度序列,并存储;
        [AINetUtils insertRefPorts_AllMvNode:cmvNode value_p:mvReference_p difStrong:difStrong];
    }
}


//MARK:===============================================================
//MARK:                     < absCmv >
//MARK:===============================================================
-(AIAbsCMVNode*) createAbsCMVNode_Outside:(AIKVPointer*)absFo_p aMv_p:(AIKVPointer*)aMv_p bMv_p:(AIKVPointer*)bMv_p{
    return [self.absCmvManager create:absFo_p aMv_p:aMv_p bMv_p:bMv_p];
}


//MARK:===============================================================
//MARK:                     < algNode >
//MARK:===============================================================

/**
 *  MARK:--------------------构建抽象概念_防重--------------------
 */
-(AIAbsAlgNode*)createAbsAlg_NoRepeat:(NSArray*)value_ps conAlgs:(NSArray*)conAlgs {
    return [AIAlgNodeManager createAbsAlg_NoRepeat:value_ps conAlgs:conAlgs at:nil ds:nil isOutBlock:nil type:ATDefault];
}
-(AIAbsAlgNode*)createAbsAlg_NoRepeat:(NSArray*)value_ps conAlgs:(NSArray*)conAlgs at:(NSString*)at type:(AnalogyType)type{
    return [AIAlgNodeManager createAbsAlg_NoRepeat:value_ps conAlgs:conAlgs at:at ds:nil isOutBlock:nil type:type];
}
-(AIAbsAlgNode*)createAbsAlg_NoRepeat:(NSArray*)value_ps conAlgs:(NSArray*)conAlgs at:(NSString*)at ds:(NSString*)ds type:(AnalogyType)type{
    return [AIAlgNodeManager createAbsAlg_NoRepeat:value_ps conAlgs:conAlgs at:at ds:ds isOutBlock:nil type:type];
}
-(AIAbsAlgNode*)createAbsAlg_NoRepeat:(NSArray*)value_ps conAlgs:(NSArray*)conAlgs isOut:(BOOL)isOut at:(NSString*)at type:(AnalogyType)type{
    return [AIAlgNodeManager createAbsAlg_NoRepeat:value_ps conAlgs:conAlgs at:at ds:nil isOutBlock:^BOOL{
        return isOut;
    } type:type];
}
-(AIAbsAlgNode*)createAbsAlg_NoRepeat:(NSArray*)value_ps conAlgs:(NSArray*)conAlgs isOut:(BOOL)isOut at:(NSString*)at ds:(NSString*)ds type:(AnalogyType)type{
    return [AIAlgNodeManager createAbsAlg_NoRepeat:value_ps conAlgs:conAlgs at:at ds:ds isOutBlock:^BOOL{
        return isOut;
    } type:type];
}

/**
 *  MARK:--------------------构建空概念_防重 (参考29031-todo1)--------------------
 */
//-(AIAlgNodeBase*)createEmptyAlg_NoRepeat:(NSArray*)conAlgs {
//    return [AIAlgNodeManager createEmptyAlg_NoRepeat:conAlgs];
//}

@end
