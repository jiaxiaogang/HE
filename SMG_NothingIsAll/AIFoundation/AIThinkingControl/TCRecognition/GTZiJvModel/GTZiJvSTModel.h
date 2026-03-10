//
//  GTZiJvSTModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTZiJvSTModel : NSObject

@property (strong, nonatomic) AIFeatureNode *baseST;
@property (strong, nonatomic) NSMutableArray *items; // List<GTZiJvSTItem>

@end
