//
//  WebViewController.m
//  OnionBrowser
//
//  Created by Mike Tigas on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WebViewController.h"
#import "AppDelegate.h"
#import "BookmarkTableViewController.h"
#import "SettingsViewController.h"
#import "Bookmark.h"
#import "BridgeTableViewController.h"

static const CGFloat kNavBarHeight = 52.0f;
static const CGFloat kToolBarHeight = 44.0f;
static const CGFloat kLabelHeight = 14.0f;
static const CGFloat kMargin = 10.0f;
static const CGFloat kSpacer = 2.0f;
static const CGFloat kLabelFontSize = 12.0f;
static const CGFloat kAddressHeight = 26.0f;

static const NSInteger kNavBarTag = 1000;
static const NSInteger kAddressFieldTag = 1001;
static const NSInteger kAddressCancelButtonTag = 1002;
static const NSInteger kLoadingStatusTag = 1003;

static const Boolean kForwardButton = YES;
static const Boolean kBackwardButton = NO;

@interface WebViewController ()

@end

@implementation WebViewController

@synthesize myWebView = _myWebView,
            toolbar = _toolbar,
            backButton = _backButton,
            forwardButton = _forwardButton,
            toolButton = _toolButton,
            optionsMenu = _optionsMenu,
            bookmarkButton = _bookmarkButton,
            stopRefreshButton = _stopRefreshButton,
            pageTitleLabel = _pageTitleLabel,
            addressField = _addressField,
            currentURL = _currentURL,
            torStatus = _torStatus;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

-(void)loadView {
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
}



-(void)loadURL: (NSURL *)navigationURL {

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    // Build request and go.
    _myWebView.delegate = self;
    _myWebView.scalesPageToFit = YES;
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:navigationURL];
    [req setHTTPShouldUsePipelining:appDelegate.usePipelining];
    [_myWebView loadRequest:req];

    _addressField.enabled = YES;
    _toolButton.enabled = YES;
    _stopRefreshButton.enabled = YES;
    _bookmarkButton.enabled = YES;
    [self updateButtons];
}


