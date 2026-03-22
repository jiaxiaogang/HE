//
//  AITest.m
//  SMG_NothingIsAll
//
//  Created by jia on 2021/9/25.
//  Copyright © 2021年 XiaoGang. All rights reserved.
//

#import "AITest.h"

@implementation AITest

//MARK:===============================================================
//MARK:               < 异常单元测试 (常开,有异常时停在断点) >
//MARK:===============================================================

+(void) test1:(NSString*)aDS hnAlgDS:(NSString*)hnAlgDS{
    if (!Switch4AITest) return;
    if (![aDS isEqualToString:@" "] ||
        ![hnAlgDS isEqualToString:@" "]) {
        NSLog(@"自检1: 测下getHN经验时vDS匹配判断代码是否多余,多余告警");
    }
}

+(void) test2:(AIKVPointer*)pointer type:(AnalogyType)type at:(NSString*)at ds:(NSString*)ds{
    if (!Switch4AITest) return;
    if (PitIsFo(pointer) || PitIsAlg(pointer)) {
        if (type == ATGreater || type == ATLess) {
            if ([@"AIVisionAlgs" isEqualToString:at]){
                if (![ds isEqualToString:@"sizeWidth"] &&
                    ![ds isEqualToString:@"sizeHeight"] &&
                    ![ds isEqualToString:@"colorRed"] &&
                    ![ds isEqualToString:@"colorBlue"] &&
                    ![ds isEqualToString:@"colorGreen"] &&
                    ![ds isEqualToString:@"radius"] &&
                    ![ds isEqualToString:@"direction"] &&
                    ![ds isEqualToString:@"distance"] &&
                    ![ds isEqualToString:@"distanceY"] &&
                    ![ds isEqualToString:@"speed"] &&
                    ![ds isEqualToString:@"border"] &&
                    ![ds isEqualToString:@"posX"] &&
                    ![ds isEqualToString:@"posY"]) {
                    NSLog(@"自检2: 测生成GL的AIKVPointer时的ds是否正常赋值,因为它影响node防重;");
                }
            }
        }
    }
}

+(void) test3:(AIKVPointer*)pointer type:(AnalogyType)type ds:(NSString*)ds{
    if (!Switch4AITest) return;
    if (PitIsFo(pointer) || PitIsAlg(pointer)) {
        if (type != ATGreater && type != ATLess) {
            if (![ds isEqualToString:@" "]) {
                NSLog(@"自检3. 测生成非GL的AIKVPointer时的ds是否为" ",因为它影响node防重;");
            }
        }
    }
}

+(void) test4:(AIKVPointer*)pointer at:(NSString*)at isOut:(BOOL)isOut{
    if (!Switch4AITest) return;
    if (PitIsValue(pointer)) {
        if ([at isEqualToString:FLY_RDS] && !isOut) {
            NSLog(@"自检4: 行为飞稀疏码的isOut为false的问题");
        }
    }
}

+(void) test5:(AIKVPointer*)pointer type:(AnalogyType)type at:(NSString*)at{
    if (!Switch4AITest) return;
    if (PitIsFo(pointer) || PitIsAlg(pointer)) {
        if (type == ATGreater || type == ATLess) {
            if (![@"AIVisionAlgs" isEqualToString:at] &&
                ![FLY_RDS isEqualToString:at]) {
                NSLog(@"自检5: 测生成GL的AIKVPointer时的at是否正常赋值,因为它影响node防重");
            }
        }
    }
}

+(void) test6:(NSArray*)arr{
    if (!Switch4AITest) return;
    arr = ARRTOOK(arr);
    if (arr.count > 1) {
        NSLog(@"自检6: 测从conNodes取at&ds&type应唯一,否则查为何不同的node会类比抽象");
    }
}

+(void) test7:(NSArray*)arr type:(AnalogyType)type{
    if (!Switch4AITest) return;
    if (type == ATPlus || type == ATSub) {
        NSArray *types = [SMGUtils removeRepeat:[SMGUtils convertArr:arr convertBlock:^id(AIKVPointer *obj) {
            return @(obj.type);
        }]];
        if (types.count > 1) {
            NSLog(@"自检7: 测构建SPFo时,元素有两种类型的原因(参考24022BUG3)");
        }
    }
}

