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

@end
