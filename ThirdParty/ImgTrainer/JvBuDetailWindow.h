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

-(void) show:(AIFeatureJvBuModel*)jvBuModel;
-(void) close;

@end
