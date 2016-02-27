//
//  EventAnnotations.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "EventsList.h"

@interface EventsList()
@property (nonatomic, strong) NSMutableArray* items;
@end

@implementation EventsList

-(id)init
{
    if(self = [super init]) {
        self.items = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

-(void)add:(NSObject<EventProtocol> *)event
{
    @synchronized(self) {
        [self.items addObject:event];
    }
}

-(void)addItems:(NSArray<NSObject<EventProtocol>*> *)items {
    @synchronized(self) {
        for(NSObject<EventProtocol> *event in items) {
            [self.items addObject:event];
        }
    }
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    @synchronized(self) {
        [self.items removeObjectAtIndex:index];
    }
}

-(void)remove:(NSObject<EventProtocol>*)event
{
    @synchronized(self) {
        [self.items removeObject:event];
    }
}

-(NSArray*)toArray
{
    return self.items;
}

-(NSObject<EventProtocol>*)itemAt:(NSUInteger)index
{
    return [self.items objectAtIndex:index];
}

-(NSArray *)allItems
{
    return [NSArray arrayWithArray:self.items];
}

-(NSUInteger)count
{
    return self.items.count;
}

-(void)removeAllItems {
    [self.items removeAllObjects];
}


-(EventsList *)filterByLattitude:(NSNumber *)lattitude longitude:(NSNumber *)longitude {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeLattitude=%@ AND placeLongitude=%@", lattitude, longitude];
    NSArray *filtered = [self.allItems filteredArrayUsingPredicate:predicate];
    EventsList *filteredList = [EventsList listFromArrayOfEvents:filtered];
    return filteredList;
}


#pragma mark - Convenience Methods
+(EventsList *)listByAddingItemsFromList:(EventsList *)list {
    EventsList *newList = [EventsList new];
    for(NSObject<EventProtocol> *event in list.allItems) {
        [newList add:event];
    }
    
    return newList;
}

+(EventsList *)listFromArrayOfEvents:(NSArray<NSObject<EventProtocol>*> *)events {
    EventsList *list = [EventsList new];
    for(NSObject<EventProtocol> *event in events) {
        [list add:event];
    }
    
    return list;
}
@end
