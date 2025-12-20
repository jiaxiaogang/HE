//
//  DDic.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/10.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------嵌套字典--------------------
 */
@interface DDic : NSObject

@property (strong, nonatomic) NSMutableDictionary *data;

-(id) objectForKey:(id)key;
-(id) objectV2ForKey1:(id)k1 k2:(id)k2;
-(id) objectV3ForKey1:(id)k1 k2:(id)k2 k3:(id)k3;
-(id) objectV4ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4;
-(id) objectV5ForKey1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5;

-(void) setObject:(id)value forKey:(id)key;
-(void) setObjectV2:(id)v2 k1:(id)k1 k2:(id)k2;
-(void) setObjectV3:(id)v3 k1:(id)k1 k2:(id)k2 k3:(id)k3;
-(void) setObjectV4:(id)v4 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4;
-(void) setObjectV5:(id)v5 k1:(id)k1 k2:(id)k2 k3:(id)k3 k4:(id)k4 k5:(id)k5;

@end
