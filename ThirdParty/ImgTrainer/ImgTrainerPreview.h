//
//  ImgTrainerPreview.h
//  SMG_NothingIsAll
//
//  Created by jia on 2025/4/27.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImgTrainerPreview : UIView

@property (strong, nonatomic) UILabel *lab;
@property (strong, nonatomic) NSMutableDictionary *lightDic;
@property (strong, nonatomic) NSMutableDictionary *hsbDic;

-(void) setData:(AIFeatureNode*)tNode lab:(NSString*)lab;

@end
