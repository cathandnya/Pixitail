//
//  GoogleDrive.m
//
//  Created by Naomoto nya on 12/07/08.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "GoogleDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2Authentication.h"
#import <objc/runtime.h>
#import "JSON.h"
#import "UserDefaults.h"
#import "ActivitySheetViewController.h"
#import "AlertView.h"
#import "PostQueue.h"
#import "StatusMessageViewController.h"
#import "ImageLoaderManager.h"
#import "AlertView.h"
#import "BigURLDownloader.h"
#import "ImageDownloader.h"


#define SCOPE			@"https://www.googleapis.com/auth/drive.file"
#define CLIENT_ID		GOOGLE_CLIENT_ID
#define CLIENT_SECRET	GOOGLE_CLIENT_SECRET
#define KEYCHAIN_NAME	@"GoogleDrive"

#define API_BASE		@"https://www.googleapis.com/drive/v2/"
#define API_BASE_UPLOAD	@"https://www.googleapis.com/upload/drive/v2/files/"

#define ESCAPE_CHARS		@"\\/*?|<>:,;'\"　"


@interface GTMOAuth2Authentication(GoogleDrive)
+ (NSString *)encodedQueryParametersForDictionary:(NSDictionary *)dict;
- (BOOL)shouldRefreshAccessToken;
@end


@implementation GoogleDrive

@synthesize auth;
@dynamic available;
@dynamic username;

+ (GoogleDrive *) sharedInstance {
	static GoogleDrive *obj = nil;
	if (!obj) {
		obj = [[GoogleDrive alloc] init];
		obj.auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:KEYCHAIN_NAME clientID:CLIENT_ID clientSecret:CLIENT_SECRET];
	}
	return obj;
}

- (void) dealloc {
	self.auth = nil;
	[super dealloc];
}

#pragma mark-

- (GTMOAuth2ViewControllerTouch *) authViewControllerWithDelegate:(id)del {
	GTMOAuth2ViewControllerTouch *vc = [GTMOAuth2ViewControllerTouch controllerWithScope:SCOPE clientID:CLIENT_ID clientSecret:CLIENT_SECRET keychainItemName:KEYCHAIN_NAME delegate:self finishedSelector:@selector(authFinished:auth:error:)];
	objc_setAssociatedObject(vc, @"Delegate", del, OBJC_ASSOCIATION_ASSIGN);
	return vc;
}

- (void) authFinished:(GTMOAuth2ViewControllerTouch *)sender auth:(GTMOAuth2Authentication *)a error:(NSError *)err {
	id delegate = objc_getAssociatedObject(sender, @"Delegate");
	if (!err) {
		self.auth = a;
		
		ActivitySheetViewController *activity = [ActivitySheetViewController activityController];
		[activity present];
		[activity.activityView startAnimating];
		[activity retain];
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			id about = [self about];
			[about retain];
			dispatch_async(dispatch_get_main_queue(), ^{
				[activity dismiss];
				[activity autorelease];
				[about autorelease];
				
				NSError *e = nil;
				if ([about isKindOfClass:[NSError class]]) {
					e = about;
				} else {
					[self setUsername:[about valueForKey:@"name"]];
					[self setRootFolderId:[about valueForKey:@"rootFolderId"]];
				}
				[self finishAuth:e withDelegate:delegate];
			});
		});
		
	} else {
		[self finishAuth:err withDelegate:delegate];
	}
}

- (void) finishAuth:(NSError *)err withDelegate:(id)del {
	[del performSelector:@selector(googleAuthFinished:error:) withObject:self withObject:err];
}

- (void) logout {
	self.auth = nil;
	self.rootFolderId = nil;
	[GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:KEYCHAIN_NAME];
}

- (NSString *)userAgent {
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *appID = [bundle bundleIdentifier];
	
	NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (version == nil) {
		version = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	}
	
	if (appID && version) {
		appID = [appID stringByAppendingFormat:@"/%@", version];
	}
	
	NSString *userAgent = @"gtm-oauth2";
	if (appID) {
		userAgent = [userAgent stringByAppendingFormat:@" %@", appID];
	}
	return userAgent;
}

