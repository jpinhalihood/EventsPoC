//
//  EventAnnotations.h
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventProtocol.h"


@interface EventsList : NSObject

-(void)add:(NSObject<EventProtocol> *)event;
-(void)addItems:(NSArray<NSObject<EventProtocol> *> *)items;
-(void)removeObjectAtIndex:(NSUInteger)index;
-(void)remove:(NSObject<EventProtocol> *)event;
-(NSArray *)toArray;
-(NSObject<EventProtocol> *)itemAt:(NSUInteger)index;
-(NSArray *)allItems;
-(NSUInteger)count;

+(EventsList *)listByAddingItemsFromList:(EventsList *)list;
@end
