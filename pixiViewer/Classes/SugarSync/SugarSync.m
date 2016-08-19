//
//  SugarSync.m
//
//  Created by Naomoto nya on 12/07/06.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SugarSync.h"
#import "UserDefaults.h"
#import "GDataXMLNode.h"
#import "PostQueue.h"
#import "StatusMessageViewController.h"
#import "AlertView.h"
#import "ImageLoaderManager.h"
#import "ImageDownloader.h"
#import "BigURLDownloader.h"


#define APPLICATION_ID			SUGARSYNC_APPLICATION_ID
#define PUBLIC_ACCESS_KEY		SUGARSYNC_PUBLIC_ACCESS_KEY
#define PRIVATE_ACCESS_KEY		SUGARSYNC_PRIVATE_ACCESS_KEY


#define APP_AUTH_REFRESH_TOKEN_API_URL	@"https://api.sugarsync.com/app-authorization"
#define APP_AUTH_REQUEST_TEMPLATE		@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>	\
<appAuthorization>\
<username>%@</username>\
<password>%@</password>\
<application>%@</application>\
<accessKeyId>%@</accessKeyId>\
<privateAccessKey>%@</privateAccessKey>\
</appAuthorization>"

#define AUTH_ACCESS_TOKEN_API_URL			@"https://api.sugarsync.com/authorization"
#define ACCESS_TOKEN_AUTH_REQUEST_TEMPLATE	@"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\
<tokenAuthRequest>\
<accessKeyId>%@</accessKeyId>\
<privateAccessKey>%@</privateAccessKey>\
<refreshToken>%@</refreshToken>\
</tokenAuthRequest>"

#define USER_INFO_API_URL		@"https://api.sugarsync.com/user"

#define CREATE_FILE_REQUEST_TEMPLATE	@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\
<file>\
<displayName>%@</displayName>\
<mediaType>%@</mediaType>\
</file>"

#define CREATE_FOLDER_REQUEST_TEMPLATE	@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\
<folder>\
<displayName>%@</displayName>\
</folder>"

#define ESCAPE_CHARS		@"\\/*?|<>:,;'\"　"



@implementation SugarSync

@dynamic hasAccount, username;

+ (SugarSync *) sharedInstance {
	static SugarSync *obj = nil;
	if (!obj) {
		obj = [[SugarSync alloc] init];
	}
	return obj;
}

- (NSString *) refreshToken {
	return UDString(@"SugarSyncRefreshToken");
}

- (void) setRefreshToken:(NSString *)str {
	UDSetString(str, @"SugarSyncRefreshToken");
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) accessToken {
	return UDString(@"SugarSyncAccessToken");
}

- (void) setAccessToken:(NSString *)str {
	UDSetString(str, @"SugarSyncAccessToken");
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *) accessTokenExpiredDate {
	return UDObject(@"SugarSyncAccessTokenExpiredDate");
}

- (void) setAccessTokenExpiredDate:(NSDate *)date {
	UDSetObject(date, @"SugarSyncAccessTokenExpiredDate");
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) username {
	return UDString(@"SugarSyncUserName");
}

- (void) setUsername:(NSString *)str {
	UDSetString(str, @"SugarSyncUserName");
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) hasAccount {
	return [self refreshToken].length > 0;
}

- (BOOL) accessTokenIsExpired {
	if (![self accessToken]) {
		return true;
	} else {
		NSDate *expired = [self accessTokenExpiredDate];
		if (!expired) {
			return true;
		} else {
			NSDate *now = [NSDate date];
			return ([expired timeIntervalSince1970] - [now timeIntervalSince1970] < 60);
		}
	}
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
	
	NSString *userAgent = @"";
	if (appID) {
		userAgent = [userAgent stringByAppendingFormat:@" %@", appID];
	}
	return userAgent;
}

- (NSMutableURLRequest *) requestWithURL:(NSString *)url {
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];
	return req;
}

#pragma mark-

