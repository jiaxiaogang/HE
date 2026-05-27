//
//  JvBuDetailWindow.m
//  SMG_NothingIsAll
//
//  Created by jia on 2026/5/22.
//  Copyright © 2026 XiaoGang. All rights reserved.
//

#import "JvBuDetailWindow.h"
#import "AIFeatureJvBuModel.h"
#import "SMGPrefixHeader.pch"

@implementation JvBuDetailWindow

-(id) init {
    self = [super initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.userInteractionEnabled = YES;
    }
    return self;
}

-(void) setData4JvBuModel:(AIFeatureJvBuModel*)jvBuModel {
    NSString *title = STRFORMAT(@"ST%ld bestGVs:%ld 匹配度:%.2f", jvBuModel.assT.pId, jvBuModel.bestGVs.count, jvBuModel.matchValue);
    
    // 每行一个bestGV
    NSArray *sortedKeys = [SMGUtils sortSmall2Big:jvBuModel.bestGVs.allKeys compareBlock:^double(NSNumber *obj) {
        return obj.integerValue;
    }];
    NSArray *lines = [SMGUtils convertArr:sortedKeys iConvertBlock:^id(NSInteger i, NSNumber *assIndex) {
        AIFeatureJvBuItem *item = [jvBuModel.bestGVs objectForKey:assIndex];
        NSMutableDictionary *fmtValues = [NSMutableDictionary dictionary];
        [item.baseGVMatchValue enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber *val, BOOL *stop) {
            fmtValues[key] = [NSString stringWithFormat:@"%.2f", val.doubleValue];
        }];
        return STRFORMAT(@"%ld. idx:%@ ProtoRect:%@ 四个相近值:%@", i + 1, assIndex, Rect2Str(item.bestGVAtProtoTRect), CLEANSTR(fmtValues));
    }];
    [self show:title lines:lines];
}

-(void) setData4JvBuItem:(AIFeatureJvBuItem*)jvBuItem {
    NSString *title = STRFORMAT(@"baseGV_p:%ld Rect:%@", jvBuItem.baseGV_p.pointerId, Rect2Str(jvBuItem.bestGVAtProtoTRect));
    NSMutableArray *lines = [NSMutableArray new];

    // 1. 显示baseGV_p的四个稀疏码值
    CGFloat totalMatchValue = 1;
    if (jvBuItem.baseGV_p) {
        AIGroupValueNode *gvNode = [SMGUtils searchNode:jvBuItem.baseGV_p];
        NSArray *sortedContent_ps = [gvNode.content_ps sortedArrayUsingComparator:^NSComparisonResult(AIKVPointer *a, AIKVPointer *b) {
            return [a.dataSource compare:b.dataSource];
        }];
        for (NSInteger i = 0; i < sortedContent_ps.count; i++) {
            AIKVPointer *value_p = ARR_INDEX(sortedContent_ps, i);
            double value = [NUMTOOK([AINetIndex getData:value_p]) doubleValue];
            double protoValue = [NUMTOOK(jvBuItem.protoGVIndex[value_p.dataSource]) doubleValue];
            CGFloat matchValue = [AIAnalyst compareCansetValue:value protoV:protoValue at:value_p.algsType ds:value_p.dataSource isOut:value_p.isOut vInfo:nil];
            
            [lines addObject:STRFORMAT(@"%ld. %@ baseGV:%.3f protoGV:%.3f 近:%.2f", i + 1, value_p.dataSource, value, protoValue, matchValue)];

            totalMatchValue *= matchValue;
        }
    }
    [lines addObject:STRFORMAT(@"总结：匹配度:%.2f", totalMatchValue)];
    [self show:title lines:lines];
}

-(void) show:(NSString*)title lines:(NSArray*)lines {
    // 移除旧子视图
    for (UIView *sub in self.subviews) [sub removeFromSuperview];

    // 容器：居中白色面板
    CGFloat panelW = ScreenWidth - 100;
    CGFloat panelH = 40 + lines.count * 20 + 30;
    panelH = MIN(panelH, ScreenHeight - 60);
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake((ScreenWidth - panelW) / 2, 64, panelW, panelH)];
    panel.backgroundColor = [UIColor whiteColor];
    panel.layer.cornerRadius = 8;
    panel.layer.borderWidth = 1;
    panel.layer.borderColor = [UIColor blackColor].CGColor;
    [self addSubview:panel];

    // 关闭按钮
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(panel.width - 36, 4, 32, 32);
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn setTintColor:[UIColor redColor]];
    [closeBtn addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:closeBtn];

    // 标题
    UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, panel.width - 50, 20)];
    titleLab.text = title;
    titleLab.font = [UIFont boldSystemFontOfSize:11];
    titleLab.adjustsFontSizeToFitWidth = YES;
    [panel addSubview:titleLab];

    // lines
    CGFloat y = 32;
    for (NSString *line in lines) {
        UILabel *lab = [[UILabel alloc] initWithFrame:CGRectMake(8, y, panel.width - 16, 18)];
        lab.text = line;
        lab.font = [UIFont systemFontOfSize:10];
        lab.adjustsFontSizeToFitWidth = YES;
        [panel addSubview:lab];
        y += 20;
    }

    // 显示到window
    [theApp.window addSubview:self];
}

-(void) close {
    [self removeFromSuperview];
}

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    UIView *hitView = [self hitTest:point withEvent:event];
    if (hitView == self) {
        [self close];
    }
}

@end
