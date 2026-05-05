//
//  AIVisionAlgsV2.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/15.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIVisionAlgsV2.h"

@implementation AIVisionAlgsV2

/**
 *  MARK:--------------------获取图片指定区域的RGB值--------------------
 *  @cropRect 注意力范围（为归一化坐标 0-1）
 */
+ (NSDictionary*) getRGBValuesFromImage:(UIImage *)image cropRect:(CGRect)cropRect {
    // 1. 创建返回字典
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    // 2. 获取图片的CGImage
    CGImageRef imageRef = image.CGImage;
    NSUInteger width = 27; // CGImageGetWidth(imageRef);
    NSUInteger height = 27; // CGImageGetHeight(imageRef);
    
    //3. 求出共分多少点，以及每点的尺寸。
    NSInteger dotNum = [self convert2DotNum:MAX(width, height)];
    CGFloat dotWidth = dotNum,dotHeight = dotNum;
    
    // 3. 创建颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 4. 创建原始数据
    unsigned char *rawData = (unsigned char *)calloc(dotHeight * dotWidth * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * dotWidth;
    NSUInteger bitsPerComponent = 8;
    
    // 5. 创建上下文
    CGContextRef context = CGBitmapContextCreate(rawData, dotWidth, dotHeight,
                                               bitsPerComponent, bytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    // 将归一化坐标转换为实际像素坐标
    CGFloat cropX = MAX(0, MIN(1, cropRect.origin.x)) * width;
    CGFloat cropY = MAX(0, MIN(1, cropRect.origin.y)) * height;
    CGFloat cropW = MIN(width - cropX, MAX(0, cropRect.size.width) * width);
    CGFloat cropH = MIN(height - cropY, MAX(0, cropRect.size.height) * height);
    CGRect pixelCropRect = CGRectMake(cropX, cropY, cropW, cropH);
    
    // 先裁剪出图片的特定区域
    imageRef = CGImageCreateWithImageInRect(imageRef, pixelCropRect);
    if (!imageRef) {
        return result;
    }
    
    // 6. 绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, dotWidth, dotHeight), imageRef);
    
    // 7. 遍历像素
    for(NSUInteger y = 0; y < dotNum; y++) {
        for(NSUInteger x = 0; x < dotNum; x++) {
            
            //8. 取出像素pixelX,pixelY的RGB值。
            NSUInteger byteIndex = (bytesPerRow * y) + x * bytesPerPixel;
            CGFloat red   = (CGFloat)rawData[byteIndex] / 255.0f;
            CGFloat green = (CGFloat)rawData[byteIndex + 1] / 255.0f;
            CGFloat blue  = (CGFloat)rawData[byteIndex + 2] / 255.0f;
            
            //9. 保存结果
            //TODO: 随后改成二维字典，或二维数组，不然大量取时，拼字符串也耗性能。
            NSString *key = [NSString stringWithFormat:@"%ld_%ld", x, y];
            result[key] = @{@"r": @(red),@"g": @(green),@"b": @(blue)};
        }
    }
    
    // 10. 清理内存
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(rawData);
    CGImageRelease(imageRef);
    
    return result;
}

/**
 *  MARK:--------------------获取当前图片能拆分成多少个点（比如100像素的图，按/3分隔，最后拆分成81点，每点=1.23457像素)--------------------
 */
+(NSInteger) convert2DotNum:(CGFloat)imageWHNum {
    NSInteger dotNum = 1;
    while (imageWHNum / dotNum >= 3.0f) {
        dotNum *= 3;
    }
    return MIN(dotNum, powf(3, VisionMaxLevel));//限制最大图片层级宽度
}

/**
 *  MARK:--------------------把HSB字典，转成粒度字典（粒度字典是每层级横纵各三格，最粗粒度共9格，细粒度下再拆分嵌套各9格，以此类推）--------------------
 */
+(NSDictionary*) convertProtoColorDic2SplitDic:(NSDictionary*)protoColorDic {
    //1. 先搞最细粒度，然后一级级向粗粒度层做，其中：KEY=level_row_column value=色值。
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    int protoDotSize = sqrtf(protoColorDic.count);//通过总点数求平方根获取边长（因为横纵点数是一致的）。
    
    //2. 计算81是3的几次方 (log3(81) = 4) (level的取值范围是1234...从1开始，其中1表示最粗粒度层）。
    int levelNum = [SMGUtils convertDotSize2Level:protoDotSize];
    for (NSInteger curLevel = levelNum; curLevel > 0; curLevel--) {
        
        //3. 每个粒度层都要把每格处理下：第1粒度宽3。第2粒度宽9。第3粒度宽27。第4粒度宽81。（row和column的取值范围是0123...从0开始，它表示每一个粒度层的行列下标）。
        int curLevelSize = powf(3, curLevel);
        for (NSInteger curRow = 0; curRow < curLevelSize; curRow++) {
            for (NSInteger curColumn = 0; curColumn < curLevelSize; curColumn++) {
                
                //4. 每一格平均色处理（最细粒度从原始数据取，别的粗粒度层都从细一级9格累求其平均算）。
                NSString *curKey = [NSString stringWithFormat:@"%ld_%ld_%ld", curLevel, curRow, curColumn];
                if (curLevel == levelNum) {
                    //4.1 当前为最细粒度时，直接从hsbDic取值。
                    [result setObject:[protoColorDic objectForKey:STRFORMAT(@"%ld_%ld",curRow,curColumn)] forKey:curKey];
                } else {
                    //4.2 别的粗粒度，都从result的细一级粒度取值（把lastLevel取到的9个值取平均值=做为当前Level的HSB值）。
                    NSArray *subDots = [CortexAlgorithmsUtil getSub9DotFromSplitDic:curLevel curRow:curRow curColumn:curColumn splitDic:result];//取出子层9格色值。
                    [result setObject:[self getAverageColorFromSubDotDics:subDots] forKey:curKey];//取平均值并存到result。
                }
            }
        }
    }
    return result;
}

/**
 *  MARK:--------------------根据子粒度层的9格色值，计算出平均色值--------------------
 */
+(NSDictionary*) getAverageColorFromSubDotDics:(NSArray*)subDots {
    //1. 别的粗粒度，都从result的细一级粒度取值（把lastLevel取到的9个值取平均值=做为当前Level的HSB值）。
    CGFloat sumR = 0,sumG = 0,sumB = 0;
    for (MapModel *model in subDots) {
        NSDictionary *subDotDic = model.v1;
        
        //3. 把这九个格的色值分别取出来，求平均值收集。
        sumR += NUMTOOK([subDotDic objectForKey:@"r"]).floatValue;
        sumG += NUMTOOK([subDotDic objectForKey:@"g"]).floatValue;
        sumB += NUMTOOK([subDotDic objectForKey:@"b"]).floatValue;
    }
    return @{@"r": @(sumR / 9),@"g": @(sumG / 9),@"b": @(sumB / 9)};
}

/**
 *  MARK:--------------------commitInput--------------------
 */
+ (void) commitInput:(UIImage*)image logDesc:(NSString*)logDesc {
    //1. 数据检查。
    if (!image) return;
    
    //2. 取rgb矩阵<K=x_y,V=RGB>
    NSDictionary *protoColorDic = [self getRGBValuesFromImage:image cropRect:CGRectMake(0, 0, 1, 1)];
    
    //3. 将rgb矩阵按粒度分层<K=level_x_y,V=RGB>
    NSDictionary *splitDic = [self convertProtoColorDic2SplitDic:protoColorDic];
    
    //4. RGB矩阵转为HSB矩阵。
    splitDic = [SMGUtils convertDic:splitDic kvBlock:^NSArray *(id protoK, NSDictionary *protoV) {
        return @[protoK,[UIColor convertRGB2HSB:protoV]];
    }];
    
    //5. 转成AIVisionAlgsModelV2模型。
    AIVisionAlgsModelV2 *model = [[AIVisionAlgsModelV2 alloc] init];
    CGFloat protoColorWH = sqrtf(protoColorDic.count);
    model.levelNum = [SMGUtils convertDotSize2Level:protoColorWH];
    
    //6. 取HSB三个特征（及感官层做精度处理：要保证整个稀疏码可能的值，其总量在不影响感知的前提下越少越好）。
    model.hColors = [SMGUtils convertDic:splitDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"h"]).floatValue * 100) / 100)];
    }];
    model.sColors = [SMGUtils convertDic:splitDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"s"]).floatValue * 100) / 100)];
    }];
    model.bColors = [SMGUtils convertDic:splitDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"b"]).floatValue * 100) / 100)];
    }];
    
    //7. 提交给思维控制器。
    [theTC commitInputWithSplitAsync:model algsType:NSStringFromClass(self) logDesc:logDesc];
}