- (NSError *) loginWithUsername:(NSString *)username password:(NSString *)password {
	NSString *bodyString = [NSString stringWithFormat:APP_AUTH_REQUEST_TEMPLATE, username, password, APPLICATION_ID, PUBLIC_ACCESS_KEY, PRIVATE_ACCESS_KEY];
	NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *req = [self requestWithURL:APP_AUTH_REFRESH_TOKEN_API_URL];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
    [req setValue:[NSString stringWithFormat:@"%@", @([body length])] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSString *refreshToken = nil;
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else if (res.statusCode > 299) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
	} else {
		refreshToken = [res.allHeaderFields objectForKey:@"Location"];
	}
	
	if (refreshToken) {
		[self setRefreshToken:refreshToken];
		[self setUsername:username];
		return nil;
	} else {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
}

- (void) loginWithUsername:(NSString *)username password:(NSString *)password block:(void (^)(NSError *))completionBlock {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError *err = [self loginWithUsername:username password:password];
		[err retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			[err autorelease];
			if (completionBlock) {
				completionBlock(err);
			}
		});
	});
}

#pragma mark-

- (void) logout {
	[self setRefreshToken:nil];
	[self setAccessToken:nil];
	[self setAccessTokenExpiredDate:nil];
}

#pragma mark-

- (NSError *) refreshAccessToken {
	NSString *bodyString = [NSString stringWithFormat:ACCESS_TOKEN_AUTH_REQUEST_TEMPLATE, PUBLIC_ACCESS_KEY, PRIVATE_ACCESS_KEY, [self refreshToken]];
	NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *req = [self requestWithURL:AUTH_ACCESS_TOKEN_API_URL];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
    [req setValue:[NSString stringWithFormat:@"%@", @([body length])] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSString *accessToken = nil;
	NSDate *expiredDate = nil;
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else if (res.statusCode > 299) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
	} else {
		accessToken = [res.allHeaderFields objectForKey:@"Location"];
		
		GDataXMLDocument *doc = [[[GDataXMLDocument alloc] initWithData:data options:0 error:&err] autorelease];
		if (err) {
			return err;
		}
		NSArray *nodes = [doc nodesForXPath:@"/authorization/expiration/text()" error:nil];
		if (nodes.count > 0) {
			GDataXMLElement *e = [nodes objectAtIndex:0];
			NSString *expiredString = [e stringValue];
			expiredString = [expiredString stringByReplacingCharactersInRange:NSMakeRange(19, 4) withString:@"GMT"];
			DLog(@"expired: %@", expiredString);
			
			NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
			[fmt setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssz"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			/*
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:sszzzz"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:Sv"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:Svvvv"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:SV"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			[fmt setDateFormat:@"yyyy-MM-dd'T'HH:mm:SVVVV"];
			expiredDate = [fmt dateFromString:expiredString];
			DLog(@"%@", [expiredDate description]);
			*/			
		}
	}
	
	if (accessToken && expiredDate) {
		[self setAccessToken:accessToken];
		[self setAccessTokenExpiredDate:expiredDate];
		return nil;
	} else {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
	}
}

#pragma mark-

- (id) loadUserInfo {
	if ([self accessTokenIsExpired]) {
		id ret = [self refreshAccessToken];
		if ([ret isKindOfClass:[NSError class]]) {
			return ret;
		}
	}
	
	NSMutableURLRequest *req = [self requestWithURL:USER_INFO_API_URL];
	[req setValue:[self accessToken] forHTTPHeaderField:@"Authorization"];
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else if (res.statusCode > 299) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
	} else {
		return data;
	}
}

- (id) magicBriefcaseLink {
	id userInfo = [self loadUserInfo];
	if ([userInfo isKindOfClass:[NSData class]]) {
		NSError *err = nil;
		GDataXMLDocument *doc = [[[GDataXMLDocument alloc] initWithData:userInfo options:0 error:&err] autorelease];
		if (err) {
			return err;
		}
		NSArray *nodes = [doc nodesForXPath:@"/user/magicBriefcase/text()" error:nil];
		if (nodes.count > 0) {
			GDataXMLElement *e = [nodes objectAtIndex:0];
			NSString *link = [e stringValue];
			DLog(@"magicBriefcase: %@", link);
			return link;
		} else {
			return [NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil];
		}
	} else {
		return userInfo;
	}
}

#pragma mark-

