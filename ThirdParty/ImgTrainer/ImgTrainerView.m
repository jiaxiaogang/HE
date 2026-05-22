//
//  ImgTrainerView.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/25.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "ImgTrainerView.h"
#import "MASConstraint.h"
#import "View+MASAdditions.h"
#import "PINDiskCache.h"
#import "TVUtil.h"
#import "XGLabCell.h"
#import "ImgTrainerItemModel.h"
#import "ImgTrainerPreview.h"
#import "AICameraCapture.h"
#import "JvBuDetailWindow.h"

@interface ImgTrainerView () <UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITableView *tv;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView1;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView2;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView3;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView4;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView5;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView6;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIImageView *curImgView;
@property (strong, nonatomic) NSMutableArray *tvDatas;

// 摄像头相关
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, assign) BOOL isCameraPreviewOn;
@property (assign, nonatomic) NSInteger curSelectRow;
@property (weak, nonatomic) IBOutlet UITextField *picNumLab;
@property (weak, nonatomic) IBOutlet UISwitch *autoNextSwitch;

@property (strong, nonatomic) NSArray *previewTVs;
@property (strong, nonatomic) NSMutableArray *previewDatas;

@end

@implementation ImgTrainerView

-(id) init {
    self = [super init];
    if(self != nil){
        [self initView];
        [self initData];
        [self initDisplay];
    }
    return self;
}

-(void) initView{
    //self
    CGFloat width = ScreenWidth;
    [self setFrame:CGRectMake(ScreenWidth - width, 44, width, ScreenHeight - 44)];
    
    //containerView
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
        make.top.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
    }];
    [self.containerView.layer setCornerRadius:8.0f];
    [self.containerView.layer setBorderWidth:1.0f];
    [self.containerView.layer setBorderColor:UIColorWithRGBHex(0x000000).CGColor];
    
    //tv
    self.tv.delegate = self;
    self.tv.dataSource = self;
    [self.tv.layer setBorderWidth:1.0f];
    [self.tv.layer setBorderColor:UIColorWithRGBHex(0x0000FF).CGColor];
    //[self.tv setContentInset:UIEdgeInsetsMake(0, -10, 0, -10)];
    
    //previewTableView
    self.previewTVs = @[self.previewTableView1,
                        self.previewTableView2,
                        self.previewTableView3,
                        self.previewTableView4,
                        self.previewTableView5,
                        self.previewTableView6];
    for (UITableView *tv in self.previewTVs) {
        tv.delegate = self;
        tv.dataSource = self;
        [tv.layer setBorderWidth:1.0f];
        [tv.layer setBorderColor:UIColorWithRGBHex(0x0000FF).CGColor];
        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(previewTVLongPress:)];
        lp.minimumPressDuration = 0.5;
        [tv addGestureRecognizer:lp];
    }

    // 摄像头预览视图 - 默认显示
    self.cameraPreviewView.backgroundColor = [UIColor whiteColor];
    self.cameraPreviewView.layer.cornerRadius = 4;
    self.cameraPreviewView.clipsToBounds = YES;
    self.cameraPreviewView.layer.borderWidth = 1.0f;
    self.cameraPreviewView.layer.borderColor = [UIColor blackColor].CGColor;
    self.cameraPreviewView.userInteractionEnabled = YES;

    // 给摄像头预览视图添加双击手势（拍照）
    UITapGestureRecognizer *cameraDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraPreviewViewDoubleTapped:)];
    cameraDoubleTap.numberOfTapsRequired = 2;
    [self.cameraPreviewView addGestureRecognizer:cameraDoubleTap];

    // 单击手势（切换预览开关）
    UITapGestureRecognizer *cameraTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraPreviewViewTapped:)];
    [self.cameraPreviewView addGestureRecognizer:cameraTap];

    // 单击手势失败时才触发双击（避免冲突）
    [cameraTap requireGestureRecognizerToFail:cameraDoubleTap];

    // 初始化摄像头
    [self setupCameraCapture];

    // 摄像头预览默认关闭
    self.isCameraPreviewOn = NO;
}

