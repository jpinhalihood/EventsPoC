//
//  MainViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-17.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "MainViewController.h"

#import "FBSession.h"

#import "EventsManager.h"

#import "AppState.h"
#import "EventsList.h"

#import "EventNotifications.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if(![FBSession getAccessToken]) {
        [FBSession renewFromViewController:self];
    } else {        
        [EventsManager loadEventsWithCompletion:^(EventsList *events, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(events && events.count > 0 && !error) {
                    [AppState sharedInstance].events = events;
                    NSDictionary *userInfo = @{KeyEventsListUpdatedNotificationPayload : events };
                    [[NSNotificationCenter defaultCenter] postNotificationName:EventsListUpdatedNotification object:nil userInfo:userInfo];
                }                
            });
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
