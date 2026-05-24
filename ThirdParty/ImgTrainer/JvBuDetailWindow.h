//
//  JvBuDetailWindow.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/22.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AIFeatureJvBuModel;

@interface JvBuDetailWindow : UIView

-(void) setData4JvBuModel:(AIFeatureJvBuModel*)jvBuModel;
-(void) setData4JvBuItem:(AIFeatureJvBuItem*)jvBuItem;
-(void) close;

@end