- (id) createFile:(NSString *)url name:(NSString *)name {
	if ([self accessTokenIsExpired]) {
		id ret = [self refreshAccessToken];
		if ([ret isKindOfClass:[NSError class]]) {
			return ret;
		}
	}
	
	NSString *bodyString = [NSString stringWithFormat:CREATE_FILE_REQUEST_TEMPLATE, name, @""];
	NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];

	NSMutableURLRequest *req = [self requestWithURL:url];
	[req setValue:[self accessToken] forHTTPHeaderField:@"Authorization"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
    [req setValue:[NSString stringWithFormat:@"%@", @([body length])] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else if (res.statusCode > 299) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
	} else {
		return [res.allHeaderFields objectForKey:@"Location"];
	}
}

#pragma mark-

- (id) createFolder:(NSString *)url name:(NSString *)name {
	if ([self accessTokenIsExpired]) {
		id ret = [self refreshAccessToken];
		if ([ret isKindOfClass:[NSError class]]) {
			return ret;
		}
	}
	
	NSString *bodyString = [NSString stringWithFormat:CREATE_FOLDER_REQUEST_TEMPLATE, name];
	NSData *body = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
	
	NSMutableURLRequest *req = [self requestWithURL:url];
	[req setValue:[self accessToken] forHTTPHeaderField:@"Authorization"];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:body];
    [req setValue:[NSString stringWithFormat:@"%@", @([body length])] forHTTPHeaderField:@"Content-Length"];
	[req setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else if (res.statusCode > 299) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
	} else {
		return [res.allHeaderFields objectForKey:@"Location"];
	}
}

#pragma mark-

- (id) loadFolderContent:(NSString *)url {
	int start = 0;
	BOOL more = YES;
	
	NSMutableArray *mary = [NSMutableArray array];
	while (more) {
		NSMutableURLRequest *req = [self requestWithURL:[url stringByAppendingFormat:@"/contents?type=folder&start=%d", start]];
		[req setValue:[self accessToken] forHTTPHeaderField:@"Authorization"];
		
		NSError *err = nil;
		NSHTTPURLResponse *res = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		if (err) {
			return err;
		} else if (res.statusCode > 299) {
			return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
		} else {
			NSError *err = nil;
			GDataXMLDocument *doc = [[[GDataXMLDocument alloc] initWithData:data options:0 error:&err] autorelease];
			if (err) {
				return err;
			}
			
			GDataXMLNode *hasMore = [doc.rootElement attributeForName:@"hasMore"];
			GDataXMLNode *end = [doc.rootElement attributeForName:@"end"];
			DLog(@"hasMore: %@", [hasMore stringValue]);
			DLog(@"end: %@", [end stringValue]);
			
			NSArray *names = [doc nodesForXPath:@"/collectionContents/collection/displayName/text()" error:nil];
			NSArray *refs = [doc nodesForXPath:@"/collectionContents/collection/ref/text()" error:nil];
			if (names.count == refs.count) {
				for (int i = 0; i < names.count; i++) {
					[mary addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[names objectAtIndex:i] stringValue], @"displayName", [[refs objectAtIndex:i] stringValue], @"ref", nil]];
				}
			}		
			DLog(@"folder: %@ contents: %@", url, [mary description]);
			
			more = [[hasMore stringValue] isEqual:@"true"];
			start = [[end stringValue] intValue];
		}
	}
	return mary;
}

- (id) findFolder:(NSString *)folderName in:(NSString *)url {
	int start = 0;
	BOOL more = YES;
	
	while (more) {
		NSMutableURLRequest *req = [self requestWithURL:[url stringByAppendingFormat:@"/contents?type=folder&start=%d", start]];
		[req setValue:[self accessToken] forHTTPHeaderField:@"Authorization"];
		
		NSError *err = nil;
		NSHTTPURLResponse *res = nil;
		NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		if (err) {
			return err;
		} else if (res.statusCode > 299) {
			return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
		} else {
			NSError *err = nil;
			GDataXMLDocument *doc = [[[GDataXMLDocument alloc] initWithData:data options:0 error:&err] autorelease];
			if (err) {
				return err;
			}
			
			GDataXMLNode *hasMore = [doc.rootElement attributeForName:@"hasMore"];
			GDataXMLNode *end = [doc.rootElement attributeForName:@"end"];
			DLog(@"hasMore: %@", [hasMore stringValue]);
			DLog(@"end: %@", [end stringValue]);
			
			NSArray *names = [doc nodesForXPath:@"/collectionContents/collection/displayName/text()" error:nil];
			NSArray *refs = [doc nodesForXPath:@"/collectionContents/collection/ref/text()" error:nil];
			if (names.count == refs.count) {
				for (int i = 0; i < names.count; i++) {
					if ([[[names objectAtIndex:i] stringValue] isEqual:folderName]) {
						// みつけた
						return [[refs objectAtIndex:i] stringValue];
					}
				}
			}		
			
			more = [[hasMore stringValue] isEqual:@"true"];
			start = [[end stringValue] intValue];
		}
	}
	return nil;
}

