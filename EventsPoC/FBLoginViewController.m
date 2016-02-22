//
//  FBLoginViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-10.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBLoginViewController.h"


@interface FBLoginViewController ()
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UIView *fbLoginButtonContainer;
@property (nonatomic, weak) IBOutlet UIView *fbProfilePictureContainer;
@property (nonatomic, weak) IBOutlet UIButton *customFBLoginButton;

@property (nonatomic, strong) FBSDKProfilePictureView *fbUserProfileImage;

@end

@implementation FBLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.usernameLabel.text = @"";
    self.fbUserProfileImage = [[FBSDKProfilePictureView alloc] initWithFrame:self.fbProfilePictureContainer.bounds];
    [self.fbProfilePictureContainer addSubview:self.fbUserProfileImage];
    self.fbUserProfileImage.layer.cornerRadius = 80.0;
    self.fbUserProfileImage.layer.masksToBounds = YES;
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];

    if(![self isLoggedIn]) {
        __weak __typeof(self) weakSelf = self;
        [self loginWithCompletion:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf completeLogin];
            });
        }];
    } else {
        [self completeLogin];
    }
    
    if(self.shouldShowCloseButton) {
        UIBarButtonItem *closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(onDone:)];
        self.navigationItem.hidesBackButton = YES;
        self.navigationItem.leftBarButtonItem = closeButton;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onLogin:(id)sender {
    if(![self isLoggedIn]) {
        __weak __typeof(self) weakSelf = self;
        [self loginWithCompletion:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf completeLogin];
            });
        }];
    } else {
        [self logout];
    }
}

- (IBAction)onDone:(id)sender {
     [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)isLoggedIn {
    NSLog(@"Token: %@", [FBSDKAccessToken currentAccessToken].tokenString);
    NSLog(@"Exiration Date: %@", [FBSDKAccessToken currentAccessToken].expirationDate);
    return ([[FBSDKAccessToken currentAccessToken].expirationDate compare:[NSDate new]] == NSOrderedDescending);
}

- (void)loginWithCompletion:(void (^) (FBSDKLoginManagerLoginResult *result, NSError *error))completion {
    FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
    [loginManager logInWithReadPermissions:@[@"public_profile", @"email", @"user_friends", @"user_events", @"user_likes"]
                        fromViewController:self
                                   handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                                if (error) {
                                    NSLog(@"Process error");
                                } else if (result.isCancelled) {
                                    NSLog(@"Cancelled");
                                } else {
                                    NSLog(@"Logged in");
                                }
                                       
                               if(completion) {
                                   completion(result, error);
                               }
                                       
                            }];
}

- (void)logout {
    
    NSString *loggedInAs = [NSString stringWithFormat:@"Logged in as %@", [FBSDKProfile currentProfile].name];
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Log Out"
                                                                         message:loggedInAs
                                                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Log Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
        [loginManager logOut];
        [self.customFBLoginButton setTitle:@"Log In" forState:UIControlStateNormal];
        self.usernameLabel.text = @"Please Log In";
        
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
    
}

- (void)updateUserProfileForId:(NSString *)profileId name:(NSString *)name {
    self.usernameLabel.text = name;
    self.fbUserProfileImage.profileID = profileId;
}

- (void)completeLogin {
    [self.customFBLoginButton setTitle:@"Log Out" forState:UIControlStateNormal];
    [self getLoggedInUser];
}

- (void)getLoggedInUser
{
 
    __weak __typeof(self) weakSelf = self;
    NSDictionary *parameters = @{@"fields" : @"id,name"};
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:parameters];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateUserProfileForId:result[@"id"] name:result[@"name"]];
        });
    }];
    
    
    parameters = @{@"fields" : @"cover,name,start_time,location"};
    request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/events" parameters:parameters];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"\n\nEvents:\n%@", result);
        });
    }];
    
    parameters = @{@"fields" : @"id,name"};
    request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"10152949963773329/friends" parameters:parameters];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"\n\nFriends:\n%@", result);
        });
    }];

}


@end