+(void) test8:(NSArray*)content_ps type:(AnalogyType)type{
    if (!Switch4AITest) return;
    for (AIKVPointer *item_p in content_ps) {
        if (item_p.type != ATDefault && item_p.type != type) {
            NSLog(@"自检8: 测构建Fo时,有不匹配type的元素原因(参考24022BUG4)");
        }
    }
}

+(void) test9:(AIFoNodeBase*)fo type:(AnalogyType)type{
    if (!Switch4AITest) return;
    if (type == ATPlus && [Fo2FStr(fo) containsString:@"Y距35"]) {
        NSLog(@"自检9: 测构建了Y距35的P节点原因(参考24057)");
    }
}

+(void) test10:(TOModelBase*)toModel{
    if (!Switch4AITest) return;
    //plan取得结果为actNo状态的自检;
    if(toModel.status == TOModelStatus_ActNo){
        WLog(@"自检10: Plan结果为已ActNo状态");
    }
}

+(void) test11:(AIShortMatchModel*)shortModel waitAlg_p:(AIKVPointer*)waitAlg_p{
    if (!Switch4AITest) return;
    //2523c-理性反馈,的旧有mIsC方式没问题,但新matchAlgs+partAlgs的方式却有BUG;
    //怀疑是反馈这块有匹配不到的问题,但又复现不了,所以此处写test11来测试下,希望能复现,报到错;
    if (shortModel && waitAlg_p) {
        NSArray *recognitionAlgs = [SMGUtils convertArr:shortModel.matchAlgs_All convertBlock:^id(AIMatchAlgModel *o) {
            return o.matchAlg;
        }];
        NSArray *mAbs = Ports2Pits([AINetUtils absPorts_All:shortModel.protoAlg]);
        BOOL oldMIsC = [mAbs containsObject:waitAlg_p];
        BOOL newMIsC = [recognitionAlgs containsObject:waitAlg_p];
        
        if (oldMIsC && !newMIsC) {
            ELog(@"自检11: 复现成功,二者不一样: 对比下mAbs和recognitionAlgs,看下区别,为什么导致newMIsC未匹配到");
        }
    }
}

+(void) test12:(CGFloat)score {
    if (!Switch4AITest) return;
    if (score > 1000 || score < -1000) {
        ELog(@"自检12: 评分异常");
    }
}

+(void) test13:(NSArray*)slowSolutionCansets {
    if (!Switch4AITest) return;
    if (slowSolutionCansets && slowSolutionCansets.count > 1000) {
        ELog(@"自检13: 求解候选集太长,建议限limit");
    }
}

+(void) test14:(CGFloat)near {
    if (!Switch4AITest) return;
    if (near == 0) {
        ELog(@"自检14: 怎么会有near=0的抽具象关联咧?查下是matchDic中没存着么?");
    }
}

+(void) test15:(AIMatchFoModel*)model {
    if (!Switch4AITest) return;
    if (model.realMaskFo.count != model.realDeltaTimes.count) {
        ELog(@"自检15: 经查AIMatchFoModel里的proto所需的两个数组不一样长度,有BUG,但下为什么不一样长,不一样长的话,就没法生成有效的order从而构建(完全)protoFo");
    }
}

+(void) test16:(CGFloat)algHDMatchValue {
    if (!Switch4AITest) return;
    if (algHDMatchValue == 0) {
        ELog(@"自检16: 概念相似度复用为0,但下原因");
    }
}

+(void) test17 {
    if (!Switch4AITest) return;
    NSLog(@"自检17: 此处打到断点时,先稳步查看n28p07-末尾-未完成项,再继续");
    NSLog(@"自检17: 核实下,H任务触发canset再类比的时机:targetAlg有反馈? (参考28071)");
    NSLog(@"自检17: 核实下,H任务触发canset再类比的条件:要求targetFo或hDemand的状态? (参考28077-另外)");
}

+(void) test18:(NSDictionary*)newIndexDic newCanset:(AIFoNodeBase*)newCanset absFo:(AIFoNodeBase*)absFo {
    if (!Switch4AITest) return;
    for (NSNumber *key in newIndexDic.allKeys) {
        NSInteger absIndex = key.integerValue;
        NSInteger conIndex = NUMTOOK([newIndexDic objectForKey:key]).integerValue;
        AIKVPointer *conAlg = ARR_INDEX(newCanset.content_ps, conIndex);
        AIKVPointer *absAlg = ARR_INDEX(absFo.content_ps, absIndex);
        if (![TOUtils mIsC_1:conAlg c:absAlg]) {
            ELog(@"自检18: 检查newCanset的indexDic有误");
        }
    }
}

