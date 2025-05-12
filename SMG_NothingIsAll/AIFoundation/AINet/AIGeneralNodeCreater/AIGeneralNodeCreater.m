//
//  AIGeneralNodeCreater.m
//  SMG_NothingIsAll
//
//  Created by jia on 2025/3/19.
//  Copyright © 2025 XiaoGang. All rights reserved.
//

#import "AIGeneralNodeCreater.h"

@implementation AIGeneralNodeCreater

/**
 *  MARK:--------------------构建组码--------------------
 *  @version
 *      2025.03.18: 支持构建组码（多个稀疏码组成）。
 *  @result notnull
 */
+(AIGroupValueNode*) createGroupValueNode:(NSArray*)item_ps conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut {
    return [AIGeneralNodeCreater createNode:item_ps conNodes:conNodes at:at ds:ds isOut:isOut newBlock:^id{
        AIGroupValueNode *newNode = [[AIGroupValueNode alloc] init];
        newNode.pointer = [SMGUtils createPointerForGroupValue:at dataSource:ds isOut:isOut];
        return newNode;
    } header:nil getRefPortsBlock:^NSArray *(AIKVPointer *item_p, NSInteger contentIndex) {
        return [AINetUtils refPorts_All4Value:item_p];
    }];
}

/**
 *  MARK:--------------------构建特征--------------------
 *  @version
 *      2025.03.19: 支持构建特征，由多个稀疏码（单码或组码）组成。
 *  @result notnull
 */
+(AIFeatureNode*) createFeatureNode:(NSArray*)groupModels conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut isJiao:(BOOL)isJiao {
    //2. 数据准备：转content_ps。
    NSArray *content_ps = [SMGUtils convertArr:groupModels convertBlock:^id(InputGroupValueModel *obj) {
        return obj.groupValue_p;
    }];
    NSArray *rects = [SMGUtils convertArr:groupModels convertBlock:^id(InputGroupValueModel *obj) {
        return @(obj.rect);
    }];
    
    //3. 生成node
    //注意：即使content_ps一模一样，level,x,y不一样时，一样不可以复用（所以要把level,x,y生成一个字符串也用于生成header）。
    NSString *header = [AINetUtils getFeatureNodeHeader:content_ps rects:rects];
    
    //4. 构建节点
    AIFeatureNode *result = [AIGeneralNodeCreater createNode:content_ps conNodes:conNodes at:at ds:ds isOut:isOut newBlock:^id{
        AIFeatureNode *newNode = [[AIFeatureNode alloc] init];
        newNode.pointer = [SMGUtils createPointerForFeature:at dataSource:ds isOut:isOut];
        
        //5. 单独存level,x,y值。
        newNode.rects = rects;
        
        //6. 是否交层,特征无法用长度来判断（类比时为交层，别的识别和proto构建全是似层）。
        newNode.pointer.isJiao = isJiao;
        
        return newNode;
    } header:header getRefPortsBlock:^NSArray *(AIKVPointer *item_p, NSInteger contentIndex) {
        return [AINetUtils refPorts_All:item_p];
    }];
    return result;
}

/**
 *  MARK:--------------------构建组特征--------------------
 *  @version
 *      2025.05.12: 支持构建组特征，由多个单特征组成。
 *  @result notnull
 */
+(AIGroupFeatureNode*) createGroupFeatureNode:(NSArray*)subTModels conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut isJiao:(BOOL)isJiao {
    //2. 数据准备：转content_ps。
    NSArray *content_ps = [SMGUtils convertArr:subTModels convertBlock:^id(InputGroupFeatureModel *obj) {
        return obj.feature_p;
    }];
    NSArray *rects = [SMGUtils convertArr:subTModels convertBlock:^id(InputGroupFeatureModel *obj) {
        return @(obj.rect);
    }];
    
    //3. 生成node
    //注意：即使content_ps一模一样，level,x,y不一样时，一样不可以复用（所以要把level,x,y生成一个字符串也用于生成header）。
    NSString *header = [AINetUtils getFeatureNodeHeader:content_ps rects:rects];
    
    //4. 构建节点
    AIGroupFeatureNode *result = [AIGeneralNodeCreater createNode:content_ps conNodes:conNodes at:at ds:ds isOut:isOut newBlock:^id{
        AIGroupFeatureNode *newNode = [[AIGroupFeatureNode alloc] init];
        newNode.pointer = [SMGUtils createPointerForGroupFeature:at ds:ds isOut:isOut];
        
        //5. 单独存level,x,y值。
        newNode.rects = rects;
        
        //6. 是否交层,特征无法用长度来判断（类比时为交层，别的识别和proto构建全是似层）。
        newNode.pointer.isJiao = isJiao;
        
        return newNode;
    } header:header getRefPortsBlock:^NSArray *(AIKVPointer *item_p, NSInteger contentIndex) {
        return [AINetUtils refPorts_All:item_p];
    }];
    return result;
}

