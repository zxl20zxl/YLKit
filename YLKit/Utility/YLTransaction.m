//
//  YLTransaction.m
//  YLKit
//
//  Created by 张晓岚 on 16/8/2.
//  Copyright © 2016年 ThinkMobile. All rights reserved.
//

#import "YLTransaction.h"

@interface YLTransaction()
@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL selector;
@end

static NSMutableSet *transactionSet = nil;

static void YYRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    if (transactionSet.count == 0) return;
    NSSet *currentSet = transactionSet;
    transactionSet = [NSMutableSet new];
    [currentSet enumerateObjectsUsingBlock:^(YLTransaction *transaction, BOOL *stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [transaction.target performSelector:transaction.selector];
#pragma clang diagnostic pop
    }];
}

static void YYTransactionSetup() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transactionSet = [NSMutableSet new];
        CFRunLoopRef runloop = CFRunLoopGetMain();
        CFRunLoopObserverRef observer;
        
        observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(),
                                           kCFRunLoopBeforeWaiting | kCFRunLoopExit,
                                           true,      // repeat
                                           0xFFFFFF,  // after CATransaction(2000000)
                                           YYRunLoopObserverCallBack, NULL);
        CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}

@implementation YLTransaction

+ (YLTransaction *)transactionWithTarget:(id)target selector:(SEL)selector{
    if (!target || !selector) return nil;
    YLTransaction *t = [YLTransaction new];
    t.target = target;
    t.selector = selector;
    return t;
}

- (void)commit {
    if (!_target || !_selector) return;
    YYTransactionSetup();
    [transactionSet addObject:self];
}

- (NSUInteger)hash {
    long v1 = (long)((void *)_selector);
    long v2 = (long)_target;
    return v1 ^ v2;
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isMemberOfClass:self.class]) return NO;
    YLTransaction *other = object;
    return other.selector == _selector && other.target == _target;
}

@end