+ (void) commitInputV2:(UIImage*)image logDesc:(NSString*)logDesc {
    //1. 数据检查。
    if (!image) return;
    
    //2. 取rgb矩阵<K=x_y,V=RGB>
    NSDictionary *rgbDic = [self getRGBValuesFromImage:image cropRect:CGRectMake(0, 0, 1, 1)];

    //3. 将rgb矩阵按粒度分层<K=level_x_y,V=RGB>（只有rgb求平均值比较方便，不必考虑loop值，直接求平均即可，所以在转hsb之前，就得把9宫粒度分层字典处理好）。
    NSDictionary *splitRGBDic = [self convertProtoColorDic2SplitDic:rgbDic];
    
    //3. RGB矩阵转为HSB矩阵。
    NSDictionary *hsbDic = [SMGUtils convertDic:rgbDic kvBlock:^NSArray *(id protoK, NSDictionary *protoV) {
        return @[protoK,[UIColor convertRGB2HSB:protoV]];
    }];
    NSDictionary *splitHSBDic = [SMGUtils convertDic:splitRGBDic kvBlock:^NSArray *(id protoK, NSDictionary *protoV) {
        return @[protoK,[UIColor convertRGB2HSB:protoV]];
    }];
    
    //5. 转成AIVisionAlgsModelV2模型。
    AIVisionAlgsModelV2 *model = [[AIVisionAlgsModelV2 alloc] init];
    CGFloat protoColorWH = sqrtf(rgbDic.count);
    model.whSize = protoColorWH;
    model.levelNum = [SMGUtils convertDotSize2Level:protoColorWH];
    
    //6. 取HSB三个特征（及感官层做精度处理：要保证整个稀疏码可能的值，其总量在不影响感知的前提下越少越好）。
    model.hColors = [SMGUtils convertDic:hsbDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"h"]).floatValue * 100) / 100)];
    }];
    model.sColors = [SMGUtils convertDic:hsbDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"s"]).floatValue * 100) / 100)];
    }];
    model.bColors = [SMGUtils convertDic:hsbDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"b"]).floatValue * 100) / 100)];
    }];
    model.splitHColors = [SMGUtils convertDic:splitHSBDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"h"]).floatValue * 100) / 100)];
    }];
    model.splitSColors = [SMGUtils convertDic:splitHSBDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"s"]).floatValue * 100) / 100)];
    }];
    model.splitBColors = [SMGUtils convertDic:splitHSBDic kvBlock:^NSArray *(NSString *protoK, NSDictionary *protoV) {
        return @[protoK,@(roundf(NUMTOOK([protoV objectForKey:@"b"]).floatValue * 100) / 100)];
    }];
    
    //7. 提交给思维控制器。
    [theTC commitInputWithSplitAsyncV2:model algsType:NSStringFromClass(self) logDesc:logDesc];
}

