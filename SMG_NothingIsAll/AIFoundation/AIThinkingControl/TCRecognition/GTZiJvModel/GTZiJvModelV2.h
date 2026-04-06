#import <Foundation/Foundation.h>

@interface GTZiJvModelV2 : NSObject

@property (strong, nonatomic) AIGroupFeatureNode *baseGT;
@property (strong, nonatomic) NSMutableDictionary *bestSTs; // GT时为Dic<stIndex, STZiJvModelV2>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newBestIndex;
-(CGRect) hopeProtoRectByAll;
@property (assign, nonatomic) CGRect hopeProtoRectByAllCache; // 复用结果，但每次best有更新时，手动将此值清空，使之可以重算。

/**
 *  MARK:--------------------主因子：匹配度--------------------
 */
-(void) run4GTMatchValue;
@property (assign, nonatomic) CGFloat gtMatchValue;

/**
 *  MARK:--------------------辅因子：位置符合度（参考36045）--------------------
 */
-(void) run4GTMatchDegree;
@property (assign, nonatomic) CGFloat gtMatchDegree;

/**
 *  MARK:--------------------辅因子：元素数归一化值（防过抽：因为只有具象的匹配数count才可能长）--------------------
 */
-(void) run4GTMatchCountRatio;
@property (assign, nonatomic) CGFloat gtMatchCountRatio;

/**
 *  MARK:--------------------ST时的位置符合度：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchDegree;
@property (assign, nonatomic) CGFloat stMatchDegree;

/**
 *  MARK:--------------------ST时的匹配率：作用于GT识别竞争因子--------------------
 */
-(void) run4STMatchCountRatio;
@property (assign, nonatomic) CGFloat stMatchCountRatio;

/**
 *  MARK:--------------------匹配率V2：直接按bestGVs总数 / GT的总gv数--------------------
 */
-(void) run4MatchCountRatioV2;
@property (assign, nonatomic) CGFloat matchCountRatioV2;

/**
 *  MARK:--------------------匹配数归一化值--------------------
 */
-(void) run4CountRatio:(NSInteger)max;
@property (assign, nonatomic) CGFloat countRatio;

/**
 *  MARK:--------------------辅因子：完整性（参考36143-方案）--------------------
 */
-(void) run4IntactRate_All:(CGFloat)protoGTArea;
@property (assign, nonatomic) CGFloat intactRate_All;

-(void) run4IntactRate_Proto:(CGFloat)protoGTArea;
@property (assign, nonatomic) CGFloat intactRate_Proto;

/**
 *  MARK:--------------------辅因子：稳定性（参考36145-方案）--------------------
 */
-(void) run4AverageContentStrong;
@property (assign, nonatomic) CGFloat averageContentStrong;

// GTModel综合评分（用于GT识别竞争）。
-(CGFloat) zonHeScore;

// GTModel综合评分的描述。
-(NSString*) zonHeDesc;

// assST的抽象中，被bestGVs全含的部分（即必能与当前ProtoGT的匹配的absST）。
-(void) run4GTValidAbs_ps;
@property (strong, nonatomic) NSArray *validAbs_ps;

@end
