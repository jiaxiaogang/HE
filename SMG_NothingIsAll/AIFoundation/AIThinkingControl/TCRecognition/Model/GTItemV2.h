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
 *  @desc 用于GT识别V7算法：在v7中broST其实就是assGT的元素（参考36013-示图）。
 */
@interface GTItemV2 : NSObject

@property (strong, nonatomic) AIFeatureJvBuModel *baseSTModel; // 对应的stModel
@property (strong, nonatomic) AIFeatureNode *baseAbsST;
@property (strong, nonatomic) AIGroupFeatureNode *baseAssGT;
@property (assign, nonatomic) NSInteger broSTIndex;
@property (assign, nonatomic) CGFloat matchValue;

-(CGRect) assST_ProtoT;

-(CGRect) broST_AssGT;

-(CGRect) absST_ProtoT;
@property (assign, nonatomic) CGRect absST_ProtoTCache;

-(CGRect) broST_ProtoT;
@property (assign, nonatomic) CGRect broST_ProtoTCache;

@end