- (UIImage *)makeForwardBackButtonImage:(Boolean)whichButton {
    // Draws the vector image for the forward or back button. (see kForwardButton
    // and kBackwardButton for the "whichButton" values)
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil,28*scale,28*scale,8,0,
                                                 colorSpace,kCGBitmapAlphaInfoMask & kCGImageAlphaPremultipliedLast);
    CFRelease(colorSpace);
    CGColorRef fillColor = [[UIColor blackColor] CGColor];
    CGContextSetFillColor(context, CGColorGetComponents(fillColor));
    
    CGContextBeginPath(context);
    if (whichButton == kForwardButton) {
        CGContextMoveToPoint(context, 20.0f*scale, 12.0f*scale);
        CGContextAddLineToPoint(context, 4.0f*scale, 4.0f*scale);
        CGContextAddLineToPoint(context, 4.0f*scale, 22.0f*scale);
    } else {
        CGContextMoveToPoint(context, 8.0f*scale, 12.0f*scale);
        CGContextAddLineToPoint(context, 24.0f*scale, 4.0f*scale);
        CGContextAddLineToPoint(context, 24.0f*scale, 22.0f*scale);
    }
    CGContextClosePath(context);
    CGContextFillPath(context);
    
    CGImageRef theCGImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *buttonImage = [[UIImage alloc] initWithCGImage:theCGImage
                                                    scale:[[UIScreen mainScreen] scale]
                                              orientation:UIImageOrientationUp];
    CGImageRelease(theCGImage);
    return buttonImage;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    /********** Initialize UIWebView **********/
    // Initialize a new UIWebView (to clear the history of the previous one)
    CGSize size = [UIScreen mainScreen].bounds.size;
    
    // Flip if we are rotated
    //if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
    //    size = CGSizeMake(size.height, size.width);
    //}
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if (
        ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) &&
        ([appDelegate deviceType] == X_DEVICE_IS_IPAD)
    ){
        // 7.0+, iPad
    } else {
        size.height -= 20.0f;
    }
    size.height -= kToolBarHeight;
    size.height -= kNavBarHeight;
    
    CGRect webViewFrame = [[UIScreen mainScreen] applicationFrame];
    webViewFrame.origin.y = kNavBarHeight;
    webViewFrame.origin.x = 0;
    webViewFrame.size = size;
    
    _myWebView = [[UIWebView alloc] initWithFrame:webViewFrame];
    _myWebView.backgroundColor = [UIColor whiteColor];
    _myWebView.scalesPageToFit = YES;
    _myWebView.contentScaleFactor = 3;
    _myWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _myWebView.delegate = self;
    [self.view addSubview: _myWebView];

    
    /********** Create Toolbars **********/
    // Set up toolbar.
    _toolbar = [[UIToolbar alloc] init];
    [_toolbar setTintColor:[UIColor blackColor]];
    _toolbar.frame = CGRectMake(0, self.view.frame.size.height - kToolBarHeight, self.view.frame.size.width, kToolBarHeight);
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    _toolbar.contentMode = UIViewContentModeBottom;
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                               target:nil
                               action:nil];
        
    _backButton = [[UIBarButtonItem alloc] initWithImage:[self makeForwardBackButtonImage:kBackwardButton]
                    style:UIBarButtonItemStylePlain
                    target:self
                    action:@selector(goBack)];
    _forwardButton = [[UIBarButtonItem alloc] initWithImage:[self makeForwardBackButtonImage:kForwardButton]
                    style:UIBarButtonItemStylePlain
                    target:self
                    action:@selector(goForward)];
    _toolButton = [[UIBarButtonItem alloc]
                      initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                      target:self
                      action:@selector(openOptionsMenu)];
    _bookmarkButton = [[UIBarButtonItem alloc]
                   initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                   target:self
                   action:@selector(showBookmarks)];
    _stopRefreshButton = [[UIBarButtonItem alloc]
                    initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                    target:self
                    action:@selector(stopLoading)];

    _forwardButton.enabled = NO;
    _backButton.enabled = NO;
    _stopRefreshButton.enabled = NO;
    _toolButton.enabled = YES;
    _bookmarkButton.enabled = NO;

    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:_backButton];
    [items addObject:space];
    [items addObject:_forwardButton];
    [items addObject:space];
    [items addObject:_toolButton];
    [items addObject:space];
    [items addObject:_bookmarkButton];
    [items addObject:space];
    [items addObject:_stopRefreshButton];
    [_toolbar setItems:items animated:NO];
    
    [self.view addSubview:_toolbar];
    // (/toolbar)
    
    // Set up actionsheets (options menu, bookmarks menu)
    _optionsMenu = [[UIActionSheet alloc] initWithTitle:nil
                                               delegate:self
                                      cancelButtonTitle:@"Close"
                                 destructiveButtonTitle:@"New Identity"
                                      otherButtonTitles:@"Bookmark Current Page", @"Browser Settings", @"Open Start Page", @"About Onion Browser", nil];
    // (/actionsheets)
    
    
    /********** Set Up Navbar **********/
    CGRect navBarFrame = self.view.bounds;
    navBarFrame.size.height = kNavBarHeight;
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:navBarFrame];
    navBar.tag = kNavBarTag;
    navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    CGRect labelFrame = CGRectMake(kMargin, kSpacer,
                                   navBar.bounds.size.width - 2*kMargin, kLabelHeight);

    /* if iOS < 7.0 */
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending) {
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.text = @"";
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textAlignment = NSTextAlignmentCenter;
        
        [navBar setTintColor:[UIColor blackColor]];
        [label setTextColor:[UIColor whiteColor]];
        
        [navBar addSubview:label];
        _pageTitleLabel = label;
    }
    /* endif */

    
    // The address field is the same with as the label and located just below 
    // it with a gap of kSpacer
    CGRect addressFrame = CGRectMake(kMargin, kSpacer*2.0 + kLabelHeight, 
                                     labelFrame.size.width, kAddressHeight);
    UITextField *address = [[UITextField alloc] initWithFrame:addressFrame];
    
    address.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    address.borderStyle = UITextBorderStyleRoundedRect;
    address.font = [UIFont systemFontOfSize:17];
    address.keyboardType = UIKeyboardTypeURL;
    address.returnKeyType = UIReturnKeyGo;
    address.autocorrectionType = UITextAutocorrectionTypeNo;
    address.autocapitalizationType = UITextAutocapitalizationTypeNone;
    address.clearButtonMode = UITextFieldViewModeNever;
    address.delegate = self;
    address.tag = kAddressFieldTag;
    [address addTarget:self 
                action:@selector(loadAddress:event:) 
      forControlEvents:UIControlEventEditingDidEndOnExit|UIControlEventEditingDidEnd];
    [navBar addSubview:address];
    _addressField = address;
    _addressField.enabled = YES;
    [self.view addSubview:navBar];
    // (/navbar)
    
    // Since this is first load: set up the overlay "loading..." bit that
    // will display tor initialization status.
    
    if (appDelegate.doPrepopulateBookmarks){
        [self prePopulateBookmarks];
    }
}

