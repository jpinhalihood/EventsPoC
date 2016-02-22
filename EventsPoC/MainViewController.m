//
//  MainViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-17.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "MainViewController.h"

#import "FBSession.h"

#import "FBGetEventsOperation.h"
#import "FBGetLikesEventsOperation.h"
#import "FBGetLikesOperation.h"

#import "AppState.h"
#import "EventsList.h"


@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if(![FBSession getAccessToken]) {
        [FBSession renewFromViewController:self];
    } else {
        [self loadEvents];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)loadEvents {

    NSDate *start = [NSDate new];
    NSDate *end = [start dateByAddingTimeInterval:60 * 60 * 24];

    
    NSOperationQueue *queue = [NSOperationQueue new];
    
    // Get my events
    FBGetEventsOperation *eventsOp = [[FBGetEventsOperation alloc] initWithObjectId:@"me" completion:^(NSArray<FBEvent *> *fbEvents, NSError *error) {
        
        NSMutableArray<NSObject<EventProtocol>*> *events = [[NSMutableArray alloc] initWithCapacity:fbEvents.count];
        for(NSObject<EventProtocol> *fbEvent in fbEvents) {
            [events addObject:fbEvent];
        }
        
        [[AppState sharedInstance].events addItems:events];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"EventsListUpdated" object:nil];
            
            NSLog(@"%ld Personal Events\n", (long)fbEvents.count);
            for(NSObject<EventProtocol> *event in fbEvents) {
                NSLog(@"Id: %@ | Name: %@\n", event.eventId, event.eventName);
            }
        });

    }];
    
    eventsOp.startDate = start;
    eventsOp.endDate = end;
    
    
    // Get my likes
    __block NSArray<NSString *> *objectIds = nil;
    FBGetLikesOperation *likesOp = [[FBGetLikesOperation alloc] initWithObjectId:@"me" completion:^(NSArray<NSString *> *objIds, NSError *error) {
        
        objectIds = objIds;
        
        FBGetLikesEventsOperation *likeEventsOp = [[FBGetLikesEventsOperation alloc] initWithObjectIds:objectIds completion:^(NSArray<FBEvent *> *fbEvents, NSError *error) {
            
            NSMutableArray<NSObject<EventProtocol>*> *events = [[NSMutableArray alloc] initWithCapacity:fbEvents.count];
            for(NSObject<EventProtocol> *fbEvent in fbEvents) {
                [events addObject:fbEvent];
            }
            
            [[AppState sharedInstance].events addItems:events];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"EventsListUpdated" object:nil];
                
                NSLog(@"%ld Page Events\n", (long)fbEvents.count);
                for(NSObject<EventProtocol> *event in fbEvents) {
                    NSLog(@"Id: %@ | Name: %@ | Date: %@\n", event.eventId, event.eventName, event.startTime);
                }
            });
        }];
        
        likeEventsOp.startDate = start;
        likeEventsOp.endDate = end;
        
        [queue addOperation:likeEventsOp];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"\n%ld Likes\n", (long)objectIds.count);
        });
    }];
    

    [queue addOperation:eventsOp];
    [queue addOperation:likesOp];


}


@end