-(void) initData{
    self.previewDatas = [NSMutableArray new];
    for (NSInteger i = 0; i < self.previewTVs.count; i++) {
        [self.previewDatas addObject:[NSMutableArray new]];
    }
    
    // 注意强训执行事件
    [theRT regist:kImgTrainerSelect target:self selector:@selector(imgTrainerSelect:)];
    [theRT regist:kImgTrainerPlay target:self selector:@selector(imgTrainerPlay)];
}

#pragma mark - 摄像头相关

- (void)setupCameraCapture {
    // 创建捕获会话
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;

    // 获取后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!videoDevice) {
        NSLog(@"没有找到可用的摄像头");
        return;
    }

    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"创建摄像头输入失败: %@", error);
        return;
    }

    if ([self.captureSession canAddInput:videoInput]) {
        [self.captureSession addInput:videoInput];
    }

    // 创建视频输出
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    self.videoQueue = dispatch_queue_create("videoQueue", DISPATCH_QUEUE_SERIAL);
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];

    if ([self.captureSession canAddOutput:self.videoOutput]) {
        [self.captureSession addOutput:self.videoOutput];
    }
}

- (void)startCameraPreview {
    if (self.captureSession && !self.captureSession.isRunning) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession startRunning];
        });
    }
}

- (void)stopCameraPreview {
    if (self.captureSession && self.captureSession.isRunning) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
        });
    }
    // 清除预览图像，显示白色背景
    self.cameraPreviewView.image = nil;
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    if (image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.cameraPreviewView.image = image;
        });
    }
}

- (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (!imageBuffer) return nil;

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:imageBuffer];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:ciImage.extent];
    if (!cgImage) return nil;

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    // 裁剪成正方形（从中间裁剪）
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat squareSize = MIN(width, height);

    CGRect cropRect = CGRectMake((width - squareSize) / 2, (height - squareSize) / 2, squareSize, squareSize);
    CGImageRef croppedCGImage = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:croppedCGImage];
    CGImageRelease(croppedCGImage);

    return croppedImage;
}

-(void) initDisplay {
    [self close];
}

/**
 *  MARK:--------------------setData--------------------
 *  @param mode 1custom模式 2imageNet模式 3Mnist模式（暂不需要，但也用过人家图库，挂个名）。
 */
-(void) setData:(int)mode {
    if (mode == 1) {
        [self loadDataForCustom];
    } else if (mode == 2) {
        [self loadDataForImageNet];
    }
    [self refreshDisplay];
}

-(void) loadDataForCustom {
    //1. 先清掉
    self.tvDatas = [NSMutableArray new];

    //2. 取所有物品文件夹
    NSString *path = [[NSBundle mainBundle] pathForResource:@"assets/TrainImages" ofType:nil];
    NSArray *subPaths = [NSFile_Extension subFolders:path];
    
    //3. 把文件夹名称取拼音字典。
    NSMutableArray *folderNames = [SMGUtils convertArr:subPaths convertBlock:^id(NSString *obj) {
        return [obj lastPathComponent];
    }];
    NSDictionary *dic = [self convertStrs2PinYinDic:folderNames];
    
    //4. 绝对目录按拼音排序
    subPaths = [subPaths sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
        NSString *name1 = [dic objectForKey:[path1 lastPathComponent]];
        NSString *name2 = [dic objectForKey:[path2 lastPathComponent]];
        return [name1 compare:name2 options:NSNumericSearch];
    }];
    
    //5. 转为models
    for (NSString *subPath in subPaths) {
        NSString *folderName = [subPath lastPathComponent];
        [self.tvDatas addObject:[ImgTrainerItemModel new:subPath imgId:folderName imgName:folderName]];
    }
}

