//
//  GTZiJvGroups.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTZiJvGroups : NSObject

@property (strong, nonatomic) AIFeatureNode *baseT; // GT时为GT ST时为ST
@property (strong, nonatomic) NSMutableArray *groups; // List<GTZiJvGroup>

// GT时为st_Proto ST时为gv_Proto
@property (assign, nonatomic) CGRect validAbsST_Proto;

@end