- (id) refreshAccessToken {
	NSMutableDictionary *paramsDict = [NSMutableDictionary dictionary];
	
	NSString *commentTemplate;
	NSString *fetchType;
	
	NSString *refreshToken = self.auth.refreshToken;
	//NSString *code = self.auth.code;
	//NSString *assertion = self.auth.assertion;
	
	if (refreshToken) {
		// We have a refresh token
		[paramsDict setObject:@"refresh_token" forKey:@"grant_type"];
		[paramsDict setObject:refreshToken forKey:@"refresh_token"];
		
		fetchType = kGTMOAuth2FetchTypeRefresh;
		commentTemplate = @"refresh token for %@";
		/*
	} else if (code) {
		// We have a code string
		[paramsDict setObject:@"authorization_code" forKey:@"grant_type"];
		[paramsDict setObject:code forKey:@"code"];
		
		NSString *redirectURI = self.redirectURI;
		if ([redirectURI length] > 0) {
			[paramsDict setObject:redirectURI forKey:@"redirect_uri"];
		}
		
		NSString *scope = self.scope;
		if ([scope length] > 0) {
			[paramsDict setObject:scope forKey:@"scope"];
		}
		
		fetchType = kGTMOAuth2FetchTypeToken;
		commentTemplate = @"fetch tokens for %@";
	} else if (assertion) {
		// We have an assertion string
		[paramsDict setObject:assertion forKey:@"assertion"];
		[paramsDict setObject:@"http://oauth.net/grant_type/jwt/1.0/bearer"
					   forKey:@"grant_type"];
		commentTemplate = @"fetch tokens for %@";
		fetchType = kGTMOAuth2FetchTypeAssertion;
		 */
	} else {
#if DEBUG
		NSAssert(0, @"unexpected lack of code or refresh token for fetching");
#endif
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
	
	NSString *clientID = self.auth.clientID;
	if ([clientID length] > 0) {
		[paramsDict setObject:clientID forKey:@"client_id"];
	}
	
	NSString *clientSecret = self.auth.clientSecret;
	if ([clientSecret length] > 0) {
		[paramsDict setObject:clientSecret forKey:@"client_secret"];
	}
	
	NSDictionary *additionalParams = self.auth.additionalTokenRequestParameters;
	if (additionalParams) {
		[paramsDict addEntriesFromDictionary:additionalParams];
	}
	
	NSString *paramStr = [GTMOAuth2Authentication encodedQueryParametersForDictionary:paramsDict];
	NSData *paramData = [paramStr dataUsingEncoding:NSUTF8StringEncoding];
	
	NSURL *tokenURL = self.auth.tokenURL;
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenURL];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
	NSString *userAgent = [self userAgent];
	[request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:paramData];
	
	NSError *error = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&res error:&error];
	
	NSDictionary *responseHeaders = [res allHeaderFields];
	NSString *responseType = [responseHeaders valueForKey:@"Content-Type"];
	BOOL isResponseJSON = [responseType hasPrefix:@"application/json"];
	BOOL hasData = ([data length] > 0);
	
	if (error) {
		// Failed; if the error body is JSON, parse it and add it to the error's
		// userInfo dictionary
		if (hasData) {
			if (isResponseJSON) {
				NSDictionary *errorJson = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] JSONValue];
				if ([errorJson count] > 0) {
#if DEBUG
					NSLog(@"Error %@\nError data:\n%@", error, errorJson);
#endif
					// Add the JSON error body to the userInfo of the error
					NSMutableDictionary *userInfo;
					userInfo = [NSMutableDictionary dictionaryWithObject:errorJson
																  forKey:kGTMOAuth2ErrorJSONKey];
					NSDictionary *prevUserInfo = [error userInfo];
					if (prevUserInfo) {
						[userInfo addEntriesFromDictionary:prevUserInfo];
					}
					error = [NSError errorWithDomain:[error domain]
												code:[error code]
											userInfo:userInfo];
				}
			}
		}
	} else {
		// Succeeded; we have an access token
#if DEBUG
		NSAssert(hasData, @"data missing in token response");
#endif
		
		if (hasData) {
			if (isResponseJSON) {
				[self.auth setKeysForResponseDictionary:[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] JSONValue]];
			} else {
				// Support for legacy token servers that return form-urlencoded data
				NSString *dataStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
				[self.auth setKeysForResponseString:dataStr];
			}
			
#if DEBUG
			// Watch for token exchanges that return a non-bearer or unlabeled token
			NSString *tokenType = [self.auth tokenType];
			if (tokenType == nil
				|| [tokenType caseInsensitiveCompare:@"bearer"] != NSOrderedSame) {
				NSLog(@"GTMOAuth2: Unexpected token type: %@", tokenType);
			}
#endif
		}
	}
	return error;
	
	/*
	GTMHTTPFetcher *fetcher;
	id <GTMHTTPFetcherServiceProtocol> fetcherService = self.fetcherService;
	if (fetcherService) {
		fetcher = [fetcherService fetcherWithRequest:request];
		
		// Don't use an authorizer for an auth token fetch
		fetcher.authorizer = nil;
	} else {
		fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
	}
	
	[fetcher setCommentWithFormat:commentTemplate, [tokenURL host]];
	fetcher.postData = paramData;
	fetcher.retryEnabled = YES;
	fetcher.maxRetryInterval = 15.0;
	*/
	
	/*
	// Fetcher properties will retain the delegate
	[fetcher setProperty:delegate forKey:kTokenFetchDelegateKey];
	if (finishedSel) {
		NSString *selStr = NSStringFromSelector(finishedSel);
		[fetcher setProperty:selStr forKey:kTokenFetchSelectorKey];
	}
	
	if ([fetcher beginFetchWithDelegate:self
					  didFinishSelector:@selector(tokenFetcher:finishedWithData:error:)]) {
		// Fetch began
		[self notifyFetchIsRunning:YES fetcher:fetcher type:fetchType];
		return fetcher;
	} else {
		// Failed to start fetching; typically a URL issue
		NSError *error = [NSError errorWithDomain:kGTMHTTPFetcherStatusDomain
											 code:-1
										 userInfo:nil];
		[[self class] invokeDelegate:delegate
							selector:finishedSel
							  object:self
							  object:nil
							  object:error];
		return nil;
	}
	 */
}

