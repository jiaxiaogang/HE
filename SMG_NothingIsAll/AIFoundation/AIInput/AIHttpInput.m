//
//  AIHttpInput.m
//  SMG_NothingIsAll
//
//  Created by Claude on 2026/6/2.
//

#import "AIHttpInput.h"
#import "AIInput.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataRequest.h"
#import "GCDWebServerDataResponse.h"

static GCDWebServer *_server;

@implementation AIHttpInput

+ (void)startServer:(NSInteger)port {
    if (_server && _server.isRunning) return;

    _server = [[GCDWebServer alloc] init];

    [_server addHandlerForMethod:@"POST"
                            path:@"/inputText"
                    requestClass:[GCDWebServerDataRequest class]
                    processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
        GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;
        NSString *text = nil;

        // 尝试解析JSON body: {"text":"..."}
        if (dataRequest.data.length > 0) {
            NSString *mimeType = dataRequest.contentType;
            if ([mimeType hasPrefix:@"application/json"] || [mimeType hasPrefix:@"text/json"]) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:dataRequest.data options:0 error:NULL];
                if ([json isKindOfClass:[NSDictionary class]]) {
                    text = json[@"text"];
                }
            }
        }

        // 兜底：纯文本body
        if (!text && dataRequest.data.length > 0) {
            text = [[NSString alloc] initWithData:dataRequest.data encoding:NSUTF8StringEncoding];
        }

        if (text.length > 0) {
            [AIInput inputTextFromHttpRequest:text];
        }

        NSDictionary *resp = @{@"code": @(0), @"msg": @"ok"};
        return [GCDWebServerDataResponse responseWithJSONObject:resp];
    }];

    [_server startWithPort:port bonjourName:nil];
    NSLog(@"AIHttpInput started on port %ld", (long)port);
}

+ (void)stopServer {
    [_server stop];
    _server = nil;
}

@end