-(void) prePopulateBookmarks {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];

    NSUInteger i = 0;
    
    Bookmark *bookmark;
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:@"The Tor Project (.onion)"];
    [bookmark setUrl:@"http://idnxcnkne4qt76tg.onion/"];
    [bookmark setOrder:i++];
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:@"Tor Project News (HTTPS)"];
    [bookmark setUrl:@"https://blog.torproject.org/"];
    [bookmark setOrder:i++];
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:@"The Hidden Wiki Mirror (.onion)"];
    [bookmark setUrl:@"http://wikitjerrta4qgz4.onion/"];
    [bookmark setOrder:i++];
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:@"Reddit /r/onions"];
    [bookmark setUrl:@"http://www.reddit.com/r/onions"];
    [bookmark setOrder:i++];
    
    bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:context];
    [bookmark setTitle:@"Reddit /r/netsec"];
    [bookmark setUrl:@"http://www.reddit.com/r/netsec"];
    [bookmark setOrder:i++];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Error adding bookmarks: %@", error);
    }
}


- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Allow all four orientations on iPad.
    // Disallow upside-down for iPhone.
    return (IS_IPAD) || (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

# pragma mark -
# pragma mark WebView behavior

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self updateAddress:request];
    return YES;
}

 - (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self updateButtons];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    [self updateTitle:webView];
    NSURLRequest* request = [webView request];
    [self updateAddress:request];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateButtons];
    [self informError:error];
    #ifdef DEBUG
        NSString* errorString = [NSString stringWithFormat:@"error %@",
                                 error.localizedDescription];
        NSLog(@"[WebViewController] Error: %@", errorString);
    #endif
}