- (NSError *) autoRefreshAccessToken {
	if ([self.auth shouldRefreshAccessToken]) {
		id ret = [self refreshAccessToken];
		if ([ret isKindOfClass:[NSError class]]) {
			return ret;
		} else {
			return nil;
		}
	} else {
		return nil;
	}
}

#pragma mark-

- (BOOL) available {
	return self.auth.canAuthorize && self.rootFolderId.length > 0;
}

- (NSString *) username {
	return UDStringWithDefault(@"GoogleDriveUsername", @"");
}

- (void) setUsername:(NSString *)username {
	UDSetString(username, @"GoogleDriveUsername");
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) rootFolderId {
	return UDString(@"GoogleDriveRootFolderId");
}

- (void) setRootFolderId:(NSString *)str {
	UDSetString(str, @"GoogleDriveRootFolderId");
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) encodeURIComponent:(NSString *)string {
	NSString *str = NSMakeCollectable([(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR("?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease]);
	if (str) {
		return str;
	}
	return @"";
}

- (id) jsonValue:(NSString *)str {
	id json =[str JSONValue];
	if ([json valueForKey:@"error"]) {
		NSString *code = [json valueForKeyPath:@"error.code"];
		//NSString *message = [json valueForKeyPath:@"error.message"];
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:[code intValue] userInfo:nil];
	} else {
		return json;
	}
}

#pragma mark-

- (id) about {
	NSError *e = [self autoRefreshAccessToken];
	if (e) {
		return e;
	}
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[API_BASE stringByAppendingString:@"about"]]];
	if (![self.auth authorizeRequest:req]) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	DLog(@"about: %@", str);
	id json = [self jsonValue:str];
	return json;
}

- (id) createDirectory:(NSString *)name inDirectory:(NSString *)dirID {
	NSError *e = [self autoRefreshAccessToken];
	if (e) {
		return e;
	}
	
	NSString *bodyString = [NSString stringWithFormat:@"{\"title\": \"%@\", \"parents\": [{\"id\":\"%@\"}], \"mimeType\": \"application/vnd.google-apps.folder\"}", name, dirID];
	NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[API_BASE stringByAppendingString:@"files"]]];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
    [req setValue:[NSString stringWithFormat:@"%@", @([body length])] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

	if (![self.auth authorizeRequest:req]) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	DLog(@"createDirectory: %@", str);
	id json = [self jsonValue:str];
	return json;
}

- (id) listDirectory:(NSString *)dirID {
	NSError *e = [self autoRefreshAccessToken];
	if (e) {
		return e;
	}
	
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[API_BASE stringByAppendingFormat:@"files/%@/children", dirID]]];
	if (![self.auth authorizeRequest:req]) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	DLog(@"listDirectory: %@", str);
	id json = [self jsonValue:str];
	return json;
}

