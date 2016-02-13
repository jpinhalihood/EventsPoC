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

-(void)add:(Event *)event
{
    [self.items addObject:event];
}

-(void)removeObjectAtIndex:(NSUInteger)index
{
    [self.items removeObjectAtIndex:index];
}

-(void)remove:(Event*)event
{
    [self.items removeObject:event];
}

-(NSArray*)toArray
{
    return self.items;
}

-(Event*)itemAt:(NSUInteger)index
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
@end