- (void)informError:(NSError *)error {
    if ([error.domain isEqualToString:@"NSOSStatusErrorDomain"] &&
        (error.code == -9807 || error.code == -9812)) {
        // Invalid certificate chain; valid cert chain, untrusted root

        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"SSL Error"
                                  message:@"Certificate chain is invalid. Either the site's SSL certificate is self-signed or the certificate was signed by an untrusted authority."
                                  delegate:nil
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Continue",nil];
        alertView.delegate = self;
        [alertView show];

    } else if ([error.domain isEqualToString:(NSString *)kCFErrorDomainCFNetwork] ||
               [error.domain isEqualToString:@"NSOSStatusErrorDomain"]) {
        NSString* errorDescription;
        
        if (error.code == kCFSOCKS5ErrorBadState) {
            errorDescription = @"Could not connect to the server. Either the domain name is incorrect, the server is inaccessible, or the Tor circuit was broken.";
        } else if (error.code == kCFHostErrorHostNotFound) {
            errorDescription = @"The server could not be found";
        } else {
            errorDescription = [NSString stringWithFormat:@"An error occurred: %@",
                                error.localizedDescription];
        }
        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Cannot Open Page"
                                  message:errorDescription delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
    #ifdef DEBUG
    else {
        NSLog(@"[WebViewController] uncaught error: %@", [error localizedDescription]);
        NSLog(@"\t -> %@", error.domain);
    }
    #endif
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // "Continue anyway" for SSL cert error
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

        // Assumung URL in address bar is the one that caused this error.
        NSURL *url = [NSURL URLWithString:_currentURL];
        NSString *hostname = url.host;
        [appDelegate.sslWhitelistedDomains addObject:hostname];

        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Whitelisted Domain"
                                  message:[NSString stringWithFormat:@"SSL certificate errors for '%@' will be ignored for the rest of this session.", hostname] delegate:nil 
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];

        // Reload (now that we have added host to whitelist)
        [self loadURL:url];
    }
}



# pragma mark -
# pragma mark Address Bar

- (void)addressBarCancel {
    _addressField.text = _currentURL;
    [_addressField resignFirstResponder];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // Stop loading if we are loading a page
    [_myWebView stopLoading];
    
    // Move a "cancel" button into the nav bar a la Safari.
    UINavigationBar *navBar = (UINavigationBar *)[self.view viewWithTag:kNavBarTag];
        
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateHighlighted];
    [cancelButton setFrame:CGRectMake(navBar.bounds.size.width,
                                      kSpacer*2.0 + kLabelHeight,
                                      75 - 2*kMargin,
                                      kAddressHeight)];
    [cancelButton setHidden:NO];
    [cancelButton setEnabled:YES];
    [cancelButton addTarget:self action:@selector(addressBarCancel) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.tag = kAddressCancelButtonTag;

    
    
    [UIView setAnimationsEnabled:YES];
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _addressField.frame = CGRectMake(kMargin,
                                                          kSpacer*2.0 + kLabelHeight,
                                                          navBar.bounds.size.width - 2*kMargin - 75,
                                                          kAddressHeight);
                         
                         [cancelButton setFrame:CGRectMake(navBar.bounds.size.width - 75,
                                                           kSpacer*2.0 + kLabelHeight,
                                                           75 - kMargin,
                                                           kAddressHeight)];
                         [navBar addSubview:cancelButton];

                     }
                     completion:^(BOOL finished) {
                         _addressField.clearButtonMode = UITextFieldViewModeAlways;
                     }]; 
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    UINavigationBar *navBar = (UINavigationBar *)[self.view viewWithTag:kNavBarTag];
    UIButton *cancelButton = (UIButton *)[self.view viewWithTag:kAddressCancelButtonTag];

    _addressField.clearButtonMode = UITextFieldViewModeNever;
    
    [UIView setAnimationsEnabled:YES];
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _addressField.frame = CGRectMake(kMargin,
                                                          kSpacer*2.0 + kLabelHeight,
                                                          navBar.bounds.size.width - 2*kMargin,
                                                          kAddressHeight);
                         [cancelButton setFrame:CGRectMake(navBar.bounds.size.width,
                                                           kSpacer*2.0 + kLabelHeight,
                                                           75 - kMargin,
                                                           kAddressHeight)];
                     }
                     completion:^(BOOL finished) {
                         [cancelButton removeFromSuperview];
                     }]; 
}

# pragma mark -
# pragma mark Options Menu action sheet