- (id) findFile:(NSString *)name inDirectory:(NSString *)dirID {
	NSError *e = [self autoRefreshAccessToken];
	if (e) {
		return e;
	}
	
	DLog(@"find: %@", [API_BASE stringByAppendingFormat:@"files?q=title+%%3d+%%27%@%%27", name]);
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[API_BASE stringByAppendingFormat:@"files?q=title+%%3d+%%27%@%%27", name]]];
	if (![self.auth authorizeRequest:req]) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	DLog(@"findFile: %@", str);
	id json = [self jsonValue:str];
	if ([json isKindOfClass:[NSError class]]) {
		return json;
	}
	for (NSDictionary *item in [json valueForKeyPath:@"items"]) {
		for (NSDictionary *p in [item valueForKey:@"parents"]) {
			if ([[p valueForKey:@"id"] isEqual:dirID]) {
				// みつけた
				return item;
			}
		}
	}
	return nil;
}

- (id) insertFileData:(NSData *)fileData title:(NSString *)name mime:(NSString *)mime inDirectory:(NSString *)dirID {
	NSError *e = [self autoRefreshAccessToken];
	if (e) {
		return e;
	}
	
	NSString *bodyString = [NSString stringWithFormat:@"{\
	\"title\" : \"%@\",\
	\"mimeType\" : \"%@\",\
	\"parents\": [{\
		\"kind\": \"drive#fileLink\",\
		\"id\": \"%@\"\
	}]\
	}", name, mime, dirID];
	NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];

	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[API_BASE stringByAppendingString:@"files"]]];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
	[req setValue:[NSString stringWithFormat:@"%@", @([body length])] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];

	if (![self.auth authorizeRequest:req]) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}

	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	NSString *str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	DLog(@"insertFile: %@", str);
	id json = [self jsonValue:str];
	if ([json isKindOfClass:[NSError class]]) {
		return json;
	}
	id idt = [json valueForKey:@"id"];
	if (idt) {
		NSError *e = [self autoRefreshAccessToken];
		if (e) {
			return e;
		}
		
		DLog(@"upload: %@", [API_BASE_UPLOAD stringByAppendingFormat:@"%@?uploadType=media", idt]);
		req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[API_BASE_UPLOAD stringByAppendingFormat:@"%@?uploadType=media", idt]]];
		[req setHTTPMethod:@"PUT"];
		[req setHTTPBody:fileData];
		[req setValue:[NSString stringWithFormat:@"%@", @([fileData length])] forHTTPHeaderField:@"Content-Length"];
		[req setValue:mime forHTTPHeaderField:@"Content-Type"];
		if (![self.auth authorizeRequest:req]) {
			return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
		}
		
		data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		if (err) {
			return err;
		}
		str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		DLog(@"insertFile data: %@", str);
		return [self jsonValue:str];
	} else {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
}

#pragma mark-

