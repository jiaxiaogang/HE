//
//  GTItem.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/9/23.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------GT识别模型--------------------
 */
@interface GTItem : NSObject

+(id) new:(NSInteger)protoIndex assIndex:(NSInteger)assIndex conST_ProtoGT:(CGRect)conST_ProtoGT conST_AssGT:(CGRect)conST_AssGT;
@property (assign, nonatomic) NSInteger protoIndex;
@property (assign, nonatomic) NSInteger assIndex;
@property (assign, nonatomic) CGRect conST_ProtoGT;
@property (assign, nonatomic) CGRect conST_AssGT;

-(CGFloat) wRate;
-(CGFloat) hRate;
-(CGFloat) getMatchDegree;

@end