- (void)openOptionsMenu {
        [_optionsMenu showFromToolbar:_toolbar];
    
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == _optionsMenu) {
        if (buttonIndex == 0) {
            ////////////////////////////////////////////////////////
            // New Identity
            ////////////////////////////////////////////////////////
            AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
            
            [appDelegate wipeAppData];
            
            // Initialize a new UIWebView (to clear the history of the previous one)
            CGSize size = [UIScreen mainScreen].bounds.size;
            
            // Flip if we are rotated
            if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
                size = CGSizeMake(size.height, size.width);
            }
            
            NSString *reqSysVer = @"7.0";
            NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
            if (
                ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) &&
                ([appDelegate deviceType] == X_DEVICE_IS_IPAD)
            ){
                // 7.0+, iPad, do nothing
            } else {
                size.height -= 20.0f;
            }
            size.height -= kToolBarHeight;
            size.height -= kNavBarHeight;
            
            CGRect webViewFrame = [[UIScreen mainScreen] applicationFrame];
            webViewFrame.origin.y = kNavBarHeight;
            webViewFrame.origin.x = 0;
            
            webViewFrame.size = size;
            
            UIWebView *newWebView = [[UIWebView alloc] initWithFrame:webViewFrame];
            newWebView.backgroundColor = [UIColor whiteColor];
            newWebView.scalesPageToFit = YES;
            newWebView.contentScaleFactor = 3;
            newWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
            newWebView.delegate = self;
            [_myWebView removeFromSuperview];
            _myWebView = newWebView;
            [self.view addSubview: _myWebView];
            
            // Reset forward/back buttons.
            [self updateButtons];
            
            // Reset the address field
            _addressField.text = @"";
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil 
                                                            message:@"Requesting a new IP address from Tor. Cache, cookies, and browser history cleared.\n\nDue to an iOS limitation, visisted links still get the ':visited' CSS highlight state. iOS is resistant to script-based access to this information, but if you are still concerned about leaking history, please force-quit this app and re-launch.\n\nFor more details:\nhttp://yu8.in/M5"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
            [alert show];
        } else if (buttonIndex == 1) {
            ////////////////////////////////////////////////////////
            // Add To Bookmarks
            ////////////////////////////////////////////////////////
            [self addCurrentAsBookmark];
        } else if (buttonIndex == 2) {
            ////////////////////////////////////////////////////////
            // Settings Menu
            ////////////////////////////////////////////////////////
            SettingsViewController *settingsController = [[SettingsViewController alloc] initWithNibName:@"SettingsViewController" bundle:nil];
            [self presentViewController:settingsController animated:YES completion:nil];
        }
        
        if ((buttonIndex == 0) || (buttonIndex == 3)) {
            ////////////////////////////////////////////////////////
            // New Identity OR Return To Home
            ////////////////////////////////////////////////////////
            [self loadURL:[NSURL URLWithString:@"onionbrowser:start"]];
        } else if (buttonIndex == 4) {
            ////////////////////////////////////////////////////////
            // About Page
            ////////////////////////////////////////////////////////
            [self loadURL:[NSURL URLWithString:@"onionbrowser:about"]];
        }
    }
}

# pragma mark -
# pragma mark Toolbar/navbar behavior

- (void)goForward {
    [_myWebView goForward];
    [self updateTitle:_myWebView];
    [self updateAddress:[_myWebView request]];
    [self updateButtons];
}
- (void)goBack {
    [_myWebView goBack];
    [self updateTitle:_myWebView];
    [self updateAddress:[_myWebView request]];
    [self updateButtons];
}
- (void)stopLoading {
    [_myWebView stopLoading];
    [self updateTitle:_myWebView];
    if (!_addressField.isEditing) {
        _addressField.text = _currentURL;
    }
    [self updateButtons];
}
- (void)reload {
    [_myWebView reload];
    [self updateButtons];
}

