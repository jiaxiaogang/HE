//
//  AIHttpInput.h
//  SMG_NothingIsAll
//
//  Created by Claude on 2026/6/2.
//

#import <Foundation/Foundation.h>

/**
 *  MARK:--------------------HTTP文本输入--------------------
 *  接受外部系统通过HTTP POST发送过来的文本，接入AIInput。
 *
 *  @用法
 *    [AIInput startHttpInputServer:8080];
 *    [AIInput stopHttpInputServer];
 *
 *  @接口
 *    POST /inputText  body: {"text":"内容"}  response: {"code":0,"msg":"ok"}
 */
@interface AIHttpInput : NSObject

+ (void)startServer:(NSInteger)port;
+ (void)stopServer;

@end