-(void) loadDataForImageNet {
    self.tvDatas = [NSMutableArray new];

    // Read words.txt file
    NSString *cachePath = kCachePath;
    NSString *wordsPath = STRFORMAT(@"%@/assets/TinyImageNetImages/words.txt", cachePath);
    NSString *wordsContent = [NSString stringWithContentsOfFile:wordsPath encoding:NSUTF8StringEncoding error:nil];
    
    // Split into lines and get first line
    NSArray *wordsLines = [wordsContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSMutableDictionary *wordsDic = [NSMutableDictionary new];
    for (NSString *line in wordsLines) {
        
        // Find first tab position in line
        NSRange tabRange = [line rangeOfString:@"\t"];
        if (tabRange.location == NSNotFound) {
            continue;
        }

        // Extract key and value from line using tab position
        NSString *key = [line substringToIndex:tabRange.location];
        NSString *value = [line substringFromIndex:tabRange.location + 1];
        wordsDic[key] = value;
    }
    //NSLog(@"读到物品名字典%ld条",wordsDic.count);
    
    // Read wnids.txt file
    NSString *filePath = STRFORMAT(@"%@/assets/TinyImageNetImages/wnids.txt", cachePath);
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    // Split into lines and create array
    NSArray *imgIds = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // Collect for every one
    for (NSString *imgId in imgIds) {
        NSString *imgName = [wordsDic objectForKey:imgId];
        if (!imgId || !imgName) continue;
        NSString *folderPath = STRFORMAT(@"%@/assets/TinyImageNetImages/train/%@/images",cachePath,imgId);
        [self.tvDatas addObject:[ImgTrainerItemModel new:folderPath imgId:imgId imgName:imgName]];
    }
    //NSLog(@"读到物品类别数%ld条",self.tvDatas.count);
}

-(void) refreshDisplay {
    //5. 重显示;
    [self.tv reloadData];
    if (self.curSelectRow < self.tvDatas.count) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.tv selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.curSelectRow inSection:0] animated:false scrollPosition:UITableViewScrollPositionNone];
        });
    }
}

//MARK:===============================================================
//MARK:                     < jvBuModels可视化 >
//MARK:===============================================================

/**
 *  MARK:--------------------单特征识别结果可视化（参考34176）--------------------
 */
-(void) setDataForJvBuModelsV1:(NSArray*)jvBuModels protoT:(AIFeatureNode*)protoT tvId:(NSInteger)tvId {
    [self addFeatureToPreview:protoT indexes:nil lab:STRFORMAT(@"protoT%ld:%@",protoT.pId,protoT.ds) left:0 top:0 tvId:tvId fromObj:nil];
    for (AIMatchModel *model in jvBuModels) {
        //NSArray *collectProtoIndexs = model.indexDic.allValues;
        [self addFeatureToPreview:(AIFeatureNode*)model.matchNode indexes:model.indexDic.allKeys lab:STRFORMAT(@"assT%ld:%@",model.matchNode.pId,model.matchNode.ds) left:0 top:0 tvId:tvId fromObj:model];
    }
    [[self getPreviewTV:tvId] reloadData];
}

//仅对匹配上itemGV进行可视化。
-(void) setDataForJvBuModelV2:(AIFeatureJvBuModel*)jvBuModel lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId {
    [self addFeatureToPreview:jvBuModel.assT indexes:nil/*jvBuModel.bestGVs.allKeys*/ lab:lab left:left top:top tvId:tvId fromObj:jvBuModel];
    [[self getPreviewTV:tvId] reloadData];
}

//把jvBuModel中的index下标的gv可视化出来。
//调用示例（把某个st的某元素gv可视化出来）：[SMGUtils runByMainQueue:^{ for (NSInteger i = 0; i < model.bestGVs.count; i++) [theApp.imgTrainerView setDataForJvBuModelV3:model lab:STRFORMAT(@"ST%ld.%ld",model.assT.pId,i) left:model.bestGVsAtProtoTRect.origin.x top:model.bestGVsAtProtoTRect.origin.y tvId:2 gvIndex:i]; }];
-(void) setDataForJvBuModelV3:(AIFeatureJvBuModel*)jvBuModel lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId gvIndex:(NSInteger)gvIndex {
    NSNumber *assIndex = ARR_INDEX(jvBuModel.bestGVs.allKeys, gvIndex);
    [self addFeatureToPreview:jvBuModel.assT indexes:@[assIndex] lab:lab left:left top:top tvId:tvId fromObj:jvBuModel];
    [[self getPreviewTV:tvId] reloadData];
}

