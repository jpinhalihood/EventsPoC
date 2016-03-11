//
//  FBSession.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-17.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBSession.h"

#import "FBLoginViewController.h"

@implementation FBSession
+ (NSString *)getAccessToken {
    return [FBSDKAccessToken currentAccessToken].tokenString;
}

+ (void)renewFromViewController:(UINavigationController *)callingVc {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    FBLoginViewController *fbLoginVc = [sb instantiateViewControllerWithIdentifier:@"FBLoginViewController"];
    fbLoginVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    fbLoginVc.preferredContentSize = CGSizeMake(300.0, 400.0);

    [callingVc presentViewController:fbLoginVc animated:YES completion:nil];

}
@end
