//
//  SMGUtil+General.m
//  SMG_NothingIsAll
//
//  Created by jia on 2019/7/9.
//  Copyright © 2019年 XiaoGang. All rights reserved.
//

#import "SMGUtils+General.h"

@implementation SMGUtils (General)

//string
+(BOOL) strIsOk:(NSString*)s{
    return (s && ![s isKindOfClass:[NSNull class]] && [s isKindOfClass:[NSString class]] && ![s isEqualToString:@""]);
}
+(NSString*) strToOk:(NSString*)s{
    return (s && ![s isKindOfClass:[NSNull class]]) ? ([s isKindOfClass:[NSString class]] ? s : [NSString stringWithFormat:@"%@", s]) : @"";
}
+(NSArray*) strToArr:(NSString*)str sep:(NSString*)sep{
    str = STRTOOK(str);
    return [str componentsSeparatedByString:sep];
}

//log
/**
 *  MARK:--------------------titleLog--------------------
 *  @version
 *      xxxx.xx.xx: 初版#def IFTitleLog(t,fmt, ...) NSLog((@"\n\n------ " t @" ------"fmt), ##__VA_ARGS__);
 *      2022.05.31: v2版,封装成方法,并支持loopId;
 *      2022.09.28: 把---改成===,因为不靠这个分IO,改成===反而更加直观些;
 */
+(void) inTitle:(NSString*)title log:(NSString*)log fileName:(NSString*)fileName{
    NSString *side = @"===============================";
    NSLog_CustomFileName(fileName, @"\n\n%@ %lld %@ %@%@",side,theTC.getLoopId,title,side,log);
}
+(void) outTitle:(NSString*)title log:(NSString*)log fileName:(NSString*)fileName{
    NSString *side = @"===============================";
    NSLog_CustomFileName(fileName, @"\n\n%@ %lld %@ %@%@",side,theTC.getLoopId,title,side,log);
}
+(NSString*) codeLocateFormat:(NSString*)fileName line:(NSInteger)line{
    //1. 数据 准备
    fileName = STRTOOK(fileName);
    
    //2. 拼lineStr
    NSString *lineStr = STRFORMAT(@"%@%ld",(line > 999 ? @"" : ((line > 99 ? @" " : ((line > 9 ? @"  " : @"   "))))),(long)line);
    
    //3. 拼fileNameStr字符串
    NSString *fileNameStr = @"";
    NSInteger fileNameMax = 19;
    if (fileName.length > fileNameMax) {
        fileNameStr = STRFORMAT(@"%@..",[fileName substringToIndex:fileNameMax - 2]);
    }else{
        NSMutableString *prefix = [[NSMutableString alloc] init];
        for (NSInteger i = 0; i < fileNameMax - fileName.length; i++) {
            [prefix appendString:@" "];
        }
        fileNameStr = STRFORMAT(@"%@%@",prefix,fileName);
    }
    return STRFORMAT(@"%@%@",fileNameStr,lineStr);
}
+(NSString*) logLineNumFormat{
    //1. 转lineStr够5位 (不够的前面加空格);
    NSString *lineStr = STRFORMAT(@"%d",++logLineNum);
    for (NSInteger i = lineStr.length; i < 5; i++) {
        lineStr = STRFORMAT(@" %@",lineStr);
    }
    return lineStr;
}
+(void) checkPrintNSLog:(NSString*)fileName line:(NSInteger)line protoLog:(NSString*)protoLog headerMode:(LogHeaderMode)headerMode{
    //1. 记录下最后一条TC;
    if ([@"TC" isEqualToString:SUBSTRToIndex(fileName, 2)]) {
        lastTCName = fileName;
    }
    
    //2. 当TC有效时,打印它;
    BOOL tcsCanPrint = LogPrintAllTCs || !STRISOK(lastTCName) || [LogJustPrintTCs containsObject:SUBSTRToIndex(lastTCName, lastTCName.length - 2)];
    BOOL logSwitch = cNSLogSwitch && [cNSLogSwitchIsOpenTypes containsObject:[self getQueueStr]];
    
    //3. 打印
    //2023.07.20: 因为改到主线程导致当前线程提前销毁报错,直接取消切到主线程;
    if (logSwitch && tcsCanPrint) {
        NSString *log = [self nsLogFormat:fileName line:line protoLog:protoLog headerMode:headerMode];
        PrintLog(log);
    }
}