// 仅显示bestGVs
-(void) setDataForJvBuModelV4:(AIFeatureJvBuModel*)jvBuModel lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId {
    [self addFeatureToPreview:jvBuModel.assT indexes:jvBuModel.bestGVs.allKeys lab:lab left:left top:top tvId:tvId fromObj:jvBuModel];
    [[self getPreviewTV:tvId] reloadData];
}

//仅对匹配上itemT进行可视化。
//-(void) setDataForZenTiModel:(AIFeatureZenTiModel*)zenTiModel lab:(NSString*)lab tvId:(NSInteger)tvId {
//    AIGroupFeatureNode *assGT = [SMGUtils searchNode:zenTiModel.assT];
//    NSArray *indexes = [SMGUtils convertArr:zenTiModel.rectItems convertBlock:^id(AIFeatureZenTiItem_Rect *obj) {
//        return @([assGT indexOfRect:obj.itemAtAssRect]);
//    }];
//    [self addFeatureToPreview:assGT indexes:indexes lab:lab left:0 top:0 tvId:tvId fromObj:zenTiModel];
//    [[self getPreviewTV:tvId] reloadData];
//}

//单特征识别结果数组，应该一个个元素显示，而不是一下把所有的显示到一个画布上。
-(void) setDataForJvBuModelsV2:(NSArray*)jvBuModels lab:(NSString*)lab tvId:(NSInteger)tvId {
    for (AIFeatureJvBuModel *jvBuModel in jvBuModels) {
        [self addFeatureToPreview:jvBuModel.assT indexes:jvBuModel.bestGVs.allKeys lab:lab left:0 top:0 tvId:tvId fromObj:jvBuModel];
    }
    [[self getPreviewTV:tvId] reloadData];
}

//有BUG，可视化像一块块分裂着。
-(void) setDataForJvBuModelsV3:(NSArray*)jvBuModels lab:(NSString*)lab tvId:(NSInteger)tvId {
    for (AIFeatureJvBuModel *jvBuModel in jvBuModels) {
        NSArray *gvModels = [SMGUtils convertArr:jvBuModel.bestGVs.allKeys convertBlock:^id(NSNumber *assIndex) {
            AIFeatureJvBuItem *obj = [jvBuModel.bestGVs objectForKey:assIndex];
            return [InputGroupValueModel new:ARR_INDEX(jvBuModel.assT.content_ps, assIndex.integerValue) rect:obj.bestGVAtProtoTRect];
        }];
        [self addFeatureToPreview:jvBuModel.assT gvModels:gvModels lab:lab tvId:tvId fromObj:jvBuModel];
    }
    [[self getPreviewTV:tvId] reloadData];
}

// 仅显示一条AIFeatureJvBuItem，按其在ProtoRect来显示。
-(void) setDataForJvBuItem_Single:(AIFeatureJvBuItem*)jvBuItem fromFeatureNode:(AIFeatureNode*)fromFeatureNode lab:(NSString*)lab tvId:(NSInteger)tvId {
    InputGroupValueModel *gvModel = [InputGroupValueModel new:jvBuItem.baseGV_p rect:jvBuItem.bestGVAtProtoTRect];
    ImgTrainerPreview *preview = [self getOrCreate:lab tvId:tvId];
    preview.fromObj = jvBuItem;
    [preview setData:fromFeatureNode gvModels:@[gvModel] lab:lab left:0 top:0];
    [[self getPreviewTV:tvId] reloadData];
}

-(void) setDataForFeature:(AIFeatureNode*)tNode lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId {
    [self addFeatureToPreview:tNode indexes:nil lab:lab left:left top:top tvId:tvId fromObj:tNode];
    [[self getPreviewTV:tvId] reloadData];
}

