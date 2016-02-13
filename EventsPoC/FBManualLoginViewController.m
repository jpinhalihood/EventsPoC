//
//  FBLoginViewController.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-04.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBManualLoginViewController.h"
#import "OAuthLoginHelper.h"
#import "OAAuthorization.h"



@interface FBManualLoginViewController ()
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@end

@implementation FBManualLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if([[OAAuthorization sharedInstance] isExpired]) {
        [self requestAuthorization];
    }
}
                            
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)requestAuthorization
{
    NSString *requestUrl = [NSString stringWithFormat:@"https://www.facebook.com/dialog/oauth?client_id=710051705726691&response_type=token&scope=public_profile,user_events,user_friends,user_location,user_posts&type=user_agent&display=touch&redirect_uri=http://localhost/callback&state=%@", [OAuthLoginHelper generateRandomStateWithLength:16]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestUrl]];
    self.webView.delegate = self;
    [self.webView loadRequest:request];

}

- (IBAction)onDone:(id)sender {
    [self completeLogin];
}

- (void)completeLogin {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate Methods
-(void)webViewDidStartLoad:(UIWebView *)webView
{
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = request.URL.absoluteString;
    NSLog(@"URL: %@", url);
    if([url containsString:@"access_token="]) {
        NSString *accessToken = [OAuthLoginHelper valueForToken:@"access_token=" fromString:url];
        NSString *expiry = [OAuthLoginHelper valueForToken:@"expires_in=" fromString:url];
        NSNumberFormatter *formatter = [NSNumberFormatter new];
        NSNumber *expiryInSeconds = [formatter numberFromString:expiry];
        NSLog(@"Code: %@", accessToken);
        NSLog(@"Expires In: %@ seconds", expiry);
        [[OAAuthorization sharedInstance] startWithAccessToken:accessToken expiryInSeconds:expiryInSeconds];
        NSLog(@"Expiry Date: %@", [OAAuthorization sharedInstance].expiryDate);
        return NO;
    }
    return YES;
}

@end
