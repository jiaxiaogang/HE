//
//  AIMatchCansetModel.m
//  SMG_NothingIsAll
//
//  Created by jia on 2023/3/29.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import "AIMatchCansetModel.h"

@implementation AIMatchCansetModel

+(AIMatchCansetModel*) newWithMatchFo:(AIFoNodeBase*)matchFo indexDic:(NSDictionary*)indexDic {
    AIMatchCansetModel *model = [[AIMatchCansetModel alloc] init];
    model.matchFo = matchFo;
    model.indexDic = indexDic;
    return model;
}

@end