#pragma mark-

- (id) uploadFile:(NSString *)url data:(NSData *)fileData {
	if ([self accessTokenIsExpired]) {
		id ret = [self refreshAccessToken];
		if ([ret isKindOfClass:[NSError class]]) {
			return ret;
		}
	}
	
	NSMutableURLRequest *req = [self requestWithURL:url];
	[req setValue:[self accessToken] forHTTPHeaderField:@"Authorization"];
	[req setHTTPMethod:@"PUT"];
	[req setHTTPBody:fileData];
    [req setValue:[NSString stringWithFormat:@"%@", @([fileData length])] forHTTPHeaderField:@"Content-Length"];
	
	NSError *err = nil;
	NSHTTPURLResponse *res = nil;
	[NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else if (res.statusCode > 299) {
		return [NSError errorWithDomain:NSStringFromClass([self class]) code:res.statusCode userInfo:nil];
	} else {
		return nil;
	}
}

#pragma mark-

- (id) uploadFileData:(NSData *)data name:(NSString *)name to:(NSString *)url {
	id obj;
	
	obj = [self createFile:url name:name];
	if ([obj isKindOfClass:[NSError class]] || ![obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	NSString *link = [obj stringByAppendingString:@"/data"];
	obj = [self uploadFile:link data:data];
	if ([obj isKindOfClass:[NSError class]]) {
		return obj;
	}
	
	return nil;
}

- (id) uploadFileToMagicBriefcaseWithData:(NSData *)data name:(NSString *)name {
	id obj;
	
	obj = [self magicBriefcaseLink];
	if ([obj isKindOfClass:[NSError class]] || ![obj isKindOfClass:[NSString class]]) {
		return obj;
	}
	
	obj = [self uploadFileData:data name:name to:obj];
	if ([obj isKindOfClass:[NSError class]]) {
		return obj;
	}
	
	return nil;
}

- (id) uploadFileToMagicBriefcaseFolder:(NSString *)folder withData:(NSData *)data name:(NSString *)name {
	id obj;
	
	NSString *magicBriefcaseRef = [self magicBriefcaseLink];
	if (![magicBriefcaseRef isKindOfClass:[NSString class]]) {
		return magicBriefcaseRef;
	}
	
	// フォルダ探す
	obj = [self findFolder:folder in:magicBriefcaseRef];
	if (!obj) {
		// ない -> 作る
		obj = [self createFolder:magicBriefcaseRef name:folder];
		if (![obj isKindOfClass:[NSString class]]) {
			return obj;
		}
	} else if (![obj isKindOfClass:[NSString class]]) {
		return obj;
	}
		
	obj = [self uploadFileData:data name:name to:obj];
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
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to SugarSync.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
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
			
			[[PostQueue sugarsyncQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
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
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to SugarSync.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
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
	if (!self.hasAccount) {
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
	
	NSString *ext = nil;
	if ([[data subdataWithRange:NSMakeRange(0, 8)] isEqualToData:png]) {
		ext = @"png";
	} else if ([[data subdataWithRange:NSMakeRange(0, 3)] isEqualToData:gif]) {
		ext = @"gif";
	} else {
		ext = @"jpg";
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
		
		id ret = [self uploadFileToMagicBriefcaseFolder:folder withData:[NSData dataWithContentsOfFile:local] name:name];
		[ret retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
			[ret autorelease];
			
			[self uploadFinished:obj];
			if ([ret isKindOfClass:[NSError class]]) {
				NSString *msg = [self errorMessage:ret];
				AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to SugarSync.", nil) message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
				alert.object = info;
				[alert show];
			} else {
				[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Sharing to SugarSync is finished.", nil)];
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
	[[PostQueue sugarsyncQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
}

@end
