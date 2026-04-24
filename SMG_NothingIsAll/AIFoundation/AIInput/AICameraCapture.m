//
//  AICameraCapture.m
//  SMG_NothingIsAll
//
//  Created by Claude on 2026/4/24.
//

#import "AICameraCapture.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface AICameraCapture () <AVCapturePhotoCaptureDelegate>
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, strong) AVCaptureDeviceInput *deviceInput;
@property (nonatomic, copy) void (^captureCompletion)(UIImage *);
@end

@implementation AICameraCapture

static AICameraCapture *_instance;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[AICameraCapture alloc] init];
    });
    return _instance;
}

- (AVCaptureSession *)captureSession {
    if (!_captureSession) {
        // 检查模拟器
#if TARGET_IPHONE_SIMULATOR
        NSLog(@"AICameraCapture: 模拟器不支持摄像头");
        return nil;
#endif
        // 检查设备
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            NSLog(@"AICameraCapture: 设备没有摄像头");
            return nil;
        }

        _captureSession = [[AVCaptureSession alloc] init];
        _captureSession.sessionPreset = AVCaptureSessionPresetMedium;

        // 获取后置摄像头
        AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (!camera) {
            NSLog(@"AICameraCapture: 没有找到摄像头");
            return nil;
        }

        NSError *error = nil;
        _deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
        if (error) {
            NSLog(@"AICameraCapture: 摄像头输入错误: %@", error);
            return nil;
        }

        if ([_captureSession canAddInput:_deviceInput]) {
            [_captureSession addInput:_deviceInput];
        }

        // 添加照片输出
        _photoOutput = [[AVCapturePhotoOutput alloc] init];
        if ([_captureSession canAddOutput:_photoOutput]) {
            [_captureSession addOutput:_photoOutput];
        }
    }
    return _captureSession;
}

+ (void)startSession {
    // 检查模拟器
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"AICameraCapture: 模拟器不支持摄像头");
    return;
#endif

    // 检查摄像头权限
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // NSLog(@"AICameraCapture: 摄像头权限状态: %ld", (long)status);

    if (status == AVAuthorizationStatusNotDetermined) {
        // 第一次请求权限，会弹出系统弹窗
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            NSLog(@"AICameraCapture: 权限请求结果: %d", granted);
            if (granted) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    AICameraCapture *instance = [self sharedInstance];
                    if (instance.captureSession && !instance.captureSession.isRunning) {
                        [instance.captureSession startRunning];
                    }
                });
            } else {
                NSLog(@"AICameraCapture: 用户拒绝摄像头权限");
            }
        }];
    } else if (status == AVAuthorizationStatusAuthorized) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            AICameraCapture *instance = [self sharedInstance];
            if (instance.captureSession && !instance.captureSession.isRunning) {
                [instance.captureSession startRunning];
            }
        });
    } else {
        NSLog(@"AICameraCapture: 摄像头权限被拒绝, status=%ld", (long)status);
    }
}

+ (void)stopSession {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        AICameraCapture *instance = [self sharedInstance];
        if (instance.captureSession.isRunning) {
            [instance.captureSession stopRunning];
        }
    });
}

+ (void)capturePhotoWithCompletion:(void(^)(UIImage *))completion {
    if (!completion) return;

    AICameraCapture *instance = [self sharedInstance];
    instance.captureCompletion = completion;

    // 检查权限状态
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // NSLog(@"AICameraCapture: 拍照时权限状态: %ld", (long)status);

    if (status == AVAuthorizationStatusNotDetermined) {
        // 第一次请求权限
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            NSLog(@"AICameraCapture: 拍照时权限请求结果: %d", granted);
            if (granted) {
                [self doCapturePhoto];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil);
                });
            }
        }];
    } else if (status == AVAuthorizationStatusAuthorized) {
        [self doCapturePhoto];
    } else {
        NSLog(@"AICameraCapture: 权限被拒绝，无法拍照");
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil);
        });
    }
}

