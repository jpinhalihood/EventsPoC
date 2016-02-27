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

-(void)add:(NSObject<EventProtocol> * _Nonnull)event;
-(void)addItems:(NSArray<NSObject<EventProtocol> *> * _Nonnull)items;
-(void)removeObjectAtIndex:(NSUInteger)index;
-(void)remove:(NSObject<EventProtocol> * _Nonnull)event;
-(NSArray * _Nonnull)toArray;
-(NSObject<EventProtocol> * _Nonnull)itemAt:(NSUInteger)index;
-(NSArray * _Nonnull)allItems;
-(NSUInteger)count;
-(void)removeAllItems;

-(EventsList *_Nonnull)filterByLattitude:(NSNumber *_Nonnull)lattitude longitude:(NSNumber *_Nonnull)longitude;

+(EventsList * _Nonnull)listByAddingItemsFromList:(EventsList * _Nonnull)list;
+(EventsList * _Nonnull)listFromArrayOfEvents:(NSArray<NSObject<EventProtocol>*> *_Nonnull)events;
@end
