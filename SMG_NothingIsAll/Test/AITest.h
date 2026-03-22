//
//  AITest.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/9/25.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AITest : NSObject

//MARK:===============================================================
//MARK:               < 异常单元测试 (常开,有异常时停在断点) >
//MARK:===============================================================
+(void) test1:(NSString*)aDS hnAlgDS:(NSString*)hnAlgDS;
+(void) test2:(AIKVPointer*)pointer type:(AnalogyType)type at:(NSString*)at ds:(NSString*)ds;
+(void) test3:(AIKVPointer*)pointer type:(AnalogyType)type ds:(NSString*)ds;
+(void) test4:(AIKVPointer*)pointer at:(NSString*)at isOut:(BOOL)isOut;
+(void) test5:(AIKVPointer*)pointer type:(AnalogyType)type at:(NSString*)at;
+(void) test6:(NSArray*)types;
+(void) test7:(NSArray*)arr type:(AnalogyType)type;
+(void) test8:(NSArray*)content_ps type:(AnalogyType)type;
+(void) test9:(AIFoNodeBase*)fo type:(AnalogyType)type;
+(void) test10:(TOModelBase*)toModel;
+(void) test11:(AIShortMatchModel*)shortModel waitAlg_p:(AIKVPointer*)waitAlg_p;
+(void) test12:(CGFloat)score;//判断一个评分是否异常
+(void) test13:(NSArray*)slowSolutionCansets;
+(void) test14:(CGFloat)near;
+(void) test15:(AIMatchFoModel*)model;
+(void) test16:(CGFloat)algHDMatchValue;
+(void) test17;
+(void) test18:(NSDictionary*)newIndexDic newCanset:(AIFoNodeBase*)newCanset absFo:(AIFoNodeBase*)absFo;
+(void) test19:(AISPStrong*)newSPStrong;
+(void) test20:(AIFoNodeBase*)newCanset newSPDic:(NSDictionary*)newSPDic;
+(void) test21:(BOOL)refrectionResult;
+(void) test22;
+(void) test23:(NSDictionary*)pmDic cmDic:(NSDictionary*)cmDic matchIndex:(NSInteger)matchIndex;
+(void) test24:(NSArray*)absArrForEmptyAlgOfAbsCountCheck;
+(void) test25:(AINodeBase*)absNode conNodes:(NSArray*)conNodes;
+(void) test26:(NSDictionary*)matchDic checkA:(AIKVPointer*)checkA;
+(void) test27:(AIFoNodeBase*)sceneFo oldCanset:(AIKVPointer*)oldCanset_p oldIndexDic:(NSDictionary*)oldIndexDic compareIndexDicFromNewCanset:(NSDictionary*)compareIndexDicFromNewCanset;
+(void) test28:(AIShortMatchModel*)inModel;
+(void) test29:(AIAlgNodeBase*)protoA assA:(AIAlgNodeBase*)assA;
+(void) test30:(NSInteger)sumStrong;
+(void) test31:(NSArray*)deltaTimes;
+(void) test32:(AIFoNodeBase*)protoCanset newCanset:(AIFoNodeBase*)newCanset;
+(void) test33:(AIFoNodeBase*)iScene fScene:(AIKVPointer*)fScene;
+(void) test34:(NSDictionary*)indexDic;
+(void) test35:(NSDictionary*)oldIndexDic newK:(NSInteger)newK newV:(NSInteger)newV;
+(void) test36:(NSDictionary*)indexDic conNode:(AINodeBase*)conNode absNode:(AINodeBase*)absNode;

//MARK:===============================================================
//MARK:    < 回测必经点测试 (常关,每个轮回测时打开,触发则关,未触发者为异常) >
//MARK:===============================================================
+(void) test101:(NSArray*)absCansetOrders newCansetOrders:(NSArray*)newCansetOrders oldCansetOrder:(NSArray*)oldCansetOrder;
+(void) test102:(AIKVPointer*)cansetFrom_p;

@end
