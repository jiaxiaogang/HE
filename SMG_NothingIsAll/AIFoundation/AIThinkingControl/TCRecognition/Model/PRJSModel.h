//
//  PRJSModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/6/18.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRJSModel : NSObject

@property (strong, nonatomic) NSMutableArray *psArr;
@property (strong, nonatomic) NSMutableArray *rsArr;
@property (strong, nonatomic) NSMutableArray *pjArr;
@property (strong, nonatomic) NSMutableArray *rjArr;

@property (strong, nonatomic, readonly) NSArray *pArr;
@property (strong, nonatomic, readonly) NSArray *rArr;

@end
