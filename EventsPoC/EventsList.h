//
//  EventAnnotations.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"


@interface EventsList : NSObject

-(void)add:(Event *)event;
-(void)removeObjectAtIndex:(NSUInteger)index;
-(void)remove:(Event *)event;
-(NSArray *)toArray;
-(Event *)itemAt:(NSUInteger)index;
-(NSArray *)allItems;
-(NSUInteger)count;
@end
