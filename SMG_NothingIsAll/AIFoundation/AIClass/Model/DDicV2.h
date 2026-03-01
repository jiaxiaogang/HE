//
//  DDicV2.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/1.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------DDic的优化版，写完未用过，未测--------------------
 */
@interface DDicV2 : NSMutableDictionary

-(id) objectForKeys:(NSArray*)keys;
-(void) setObject:(id)object forKeys:(NSArray*)keys;

@end
