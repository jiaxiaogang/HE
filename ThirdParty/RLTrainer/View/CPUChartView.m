//
//  CPUChartView.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/10.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "CPUChartView.h"
#import "DeviceUtil.h"

@implementation CPUChartView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _dataArray = [[NSMutableArray alloc] init];
        [self setBackgroundColor:[UIColor clearColor]];
        
        //启动CPU监控定时器 (每1秒采集一次)
        self.cpuTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCpuData) userInfo:nil repeats:YES];
        [self.cpuTimer fire];
    }
    return self;
}

-(void)updateCpuData {
    //获取当前CPU占用率
    double cpuUsage = [DeviceUtil getCpuUsage];
    
    //限制最大值不超过100
    if (cpuUsage > 100) cpuUsage = 100;
    if (cpuUsage < 0) cpuUsage = 0;
    
    //添加到数据数组
    [self.dataArray addObject:@(cpuUsage)];
    
    //保持最多60秒的数据
    while (self.dataArray.count > 60) {
        [self.dataArray removeObjectAtIndex:0];
    }
    
    //刷新图表显示
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
    if (self.dataArray.count == 0) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    CGFloat width = rect.size.width;
    CGFloat height = rect.size.height;
    CGFloat padding = 2;
    
    //绘制背景 (半透明黑色)
    CGContextSetFillColorWithColor(context, [[UIColor colorWithWhite:0.2 alpha:0.6] CGColor]);
    CGContextFillRect(context, rect);
    
    //绘制网格线
    CGContextSetStrokeColorWithColor(context, [[UIColor colorWithWhite:0.5 alpha:0.5] CGColor]);
    CGContextSetLineWidth(context, 0.5);
    for (int i = 1; i < 4; i++) {
        CGFloat y = padding + (height - 2 * padding) * i / 4;
        CGContextMoveToPoint(context, padding, y);
        CGContextAddLineToPoint(context, width - padding, y);
    }
    CGContextStrokePath(context);
    
    //绘制CPU曲线
    if (self.dataArray.count >= 2) {
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextSetLineJoin(context, kCGLineJoinRound);
        CGFloat stepX = (width - 2 * padding) / 59.0;
        
        //最多60个点
        //从左到右绘制折线
        for (NSInteger i = 0; i < self.dataArray.count - 1; i++) {
            double cpu1 = [self.dataArray[i] doubleValue];
            double cpu2 = [self.dataArray[i + 1] doubleValue];
            CGFloat x1 = padding + stepX * i;
            CGFloat y1 = height - padding - (height - 2 * padding) * cpu1 / 100.0;
            CGFloat x2 = padding + stepX * (i + 1);
            CGFloat y2 = height - padding - (height - 2 * padding) * cpu2 / 100.0;
            
            //限制y值在有效范围内
            y1 = MAX(padding, MIN(height - padding, y1));
            y2 = MAX(padding, MIN(height - padding, y2));
            CGContextMoveToPoint(context, x1, y1);
            CGContextAddLineToPoint(context, x2, y2);
        }
        CGContextStrokePath(context);
    }
    
    //显示当前CPU值
    double lastCpu = [self.dataArray.lastObject doubleValue];
    NSString *cpuStr = [NSString stringWithFormat:@"%.0f%%", lastCpu];
    NSDictionary *attr = @{NSFontAttributeName: [UIFont systemFontOfSize:9],NSForegroundColorAttributeName: [UIColor whiteColor]};
    CGSize strSize = [cpuStr sizeWithAttributes:attr];
    [cpuStr drawAtPoint:CGPointMake((width - strSize.width) / 2, (height - strSize.height) / 2) withAttributes:attr];
}

-(void)dealloc {
    [self.cpuTimer invalidate];
    self.cpuTimer = nil;
}

@end
