//
//  AppDelegate.h
//  OnionBrowser
//
//  Copyright (c) 2012 Mike Tigas. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WebViewController.h"

#define DNT_HEADER_UNSET 0
#define DNT_HEADER_CANTRACK 1
#define DNT_HEADER_NOTRACK 2

#define UA_SPOOF_NO 0
#define UA_SPOOF_WIN7_TORBROWSER 1
#define UA_SPOOF_SAFARI_MAC 2

#define X_DEVICE_IS_IPHONE 0
#define X_DEVICE_IS_IPAD 1
#define X_DEVICE_IS_SIM 2

@interface AppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) WebViewController *appWebView;

@property (nonatomic) Byte spoofUserAgent;
@property (nonatomic) Byte dntHeader;
@property (nonatomic) Boolean usePipelining;

// either nil (for standard "onionbrowser:start" ) or url given by a "onionbrowser://" (HTTP)
// or "onionbrowsers://" (HTTPS) callback url
@property (nonatomic) NSURL *startUrl;

// list for known domains w/self-signed certs
@property (nonatomic) NSMutableArray *sslWhitelistedDomains;

@property (nonatomic) Boolean doPrepopulateBookmarks;

- (NSURL *)applicationDocumentsDirectory;
- (void)wipeAppData;
- (NSUInteger) deviceType;


@end
