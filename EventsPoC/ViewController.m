//
//  ViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2013-06-26.
//  Copyright (c) 2013 Jeff Price. All rights reserved.
//

#import "ViewController.h"

#import "EventsMapViewController.h"
#import "EventsListTableViewController.h"
#import "SegmentedViewControllerProtocol.h"

NS_ENUM(NSInteger, MainViewSegmentOptions) {
    MainViewSegmentOptionMap,
    MainViewSegmentOptionList,    
};



@interface ViewController ()
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet UIView *contentView;

@property (nonatomic, strong) EventsMapViewController *mapViewController;
@property (nonatomic, strong) EventsListTableViewController *tableViewController;

@property (nonatomic, strong) NSArray *segments;
@property (nonatomic, strong) UIViewController *selectedViewController;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createSegmentControllers];
    [self createSegments];
    
    self.segmentedControl.selectedSegmentIndex = 0;
    self.selectedViewController = [self.segments objectAtIndex:self.segmentedControl.selectedSegmentIndex];
    self.selectedViewController.view.frame = self.view.bounds;
    [self addChildViewController:self.selectedViewController];
    [self.contentView addSubview:self.selectedViewController.view];
    [self.selectedViewController didMoveToParentViewController:self];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)createSegmentControllers {
    self.tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EventsListTableViewController"];
    self.mapViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"EventsMapViewController"];
    self.segments = [[NSArray alloc] initWithObjects:self.mapViewController, self.tableViewController, nil];
}

-(void)createSegments {
    [self.segmentedControl removeAllSegments];
    NSUInteger index = 0;
    for(NSObject<SegmentedViewControllerProtocol> *segmentVC in self.segments) {
        [self.segmentedControl insertSegmentWithTitle:[segmentVC displayName] atIndex:index animated:NO];
        index++;
    }
}

-(void)showViewController:(UIViewController *)vc {
    [self addChildViewController:vc];
    [self.view addSubview:vc.view];
}

#pragma mark - IBActions/Action Handlers
-(IBAction)segmentChanged {
    
    UIViewController *currentVC = self.selectedViewController;
    UIViewController *nextVC = [self.segments objectAtIndex:self.segmentedControl.selectedSegmentIndex];
    nextVC.view.frame = self.contentView.bounds;
    [self.contentView addSubview:nextVC.view];
    [self addChildViewController:nextVC];
    
    [nextVC didMoveToParentViewController:self];
    [currentVC removeFromParentViewController];
    [currentVC.view removeFromSuperview];
    self.selectedViewController = nextVC;
    
}

@end
