//
//  TOMVisionFoView.m
//  SMG_NothingIsAll
//
//  Created by jia on 2022/3/15.
//  Copyright © 2022年 XiaoGang. All rights reserved.
//

#import "TOMVisionFoView.h"

@interface TOMVisionFoView ()

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *headerBtn;

@end

@implementation TOMVisionFoView

-(void) initView{
    //self
    [super initView];
    [self setFrame:CGRectMake(0, 0, 40, 10)];
    
    //containerView
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil];
    [self addSubview:self.containerView];
}

-(void) refreshDisplay{
    //1. 检查数据;
    [super refreshDisplay];
    if (!self.data) return;
    AIFoNodeBase *fo = [SMGUtils searchNode:self.data.content_p];
    
    [self.headerBtn setTitle:STRFORMAT(@"F%ld",self.data.content_p.pointerId) forState:UIControlStateNormal];
    
    //2. 刷新UI;
    for (AIKVPointer *alg_p in fo.content_ps) {
        //可以显示一些容易看懂的,比如某方向飞行,或者吃,果,棒,这些;
        
        
    }
}

//MARK:===============================================================
//MARK:                     < override >
//MARK:===============================================================
-(void) setData:(TOFoModel*)value{
    [super setData:value];
    [self refreshDisplay];
}

-(TOFoModel*) data{
    return (TOFoModel*)[super data];
}

-(void) setFrame:(CGRect)frame{
    [super setFrame:frame];
    [self.containerView setFrame:CGRectMake(0, 0, self.width, self.height)];
    [self.headerBtn setFrame:CGRectMake(0, 0, self.width, self.height)];
}

@end
