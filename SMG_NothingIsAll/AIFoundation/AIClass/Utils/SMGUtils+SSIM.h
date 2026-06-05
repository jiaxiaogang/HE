//
//  SMGUtils+SSIM.h
//  SMG_NothingIsAll
//
//  Created by XiaoGang.
//

#import "SMGUtils.h"

@interface SMGUtils (SSIM)

// 计算两张图片的 SSIM 相似度（0.0~1.0，1.0=完全相同）
+ (CGFloat)ssimImage:(UIImage *)imageA image:(UIImage *)imageB;

@end
