//
//  SMGUtils+SSIM.m
//  SMG_NothingIsAll
//
//  Created by XiaoGang.
//

#import "SMGUtils+SSIM.h"
#import <Accelerate/Accelerate.h>

static const int kSSIMKernelSize = 11;
static const float kSSIMKernelSigma = 1.5f;
static const float kSSIM_K1 = 0.01f;
static const float kSSIM_K2 = 0.03f;
static const float kSSIM_L = 255.0f;

@implementation SMGUtils (SSIM)

+ (CGFloat)ssimImage:(UIImage *)imageA image:(UIImage *)imageB {
    if (!imageA || !imageB) return -1.0;

    // 缩到100像素内再算（保证性能）
    static const int kSSIMMaxDim = 100;
    CGFloat scale = MIN(1.0, (CGFloat)kSSIMMaxDim / MAX(imageA.size.width, imageA.size.height));
    scale = MIN(scale, (CGFloat)kSSIMMaxDim / MAX(imageB.size.width, imageB.size.height));
    int w = (int)(imageA.size.width * scale);
    int h = (int)(imageA.size.height * scale);
    if (w < kSSIMKernelSize || h < kSSIMKernelSize) return -1.0;

    // 灰度转换
    float *grayA = [self ssimGrayscaleFloatsFromImage:imageA width:w height:h];
    float *grayB = [self ssimGrayscaleFloatsFromImage:imageB width:w height:h];
    if (!grayA || !grayB) {
        free(grayA); free(grayB);
        return -1.0;
    }

    int N = w * h;
    CGFloat result = [self ssimComputeGrayA:grayA grayB:grayB width:w height:h];

    free(grayA);
    free(grayB);
    return result;
}

#pragma mark - 灰度转换

+ (float *)ssimGrayscaleFloatsFromImage:(UIImage *)image width:(int)w height:(int)h {
    // 先缩放到目标尺寸
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 1.0);
    [image drawInRect:CGRectMake(0, 0, w, h)];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGImageRef cgImg = resized.CGImage;
    if (!cgImg) return NULL;

    // 灰度 bitmap context
    size_t bytesPerRow = w;
    uint8_t *pixels = (uint8_t *)calloc(w * h, sizeof(uint8_t));
    if (!pixels) return NULL;

    CGColorSpaceRef graySpace = CGColorSpaceCreateDeviceGray();
    CGContextRef ctx = CGBitmapContextCreate(pixels, w, h, 8, bytesPerRow, graySpace, kCGImageAlphaNone);
    CGColorSpaceRelease(graySpace);
    if (!ctx) { free(pixels); return NULL; }

    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), cgImg);
    CGContextRelease(ctx);

    // Planar8 -> PlanarF
    float *floats = (float *)malloc(w * h * sizeof(float));
    if (!floats) { free(pixels); return NULL; }

    vImage_Buffer src = { pixels, (vImagePixelCount)h, (vImagePixelCount)w, bytesPerRow };
    vImage_Buffer dst = { floats, (vImagePixelCount)h, (vImagePixelCount)w, w * sizeof(float) };
    vImageConvert_Planar8toPlanarF(&src, &dst, 1.0f, 0.0f, kvImageNoFlags);

    free(pixels);
    return floats;
}

#pragma mark - SSIM 核心计算