- (id) insertToFolder:(NSString *)folder withData:(NSData *)data name:(NSString *)name mime:(NSString *)mime {
	id obj;
	
	// フォルダ探す
	obj = [self findFile:folder inDirectory:[self rootFolderId]];
	if ([obj isKindOfClass:[NSError class]]) {
		return obj;
	}
	if (!obj) {
		// ない -> 作る
		obj = [self createDirectory:folder inDirectory:[self rootFolderId]];
		if ([obj isKindOfClass:[NSError class]]) {
			return obj;
		}
		obj = [obj valueForKey:@"id"];
	} else {
		obj = [obj valueForKey:@"id"];
	}
	
	obj = [self insertFileData:data title:name mime:mime inDirectory:obj];
	if ([obj isKindOfClass:[NSError class]]) {
		return obj;
	}
	
	return nil;
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;
	
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to GoogleDrive.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = sender.object;
		[alert show];
		
		[urlDownloadHandler post:self finished:0];
	} else {
		int i = 0;
		for (NSString *url in sender.imageURLs) {
			NSMutableDictionary *info = [[sender.object mutableCopy] autorelease];
			[info setObject:url forKey:@"ImageURL"];
			if (i > 0) {
				NSString *p = [info objectForKey:@"Path"];
				p = [p stringByAppendingFormat:@"_%d", i];
				[info setObject:p forKey:@"Path"];
			}
			if (sender.imageURLs.count > 1) {
				NSString *n = [info objectForKey:@"Name"];
				
				[info setObject:[[n copy] autorelease] forKey:@"Directory"];
				
				n = [n stringByAppendingFormat:@"_%03d", i + 1];
				[info setObject:n forKey:@"Name"];				
			}
			i++;
			
			[[PostQueue googleDriveQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
		}
		[urlDownloadHandler post:self finished:0];
	}	
	urlDownloadHandler = nil;
}

- (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err {
	NSDictionary *info = [[sender.object retain] autorelease];
	[imageDownloader autorelease];
	imageDownloader = nil;
	
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to GoogleDrive.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = info;
		[alert show];
		
		[imageDownloadHandler post:self finished:0];
	} else {
		[self uploadPhoto:info handler:imageDownloadHandler];
	}	
	imageDownloadHandler = nil;
}

#pragma mark-

- (NSString *) errorMessage:(NSError *)err {
	return [err localizedDescription];
}

- (void) uploadFinished:(id)obj {
	[obj post:self finished:0];
}

- (void) uploadCancel {
}

- (long) uploadPhoto:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if (!self.available) {
		[self performSelector:@selector(uploadFinished:) withObject:obj afterDelay:0.1];
		return 0;
	}
	
	NSString *imgPath = [info objectForKey:@"Path"];
	DLog(@"upload: %@", imgPath);
	if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath] == NO) {
		NSString *imgURL = [info objectForKey:@"ImageURL"];
		if (imgURL) {
			imageDownloader = [[ImageDownloader alloc] init];
			imageDownloader.url = imgURL;
			imageDownloader.savePath = imgPath;
			imageDownloader.referer = [info objectForKey:@"Referer"];
			imageDownloader.object = info;
			imageDownloader.delegate = self;
			imageDownloadHandler = obj;
			
			[imageDownloader download];			
			DLog(@" -> download image");
		} else {
			urlDownloader = [[BigURLDownloader alloc] init];
			urlDownloader.parserClassName = [info objectForKey:@"ParserClass"];
			urlDownloader.bigSourceURL = [info objectForKey:@"SourceURL"];
			urlDownloader.referer = [info objectForKey:@"Referer"];
			urlDownloader.object = info;
			urlDownloader.delegate = self;
			urlDownloadHandler = obj;
			
			[urlDownloader download];
			DLog(@" -> download url");
		}
		return 0;
	}
	DLog(@" -> upload");
	
	static const char pngBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
	NSData *png = [NSData dataWithBytes:pngBytes length:8];
	static const char gifBytes[3] = {0x47, 0x49, 0x46};
	NSData *gif = [NSData dataWithBytes:gifBytes length:3];
	
	NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:[info objectForKey:@"Path"]];
	NSData *data = [fh readDataOfLength:8];
	
	NSString *mime = nil;
	NSString *ext = nil;
	if ([[data subdataWithRange:NSMakeRange(0, 8)] isEqualToData:png]) {
		ext = @"png";
		mime = @"image/png";
	} else if ([[data subdataWithRange:NSMakeRange(0, 3)] isEqualToData:gif]) {
		ext = @"gif";
		mime = @"image/gif";
	} else {
		ext = @"jpg";
		mime = @"image/jpeg";
	}
	
	NSString *name = [info objectForKey:@"Name"];
	NSString *replacement = ESCAPE_CHARS;
	for (int i = 0; i < replacement.length; i++) {
		NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
		name = [name stringByReplacingOccurrencesOfString:s withString:@"#"];
	}
	if ([info objectForKey:@"Username"]) {
		NSString *uname = [info objectForKey:@"Username"];
		NSString *replacement = ESCAPE_CHARS;
		for (int i = 0; i < replacement.length; i++) {
			NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
			uname = [uname stringByReplacingOccurrencesOfString:s withString:@"#"];
		}
		
		name = [uname stringByAppendingFormat:@"_%@", name];
	} else {
		//path = [path stringByAppendingPathComponent:@"Unknown"];
	}
	
	NSString *local = [info objectForKey:@"Path"];
	name = [name stringByAppendingPathExtension:ext];
	
	[local retain];
	[name retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[name autorelease];
		[local autorelease];
		
		NSString *folder;
#ifdef PIXITAIL
		folder = @"Pixitail";
#else
		folder = @"Illustail";
#endif
		
		id ret = [self insertToFolder:folder withData:[NSData dataWithContentsOfFile:local] name:name mime:mime];
		[ret retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
			[ret autorelease];
			
			[self uploadFinished:obj];
			if ([ret isKindOfClass:[NSError class]]) {
				NSString *msg = [self errorMessage:ret];
				AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to GoogleDrive.", nil) message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
				alert.object = info;
				[alert show];
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Sharing to GoogleDrive is finished.", nil)];
			}
		});
	});
	return 0;
}

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		NSDictionary *dic = alertView.object;
		[self upload:dic];
	}
}

- (void) upload:(NSDictionary *)info {
	[[PostQueue googleDriveQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
}

@end
