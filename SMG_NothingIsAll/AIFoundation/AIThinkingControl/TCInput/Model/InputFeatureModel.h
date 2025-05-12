//
//  InputFeatureModel.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/5/12.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InputFeatureModel : NSObject

+(id) new:(AIKVPointer*)feature_p rect:(CGRect)rect;

@property (assign, nonatomic) CGRect rect;//单特征组成组特征中的范围
@property (strong, nonatomic) AIKVPointer *feature_p;//单特征。

@end
