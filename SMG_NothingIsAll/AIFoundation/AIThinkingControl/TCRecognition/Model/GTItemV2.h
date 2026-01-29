//
//  GTItemV2.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/1/29.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------AssGT.itemST模型--------------------
 *  @desc 用于GT识别V7算法：在v7中itemST其实就是assST的broST（参考36013-示图）。
 */
@interface GTItemV2 : NSObject

@property (strong, nonatomic) AIFeatureJvBuModel *baseSTModel; // 对应的stModel
@property (strong, nonatomic) AIFeatureNode *baseAbsST;
@property (assign, nonatomic) NSInteger itemSTIndex;
@property (assign, nonatomic) CGRect itemST_AssGT;

-(CGRect) assST_ProtoT;
-(CGRect) absST_ProtoT;
-(CGRect) itemST_ProtoT;

@end