- (void)updateButtons
{
    _forwardButton.enabled = _myWebView.canGoForward;
    _backButton.enabled = _myWebView.canGoBack;
    if (_myWebView.loading) {
        _stopRefreshButton = nil;
        _stopRefreshButton = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                              target:self
                              action:@selector(stopLoading)];
    } else {
        _stopRefreshButton = nil;
        _stopRefreshButton = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                              target:self
                              action:@selector(reload)];
    }
    _stopRefreshButton.enabled = YES;
    NSMutableArray *items = [[NSMutableArray alloc] init];
    UIBarButtonItem *space = [[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                              target:nil
                              action:nil];
    [items addObject:_backButton];
    [items addObject:space];
    [items addObject:_forwardButton];
    [items addObject:space];
    [items addObject:_toolButton];
    [items addObject:space];
    [items addObject:_bookmarkButton];
    [items addObject:space];
    [items addObject:_stopRefreshButton];
    [_toolbar setItems:items animated:NO];

}

- (void)updateTitle:(UIWebView*)aWebView
{
    NSString* pageTitle = [aWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    /* if iOS < 7.0 */
    NSString *reqSysVer = @"7.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    if ([currSysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending) {
        _pageTitleLabel.text = pageTitle;
    }
    /* endif */
}

- (void)updateAddress:(NSURLRequest*)request {
    NSURL* url = [request mainDocumentURL];
    NSString* absoluteString;
    
    if ((url != nil) && [[url scheme] isEqualToString:@"file"]) {
        // Faked local URLs
        if ([[url absoluteString] rangeOfString:@"startup.html"].location != NSNotFound) {
            absoluteString = @"onionbrowser:start";
        }
        else if ([[url absoluteString] rangeOfString:@"about.html"].location != NSNotFound) {
            absoluteString = @"onionbrowser:about";
        } else {
            absoluteString = @"";
        }
    } else {
        // Regular ol' web URL.
        absoluteString = [url absoluteString];
    }
    
    if (![absoluteString isEqualToString:_currentURL]){
        _currentURL = absoluteString;
        if (!_addressField.isEditing) {
            _addressField.text = absoluteString;
        }
    }
}

- (void)loadAddress:(id)sender event:(UIEvent *)event {
    NSString* urlString = _addressField.text;
    NSURL* url = [NSURL URLWithString:urlString];
    if(!url.scheme)
    {
        NSString *absUrl = [NSString stringWithFormat:@"http://%@", urlString];
        url = [NSURL URLWithString:absUrl];
    }
    _currentURL = [url absoluteString];
    [self loadURL:url];
}

- (void) addCurrentAsBookmark {
    if ((_currentURL != nil) && ![_currentURL isEqualToString:@""]) {
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:appDelegate.managedObjectContext];
        [request setEntity:entity];
        
        NSError *error = nil;
        NSUInteger numBookmarks = [appDelegate.managedObjectContext countForFetchRequest:request error:&error];
        if (error) {
            // error state?
        }
        Bookmark *bookmark = (Bookmark *)[NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:appDelegate.managedObjectContext];
        
        NSString *pageTitle = [_myWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
        [bookmark setTitle:pageTitle];
        [bookmark setUrl:_currentURL];
        [bookmark setOrder:numBookmarks];
        
        NSError *saveError = nil;
        if (![appDelegate.managedObjectContext save:&saveError]) {
            NSLog(@"Error saving bookmark: %@", saveError);
        }

        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Add Bookmark"
                                  message:[NSString stringWithFormat:@"Added '%@' %@ to bookmarks.",
                                           pageTitle, _currentURL]
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        alertView.delegate = self;
        [alertView show];
    } else {
        UIAlertView* alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Add Bookmark"
                                  message:@"Can't bookmark a (local) page with no URL."
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        alertView.delegate = self;
        [alertView show];
    }
}

-(void)showBookmarks {
    BookmarkTableViewController *bookmarksVC = [[BookmarkTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *bookmarkNavController = [[UINavigationController alloc]
                                                     initWithRootViewController:bookmarksVC];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    bookmarksVC.managedObjectContext = context;
    
    [self presentViewController:bookmarkNavController animated:YES completion:nil];
}

@end