// 显示到showRect指定画布大小。
-(void) setDataForFeatureV2:(AIFeatureNode*)tNode lab:(NSString*)lab canvasRect:(CGRect)canvasRect tvId:(NSInteger)tvId {
    NSArray *gvModels = [tNode convert2GVModels:nil];
    
    // 转为实际在proto中显示的大小。
    CGRect objRect = tNode.rect;
    for (InputGroupValueModel *gvModel in gvModels) {
        gvModel.rect = [SMGUtils convertAAtCWithAAtB:gvModel.rect bAtC:canvasRect protoBSize:objRect.size];
    }
    
    // 可视化显示。
    ImgTrainerPreview *preview = [self getOrCreate:lab tvId:tvId];
    preview.fromObj = tNode;
    preview.fromCanvas = canvasRect;
    [preview setData:tNode gvModels:gvModels lab:lab left:0 top:0];
    [[self getPreviewTV:tvId] reloadData];
}

//-(void) setDataForGTModel:(GTModel*)gtModel lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId {
//    // 为GT全显示。
//    NSArray *indexes = nil; //[SMGUtils convertArr:gtModel.items convertBlock:^id(GTItem *gtItem) { return @(gtItem.assIndex); }];
//    [self addFeatureToPreview:gtModel.assGT indexes:indexes lab:lab left:left top:top tvId:tvId];
//    [[self getPreviewTV:tvId] reloadData];
//}
//
-(void) setDataForGTModelV2:(GTModelV2*)gtModel lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId {
    // 为GT全显示。
    NSArray *indexes = nil; //[SMGUtils convertArr:gtModel.items convertBlock:^id(GTItem *gtItem) { return @(gtItem.assIndex); }];
    [self addFeatureToPreview:gtModel.assGT indexes:indexes lab:lab left:left top:top tvId:tvId fromObj:gtModel];
    [[self getPreviewTV:tvId] reloadData];
}

-(void) setDataForGTModelV3:(GTZiJvModelV2*)gtGroup lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId {
    // 为GT全显示。
    NSArray *indexes = nil; //[SMGUtils convertArr:gtModel.items convertBlock:^id(GTItem *gtItem) { return @(gtItem.assIndex); }];
    [self addFeatureToPreview:gtGroup.baseGT indexes:indexes lab:lab left:left top:top tvId:tvId fromObj:gtGroup];
    [[self getPreviewTV:tvId] reloadData];
}

-(void) setDataForAlgs:(NSArray*)models tvId:(NSInteger)tvId {
    for (AIMatchAlgModel *model in models) {
        AIAlgNodeBase *assAlg = [SMGUtils searchNode:model.matchAlg];
        NSString *lab = STRFORMAT(@"A%ld:%@",assAlg.pId,CLEANSTR([assAlg getLogDesc:false].allKeys));
        [self addAlgToPreview:assAlg lab:lab tvId:tvId];
    }
    [[self getPreviewTV:tvId] reloadData];
}

