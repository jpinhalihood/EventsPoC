//
//  AsynchronousOperation.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-12.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "AsynchronousOperation.h"

@interface AsynchronousOperation()
@property (nonatomic, getter=isFinished, readwrite) BOOL finished;
@property (nonatomic, getter=isExecuting, readwrite) BOOL executing;
@end


@implementation AsynchronousOperation

@synthesize finished = _finished;
@synthesize executing = _executing;

- (instancetype)init {
    if(self = [super init]) {
        _finished = NO;
        _executing = NO;
    }
    return self;
}

- (void)start {
    if([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    [self main];
}

- (void)completeOperation {
    self.executing = NO;
    self.finished = YES;
}


- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    @synchronized(self) {
        return _executing;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _finished;
    }
}

- (void)setExecuting:(BOOL)executing {
    if(_executing != executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished {
    if(_finished != finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}
@end
