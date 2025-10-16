//
//  AIMatchCansetModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2023/3/29.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------Canset单条识别结果--------------------
 */
@interface AIMatchCansetModel : NSObject

+(AIMatchCansetModel*) newWithMatchFo:(AIFoNodeBase*)matchFo indexDic:(NSDictionary*)indexDic;

//识别到的oldCansetFo;
@property (strong, nonatomic) AIFoNodeBase *matchFo;

//新旧Canset映射;
@property (strong, nonatomic) NSDictionary *indexDic;

@end