+(NSString*) nsLogFormat:(NSString*)fileName line:(NSInteger)line protoLog:(NSString*)protoLog headerMode:(LogHeaderMode)headerMode{
    //1. 数据准备
    protoLog = STRTOOK(protoLog);
    NSString *timeStr = [SMGUtils date2HHMMSSSSS];
    NSString *codeStr = [SMGUtils codeLocateFormat:fileName line:line];
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *queueStr = [self getQueueStr];
    
    //2. 拼接结果
    if (headerMode == LogHeaderMode_All) {
        NSString *sep = @"\n";
        NSArray *logLines = ARRTOOK(STRTOARR(protoLog, sep));
        for (NSString *logLine in logLines) {
            [result appendFormat:@"%@ [%@ %@ %@] %@\n",[SMGUtils logLineNumFormat],timeStr,queueStr,codeStr,logLine];
        }
    }else if(headerMode == LogHeaderMode_First){
        [result appendFormat:@"%@ [%@ %@ %@] %@\n",[SMGUtils logLineNumFormat],timeStr,queueStr,codeStr,protoLog];
    }else{
        [result appendFormat:@"%@\n",protoLog];
    }
    return result;
}

//线程简写名称
+(NSString*) getQueueStr {
    NSString *curQueueLab = [AIThinkingControl getCurQueueLab];
    if ([tiQueueLab isEqualToString:curQueueLab]) {
        return @"TI";
    } else if ([toQueueLab isEqualToString:curQueueLab]) {
        return @"TO";
    } else if ([@"com.apple.main-thread" containsString:curQueueLab]) {
        return @"MA";
    }
    return @"OT";
}

//注: STRFORMAT目前的宏定义中,并没有多余调用,所以不需要单独封装出来;
//注2: 如果有一天要使用此代码,可以尝试1: SMGArrayMake()来转换array, 尝试2:直接传递format,...到stringWithFormat:
//#define STRFORMAT(s, ...) [SMGUtils strFormat:s, ##__VA_ARGS__]
//+(NSString*) strFormat:(NSString*)format, ...{
//    va_list paramList;
//    va_start(paramList,format);
//    NSString *result = [[NSString alloc]initWithFormat:format arguments:paramList];
//    result = [result stringByAppendingString:@"\n"];
//    va_end(paramList);
//    //return [NSString stringWithFormat:s...];
//    //return [NSString stringWithFormat:a, ##__VA_ARGS__];
//    return result;
//}

//notnull
+(NSString*) subStr:(NSString*)s toIndex:(NSInteger)index{
    return (STRISOK(s) ? [s substringToIndex:MIN(s.length, MAX(0, index))] : @"");
}
+(NSString*) subStr:(NSString*)s fromIndex:(NSInteger)index{
    return (STRISOK(s) ? [s substringFromIndex:MIN(s.length, MAX(0, index))] : @"");
}

