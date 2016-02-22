//
//  FBGetLikesOperation.h
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FBPagedApiOperation.h"

@interface FBGetLikesOperation : FBPagedApiOperation
-(instancetype)initWithObjectId:(NSString *)identifier completion:(void (^) (NSArray<NSString*> *, NSError *))completion;
@end