/**
 *  MARK:--------------------通用节点构建器--------------------
 *  @param content_ps     : 要构建Node的content_ps (稀疏码组) notnull;
 *  @param conNodes      : 具象Node数组（可为空）。
 *  @param ds           : 为nil时,默认为DefaultDataSource;
 *  @result notnull
 */
+(id) createNode:(NSArray*)content_ps conNodes:(NSArray*)conNodes at:(NSString*)at ds:(NSString*)ds isOut:(BOOL)isOut newBlock:(id(^)())newBlock header:(NSString*)header getRefPortsBlock:(NSArray*(^)(AIKVPointer *item_p,NSInteger contentIndex))getRefPortsBlock {
    //1. 数据检查
    content_ps = ARRTOOK(content_ps);
    if (!at) at = DefaultAlgsType;
    if (!ds) ds = DefaultDataSource;
    if (!STRISOK(header)) header = [NSString md5:[SMGUtils convertPointers2String:content_ps]];
    NSMutableArray *validConAlgs = [[NSMutableArray alloc] initWithArray:conNodes];
    AINodeBase *result = nil;
    
    //2. 去重找本地 (仅抽象);
    AINodeBase *localResult = [AINetIndexUtils getAbsoluteMatching_ValidPs:content_ps findHeader:header except_ps:nil noRepeatArea_ps:nil getRefPortsBlock:getRefPortsBlock at:at ds:ds type:ATDefault];
    
    //3. 有则加强 并 返回;
    if (localResult) {
        [AINetUtils relateGeneralAbs:localResult absConPorts:localResult.conPorts conNodes:conNodes isNew:false difStrong:1];
        return localResult;
    }
    
    //4. 判断具象节点中,已有一个抽象sames节点,则不需要再构建新的;
    for (AINodeBase *checkNode in conNodes) {
        //b. 并且md5与orderSames相同时,即发现checkNode本身就是抽象节点;
        if ([checkNode.pointer.algsType isEqualToString:at] && [checkNode.pointer.dataSource isEqualToString:ds] && [header isEqualToString:checkNode.getHeaderNotNull]) {
            
            //c. 则把conAlgs去掉checkNode;
            [validConAlgs removeObject:checkNode];
            
            //d. 找到result
            result = checkNode;
        }
    }
    
    //5. 判断具象节点的absPorts中,是否已有一个"sames"节点,有则无需构建新的;
    if (!result) {
        for (AINodeBase *conNode in conNodes) {
            NSArray *absPorts_All = [AINetUtils absPorts_All:conNode];
            for (AIPort *absPort in absPorts_All) {
                //1> 遍历找抽象是否已存在;
                if ([header isEqualToString:absPort.header] && [absPort.target_p.algsType isEqualToString:at] && [absPort.target_p.dataSource isEqualToString:ds]) {
                    //3> findAbsNode成功;
                    result = [SMGUtils searchNode:absPort.target_p];
                    break;
                }
            }
        }
    }
    
    //6. 无则创建
    BOOL absIsNew = false;
    if (!result) {
        absIsNew = true;
        result = newBlock();
        
        //7. 存header到node
        result.header = header;
        
        [result setContent_ps:content_ps];
        //NSLog(@"构建新码:%@%ld fromConAlgs:%@",NSStringFromClass(result.class),result.pointer.pointerId,CLEANSTR([SMGUtils convertArr:conNodes convertBlock:^id(AINodeBase *obj) {
        //    return STRFORMAT(@"%@%ld",NSStringFromClass(obj.class),obj.pId);
        //}]));
    }
    
    //11. 关联 & 存储
    [AINetUtils relateGeneralAbs:result absConPorts:result.conPorts conNodes:validConAlgs isNew:absIsNew difStrong:1];
    [SMGUtils insertNode:result];
    
    //12. value.refPorts (更新/加强微信息的引用序列)
    [AINetUtils insertRefPorts_General:result.pointer content_ps:result.content_ps difStrong:1 header:header];
    return result;
}

@end
