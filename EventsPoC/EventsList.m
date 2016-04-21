//
//  EventAnnotations.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-10-24.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "EventsList.h"

@interface EventsList()
@property (nonatomic, strong) NSMutableArray<NSObject<EventProtocol>*> *items;
@end

@implementation EventsList

// Thread safety
@synthesize items = _items;
- (void)setItems:(NSMutableArray<NSObject<EventProtocol>*> *)items {
    @synchronized (self) {
        _items = items;
    }
}

- (NSMutableArray<NSObject<EventProtocol>*> *)items {
    @synchronized (self) {
        return _items;
    }
}


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

-(void)mergeItems:(NSArray<NSObject<EventProtocol>*> *)items {
    for(NSObject<EventProtocol> *event in items) {
        if(![self containsItem:event]) {
            [self.items addObject:event];
        }
    }
}

-(BOOL)containsItem:(NSObject<EventProtocol>*)item {
    for(NSObject<EventProtocol>* event in self.items) {
        if([item.eventId isEqualToNumber:event.eventId]) {
            return YES;
        }
    }
    
    return NO;
}

-(void)sortUsingDescriptors:(NSArray<NSSortDescriptor *> *)descriptors {
    [self.items sortUsingDescriptors:descriptors];
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


#pragma mark - NSCopying Methods
- (id)copyWithZone:(NSZone *)zone {
    EventsList *copy = [[EventsList allocWithZone:zone] init];
    for(NSObject<EventProtocol> *event in self.allItems) {
        [copy add:[event copy]];
    }
    return copy;
}
@end
