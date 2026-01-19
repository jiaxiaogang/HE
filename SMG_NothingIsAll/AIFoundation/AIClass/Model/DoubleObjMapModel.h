//
//  DoubleObjMapModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/12/18.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoubleObjMapModel : NSObject

+(DoubleObjMapModel*) newWithDoubleValue:(double)doubleValue obj:(id)obj;

@property (assign, nonatomic) double doubleValue;
@property (strong, nonatomic) id obj;

@end
