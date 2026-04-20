//
//  TCRecognitionUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2023/5/30.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCRecognitionUtil : NSObject

/**
 *  MARK:--------------------获取V重要性字典 (参考29105 & 29106)--------------------
 */
+(NSDictionary*) getVImportanceDic:(AIShortMatchModel*)inModel;

// gtGroups末尾淘汰。
+(NSMutableArray*) filter4ZonHe:(NSMutableArray*)allGTGroups;

@end
