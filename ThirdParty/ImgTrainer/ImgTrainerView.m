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

@interface ImgTrainerView () <UITableViewDelegate,UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITableView *tv;
@property (weak, nonatomic) IBOutlet UITableView *previewTableView;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIImageView *curImgView;
@property (strong, nonatomic) NSMutableArray *tvDatas;
@property (assign, nonatomic) NSInteger curSelectRow;
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
    CGFloat width = 670;
    [self setFrame:CGRectMake(ScreenWidth - width - 20, 64, width, ScreenHeight - 128)];
    
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
    self.previewTableView.delegate = self;
    self.previewTableView.dataSource = self;
    [self.previewTableView.layer setBorderWidth:1.0f];
    [self.previewTableView.layer setBorderColor:UIColorWithRGBHex(0x0000FF).CGColor];
}

-(void) initData{
    self.previewDatas = [NSMutableArray new];
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
 *  MARK:--------------------局部特征识别结果可视化（参考34176）--------------------
 */
-(void) setDataForJvBuModels:(NSArray*)jvBuModels protoT:(AIFeatureNode*)protoT {
    [self addFeatureToPreview:protoT lab:STRFORMAT(@"protoT%ld:%@",protoT.pId,protoT.ds)];
    for (AIMatchModel *model in jvBuModels) {
        //NSArray *collectProtoIndexs = model.indexDic.allValues;
        [self addFeatureToPreview:(AIFeatureNode*)model.matchNode lab:STRFORMAT(@"assT%ld:%@",model.matchNode.pId,model.matchNode.ds)];
    }
    [self.previewTableView reloadData];
}

-(void) setDataForFeature:(AIFeatureNode*)tNode lab:(NSString*)lab {
    [self addFeatureToPreview:tNode lab:lab];
    [self.previewTableView reloadData];
}

-(void) setDataForAlgs:(NSArray*)models {
    for (AIMatchAlgModel *model in models) {
        AIAlgNodeBase *assAlg = [SMGUtils searchNode:model.matchAlg];
        NSString *lab = STRFORMAT(@"A%ld:%@",assAlg.pId,CLEANSTR([assAlg getLogDesc:false].allKeys));
        [self addAlgToPreview:assAlg lab:lab];
    }
    [self.previewTableView reloadData];
}

-(void) setDataForAlg:(AINodeBase*)algNode lab:(NSString*)lab {
    [self addAlgToPreview:algNode lab:lab];
    [self.previewTableView reloadData];
}

//MARK:===============================================================
//MARK:                     < privateMethod >
//MARK:===============================================================

-(void) addFeatureToPreview:(AIFeatureNode*)tNode lab:(NSString*)lab {
    //1. 每条itemAbsT分别可视化。
    MapModel *old = [SMGUtils filterSingleFromArr:self.previewDatas checkValid:^BOOL(MapModel *item) {
        return [lab isEqualToString:item.v1];
    }];
    ImgTrainerPreview *preview = old ? old.v2 : nil;
    if (!preview) {
        preview = [[ImgTrainerPreview alloc] init];
        [self.previewDatas addObject:[MapModel newWithV1:lab v2:preview]];
    }
    
    //2. 并更新显示;
    [preview setData:tNode lab:lab];
}

-(void) addAlgToPreview:(AINodeBase*)algNode lab:(NSString*)lab{
    //1. 取preview 并更新显示;
    MapModel *old = [SMGUtils filterSingleFromArr:self.previewDatas checkValid:^BOOL(MapModel *item) {
        return [item.v1 isEqual:lab];
    }];
    ImgTrainerPreview *preview = old ? old.v2 : nil;
    if (!preview) {
        preview = [[ImgTrainerPreview alloc] init];
        [self.previewDatas addObject:[MapModel newWithV1:lab v2:preview]];
    }
    
    for (AIKVPointer *itemT_p in algNode.content_ps) {
        AIFeatureNode *itemT = [SMGUtils searchNode:itemT_p];
        [preview setData:itemT lab:lab];
    }
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
    //1. 去掉可视化lightDic。
    for (MapModel *item in self.previewDatas) {
        ImgTrainerPreview *preview = item.v2;
        [preview removeFromSuperview];
    }
    [self.previewDatas removeAllObjects];
    
    //2. 重显示preview表。
    [self.previewTableView reloadData];
}

//MARK:===============================================================
//MARK:                     < onclick >
//MARK:===============================================================
- (IBAction)playBtnOnClick:(id)sender {
    //NSIndexPath *selected = [self.tv indexPathForSelectedRow];
    ImgTrainerItemModel *model = ARR_INDEX(self.tvDatas, self.curSelectRow);
    if (model) {
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

- (IBAction)closeBtnOnClick:(id)sender {
    [self close];
}


//MARK:===============================================================
//MARK:       < UITableViewDataSource &  UITableViewDelegate>
//MARK:===============================================================
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([tableView isEqual:self.previewTableView]) {
        return self.previewDatas.count;
    }
    return self.tvDatas.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([tableView isEqual:self.previewTableView]) {
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        MapModel *model = ARR_INDEX(self.previewDatas, indexPath.row);
        ImgTrainerPreview *subPreview = model.v2;
        [cell addSubview:subPreview];
        return cell;
    }
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    ImgTrainerItemModel *model = ARR_INDEX(self.tvDatas, indexPath.row);
    NSString *curIndexing = (model.imgIndex==0) ? @"" : STRFORMAT(@"%ld",model.imgIndex - 1);//当前正在处理中的图
    NSString *imgNameDesc = [model.imgName isEqualToString:model.imgId] ? @"" : model.imgName;
    [cell.textLabel setText:STRFORMAT(@"%ld. %@ %@ %@",indexPath.row+1,model.imgId,imgNameDesc,curIndexing)];
    [cell.textLabel setFont:[UIFont systemFontOfSize:12]];
    return cell;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([tableView isEqual:self.previewTableView]) {
        return 115;
    }
    return 20;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView isEqual:self.previewTableView]) {
        return;
    }
    self.curSelectRow = indexPath.row;
}

@end
