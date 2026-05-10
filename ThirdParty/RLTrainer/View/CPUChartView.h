//
//  CPUChartView.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPUChartView : UIView

@property (strong, nonatomic) NSTimer *cpuTimer;
@property (strong, nonatomic) NSMutableArray *dataArray;

@end
