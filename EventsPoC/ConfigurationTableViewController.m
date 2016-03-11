//
//  ConfigurationTableViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-17.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "ConfigurationTableViewController.h"

#import "RadiusSelectionTableViewCell.h"
#import "EventsManager.h"

@interface ConfigurationTableViewController ()

@end

@implementation ConfigurationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    return 2;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    if(indexPath.row == 0) {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"FBLoginCell" forIndexPath:indexPath];
        cell.textLabel.text = @"Connect Facebook";
        return cell;
        
    } else {
        RadiusSelectionTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"RadiusSelectionCell" forIndexPath:indexPath];
        cell.initialRadius = [NSNumber numberWithDouble:EventsDefaultRadius];
        cell.radiusChangedAction = ^(CGFloat newRadius) {
            [EventsManager sharedInstance].radius = [NSNumber numberWithFloat:newRadius];
        };
        return cell;
    }

}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-( void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0) {
        [self performSegueWithIdentifier:@"SegueToFBLoginVC" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"SegueToFBLoginVC"]) {
    }
}

@end