#pragma mark - Test Methods

// 创建测试用的100x100像素图片
+ (UIImage *) createTest4ColorImage {
    CGFloat size = 20;
    CGFloat half = size / 2;
    UIGraphicsBeginImageContext(CGSizeMake(size, size));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // 左上角像素 - 红色
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, half, half));
    
    // 右上角像素 - 绿色
    CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 1.0);
    CGContextFillRect(context, CGRectMake(half, 0, half, half));

    // 左下角像素 - 蓝色
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, half, half, half));

    // 右下角像素 - 黄色
    CGContextSetRGBFillColor(context, 1.0, 1.0, 0.0, 1.0);
    CGContextFillRect(context, CGRectMake(half, half, half, half));

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *) createImageFromMnistImageWithName:(NSString*)imgName forTest:(BOOL)forTest {
    //1. 读图片路径。
    NSString *folder = forTest ? @"MnistImages/test" : @"MnistImages/train";
    NSString *path = [[NSBundle mainBundle] pathForResource:STRFORMAT(@"assets/%@/%@",folder,imgName) ofType:@"png"];
    
    //2. 读出第imgIndex张图。
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    return img;
}

+ (UIImage *) createImageFromCustomImageWithName:(NSString*)imgName {
    //1. 读图片路径。
    NSString *path = [[NSBundle mainBundle] pathForResource:STRFORMAT(@"assets/CustomImages/%@",imgName) ofType:@"png"];
    
    //2. 读出第imgIndex张图。
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    return img;
}

@end
