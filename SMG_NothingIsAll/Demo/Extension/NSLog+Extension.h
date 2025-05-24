//
//  NSLog+Extension.h
//  SMG_NothingIsAll
//
//  Created by jia on 2020/9/21.
//  Copyright © 2020年 XiaoGang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSLog_Extension : NSObject

+(NSString*) convertTOStatus2Desc:(TOModelStatus)status;
+(NSString*) convertATType2Desc:(AnalogyType)atType;
+(NSString*) convertTIStatus2Desc:(TIModelStatus)status;
+(NSString*) convertCansetStatus2Desc:(CansetStatus)status;
+(NSString*) convertClass2Desc:(Class)clazz;
+(NSString*) convertClassName2Desc:(NSString*)className;
+(NSString*) convertMvp2DeltaDesc:(AIKVPointer*)mv_p;
+(NSString*) convertSceneType2Desc:(SceneType)type simple:(BOOL)simple;
+(NSString*) convertRect2Desc:(CGRect)rect;

@end
