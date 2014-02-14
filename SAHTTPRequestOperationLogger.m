// SAHTTPRequestLogger.h
//
// Copyright (c) 2011 AFNetworking (http://afnetworking.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SAHTTPRequestOperationLogger.h"
#import "SAHTTPRequestOperation.h"

#import <objc/runtime.h>

@implementation SAHTTPRequestOperationLogger

+ (instancetype)sharedLogger {
    static SAHTTPRequestOperationLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[self alloc] init];
    });
    
    return _sharedLogger;
}

- (id)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.level = SALoggerLevelInfo;
    
    return self;
}

- (void)dealloc {
    [self stopLogging];
}

- (void)startLogging {
    [self stopLogging];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HTTPOperationDidStart:) name:SANetworkingOperationDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(HTTPOperationDidFinish:) name:SANetworkingOperationDidFinishNotification object:nil];
}

- (void)stopLogging {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - NSNotification

static void * SAHTTPRequestOperationStartDate = &SAHTTPRequestOperationStartDate;

- (void)HTTPOperationDidStart:(NSNotification *)notification {
    SAHTTPRequestOperation *operation = (SAHTTPRequestOperation *)[notification object];
    
    if (![operation isKindOfClass:[SAHTTPRequestOperation class]]) {
        return;
    }
    
    objc_setAssociatedObject(operation, SAHTTPRequestOperationStartDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if (self.filterPredicate && [self.filterPredicate evaluateWithObject:operation]) {
        return;
    }
    
    NSString *body = nil;
    if ([operation.request HTTPBody]) {
        body = [[NSString alloc] initWithData:[operation.request HTTPBody] encoding:NSUTF8StringEncoding];
    }
    
    switch (self.level) {
        case SALoggerLevelDebug:
            NSLog(@"%@ '%@': %@ %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], [operation.request allHTTPHeaderFields], body);
            break;
        case SALoggerLevelInfo:
            NSLog(@"%@ '%@'", [operation.request HTTPMethod], [[operation.request URL] absoluteString]);
            break;
        default:
            break;
    }
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification {
    SAHTTPRequestOperation *operation = (SAHTTPRequestOperation *)[notification object];
    
    if (![operation isKindOfClass:[SAHTTPRequestOperation class]]) {
        return;
    }
    
    if (self.filterPredicate && [self.filterPredicate evaluateWithObject:operation]) {
        return;
    }
    
    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:objc_getAssociatedObject(operation, SAHTTPRequestOperationStartDate)];
    
    if (operation.error) {
        switch (self.level) {
            case SALoggerLevelDebug:
            case SALoggerLevelInfo:
            case SALoggerLevelWarn:
            case SALoggerLevelError:
                NSLog(@"[Error] %@ '%@' (%ld) [%.04f s]: %@", [operation.request HTTPMethod], [[operation.response URL] absoluteString], (long)[operation.response statusCode], elapsedTime, operation.error);
            default:
                break;
        }
    } else {
        switch (self.level) {
            case SALoggerLevelDebug:
                NSLog(@"%ld '%@' [%.04f s]: %@ %@", (long)[operation.response statusCode], [[operation.response URL] absoluteString], elapsedTime, [operation.response allHeaderFields], operation.responseString);
                break;
            case SALoggerLevelInfo:
                NSLog(@"%ld '%@' [%.04f s]", (long)[operation.response statusCode], [[operation.response URL] absoluteString], elapsedTime);
                break;
            default:
                break;
        }
    }
}

@end
