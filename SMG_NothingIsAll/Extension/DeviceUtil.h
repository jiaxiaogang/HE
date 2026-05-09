//
//  DeviceUtil.h
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/9.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceUtil : NSObject

//获取当前iOS进程CPU占用率 (0-100)
+(double)getCpuUsage;

@end
