//
//  EventsListTableViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-04.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "EventsListTableViewController.h"

#import "FBEvent.h"
#import "FBGetEventsOperation.h"

#import "Event.h"
#import "EventsList.h"
#import "EventsListTableViewCell.h"

@interface EventsListTableViewController ()
@property (nonatomic, strong) EventsList *events;
@property (nonatomic, strong) NSArray<FBEvent*> *fbEvents;
@end

@implementation EventsListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 101.0;
    
    __weak __typeof(self) weakSelf = self;
    FBGetEventsOperation *getFBEventsOp = [[FBGetEventsOperation alloc] initWithUser:@"me" completion:^(NSArray<FBEvent *> *fbEvents, NSError *fbEventsError) {
        
        if(fbEvents && !fbEventsError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.fbEvents = fbEvents;
                [weakSelf.tableView reloadData];
            });
        } else{
            NSLog(@"FB EVENTS ERROR: %@", fbEventsError.localizedDescription);
        }
        
    }];
    
    NSOperationQueue *fbEventOpQ = [NSOperationQueue new];
    [fbEventOpQ addOperation:getFBEventsOp];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.fbEvents.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *EventsListTableViewCellId = @"EventsListTableViewCell";
    
    EventsListTableViewCell *eventsListCell = [tableView dequeueReusableCellWithIdentifier:EventsListTableViewCellId forIndexPath:indexPath];
    
    FBEvent *event = self.fbEvents[indexPath.row];
    [eventsListCell configureWithTitle:event.eventName description:event.eventDescription startDate:event.startTime];
    
    return eventsListCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

@end
