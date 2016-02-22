//
//  FBGetLikesOperation.m
//  EventsPoC
//
//  Created by Jeff Price on 2016-02-18.
//  Copyright © 2016 Jeff Price. All rights reserved.
//

#import "FBGetLikesOperation.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>

@interface FBGetLikesOperation()
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSMutableArray<NSString *> *objectIds;
@property (nonatomic, copy) void (^completionAction)(NSArray<NSString *> *, NSError *);
@end

@implementation FBGetLikesOperation

- (instancetype)initWithObjectId:(NSString *)identifier completion:(void (^) (NSArray<NSString*> *, NSError *))completion {
    if(self = [super init]) {
        _identifier = identifier;
        _completionAction = completion;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if(self.isCancelled) {
            return;
        }
        
        if([[FBSDKAccessToken currentAccessToken].expirationDate compare:[NSDate new]] == NSOrderedDescending) {
            NSString *accessToken = [FBSDKAccessToken currentAccessToken].tokenString;
            NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/v2.5/%@/likes?access_token=%@&pretty=0&limit=100", self.identifier, accessToken];
            
            NSError *error = nil;
            self.objectIds = [NSMutableArray new];
            
            while (url != nil && !self.isCancelled) {
                
                NSDictionary *json = nil;
                
                url = [self fetchDataForUrl:url json:&json error:&error];
                
                if(json && !error) {
                    NSArray<NSDictionary*> *dataJson = [json objectForKey:@"data"];
                    for(NSDictionary *likeJson in dataJson) {
                        NSString *objectId = [likeJson objectForKey:@"id"];
                        [self.objectIds addObject:objectId];
                    }
                }
            }
            
            NSArray *allObjectIds = [NSArray arrayWithArray:self.objectIds];
            if(self.completionAction) {
                self.completionAction(allObjectIds, error);
            }
            [self completeOperation];
        }
    }
}
@end