-(void) setDataForAlg:(AINodeBase*)algNode lab:(NSString*)lab tvId:(NSInteger)tvId {
    [self addAlgToPreview:algNode lab:lab tvId:tvId];
    [[self getPreviewTV:tvId] reloadData];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

-(void) addFeatureToPreview:(AIFeatureNode*)tNode gvModels:(NSArray*)gvModels lab:(NSString*)lab tvId:(NSInteger)tvId fromObj:(id)fromObj {
    ImgTrainerPreview *preview = [self getOrCreate:lab tvId:tvId];
    preview.fromObj = fromObj;
    [preview setData:tNode gvModels:gvModels lab:lab left:0 top:0];
}

-(void) addFeatureToPreview:(AIFeatureNode*)tNode indexes:(NSArray*)indexes lab:(NSString*)lab left:(CGFloat)left top:(CGFloat)top tvId:(NSInteger)tvId fromObj:(id)fromObj {
    ImgTrainerPreview *preview = [self getOrCreate:lab tvId:tvId];
    preview.fromObj = fromObj;
    [preview setData:tNode indexes:indexes lab:lab left:left top:top];
}

-(void) addAlgToPreview:(AINodeBase*)algNode lab:(NSString*)lab tvId:(NSInteger)tvId {
    //1. 取preview 并更新显示;
    ImgTrainerPreview *preview = [self getOrCreate:lab tvId:tvId];
    for (AIKVPointer *itemT_p in algNode.content_ps) {
        AIFeatureNode *itemT = [SMGUtils searchNode:itemT_p];
        [preview setData:itemT indexes:nil lab:lab left:0 top:0];
    }
}

-(ImgTrainerPreview*) getOrCreate:(NSString*)lab tvId:(NSInteger)tvId {
    //1. 每条itemAbsT分别可视化。
    ImgTrainerPreview *preview = [SMGUtils filterSingleFromArr:[self getPreviewDatas:tvId] checkValid:^BOOL(ImgTrainerPreview *preview) {
        return [lab isEqualToString:preview.lab.text];
    }];
    if (!preview) {
        preview = [[ImgTrainerPreview alloc] init];
        [[self getPreviewDatas:tvId] addObject:preview];
    }
    return preview;
}

//MARK:===============================================================
//MARK:                     < publicMethod >
//MARK:===============================================================
-(void) reloadData{
    [self refreshDisplay];
}
-(void) open{
    [self setHidden:false];
}
-(void) close{
    // 关闭摄像头预览
    [self stopCameraPreview];
    self.isCameraPreviewOn = NO;
    [self setHidden:true];
}

//取汉字的拼音
- (NSDictionary *) convertStrs2PinYinDic:(NSMutableArray *)strArr {
    NSMutableDictionary *result = [NSMutableDictionary new];
    for (NSString *stringdict in strArr) {
        NSString *string = stringdict;
        if ([string length]) {
            NSMutableString *mutableStr = [[NSMutableString alloc] initWithString:string];
        
            //2. 转成拼音
            CFStringTransform((__bridge CFMutableStringRef)mutableStr, 0, kCFStringTransformMandarinLatin, NO);
            
            //3. 去掉声调
            if (CFStringTransform((__bridge CFMutableStringRef)mutableStr, 0, kCFStringTransformStripDiacritics, NO)) {
                
                //4. 转成大写
                NSString *str = [NSString stringWithString:mutableStr];
                str = [str uppercaseString];
                [result setObject:str forKey:string];
            }
        }
    }
    return result;
}

-(void) removePreviewDatas {
    for (NSInteger i = 0; i < self.previewTVs.count; i++) {
        NSInteger tvId = i + 1;
        [self removePreviewDatas:tvId];
    }
}

-(void) removePreviewDatas:(NSInteger)tvId {
    //1. 去掉可视化lightDic。
    NSMutableArray *items = [self getPreviewDatas:tvId];
    for (ImgTrainerPreview *preview in items) {
        [preview removeFromSuperview];
    }
    [items removeAllObjects];
    
    //2. 重显示preview表。
    [[self getPreviewTV:tvId] reloadData];
}

-(UITableView*) getPreviewTV:(NSInteger)tvId {
    NSInteger index = tvId - 1;
    return ARR_INDEX(self.previewTVs, index);
}

-(NSMutableArray*) getPreviewDatas:(NSInteger)tvId {
    NSInteger index = tvId - 1;
    return ARR_INDEX(self.previewDatas, index);
}

-(NSInteger) getTVIdByTableView:(UITableView*)tableView {
    if ([self.previewTVs containsObject:tableView]) {
        NSInteger index = [self.previewTVs indexOfObject:tableView];
        NSInteger tvId = index + 1;
        return tvId;
    }
    return -1;
}

//MARK:===============================================================
//MARK:                     < onclick >
//MARK:===============================================================
- (IBAction)playBtnOnClick:(id)sender {
    //NSIndexPath *selected = [self.tv indexPathForSelectedRow];
    ImgTrainerItemModel *model = ARR_INDEX(self.tvDatas, self.curSelectRow);
    if (model) {
        // 指定哪一张。
        NSInteger picNum = STRISOK(self.picNumLab.text) ? self.picNumLab.text.integerValue : -1;
        if (picNum >= 0) model.imgIndex = picNum;
        
        // 自动跳到下一张。
        if (self.autoNextSwitch.isOn) {
            self.curSelectRow ++;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.tv selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.curSelectRow inSection:0] animated:false scrollPosition:UITableViewScrollPositionNone];
            });
        }
        
        //1. 取图
        NSArray *tryExts = @[@"JPEG",@"png",@"jpg"];
        UIImage *img = nil;
        for (NSString *ext in tryExts) {
            NSString *fileName = STRFORMAT(@"%@_%ld.%@",model.imgId,model.imgIndex,ext);
            NSString *fullPath = [model.folderPath stringByAppendingPathComponent:fileName];
            img = [UIImage imageWithContentsOfFile:fullPath];
            if (img) break;
        }
        if (!img) return;
        
        //2. 提交视觉
        [AIVisionAlgsV2 commitInputV2:img logDesc:STRFORMAT(@"%@_%ld",model.imgName,model.imgIndex)];
        
        //3. 预览图
        [self.curImgView setImage:img];
        
        //4. 下一张
        model.imgIndex++;
        [self refreshDisplay];
        
        //5. 去掉可视化lightDic。
        [self removePreviewDatas];
    }
}

