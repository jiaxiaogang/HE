//
//  AIPointer.h
//  SMG_NothingIsAll
//
//  Created by 贾  on 2017/5/20.
//  Copyright © 2017年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------指针基类--------------------
 *  1. 可以指向任何表的任一项;
 *  2. 指针的字段,是为指针的使用者而设的;例如A有B的指针,则需要B指针描述B的确切位置;
 *  @version
 *      2022.10.09: 废弃isMem (参考27124-todo1);
 */
@interface AIPointer : NSObject <NSCoding,NSCopying>

@property (assign, nonatomic) NSInteger pointerId;          //指针地址(Id)
@property (strong, nonatomic) NSMutableDictionary *params;  //用于分区(在二分查巨量队列,params越细分,越有利性能)
@property (assign, nonatomic) BOOL isJiao;                  //是否交层(默认false);
@property (assign, nonatomic) BOOL isGT;                    //是否整体特征(默认false);
-(NSString*) filePath;                                      //文件路径(可以是key,或者path,或者sql表和行号等)

/**
 *  MARK:--------------------分区标识--------------------
 *  @组成: 一般由 "algsType" + "dataSource/Source" 组成;
 *  @result notnull
 */
-(NSString*) identifier;
-(id) paramForKey:(NSString*)key;

@end