+(void) test19:(AISPStrong*)newSPStrong {
    if (!Switch4AITest) return;
    if (newSPStrong.sStrong < 0 || newSPStrong.pStrong < 0) {
        ELog(@"自检19: 检查newSPStrong有误,肯定是前面少计数了,导致后面的P太大,而前面的SP之和反而小于它");
    }
}

+(void) test20:(AIFoNodeBase*)newCanset newSPDic:(NSDictionary*)newSPDic {
    if (!Switch4AITest) return;
    if (newCanset.count != newSPDic.count) {
        ELog(@"自检20: 检查newSPDic有误,它的长度不等于absCanset长度,查下原因");
    }
}

+(void) test21:(BOOL)refrectionResult {
    if (!Switch4AITest) return;
    if (!refrectionResult) {
        ELog(@"自检21: 调试下反思未通过的原因,此处仅为了保证反思有失败时,且失败的原因合理");
    }
}

+(void) test22 {
    if (!Switch4AITest) return;
    ELog(@"自检22: 发现indexDic在absIndex下找不到conIndex,查下为什么没映射到?是不是识别时全含判断错了?");
}

+(void) test23:(NSDictionary*)pmDic cmDic:(NSDictionary*)cmDic matchIndex:(NSInteger)matchIndex {
    if (!Switch4AITest) return;
    if (![pmDic objectForKey:@(matchIndex)] || ![cmDic objectForKey:@(matchIndex)]) {
        ELog(@"自检23: matchIndex在前段条件判断中,未找到proto或canset的映射,查下原因 (H任务跳转多了是否有找不着的可能?)");
    }
}

+(void) test24:(NSArray*)absArrForEmptyAlgOfAbsCountCheck {
    if (!Switch4AITest) return;
    if (!ARRISOK(absArrForEmptyAlgOfAbsCountCheck)) {
        ELog(@"自检24: 构建空抽象时,它的具象概念们的抽象没有共同抽象! (查下Canset识别算法,它有共同抽象才被全含匹配到,如果匹配了,但却没共同抽象,显然有问题)");
    }
}

//2024.08.1: 在类比后,构建absAlg后,这里会立马构建关联,此时还没设置抽具象概念的matchValue值,所以改为设置相似度值后,再调用此方法检查;
+(void) test25:(AINodeBase*)absNode conNodes:(NSArray*)conNodes {
    NSArray *copyConAlgs = [conNodes copy];
    for (AINodeBase *con in copyConAlgs) {
        if (absNode.pId != con.pId && ![absNode.conMatchDic objectForKey:@(con.pId)]) {
            //这个错报也没啥事,因为有时卡了,还没存上,就执行了这儿,如果这里的错一直报了,可以查下test26,只要26不报,说明取用时没问题,这个存自然也就没问题;
            ELog(@"自检25: 存抽具象节点匹配度: 抽具象关联后: 二者的匹配度未保存,查下为什么匹配度没写存上 abs:%ld con:%ld",absNode.pId,con.pId);
        }
    }
}

+(void) test26:(NSDictionary*)matchDic checkA:(AIKVPointer*)checkA {
    if (![matchDic objectForKey:@(checkA.pointerId)]) {
        //ELog(@"自检26: 取概念匹配度: 复用概念匹配度失败,查下为什么");//报的很多,但没时间查,先注掉
    }
}

/**
 *  MARK:--------------------test27--------------------
 *  @desc 作用说明: 在Canset类比中,用old和new生成最终indexDic应该是一致的,此test27用于检查二者是否一致,如果不一致则查下是不是有什么BUG;
 *        有效日期: 2023.08前如果未发现问题,则test27可删掉;
 */