-(void) previewTVLongPress:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    UITableView *tv = (UITableView*)gesture.view;
    NSInteger tvId = [self getTVIdByTableView:tv];
    if (tvId == -1) return;
    CGPoint point = [gesture locationInView:tv];
    NSIndexPath *indexPath = [tv indexPathForRowAtPoint:point];
    if (!indexPath) return;
    NSArray *datas = [self getPreviewDatas:tvId];
    ImgTrainerPreview *preview = ARR_INDEX(datas, indexPath.row);
    if (ISOK(preview.fromObj, AIFeatureJvBuModel.class)) {
        AIFeatureJvBuModel *jvBuModel = (AIFeatureJvBuModel*)preview.fromObj;
        JvBuDetailWindow *window = [[JvBuDetailWindow alloc] init];
        [window show:jvBuModel];
    }
}

- (IBAction)closeBtnOnClick:(id)sender {
    [self close];
}

- (void)captureBtnOnClick:(id)sender {
    // 只有在预览开启时才停止/恢复session
    BOOL wasRunning = self.isCameraPreviewOn && self.captureSession.isRunning;

    // 停止预览session（避免与AICameraCapture的session冲突）
    if (wasRunning) {
        dispatch_async(self.videoQueue, ^{
            [self.captureSession stopRunning];
            // 等待session真正停止
            while (self.captureSession.isRunning) {
                [NSThread sleepForTimeInterval:0.05];
            }
            // session停止后，开始拍照流程
            [self doCaptureAfterStopSession:wasRunning];
        });
    } else {
        // 没有预览session，直接拍照
        [self doCaptureAfterStopSession:wasRunning];
    }
}

- (void)doCaptureAfterStopSession:(BOOL)shouldResumePreview {
    // 使用AICameraCapture拍照
    [AICameraCapture startSession];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AICameraCapture capturePhotoWithCompletion:^(UIImage *image) {
            if (image) {
                // 显示到curImgView
                [self.curImgView setImage:image];

                // 保存到相册
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);

                // 清空旧显示
                [self removePreviewDatas];

                // 提交视觉
                [AIVisionAlgsV2 commitInputV2:image logDesc:@"camera_0"];
            }

            // 恢复预览session（如果之前是开启的）
            if (shouldResumePreview) {
                dispatch_async(self.videoQueue, ^{
                    [self.captureSession startRunning];
                    // 等待session真正启动
                    NSInteger waitCount = 0;
                    while (!self.captureSession.isRunning && waitCount < 20) {
                        [NSThread sleepForTimeInterval:0.1];
                        waitCount++;
                    }
                });
            }
        }];
    });
}

- (void)cameraPreviewViewTapped:(UITapGestureRecognizer *)gesture {
    // 单击切换预览开关
    if (self.isCameraPreviewOn) {
        [self stopCameraPreview];
    } else {
        [self startCameraPreview];
    }
    self.isCameraPreviewOn = !self.isCameraPreviewOn;
}

