//
//  TCInput.h
//  SMG_NothingIsAll
//
//  Created by jia on 2021/11/28.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCInput : NSObject

+(void) rInput:(AIAlgNodeBase*)algNode except_ps:(NSArray*)except_ps fuJia:(id)fuJia;
+(void) pInput:(AICMVNodeBase*)mv;
+(void) hInput:(TOAlgModel*)algModel;

@end
