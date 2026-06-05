//
//  ImvAlgsUnknownModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/6/5.
//  Copyright © 2026年 XiaoGang. All rights reserved.
//

#import "ImvBadModel.h"

/**
 *  MARK:--------------------未知恐惧模型--------------------
 *  @desc 识别不明确时，根据未知度构建任务的价值模型（参考38065-TODO1）；
 *        价值感很弱，只要有别的任务，几乎都比它强；
 */
@interface ImvAlgsUnknownModel : ImvBadModel

@end
