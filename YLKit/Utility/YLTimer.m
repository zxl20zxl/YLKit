//
//  YLTimer.m
//  YLKit
//
//  Created by 张晓岚 on 16/8/2.
//  Copyright © 2016年 ThinkMobile. All rights reserved.
//

#import "YLTimer.h"
#import <pthread.h>

#define LOCK(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);


@implementation YLTimer {
    BOOL _valid;
    NSTimeInterval _timeInterval;
    BOOL _repeats;
    __weak id _target;
    SEL _selector;
    dispatch_source_t _source;
    dispatch_semaphore_t _lock;
}

+ (YLTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                            target:(id)target
                          selector:(SEL)selector
                           repeats:(BOOL)repeats {
    return [[self alloc] initWithFireTime:interval interval:interval target:target selector:selector repeats:repeats];
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YYTimer init error" reason:@"Use the designated initializer to init." userInfo:nil];
    return [self initWithFireTime:0 interval:0 target:self selector:@selector(invalidate) repeats:NO];
}

- (instancetype)initWithFireTime:(NSTimeInterval)start
                        interval:(NSTimeInterval)interval
                          target:(id)target
                        selector:(SEL)selector
                         repeats:(BOOL)repeats {
    self = [super init];
    _repeats = repeats;
    _timeInterval = interval;
    _valid = YES;
    _target = target;
    _selector = selector;
    
    __weak typeof(self) _self = self;
    _lock = dispatch_semaphore_create(1);
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_source, dispatch_time(DISPATCH_TIME_NOW, (start * NSEC_PER_SEC)), (interval * NSEC_PER_SEC), 0);
    dispatch_source_set_event_handler(_source, ^{[_self fire];});
    dispatch_resume(_source);
    return self;
}

- (void)invalidate {
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    if (_valid) {
        dispatch_source_cancel(_source);
        _source = NULL;
        _target = nil;
        _valid = NO;
    }
    dispatch_semaphore_signal(_lock);
}

- (void)fire {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER);
    id target = _target;
    if (!_repeats || !target) {
        dispatch_semaphore_signal(_lock);
        [self invalidate];
    } else {
        dispatch_semaphore_signal(_lock);
        [target performSelector:_selector withObject:self];
    }
#pragma clang diagnostic pop
}

- (BOOL)repeats {
    LOCK(BOOL repeat = _repeats); return repeat;
}

- (NSTimeInterval)timeInterval {
    LOCK(NSTimeInterval t = _timeInterval) return t;
}

- (BOOL)isValid {
    LOCK(BOOL valid = _valid) return valid;
}

- (void)dealloc {
    [self invalidate];
}

@end