+(void) test27:(AIFoNodeBase*)sceneFo oldCanset:(AIKVPointer*)oldCanset_p oldIndexDic:(NSDictionary*)oldIndexDic compareIndexDicFromNewCanset:(NSDictionary*)compareIndexDicFromNewCanset {
    NSDictionary *sceneOldCansetIndexDic = [sceneFo getConIndexDic:oldCanset_p];
    NSMutableDictionary *indexDicFromOldCanset = [[NSMutableDictionary alloc] init];
    for (id sceneIndex in sceneOldCansetIndexDic.allKeys) {
        id oldCansetIndex = [sceneOldCansetIndexDic objectForKey:sceneIndex];
        id absCansetIndex = ARR_INDEX([oldIndexDic allKeysForObject:oldCansetIndex], 0);
        if (absCansetIndex) [indexDicFromOldCanset setObject:absCansetIndex forKey:sceneIndex];
    }
    
    //> 在canset类比中已经为new生成了indexDic,本test27中再为old生成indexDic,然后对比二者是否一致,不一致则打出错误日志;
    NSString *newStr = CLEANSTR(compareIndexDicFromNewCanset);
    NSString *oldStr = CLEANSTR(indexDicFromOldCanset);
    if (![newStr isEqualToString:oldStr]) {
        ELog(@"自检27: 测得Canset类比的最终生成indexDic从新旧路径不一致!!!查下为什么: new:%@ old:%@",newStr,oldStr);
    }
}

+(void) test28:(AIShortMatchModel*)inModel {
    for (AIMatchFoModel *item in inModel.matchPFos) {
        AIFoNodeBase *fo = [SMGUtils searchNode:item.matchFo];
        AIKVPointer *alg_p = ARR_INDEX(fo.content_ps, item.cutIndex);
        if (![SMGUtils filterSingleFromArr:inModel.matchAlgs_Si checkValid:^BOOL(AIMatchAlgModel *obj) {
            return [obj.matchAlg isEqual:alg_p];
        }]) {
            ELog(@"自检28: 测得matchPFos的cutIndex对应的下标alg竟然不属于matchAlgs,按道理来cutIndex是刚发生的最后一帧,然后最后一帧应该都抽象源自matchAlgs才对");
        }
    }
}

+(void) test29:(AIAlgNodeBase*)protoA assA:(AIAlgNodeBase*)assA {
    if (!protoA || !assA) {
        ELog(@"自检29: alg类比器有闪退的情况,报arrayWithObjects:count:什么错,怀疑是这俩有一个是空的,如果这里触发了,断点,并查下为何为空,是_p没取到algNode吗,还是啥情况?");
    }
}

+(void) test30:(NSInteger)sumStrong {
    if (sumStrong < 2) {
        ELog(@"自检30: 时序类比抽象时,已经建立了关联,所以关联强度最小也是2,小于2则断点立马查下为什么");
    }
}

+(void) test31:(NSArray*)deltaTimes {
    deltaTimes = ARRTOOK(deltaTimes);
    for (NSInteger i = 0; i < deltaTimes.count; i++) {
        NSNumber *item = ARR_INDEX(deltaTimes, i);
        if (i == 0 && item.doubleValue != 0) {
            ELog(@"自检31: 时间deltaTime的0位不是0");
        } else if (i > 0) {
            if (item.doubleValue == 0) {
                ELog(@"自检31: 时间deltaTime的非0位是0");
            } else if (item.doubleValue > 900) {
                ELog(@"自检31: 时间deltaTime的非0位>900");
            }
        }
    }
}

+(void) test32:(AIFoNodeBase*)protoCanset newCanset:(AIFoNodeBase*)newCanset {
    if (protoCanset.count != newCanset.count) {
        ELog(@"自检32: 在迁移发生后,迁移前后的两个canset必须长度一致,不然会导致3101b-todo1继承的SP值失败或错位,如果这条日志打印了,请先检查一下是两个canset长度不一致有BUG,还是设计改变了,那么SP的继承也要跟着改下");
    }
}

+(void) test33:(AIFoNodeBase*)iScene fScene:(AIKVPointer*)fScene {
    if (![iScene.p isEqual:fScene] && ![iScene.absMatchDic objectForKey:@(fScene.pointerId)]) {
        BOOL aaa = [Ports2Pits(iScene.absPorts) containsObject:fScene];//核实下,到底是不是抽具象关联?
        BOOL bbb = [TOUtils mIsC_1:iScene.p c:fScene];
        ELog(@"自检33: 现在场景树只有IF两层,而IF也必然有抽具象关系,所以迁移场景之间,没有抽具象关联是BUG: 查下relateTransfer中排查下它哪来的 || 或者取IF场景树时是不是就有问题 || 或者认知期就把抽具象关联漏了? (参考33143&33144) %d %d",aaa,bbb);
    }
}

