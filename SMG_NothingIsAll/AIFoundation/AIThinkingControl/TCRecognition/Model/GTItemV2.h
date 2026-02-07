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

//MARK:===============================================================
//MARK: < 显著度：因为通路是ass,abs,bro，所以显著度有两个值（参考36019-步骤2&3）>
//MARK:===============================================================

// 对于assST的显著程度（参考36021-TODO1）。
-(CGFloat) beAssSTStrongRatio;
@property (assign, nonatomic) CGFloat beAssSTStrongRatioCache;

// 对于broST的显著程度（参考36021-TODO2）。
-(CGFloat) beBroSTStrongRatio;
@property (assign, nonatomic) CGFloat beBroSTStrongRatioCache;

@end
