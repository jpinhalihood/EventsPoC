//
//  EventsListTableViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-04.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "EventsListTableViewController.h"

#import "AppState.h"
#import "EventsList.h"
#import "EventProtocol.h"
#import "EventsListTableViewCell.h"
#import "EventsManager.h"
#import "EventNotifications.h"

@interface EventsListTableViewController ()
@property (nonatomic, strong) EventsList *events;
@end

@implementation EventsListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(manualRefresh) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.refreshControl];
    
    [self.navigationController.navigationBar setTitleTextAttributes:
     @{NSForegroundColorAttributeName:[UIColor darkGrayColor]}];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 101.0;
    [self addNotificationCenter];
    
    self.events = [EventsManager sharedInstance].filteredEvents;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)dealloc {
    [self removeNotificationCenter];
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
    return self.events.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *EventsListTableViewCellId = @"EventsListTableViewCell";
    
    EventsListTableViewCell *eventsListCell = [tableView dequeueReusableCellWithIdentifier:EventsListTableViewCellId forIndexPath:indexPath];
    
    NSObject<EventProtocol> *event = [self.events itemAt:indexPath.row];
    [eventsListCell configureWithTitle:event.eventName description:event.eventDescription startDate:event.startTime host:event.eventHost];
    
    return eventsListCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}


#pragma mark - SegmentedViewControllerProtocol Methods
- (NSString *)displayName {
    return NSLocalizedString(@"List View", @"A label indicating this view shows events in a list format");
}

- (void)addNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUpdatedEventsList:) name:EventsListUpdatedNotification object:nil];
}

- (void)removeNotificationCenter {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EventsListUpdatedNotification object:nil];
}

- (void)handleUpdatedEventsList:(NSNotification *)notification {
    if(self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
    self.events = [EventsManager sharedInstance].filteredEvents;
    [self.tableView reloadData];
}

- (void)manualRefresh {
    [[EventsManager sharedInstance] start];
}

@end
