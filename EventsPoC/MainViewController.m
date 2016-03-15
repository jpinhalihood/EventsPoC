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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(![FBSession getAccessToken]) {
        [FBSession renewFromViewController:self.selectedViewController];
    } else {
        [EventsManager sharedInstance].radius = [NSNumber numberWithDouble:EventsDefaultRadius];
        [[EventsManager sharedInstance] start];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
