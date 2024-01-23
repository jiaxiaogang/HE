//
//  TCTransfer.h
//  SMG_NothingIsAll
//
//  Created by jia on 2023/4/17.
//  Copyright © 2023年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------迁移器--------------------
 *  @desc 负责Canset的迁移功能 (参考29069-todo10.1 & todo10.2 & 688示图);
 *  @desc 目前仅R任务支持迁移器,H任务暂未支持;
 */
@interface TCTransfer : NSObject

//MARK:===============================================================
//MARK:                     < 用体整体迁移算法 >
//MARK:===============================================================

/**
 *  MARK:--------------------canset迁移算法 (29069-todo10)--------------------
 */
+(void) transfer:(TOFoModel*)bestCansetModel complate:(void(^)(AITransferModel *brother,AITransferModel *father,AITransferModel *i))complate;

//MARK:===============================================================
//MARK:                     < 一用一体迁移算法 >
//MARK:===============================================================

/**
 *  MARK:--------------------伪迁移 (仅得出模型) (参考31073-TODO1)--------------------
 */
+(void) transferForModel:(TOFoModel*)rCansetModel;

/**
 *  MARK:--------------------迁移之体 (仅构建节点和初始spDic) (参考31073-TODO2c)--------------------
 */
+(void) transferForCreate:(TOFoModel*)cansetModel;

/**
 *  MARK:--------------------cansetAlg迁移算法 (29075-方案3)--------------------
 */
+(AIKVPointer*) transferAlg:(AISceneModel*)sceneModel canset:(AIFoNodeBase*)canset cansetIndex:(NSInteger)cansetIndex;

@end