- (void)cameraPreviewViewDoubleTapped:(UITapGestureRecognizer *)gesture {
    // 双击拍照，调用captureBtnOnClick的逻辑
    [self captureBtnOnClick:nil];
}

// 强训工具事件
-(void) imgTrainerSelect:(NSNumber*)row {
    self.curSelectRow = row.integerValue;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tv selectRowAtIndexPath:[NSIndexPath indexPathForRow:self.curSelectRow inSection:0] animated:false scrollPosition:UITableViewScrollPositionNone];
        [theRT invoked:kImgTrainerSelect];
    });
}

-(void) imgTrainerPlay {
    [self playBtnOnClick:nil];
    [theRT invoked:kImgTrainerPlay];
}


//MARK:===============================================================
//MARK:       < UITableViewDataSource &  UITableViewDelegate>
//MARK:===============================================================
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.previewTVs containsObject:tableView]) {
        NSInteger index = [self.previewTVs indexOfObject:tableView];
        NSInteger tvId = index + 1;
        return [self getPreviewDatas:tvId].count;
    }
    return self.tvDatas.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    NSInteger tvId = -1;
    if ([self.previewTVs containsObject:tableView]) {
        NSInteger index = [self.previewTVs indexOfObject:tableView];
        NSInteger tvId = index + 1;
        NSArray *datas = [self getPreviewDatas:tvId];
        ImgTrainerPreview *subPreview = ARR_INDEX(datas, indexPath.row);
        [cell addSubview:subPreview];
        return cell;
    }
    
    ImgTrainerItemModel *model = ARR_INDEX(self.tvDatas, indexPath.row);
    NSString *curIndexing = (model.imgIndex==0) ? @"" : STRFORMAT(@"%ld",model.imgIndex - 1);//当前正在处理中的图
    NSString *imgNameDesc = [model.imgName isEqualToString:model.imgId] ? @"" : model.imgName;
    [cell.textLabel setText:STRFORMAT(@"%ld. %@ %@ %@",indexPath.row+1,model.imgId,imgNameDesc,curIndexing)];
    [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.previewTVs containsObject:tableView]) return cPreviewCellWidth + 15;
    return 20;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger tvId = [self getTVIdByTableView:tableView];
    if (tvId != -1) {
        NSArray *datas = [self getPreviewDatas:tvId];
        ImgTrainerPreview *preview = ARR_INDEX(datas, indexPath.row);
        if (ISOK(preview.fromObj, AIFeatureJvBuModel.class)) {
            // 长按弹出详情（见previewTVLongPress:）
            // 点击时，把bestGVs的每个元素gv，显示到tvId=3的tableView上去。
            AIFeatureJvBuModel *jvBuModel = (AIFeatureJvBuModel*)preview.fromObj;
            [self removePreviewDatas:3];
            NSArray *sortedKeys = [SMGUtils sortSmall2Big:jvBuModel.bestGVs.allKeys compareBlock:^double(NSNumber *obj) {
                return obj.integerValue;
            }];
            for (NSInteger i = 0; i < sortedKeys.count; i++) {
                AIFeatureJvBuItem *item = [jvBuModel.bestGVs objectForKey:@(i)];
                [self setDataForJvBuItem_Single:item fromFeatureNode:jvBuModel.assT lab:STRFORMAT(@"ST%ld.%ld",jvBuModel.assT.pId,i) tvId:3];
            }
        } else if (ISOK(preview.fromObj, AIFeatureNode.class)) {
            AIFeatureNode *tNode = (AIFeatureNode*)preview.fromObj;
            NSLog(@"AIFeatureNode被点击:%@ %@",Rect2Str(tNode.rect),CGRectIsEmpty(preview.fromCanvas) ? @"未指定" : Rect2Str(preview.fromCanvas));
        }
    }
    
    if ([self.previewTVs containsObject:tableView]) return;
    self.curSelectRow = indexPath.row;
}

@end
