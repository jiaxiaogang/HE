//
//  DeviceUtil.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/9.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "DeviceUtil.h"
#import <mach/mach.h>
#import <mach/processor_info.h>

@implementation DeviceUtil

//获取当前iOS进程CPU占用率 (0-100)
+(double)getCpuUsage {
    task_t task = mach_task_self();

    //获取线程列表
    thread_act_array_t threadList;
    mach_msg_type_number_t threadCount;
    kern_return_t err = task_threads(task, &threadList, &threadCount);
    if (err != KERN_SUCCESS) return 0.0;

    //累加所有线程的CPU使用率 (cpu_usage 是所有核心的累计值)
    integer_t totalCpu = 0;
    for (mach_msg_type_number_t i = 0; i < threadCount; i++) {
        thread_basic_info_data_t threadInfo;
        mach_msg_type_number_t threadInfoCount = THREAD_BASIC_INFO_COUNT;

        err = thread_info(threadList[i], THREAD_BASIC_INFO, (thread_info_t)&threadInfo, &threadInfoCount);
        if (err == KERN_SUCCESS) {
            totalCpu += threadInfo.cpu_usage;
        }
    }

    //释放线程列表
    vm_size_t threadListSize = threadCount * sizeof(thread_t);
    vm_deallocate(mach_task_self(), (vm_address_t)threadList, threadListSize);

    //cpu_usage 是以 TH_USAGE_SCALE (1000) 为基准的百分比 * 核心数
    // NSInteger processorCount = [[NSProcessInfo processInfo] processorCount]; // CPU核心数
    double usage = (double)totalCpu / (double)TH_USAGE_SCALE * 100.0;
    return usage;
}

@end
