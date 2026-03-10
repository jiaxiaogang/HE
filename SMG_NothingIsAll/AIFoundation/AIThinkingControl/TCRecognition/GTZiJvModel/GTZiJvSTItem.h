//
//  GTZiJvSTItem.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/3/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GTZiJvSTItem : NSObject

@property (strong, nonatomic) AIFeatureNode *baseST;
@property (strong, nonatomic) NSMutableArray *gvs; // List<AIFeatureJvBuItem>

// 根据已知oldGVs，预计newGV的protoRect（即：用已知protoRects，计算出整体protoRect）。
-(CGRect) hopeProtoRectByIndex:(NSInteger)newGVIndex;

@end
