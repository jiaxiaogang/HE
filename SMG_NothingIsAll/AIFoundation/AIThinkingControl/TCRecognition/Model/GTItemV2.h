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

@property (assign, nonatomic) NSInteger itemSTIndex;
@property (strong, nonatomic) AIFeatureJvBuModel *stModel; // 对应的stModel
@property (assign, nonatomic) CGRect itemST_AssGT;

-(CGRect) assST_ProtoGT;
-(CGRect) absST_ProtoGT;
-(CGRect) itemST_ProtoGT;

@end
