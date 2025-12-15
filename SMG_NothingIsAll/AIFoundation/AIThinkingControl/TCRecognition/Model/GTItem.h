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

+(id) new:(NSInteger)protoIndex assIndex:(NSInteger)assIndex curST_ProtoGT:(CGRect)curST_ProtoGT curST_AssGT:(CGRect)curST_AssGT;
@property (assign, nonatomic) NSInteger protoIndex;
@property (assign, nonatomic) NSInteger assIndex;
@property (assign, nonatomic) CGRect curST_ProtoGT;
@property (assign, nonatomic) CGRect curST_AssGT;

-(CGFloat) wRate;
-(CGFloat) hRate;
-(CGFloat) xDelta;
-(CGFloat) yDelta;

@property (assign, nonatomic) CGFloat itemMatchDegree;
-(void) run4ItemMatchDegree:(GTModel*)baseGTModel;

@end
