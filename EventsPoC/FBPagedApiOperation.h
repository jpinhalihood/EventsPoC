//
//  FBPagedApiOperation.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsynchronousOperation.h"
@interface FBPagedApiOperation : AsynchronousOperation
@property (nonatomic, weak) NSURLSessionDataTask *task;
- (NSString *)fetchDataForUrl:(NSString *)url json:(__autoreleasing NSDictionary **)returnJson error:(__autoreleasing NSError **)returnError;
@end
