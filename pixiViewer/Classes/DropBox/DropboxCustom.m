//
//  DropboxCustom.m
//  Pictures
//
//  Created by nya on 2012/08/20.
//
//

#import "DropboxCustom.h"
#import "DBConnectController.h"
#import <CommonCrypto/CommonDigest.h>
#import "DBConnectController.h"
#import <objc/runtime.h>


static NSString *kDBProtocolDropbox = @"dbapi-1";
static NSString *kDBLinkNonce = @"dropbox.sync.nonce";


@interface DBConnectControllerCustom : DBConnectController

@end


@interface DBConnectControllerCustom (Custom)

@property (nonatomic, retain) NSURL *url;

- (void)dismiss;
- (void)cancelAnimated:(BOOL)animated;

@end


@implementation DBConnectControllerCustom

- (void)openUrl:(NSURL *)openUrl {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"DBConnectControllerCustomOpenURL" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:openUrl, @"URL", nil]];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	
    NSString *appScheme = [[DBSession sharedSession] appScheme];
    if ([[[request URL] scheme] isEqual:appScheme]) {
		
        [self openUrl:[request URL]];
        [self dismiss];
        return NO;
    } else if ([[[request URL] scheme] isEqual:@"itms-apps"]) {
#if TARGET_IPHONE_SIMULATOR
        //DBLogError(@"DropboxSDK - Can't open on simulator. Run on an iOS device to test this functionality");
#else
        [[UIApplication sharedApplication] openURL:[request URL]];
        [self cancelAnimated:NO];
#endif
        return NO;
    } else if (![[[request URL] pathComponents] isEqual:[self.url pathComponents]]) {
        DBConnectController *childController = [[[DBConnectControllerCustom alloc] initWithUrl:[request URL] fromController:self.rootController] autorelease];
		
        NSDictionary *queryParams = [DBSession parseURLParams:[[request URL] query]];
        NSString *title = [queryParams objectForKey:@"embed_title"];
        if (title) {
            childController.title = title;
        } else {
            childController.title = self.title;
        }
        childController.navigationItem.rightBarButtonItem = nil;
		
        [self.navigationController pushViewController:childController animated:YES];
        return NO;
    }
    return YES;
}

@end


@implementation DBSessionCustom

- (NSString *) handleOpenURLReturningUserID:(NSURL *)url {
    NSString *expected = [NSString stringWithFormat:@"%@://%@/", [self appScheme], kDBDropboxAPIVersion];
    if (![[url absoluteString] hasPrefix:expected]) {
        return NO;
    }
	
    NSArray *components = [[url path] pathComponents];
    NSString *methodName = [components count] > 1 ? [components objectAtIndex:1] : nil;
	
    if ([methodName isEqual:@"connect"]) {
        NSDictionary *params = [DBSession parseURLParams:[url query]];
        NSString *token = [params objectForKey:@"oauth_token"];
        NSString *secret = [params objectForKey:@"oauth_token_secret"];
        NSString *userId = [params objectForKey:@"uid"];
        [self updateAccessToken:token accessTokenSecret:secret forUserId:userId];
		return userId;
    } else if ([methodName isEqual:@"cancel"]) {
		return @"";
    } else {
		return nil;
	}
}

- (BOOL)appConformsToScheme {
	return NO;
}

- (void)linkUserId:(NSString *)userId fromController:(UIViewController *)rootController {	
    extern NSString *kDBDropboxUnknownUserId;
    NSString *userIdStr = @"";
    if (userId && ![userId isEqual:kDBDropboxUnknownUserId]) {
        userIdStr = [NSString stringWithFormat:@"&u=%@", userId];
    }
	
    NSString *consumerKey = [baseCredentials objectForKey:kMPOAuthCredentialConsumerKey];
	
    NSData *consumerSecret =
    [[baseCredentials objectForKey:kMPOAuthCredentialConsumerSecret] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(consumerSecret.bytes, (CC_LONG)[consumerSecret length], md);
    CC_LONG sha_32 = htonl(((CC_LONG *)md)[CC_SHA1_DIGEST_LENGTH/sizeof(CC_LONG) - 1]);
    NSString *secret = [NSString stringWithFormat:@"%lx", (unsigned long)sha_32];
	
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef uuid_str = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    NSString *nonce = [(NSString *)uuid_str autorelease];
    [[NSUserDefaults standardUserDefaults] setObject:nonce forKey:kDBLinkNonce];
    [[NSUserDefaults standardUserDefaults] synchronize];
	
    NSString *urlStr = nil;
	
    NSURL *dbURL =
    [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@/connect", kDBProtocolDropbox, kDBDropboxAPIVersion]];
    if ([self appConformsToScheme] && [[UIApplication sharedApplication] canOpenURL:dbURL]) {
        urlStr = [NSString stringWithFormat:@"%@?k=%@&s=%@&state=%@%@",
				  dbURL, consumerKey, secret, nonce, userIdStr];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
    } else {
        urlStr = [NSString stringWithFormat:@"%@://%@/%@/connect_login?k=%@&s=%@&state=%@&easl=1%@",
                  kDBProtocolHTTPS, kDBDropboxWebHost, kDBDropboxAPIVersion,
                  consumerKey, secret, nonce, userIdStr];
        UIViewController *connectController = [[[DBConnectControllerCustom alloc] initWithUrl:[NSURL URLWithString:urlStr] fromController:rootController session:self] autorelease];
        UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:connectController] autorelease];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            connectController.modalPresentationStyle = UIModalPresentationFormSheet;
            navController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
		
        [rootController presentModalViewController:navController animated:YES];
    }
}

@end


#import "DropBoxTail.h"


@implementation SessionDelegate

+ (SessionDelegate *) sharedInstance {
	static SessionDelegate *obj = nil;
	if (!obj) {
		obj = [[SessionDelegate alloc] init];
	}
	return obj;
}

- (id) init {
    self = [super init];
    if (self) {
		DBSession *session = [[DBSessionCustom alloc] initWithAppKey:DROPBOX_CONSUMER_KEY appSecret:DROPBOX_CONSUMER_SECRET root:kDBRootDropbox];
		session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
		[DBSession setSharedSession:session];
    }
    return self;
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId {
	UIAlertView *alert = [[[UIAlertView alloc]
						   initWithTitle:NSLocalizedString(@"Dropbox Session Ended", nil) message:NSLocalizedString(@"Do you want to relink?", nil) delegate:self
						   cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Relink", nil), nil]
						  autorelease];
	objc_setAssociatedObject(alert, @"userId", userId, OBJC_ASSOCIATION_RETAIN);
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	if (index != alertView.cancelButtonIndex) {
		NSString *relinkUserId = objc_getAssociatedObject(alertView, @"userId");
		[[DBSession sharedSession] linkUserId:relinkUserId fromController:[self rootViewController]];
	}
}

- (UIViewController *) rootViewController {
	return [[DropBoxTail sharedInstance] currentViewController];
}

@end