+ (void)doCapturePhoto {
    AICameraCapture *instance = [self sharedInstance];

    // 如果captureSession为nil，说明之前初始化失败
    if (!instance.captureSession) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (instance.captureCompletion) {
                instance.captureCompletion(nil);
                instance.captureCompletion = nil;
            }
        });
        return;
    }

    // 启动会话并拍照
    if (!instance.captureSession.isRunning) {
        [instance.captureSession startRunning];
    }

    // 等待一小段时间确保会话准备好
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [instance takePhoto];
    });
}

- (void)takePhoto {
    if (!_photoOutput) {
        [self callCompletionWithImage:nil];
        return;
    }

    // 直接使用默认设置，拍照后缩放到200x200
    // 这样兼容所有iOS版本
    AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];

    [_photoOutput capturePhotoWithSettings:settings delegate:self];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    if (error) {
        NSLog(@"AICameraCapture: 拍照错误: %@", error);
        [self callCompletionWithImage:nil];
        return;
    }

    NSData *imageData = [photo fileDataRepresentation];
    if (!imageData) {
        [self callCompletionWithImage:nil];
        return;
    }

    UIImage *image = [UIImage imageWithData:imageData];

    // 修正图片方向
    if (image) {
        image = [self fixImageOrientation:image];
    }

    // 缩放到200x200
    if (image) {
        UIImage *resized = [self resizeImage:image toSize:CGSizeMake(100, 100)]; // 向下切3的n次方宽高，比如100时视觉只处理81x81像素，因为当前九宫切图是按3倍数来粒度展开的。
        [self callCompletionWithImage:resized];
    } else {
        [self callCompletionWithImage:nil];
    }
}

- (UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size {
    // 1. 先裁剪成正方形（从中间裁剪）
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat squareSize = MIN(width, height);

    CGRect cropRect = CGRectMake((width - squareSize) / 2, (height - squareSize) / 2, squareSize, squareSize);

    CGImageRef cgImage = image.CGImage;
    CGImageRef croppedCGImage = CGImageCreateWithImageInRect(cgImage, cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedCGImage scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(croppedCGImage);

    // 2. 缩放到目标尺寸
    UIGraphicsBeginImageContextWithOptions(size, YES, 1.0);
    [croppedImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resized;
}

- (UIImage *)fixImageOrientation:(UIImage *)image {
    // NSLog(@"AICameraCapture: 原图方向=%ld, 尺寸=%@", (long)image.imageOrientation, NSStringFromCGSize(image.size));

    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }

    // 根据原始方向进行旋转
    UIImage *fixedImage = nil;
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            fixedImage = [self rotateImage:image angle:M_PI];
            break;
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            fixedImage = [self rotateImage:image angle:M_PI_2];
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            fixedImage = [self rotateImage:image angle:-M_PI_2];
            break;
        default:
            fixedImage = image;
            break;
    }

    // NSLog(@"AICameraCapture: 修正后方向=%ld", (long)fixedImage.imageOrientation);
    return fixedImage;
}

- (UIImage *)rotateImage:(UIImage *)image angle:(CGFloat)angle {
    CGFloat rad = angle;
    CGFloat sinVal = sin(rad);
    CGFloat cosVal = cos(rad);

    CGAffineTransform transform = CGAffineTransformMakeRotation(rad);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0, 0, image.size.width, image.size.height), transform);

    CGSize rotatedSize = CGSizeMake(fabs(newRect.size.width), fabs(newRect.size.height));

    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextTranslateCTM(context, rotatedSize.width / 2, rotatedSize.height / 2);
    CGContextRotateCTM(context, rad);
    [image drawInRect:CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height)];

    UIImage *rotatedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return rotatedImage;
}

- (void)callCompletionWithImage:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.captureCompletion) {
            self.captureCompletion(image);
            self.captureCompletion = nil;
        }
    });
}

@end