+(void) test34:(NSDictionary*)indexDic {
    if ([SMGUtils removeRepeat:indexDic.allKeys].count < indexDic.count || [SMGUtils removeRepeat:indexDic.allValues].count < indexDic.count) {
        ELog(@"映射有重复BUG %@ (看起来主要是realIndexDic来的,查下重复原因)",indexDic);//此BUG如果再出现，打开配套日志分析之（日志搜：test3435配套日志）
    }
}

+(void) test35:(NSDictionary*)oldIndexDic newK:(NSInteger)newK newV:(NSInteger)newV {
    if ([oldIndexDic objectForKey:@(newK)] || ARRISOK([oldIndexDic allKeysForObject:@(newV)])) {
        ELog(@"自检35: indexDic:%@更新的KV(K%ld V%ld)又重复了，但下为何重复的，一般情况下：",CLEANSTR(oldIndexDic),newK,newV);//此BUG如果再出现，打开配套日志分析之（日志搜：test3435配套日志）
        
        //===== 1、如果是V重复那就是realMaskFo少收集了（在TIR或TIP中都要收集输入才可以）
        //这一条的BUG出现过，并且已修已回测ok (参考：全局搜索RealCansetToIndexDic重复BUG)。
        
        //===== 2、如果是K重复那就是CansetTo.ActIndex推进重复了，查下会不会是init或fix映射后的映射超过了ActIndex的位置，导致ActIndex又被反馈到后，就重复计了。");
        //这一条BUG未出现过，但理论上，现代码可能出现这问题，如果出现了，就把init或fix后的CutIndex重新往后靠下，但要观察理顺相关数据，看这BUG是否来源明确，修好也没啥别的影响。
        //曾疑似出现过此BUG记录：在RealCansetToIndexDic初始化时就有问题,它既然已经有了末帧的初始映射,那么后续再更新时,就不应该再更新末帧了(导致重复),
        //分析1: 看来,在initRealCansetToDic()时,cansetTo正在执行中的帧,可能与realMaskFo有映射,说白了,表示它已经实现了;
        //分析2: initRealCansetToDic后,actIndex应该也得更新下?毕竟正在等待中的可能已经被实现了;
        //分析3: 再向前追查下: 为什么cansetCutIndex会计算错误?明明已经实现的帧,为什么在计算的cansetCutIndex之后?
        //怀疑: 是sceneFromCansetFrom比sceneToCansetTo的映射更少，导致前者取cutIndex靠前，后者靠后。
        //或者: sceneFrom也有cutIndex，而这里在initRealCansetToDic时，没考虑这个进度的限制？//但pFo.indexDic2就是real映射，它是必定已经发生了的，那为什么sceneFrom的cutIndex又那么靠前呢？
    }
}

+(void) test36:(NSDictionary*)indexDic conNode:(AINodeBase*)conNode absNode:(AINodeBase*)absNode {
    // 看下有没indexDic越界了;
    for (NSNumber *key in indexDic.allKeys) {
        NSNumber *value = [indexDic objectForKey:key];
        if (value.integerValue >= conNode.count) {
            ELog(@"映射的value越界,已修,复测一段时间,遇过两次,都修了");
        } else if (key.integerValue >= absNode.count) {
            ELog(@"映射的key越界,已修,复测一段时间,遇过两次,都修了");
        }
    }
}

//MARK:===============================================================
//MARK:    < 回测必经点测试 (常关,每个轮回测时打开,触发则关,未触发者为异常) >
//MARK:===============================================================
+(void) test101:(NSArray*)absCansetOrders newCansetOrders:(NSArray*)newCansetOrders oldCansetOrder:(NSArray*)oldCansetOrder {
    if (!Switch4AITest) return;
    WLog(@"必经点测试: 触发canset再抽象执行到;\n\tabsCanset %@ from:\n\tproto:%@\n\tconConset:%@",Pits2FStr(Simples2Pits(absCansetOrders)),Pits2FStr(Simples2Pits(newCansetOrders)),Pits2FStr(Simples2Pits(oldCansetOrder)));
}

+(void) test102:(AIKVPointer*)cansetFrom_p {
    if (!Switch4AITest) return;
    //测试27222-1,TCSolution取得抽象canset;
    if ([cansetFrom_p.dataSource isEqualToString:@"AINetAbsFoNode"]) {
        WLog(@"必经点测试: 读取到抽象canset: %@",cansetFrom_p.identifier);
    }
}

@end