+ (CGFloat)ssimComputeGrayA:(float *)grayA grayB:(float *)grayB width:(int)w height:(int)h {
    int N = w * h;
    int half = kSSIMKernelSize / 2;
    int validW = w - kSSIMKernelSize + 1;
    int validH = h - kSSIMKernelSize + 1;
    int validN = validW * validH;

    if (validN <= 0) return -1.0;

    // 生成 1D 高斯核
    float kernel1D[kSSIMKernelSize];
    float kernelSum = 0.0f;
    for (int i = 0; i < kSSIMKernelSize; i++) {
        float x = (float)(i - half);
        kernel1D[i] = expf(-(x * x) / (2.0f * kSSIMKernelSigma * kSSIMKernelSigma));
        kernelSum += kernel1D[i];
    }
    for (int i = 0; i < kSSIMKernelSize; i++) {
        kernel1D[i] /= kernelSum;
    }

    // 分配中间缓冲
    float *muA = (float *)calloc(N, sizeof(float));
    float *muB = (float *)calloc(N, sizeof(float));
    float *sigA2 = (float *)calloc(N, sizeof(float));
    float *sigB2 = (float *)calloc(N, sizeof(float));
    float *sigAB = (float *)calloc(N, sizeof(float));
    float *tmpH = (float *)calloc(N, sizeof(float));
    float *tmpV = (float *)calloc(N, sizeof(float));

    // x*x, y*y, x*y
    float *xx = (float *)malloc(N * sizeof(float));
    float *yy = (float *)malloc(N * sizeof(float));
    float *xy = (float *)malloc(N * sizeof(float));
    vDSP_vmul(grayA, 1, grayA, 1, xx, 1, N);
    vDSP_vmul(grayB, 1, grayB, 1, yy, 1, N);
    vDSP_vmul(grayA, 1, grayB, 1, xy, 1, N);

    // 可分离高斯卷积辅助：先水平后垂直
    // muA = blur(grayA)
    [self ssimSeparableConv:grayA tmpH:tmpH tmpV:tmpV output:muA width:w height:h kernel:kernel1D kernelLen:kSSIMKernelSize];
    // muB = blur(grayB)
    [self ssimSeparableConv:grayB tmpH:tmpH tmpV:tmpV output:muB width:w height:h kernel:kernel1D kernelLen:kSSIMKernelSize];
    // sigA2 = blur(x*x) - muA*muA
    [self ssimSeparableConv:xx tmpH:tmpH tmpV:tmpV output:sigA2 width:w height:h kernel:kernel1D kernelLen:kSSIMKernelSize];
    // sigB2 = blur(y*y) - muB*muB
    [self ssimSeparableConv:yy tmpH:tmpH tmpV:tmpV output:sigB2 width:w height:h kernel:kernel1D kernelLen:kSSIMKernelSize];
    // sigAB = blur(x*y) - muA*muB
    [self ssimSeparableConv:xy tmpH:tmpH tmpV:tmpV output:sigAB width:w height:h kernel:kernel1D kernelLen:kSSIMKernelSize];

    // 减去 mu*mu 得到方差/协方差
    float *muA2 = (float *)malloc(N * sizeof(float));
    float *muB2 = (float *)malloc(N * sizeof(float));
    float *muAB = (float *)malloc(N * sizeof(float));
    vDSP_vmul(muA, 1, muA, 1, muA2, 1, N);
    vDSP_vmul(muB, 1, muB, 1, muB2, 1, N);
    vDSP_vmul(muA, 1, muB, 1, muAB, 1, N);
    vDSP_vsub(muA2, 1, sigA2, 1, sigA2, 1, N);
    vDSP_vsub(muB2, 1, sigB2, 1, sigB2, 1, N);
    vDSP_vsub(muAB, 1, sigAB, 1, sigAB, 1, N);

    // SSIM 常量
    float C1 = (kSSIM_K1 * kSSIM_L) * (kSSIM_K1 * kSSIM_L); // 6.5025
    float C2 = (kSSIM_K2 * kSSIM_L) * (kSSIM_K2 * kSSIM_L); // 58.5225

    // 只计算有效区域（卷积后完整的区域）
    double ssimSum = 0.0;
    for (int row = half; row < h - half; row++) {
        for (int col = half; col < w - half; col++) {
            int idx = row * w + col;
            float muAX = muA[idx], muBX = muB[idx];
            float sA2 = sigA2[idx], sB2 = sigB2[idx], sAB = sigAB[idx];

            float num = (2.0f * muAX * muBX + C1) * (2.0f * sAB + C2);
            float den = (muAX * muAX + muBX * muBX + C1) * (sA2 + sB2 + C2);
            ssimSum += (double)(num / den);
        }
    }

    // 释放所有缓冲
    free(muA); free(muB); free(sigA2); free(sigB2); free(sigAB);
    free(tmpH); free(tmpV); free(xx); free(yy); free(xy);
    free(muA2); free(muB2); free(muAB);

    return (CGFloat)(ssimSum / validN);
}

#pragma mark - 可分离高斯卷积

+ (void)ssimSeparableConv:(float *)input tmpH:(float *)tmpH tmpV:(float *)tmpV output:(float *)output
                    width:(int)w height:(int)h kernel:(float *)kernel kernelLen:(int)kernelLen {
    int half = kernelLen / 2;

    // 水平卷积
    for (int row = 0; row < h; row++) {
        vDSP_conv(input + row * w + half, 1, kernel, 1, tmpH + row * w + half, 1, w - kernelLen + 1, kernelLen);
    }

    // 垂直卷积（转置思路：stride=w）
    for (int col = half; col < w - half; col++) {
        // 收集列数据到 tmpV 偏移处，再用 vDSP_conv
        for (int row = half; row < h - half; row++) {
            float sum = 0.0f;
            for (int k = 0; k < kernelLen; k++) {
                sum += tmpH[(row - half + k) * w + col] * kernel[k];
            }
            output[row * w + col] = sum;
        }
    }
}

@end