+(NSString*) cleanStr:(id)str{
    NSString *validStr = STRTOOK(str);
    validStr = [validStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    validStr = [validStr stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    //validStr = [validStr stringByReplacingOccurrencesOfString:@" " withString:@""];
    return validStr;
}

//array
+(BOOL) arrIsOk:(NSArray*)a{
    return a && [a isKindOfClass:[NSArray class]] && a.count;
}
+(NSArray*) arrToOk:(NSArray*)a{
    return (a && [a isKindOfClass:[NSArray class]]) ? a : [NSArray new];
}
+(id) arrIndex:(NSArray*)a index:(NSInteger)i{
    return [self arrIndexIsOk:a index:i] ? a[i] : nil;
}
+(id) arrTransIndex:(NSArray*)a index:(NSInteger)i{
    NSInteger index = ARRTOOK(a).count - 1 - i;
    return [self arrIndex:a index:index];
}
+(BOOL) arrIndexIsOk:(NSArray*)a index:(NSInteger)i{
    return (a && [a isKindOfClass:[NSArray class]] && a.count > i && i >= 0);
}

/**
 *  MARK:--------------------分隔数组--------------------
 *  @version
 *      2020.08.19: 将a.count提取为NSInteger类型,再参与MAX和MIN运算 (因为a.count默认为NSUInteger类型,导致s和l不支持负数)
 *  @result notnull (注意: subarrayWithRange是否可能返回null善未验证);
 */
+(NSArray*) arrSub:(NSArray*)a start:(NSInteger)s length:(NSInteger)l{
    NSInteger count = ARRISOK(a) ? a.count : 1;
    s = MAX(0, MIN(s,count));
    l = MAX(0, MIN(count - s, l));
    return (ARRISOK(a) ? [a subarrayWithRange:NSMakeRange(s, l)] : [NSArray new]);
}

+(NSString*) arrToStr:(NSArray*)arr prefix:(NSString*)prefix sep:(NSString*)sep {
    arr = ARRTOOK(arr);
    NSMutableString *result = [[NSMutableString alloc] init];
    for (NSInteger i = 0; i < arr.count; i++) {
        id item = ARR_INDEX(arr, i);
        [result appendFormat:@"%@%@%@",prefix,item,(i == arr.count - 1) ? @"" : sep];
    }
    return result;
}

//number
+(BOOL) numIsOk:(NSNumber*)n{
    return (n && [n isKindOfClass:[NSNumber class]]);
}
+(NSNumber*) numToOk:(NSNumber*)n{
    return [self numToOk:n defaultValue:0];
}
+(NSNumber*) numToOk:(NSNumber*)n defaultValue:(double)defaultValue{
    return (n && [n isKindOfClass:[NSNumber class]]) ? n : @(defaultValue);
}
+(NSValue*) valToOk:(NSValue*)n {
    return (n && [n isKindOfClass:[NSValue class]]) ? n : [NSValue new];
}

//dictionary
+(BOOL) dicIsOk:(NSDictionary*)d{
    return (d && [d isKindOfClass:[NSDictionary class]] && d.count);
}
+(NSDictionary*) dicToOk:(NSDictionary*)d{
    return (d && [d isKindOfClass:[NSDictionary class]]) ? d : [NSDictionary new];
}

//pointer (pointerId从0开始)
+(BOOL) pointerIsOk:(AIPointer*)p{
    return (p && [p isKindOfClass:[AIPointer class]] && p.pointerId >= 0);
}

//object
+(BOOL) isOk:(NSObject*)o class:(Class)c{
    return (o && [o isKindOfClass:c]);
}

//date2Str
+(NSString*) date2HHMMSS{
    return [SMGUtils date2Str:kHHmmss date:nil];
}
+(NSString*) date2HHMMSSSSS{
    return [SMGUtils date2Str:kHHmmssSSS date:nil];
}
+(NSString*) date2yyyyMMddHHmmss{
    return [SMGUtils date2Str:kyyyyMMddHHmmss date:nil];
}
+(NSString*) date2yyyyMMddHHmmssSSS:(NSDate*)date{
    return [SMGUtils date2Str:kyyyyMMddHHmmssSSS date:date];
}
+(NSString*) date2Str:(NSString*)format timeInterval:(long long)timeInterval{
    return [self date2Str:format date:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
}
+(NSString*) date2Str:(NSString*)format date:(NSDate*)date{
    if (!date) date = [NSDate new];
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = format;
    return [fmt stringFromDate:date];
}

//dateFromStr
+(NSDate*) dateFromTimeStr_yyyyMMddHHmmssSSS:(NSString*)timeStr{
    return [SMGUtils dateFromTimeStr:timeStr format:kyyyyMMddHHmmssSSS_Simple];
}
+(NSDate*) dateFromTimeStr:(NSString*)timeStr format:(NSString*)format{
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = STRTOOK(format);
    return [fmt dateFromString:timeStr];
}

//timestampFromStr
+(long long)timestampFromStr_yyyyMMddHHmmssSSS:(NSString*)timeStr defaultResult:(long long)defaultResult{
    long long result = defaultResult;
    if (STRISOK(timeStr)) {
        NSDate *date = [SMGUtils dateFromTimeStr_yyyyMMddHHmmssSSS:timeStr];
        if (date) {
            result = [date timeIntervalSince1970] * 1000.0f;
        }
    }
    return result;
}

//nsdata
+(NSArray*)datas2Objs:(NSArray*)datas{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    datas = ARRTOOK(datas);
    for (NSData *data in datas) {
        [result addObject:DATA2OBJ(data)];
    }
    return result;
}

//log
+(void)allLog:(NSString *)log{
    NSLog(@"%@",log);
    [theApp.heLogView addLog:log];
    [theApp setTipLog:log];
}

@end
