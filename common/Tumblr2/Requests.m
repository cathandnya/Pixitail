//
//  Requests.m
//  Tumbltail
//
//  Created by nya on 11/09/17.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "Requests.h"
#import "Tumblr.h"
#import "OAMutableURLRequest.h"
#import "OAAsynchronousDataFetcher.h"
#import "OAServiceTicket.h"
#import "SharedAlertView.h"
#import "AccountManager.h"
#import "PostQueue.h"
#import "RegexKitLite.h"
#import "StatusMessageViewController.h"
#import "OADataFetcher.h"
#import "Reachability.h"
#import "TumblrAccountManager.h"


static NSString *encodeURIComponent(NSString *string) {
	NSString *newString = CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
	if (newString) {
		return newString;
	}
	return @"";
}



@implementation RequestPool

+ (RequestPool *) sharedObject {
	static RequestPool *obj = nil;
	if (obj == nil) {
		obj = [[RequestPool alloc] init];
	}
	return obj;
}

- (id) init {
	self = [super init];
	if (self) {
		requests = [[NSMutableDictionary alloc] init];
		pendingRequestIDs = [[NSMutableSet alloc] init];
		
		reachability = [Reachability reachabilityForInternetConnection];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:reachability];
		[reachability startNotifer];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL) reachable {
	return (reachability.currentReachabilityStatus != NotReachable);
}

- (void) reachabilityChanged:(NSNotification *)notif {
	BOOL reachable = [self reachable];
	if (reachable) {
		for (NSString *ID in pendingRequestIDs) {
			Request *req = [self requestForID:ID];
			[req start];
		}
		[pendingRequestIDs removeAllObjects];
	}
}

- (void) addAndStart:(Request *)req {
	if (![self isRunning:req.ID]) {
		req.pool = self;
		if ([self reachable]) {
			[req start];
		} else {
			[pendingRequestIDs addObject:req.ID];
		}
		[requests setObject:req forKey:req.ID];
	}
}

- (void) remove:(NSString *)ID {
	if ([self isRunning:ID]) {
		Request *req = [requests objectForKey:ID];
		req.delegate = nil;
		
		[requests removeObjectForKey:ID];
		if ([pendingRequestIDs containsObject:ID]) {
			[pendingRequestIDs removeObject:ID];
		}
	}
}

- (BOOL) isRunning:(NSString *)ID {
	return [requests objectForKey:ID] != nil;
}

- (Request *) requestForID:(NSString *)ID {
	return [requests objectForKey:ID];
}

- (void) retry:(Request *)req {
	[self remove:req.ID];
	[self addAndStart:req];
}

@end


@interface Request()
@property(assign) int retryCount;
@property(strong) NSString *multipartBodyFilepath;
@end


@implementation Request

@dynamic isLoading, ID;
@synthesize delegate, pool, param, url, token, consumer;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (void) dealloc {
	[self cancel];
}

#pragma mark-

- (NSString *) httpMethod {
	return @"GET";
}

- (NSString *) referer {
	return nil;
}

- (id) parse:(NSData *)data {
	return data;
}

- (NSString *) notificationName {
	return [NSString stringWithFormat:@"%@FinishedNotification", NSStringFromClass([self class])];
}

- (SEL) selector {
	NSString *str = NSStringFromClass([self class]);
	NSString *first = [str substringToIndex:1];
	first = [first lowercaseString];
	str = [str substringFromIndex:1];
	str = [first stringByAppendingString:str];
	str = [NSString stringWithFormat:@"%@:finished:", str];
	return NSSelectorFromString(str);
}

- (NSString *) ID {
	return NSStringFromClass([self class]);
}

- (NSString *) multipartBoundary {
	return nil;
}

#pragma mark-

- (NSString *) paramString:(NSDictionary *)dic {
	NSMutableString *str = [NSMutableString string];
	if ([dic count] > 0) {
		NSArray *keys = [dic allKeys];
		for (NSString *key in keys) {
			if ([dic[key] isKindOfClass:[NSString class]]) {
				[str appendFormat:@"%@=%@", encodeURIComponent(key), encodeURIComponent([dic objectForKey:key])];
				if (key != [keys lastObject]) {
					[str appendString:@"&"];
				}
			}
		}
	}
	return str;
}

- (NSString *) urlString:(NSString *)urlStr withParam:(NSDictionary *)dic {
	NSMutableString *str = [NSMutableString stringWithString:urlStr];
	if ([dic count] > 0) {
		if (![str hasSuffix:@"&"]) {
			if ([str rangeOfString:@"?"].location == NSNotFound) {
				[str appendString:@"?"];
			} else {
				[str appendString:@"&"];
			}
		}
		[str appendString:[self paramString:dic]];
	}
	return str;
}

+ (void) addValue:(id)val forKey:(NSString *)key toFile:(NSFileHandle *)file withBoundary:(NSString *)boundary {
	if ([val isKindOfClass:[NSNumber class]]) {
		val = [val stringValue];
	}
	if ([val isKindOfClass:[NSString class]]) {
		[file writeData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[file writeData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", encodeURIComponent(key)] dataUsingEncoding:NSUTF8StringEncoding]];
		[file writeData:[val dataUsingEncoding:NSUTF8StringEncoding]];
		[file writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSData class]]) {
		[file writeData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[file writeData:[[NSString stringWithFormat:@"Content-Disposition: file; name=\"%@\"; filename=\"file.jpg\"\r\n", encodeURIComponent(key)] dataUsingEncoding:NSUTF8StringEncoding]];
		[file writeData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[file writeData:val];
		[file writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSDictionary class]] && ([val[@"data"] isKindOfClass:[NSData class]] || [val[@"filepath"] isKindOfClass:[NSString class]])) {
		NSData *data = nil;
		if (val[@"data"]) {
			data = val[@"data"];
		} else if (val[@"filepath"]) {
			data = [NSData dataWithContentsOfFile:val[@"filepath"]];
		}
		NSString *filename = val[@"filename"];
		NSString *mine = val[@"mime_type"];
		[file writeData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[file writeData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename ? filename : @"file.jpg"] dataUsingEncoding:NSUTF8StringEncoding]];
		if (mine) {
			[file writeData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mine] dataUsingEncoding:NSUTF8StringEncoding]];
		}
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[file writeData:data];
		[file writeData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSArray class]]) {
		for (id v in val) {
			[self addValue:v forKey:[key stringByAppendingFormat:@"[%@]", @([val indexOfObject:v])] toFile:file withBoundary:boundary];
		}
	} else {
		assert(0);
	}
}

+ (void) addValue:(id)val forKey:(NSString *)key toBody:(NSMutableData *)body withBoundary:(NSString *)boundary {
	if ([val isKindOfClass:[NSNumber class]]) {
		val = [val stringValue];
	}
	if ([val isKindOfClass:[NSString class]]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", encodeURIComponent(key)] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSData class]]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: file; name=\"%@\"; filename=\"file.jpg\"\r\n", encodeURIComponent(key)] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[body appendData:val];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSDictionary class]] && ([val[@"data"] isKindOfClass:[NSData class]] || [val[@"filepath"] isKindOfClass:[NSString class]])) {
		NSData *data = nil;
		if (val[@"data"]) {
			data = val[@"data"];
		} else if (val[@"filepath"]) {
			data = [NSData dataWithContentsOfFile:val[@"filepath"]];
		}
		NSString *filename = val[@"filename"];
		NSString *mine = val[@"mime_type"];
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, filename ? filename : @"file.jpg"] dataUsingEncoding:NSUTF8StringEncoding]];
		if (mine) {
			[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mine] dataUsingEncoding:NSUTF8StringEncoding]];
		}
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[body appendData:data];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSArray class]]) {
		for (id v in val) {
			@autoreleasepool {
				[self addValue:v forKey:[key stringByAppendingFormat:@"[%@]", @([val indexOfObject:v])] toBody:body withBoundary:boundary];
			}
		}
	} else {
		assert(0);
	}
}

+ (NSData *) multipartBodyData:(NSDictionary *)dic boundary:(NSString *)boundary {
	NSMutableData	*body = [NSMutableData data];
	
	if ([dic count] > 0) {
		NSArray *keys = [[dic allKeys] sortedArrayUsingSelector:@selector(compare:)];
		for (NSString *key in keys) {
			id val = [dic objectForKey:key];
			[self addValue:val forKey:key toBody:body withBoundary:boundary];
		}
	}
	[body appendData:[[NSString stringWithFormat:@"%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return body;
}

+ (BOOL) writeMultipartBodyData:(NSDictionary *)dic boundary:(NSString *)boundary toFile:(NSFileHandle *)file {
	@try {
		if ([dic count] > 0) {
			NSArray *keys = [[dic allKeys] sortedArrayUsingSelector:@selector(compare:)];
			for (NSString *key in keys) {
				id val = [dic objectForKey:key];
				@autoreleasepool {
					[self addValue:val forKey:key toFile:file withBoundary:boundary];
				}
			}
		}
		[file writeData:[[NSString stringWithFormat:@"%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}
	@finally {
	}
}

- (id) request {
	NSString *str;
	if ([[self httpMethod] isEqualToString:@"POST"]) {
		str = [self url];
	} else {
		str = [self urlString:[self url] withParam:[self param]];
	}
	DLog(@"load: %@", str);
	
	if (self.consumer && self.token) {
		OAMutableURLRequest	*req = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:str] consumer:self.consumer token:self.token realm:nil signatureProvider:nil];
		if ([self referer]) {
			[req setValue:[self referer] forHTTPHeaderField:@"Referer"];
		}
		if ([self httpMethod]) {
			[req setHTTPMethod:[self httpMethod]];
		}
		if ([[self httpMethod] isEqualToString:@"POST"]) {
			if ([self multipartBoundary]) {
				NSDictionary *paramDic = [self param];
				NSMutableDictionary *prepareParam = [NSMutableDictionary dictionary];
				for (NSString *key in [paramDic allKeys]) {
					id obj = [paramDic objectForKey:key];
					if (![obj isKindOfClass:[NSData class]]) {
						[prepareParam setObject:obj forKey:key];
					}
				}
				[req setHTTPBody:[[self paramString:prepareParam] dataUsingEncoding:NSUTF8StringEncoding]];
				[req prepare];
				id oauthHeader = [req valueForHTTPHeaderField:@"Authorization"];
				
				NSMutableURLRequest *newReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:str]];
				[newReq setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
				if ([self referer]) {
					[newReq setValue:[self referer] forHTTPHeaderField:@"Referer"];
				}
				if ([self httpMethod]) {
					[newReq setHTTPMethod:[self httpMethod]];
				}
				
				CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
				NSString *uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidRef));
				CFRelease(uuidRef);
				NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:uuid];
				
				[[NSFileManager defaultManager] createFileAtPath:path contents:[NSData data] attributes:nil];
				NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
				[[self class] writeMultipartBodyData:paramDic boundary:[self multipartBoundary] toFile:file];
				[file closeFile];
				self.multipartBodyFilepath = path;
				
				NSInputStream *strm = [[NSInputStream alloc] initWithFileAtPath:path];
				[newReq setHTTPBodyStream:strm];
				[newReq setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [[self multipartBoundary] substringFromIndex:2]] forHTTPHeaderField:@"Content-Type"];
				
				req = (id)newReq;
			} else {
				DLog(@"post: %@", [self paramString:[self param]]);
				[req setHTTPBody:[[self paramString:[self param]] dataUsingEncoding:NSUTF8StringEncoding]];
			}
		}
		return req;
	} else {
		NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:str]];
		if ([self referer]) {
			[req setValue:[self referer] forHTTPHeaderField:@"Referer"];
		}
		if ([self httpMethod]) {
			[req setHTTPMethod:[self httpMethod]];
		}
		if ([[self httpMethod] isEqualToString:@"POST"]) {
			[req setHTTPBody:[[self paramString:[self param]] dataUsingEncoding:NSUTF8StringEncoding]];
		}
		return req;
	}
}

- (BOOL) isLoading {
	return fetcher != nil || connection != nil || asyncLoading;
}

#pragma mark-

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
- (void) finished:(NSDictionary *)dic {
	if (self.multipartBodyFilepath) {
		[[NSFileManager defaultManager] removeItemAtPath:self.multipartBodyFilepath error:nil];
		self.multipartBodyFilepath = nil;
	}
	
	if (bgTaskID != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
		bgTaskID = UIBackgroundTaskInvalid;
	}
	
	Request *me = self;
	NSError *err = [dic objectForKey:@"Error"];
    if (pool && ![pool reachable] && err && [[err domain] isEqualToString:NSURLErrorDomain] && self.retryCount < 4) {
		// リトライ
		self.retryCount++;
		[me cancel];
		[pool retry:me];
	} else {
		[me cancel];
		
		if ([delegate respondsToSelector:me.selector]) {
			[delegate performSelector:me.selector withObject:me withObject:dic];
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:[me notificationName] object:me userInfo:dic];
		[pool remove:me.ID];
	}
}
#pragma clang diagnostic pop

#pragma mark-

/*
 - (void) startInBackground {
 if (self.isLoading) {
 return;
 }
 
 backgroundLoading = YES;
 
 __block UIBackgroundTaskIdentifier bgTask = UIBackgroundTaskInvalid;
 bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
 // Synchronize the cleanup call on the main thread in case
 // the task actually finishes at around the same time.
 dispatch_async(dispatch_get_main_queue(), ^{
 if (bgTask != UIBackgroundTaskInvalid) {
 [[UIApplication sharedApplication] endBackgroundTask:bgTask];
 bgTask = UIBackgroundTaskInvalid;
 }
 });
 }];
 
 [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
 
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
 id req = [self request];
 NSData *data = nil;
 NSURLResponse *res = nil;
 NSError *err = nil;
 if ([req isKindOfClass:[OAMutableURLRequest class]]) {
 [req prepare];
 }
 data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
 
 NSDictionary *dic;
 if (err) {
 dic = [NSDictionary dictionaryWithObjectsAndKeys:err, @"Error", nil];
 } else {
 id ret = [self parse:data];
 if ([ret isKindOfClass:[NSError class]]) {
 dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Error", nil];
 } else {
 dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Result", nil];
 }
 }
 
 dispatch_async(dispatch_get_main_queue(), ^{
 [[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
 [self finished:dic];
 
 if (bgTask != UIBackgroundTaskInvalid) {
 [[UIApplication sharedApplication] endBackgroundTask:bgTask];
 bgTask = UIBackgroundTaskInvalid;
 }
 
 backgroundLoading = NO;
 });
 });
 }
 */

- (void) start {
	if (self.isLoading) {
		return;
	}
	
	id req = [self request];
	if ([req isKindOfClass:[OAMutableURLRequest class]]) {
		fetcher = [[OAAsynchronousDataFetcher alloc] initWithRequest:req delegate:self didFinishSelector:@selector(fetcher:didReceiveData:) didFailSelector:@selector(fetcher:didFailWithError:)];
		[fetcher start];
	} else {
		connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[connection start];
	}
	
	Request *me = self;
	bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			[me cancel];
		});
	}];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
}

- (void) start:(void (^)(NSDictionary *))block {
	id req = [self request];
	if ([req isKindOfClass:[OAMutableURLRequest class]]) {
		[(OAMutableURLRequest *)req prepare];
	}
	NSURLRequest *request = req;
	
	__block Request *me = self;
	bgTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
		dispatch_async(dispatch_get_main_queue(), ^{
			asyncLoading = NO;
			[me cancel];
		});
	}];
	asyncLoading = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:me];
		NSDictionary *dic;
		id ret = [me parse:data];
		if ([ret isKindOfClass:[NSError class]]) {
			dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Error", nil];
		} else {
			dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Result", nil];
		}
		
		[me cancel];
		block(dic);
		
		[[NSNotificationCenter defaultCenter] postNotificationName:[me notificationName] object:me userInfo:dic];
		[pool remove:me.ID];
		
		if (bgTaskID != UIBackgroundTaskInvalid) {
			[[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
			bgTaskID = UIBackgroundTaskInvalid;
		}
		
		asyncLoading = NO;
		me = nil;
	}];
}

#pragma mark-

- (void) cancel {
	if (fetcher) {
		[fetcher cancel];
		fetcher = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	} else if (connection) {
		[connection cancel];
		connection = nil;
		responseData = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	}
	
	if (bgTaskID != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:bgTaskID];
		bgTaskID = UIBackgroundTaskInvalid;
	}
}

#pragma mark-

- (void) fetcher:(OAServiceTicket *)ticket didReceiveData:(NSData *)data {
	DLog(@"%@ loaded: %@", NSStringFromClass([self class]), [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	NSDictionary *dic;
	id ret = [self parse:data];
	if ([ret isKindOfClass:[NSError class]]) {
		dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Error", nil];
	} else {
		dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Result", nil];
	}
	[self finished:dic];
}

- (void) fetcher:(OAServiceTicket *)ticket didFailWithError:(NSError *)error {
	DLog(@"%@ failed: %@", NSStringFromClass([self class]), [error localizedDescription]);
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:error, @"Error", nil];
	[self finished:dic];
}

#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	responseData = [[NSMutableData alloc] init];
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[responseData appendData:data];
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:error, @"Error", nil];
	[self finished:dic];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	NSDictionary *dic;
	id ret = [self parse:responseData];
	if ([ret isKindOfClass:[NSError class]]) {
		dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Error", nil];
	} else {
		dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Result", nil];
	}
	[self finished:dic];
}

#pragma mark-

- (id) load {
	NSDictionary *dic = nil;
	id req = [self request];
	if ([req isKindOfClass:[OAMutableURLRequest class]]) {
		[req prepare];
	}
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		dic = [NSDictionary dictionaryWithObjectsAndKeys:err, @"Error", nil];
	} else {
		id ret = [self parse:data];
		if ([ret isKindOfClass:[NSError class]]) {
			dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Error", nil];
		} else {
			dic = [NSDictionary dictionaryWithObjectsAndKeys:ret, @"Result", nil];
		}
	}
	
	return dic;
}

@end


@implementation JsonRequest

- (id) parse:(NSData *)data {
    id value = data ? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil] : nil;
	return value;
}

@end


#pragma mark-


@implementation LoginRequest

- (id) init {
	self = [super init];
	if (self) {
		self.consumer = [Tumblr sharedInstance].consumer;
	}
	return self;
}

- (void) startWithUsername:(NSString *)uname password:(NSString *)pass {
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.tumblr.com/oauth/access_token"]
																   consumer:consumer
																	  token:nil
																	  realm:nil
														  signatureProvider:nil];
	
    // 新たに付加するパラメータ
    NSMutableArray *xAuthParameters = [NSMutableArray arrayWithCapacity:3];
    [xAuthParameters addObject:[OARequestParameter requestParameterWithName:@"x_auth_mode" value:@"client_auth"]];
    [xAuthParameters addObject:[OARequestParameter requestParameterWithName:@"x_auth_username" value:uname]];
    [xAuthParameters addObject:[OARequestParameter requestParameterWithName:@"x_auth_password" value:pass]];
	
    // 順番が大事！
    [request setHTTPMethod:@"POST"];
    [request setParameters:xAuthParameters];
	
	fetcher = [[OAAsynchronousDataFetcher alloc] initWithRequest:request delegate:self didFinishSelector:@selector(fetcher:didReceiveData:) didFailSelector:@selector(fetcher:didFailWithError:)];
	[fetcher start];
}

- (id) parse:(NSData *)data {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // レスポンスの解析
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (NSString *pair in [dataString componentsSeparatedByString:@"&"]) {
        NSArray *keyValue = [pair componentsSeparatedByString:@"="];
		if (keyValue.count == 2) {
			[dict setObject:[keyValue objectAtIndex:1] forKey:[keyValue objectAtIndex:0]];
		}
    }
    DLog(@"result: %@", dict);
	OAToken	*t = [[OAToken alloc] initWithHTTPResponseBody:dataString];
	if (t.key && t.secret) {
		return t;
	} else {
		id dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
		NSError *err = nil;
		if ([dic isKindOfClass:[NSDictionary class]]) {
			NSDictionary *status = [dic objectForKey:@"meta"];
			err = [NSError errorWithDomain:@"TumblrLogin" code:[[status objectForKey:@"status"] intValue] userInfo:status];
		}
		if (!err) {
			err = [NSError errorWithDomain:@"TumblrLogin" code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:dataString, NSLocalizedDescriptionKey, nil]];
		}
		return err;
	}
}

@end


@implementation TumblrRequest

- (BOOL) needsOAuth {
	return YES;
}

- (id) init {
	self = [super init];
	if (self) {
		self.consumer = [Tumblr sharedInstance].consumer;
		if ([self needsOAuth]) {
			self.token = [TumblrAccountManager sharedInstance].currentAccount.token;
			//assert([AccountManager sharedInstance].currentAccount);
			//assert(self.token);
		}
	}
	return self;
}

- (id) parse:(NSData *)data {
	NSDictionary *dic = [super parse:data];
	id ret;
	if ([dic isKindOfClass:[NSDictionary class]]) {
		NSDictionary *status = [dic objectForKey:@"meta"];
		if ([[status objectForKey:@"status"] intValue] / 100 == 2) {
			ret = [dic objectForKey:@"response"];
		} else {
			ret = [NSError errorWithDomain:@"TumblrRequest" code:1 userInfo:status];
		}
	} else {
		ret = [NSError errorWithDomain:@"TumblrRequest" code:-1 userInfo:nil];
	}
	
	if ([ret isKindOfClass:[NSError class]]) {
		NSString *msg;
		if ([[dic objectForKey:@"response"] isKindOfClass:[NSDictionary class]] && [[[dic objectForKey:@"response"] objectForKey:@"errors"] isKindOfClass:[NSArray class]] && [[[dic objectForKey:@"response"] objectForKey:@"errors"] count] > 0) {
			msg = [[[dic objectForKey:@"response"] objectForKey:@"errors"] objectAtIndex:0];
		} else {
			msg = [[(NSError *)ret userInfo] objectForKey:@"msg"];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Load failed.", nil) message:msg cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
		});
	}
	return ret;
}

@end


@implementation TumblrBlogRequest

@synthesize blogHostName;

@end


@implementation UserInfoRequest

- (NSString *) url {
	return @"http://api.tumblr.com/v2/user/info";
}

@end


@implementation PostLoadRequest

@end


@implementation BlogPostLoadRequest

@synthesize type;

- (BOOL) needsOAuth {
	return NO;
}

- (NSString *) url {
	if (self.type) {
		return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/posts/%@?api_key=%@", blogHostName, self.type, self.consumer.key];
	} else {
		return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/posts?api_key=%@", blogHostName, self.consumer.key];
	}
}

@end


@implementation ReblogRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post/reblog", blogHostName];
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"id"]];
}

@end


@implementation DeleteRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post/delete", blogHostName];
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"id"]];
}

@end


@implementation EditRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post/edit", blogHostName];
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"id"]];
}

@end


@implementation LikeRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return @"http://api.tumblr.com/v2/user/like";
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"id"]];
}

@end


@implementation UnlikeRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return @"http://api.tumblr.com/v2/user/unlike";
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"id"]];
}

@end


@implementation FollowRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return @"http://api.tumblr.com/v2/user/follow";
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"url"]];
}

+ (BOOL) isLoading:(NSString *)url {
	return [[RequestPool sharedObject] isRunning:[NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", url]];
}

@end


@implementation UnfollowRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSString *) url {
	return @"http://api.tumblr.com/v2/user/unfollow";
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", [self.param objectForKey:@"url"]];
}

+ (BOOL) isLoading:(NSString *)url {
	return [[RequestPool sharedObject] isRunning:[NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", url]];
}

@end


@implementation BlogInfoRequest

- (BOOL) needsOAuth {
	return NO;
}

- (NSString *) httpMethod {
	return @"GET";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/info?api_key=%@", blogHostName, self.consumer.key];
}

@end


@implementation FollowerListRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"GET";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/followers", blogHostName];
}

@end


@implementation FollowingListRequest

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"GET";
}

- (NSString *) url {
	return @"http://api.tumblr.com/v2/user/following";
}

@end


static NSString *removeHTML(NSString *str) {
	str = [str stringByReplacingOccurrencesOfRegex:@"<.*?>" withString:@""];
	str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	str = [str stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	str = [str stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	return str;
}

@implementation PostRequest

@synthesize uuid, sendToTwitter, postID;

- (id) init {
	self = [super init];
	if (self) {
		CFUUIDRef uid = CFUUIDCreate(kCFAllocatorDefault);
		self.uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uid));
		CFRelease(uid);
	}
	return self;
}

- (NSString *) ID {
	return [NSStringFromClass([self class]) stringByAppendingFormat:@"_%@", self.uuid];
}

- (BOOL) needsOAuth {
	return YES;
}

- (NSString *) httpMethod {
	return @"POST";
}

- (NSDictionary *) param {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:param];
	
	if (!self.sendToTwitter) {
		[mdic setObject:@"off" forKey:@"tweet"];
	}
	if (postID) {
		[mdic setObject:postID forKey:@"id"];
		return mdic;
	}
	
	return mdic;
}

- (NSString *) url {
	if (postID) {
		return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post/edit", blogHostName];
	} else {
		return [NSString stringWithFormat:@"http://api.tumblr.com/v2/blog/%@/post", blogHostName];
	}
}

- (NSString *) commentString {
	NSString *ret = nil;
	NSString *type = [param objectForKey:@"type"];
	if ([type isEqual:@"text"]) {
		ret = [param objectForKey:@"title"];
		if (ret.length > 0) {
			ret = removeHTML(ret);
		} else {
			ret = removeHTML([param objectForKey:@"body"]);
		}
	} else if ([type isEqual:@"quote"]) {
		ret = removeHTML([param objectForKey:@"quote"]);
	} else if ([type isEqual:@"link"]) {
		NSString *desc = removeHTML([param objectForKey:@"description"]);
		if (desc.length > 0) {
			ret = [NSString stringWithFormat:@"%@ | %@", desc, removeHTML([param objectForKey:@"title"])];
		} else {
			ret = removeHTML([param objectForKey:@"title"]);
		}
	}
	return ret;
}

- (void) finished:(NSDictionary *)dic {
	NSString *ID = [dic valueForKeyPath:@"Result.id"];
	/*
	 if (self.sendToTwitter && ID) {
	 NSMutableString *str = [NSMutableString string];
	 if ([self commentString]) {
	 if ([self commentString].length > 80) {
	 [str appendString:[[self commentString] substringToIndex:80]];
	 [str appendString:@"..."];
	 } else {
	 [str appendString:[self commentString]];
	 }
	 }
	 [str appendFormat:@" http://%@/post/%@ #Tumbletail", self.blogHostName, ID];
	 
	 [[Twitter sharedInstance] sendSync:str followMessage:nil handler:nil];
	 //NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:str, @"Text", nil];
	 //[[PostQueue sharedInstance] pushObject:info toTarget:[Twitter sharedInstance] action:@selector(send:handler:) cancelAction:@selector(sendCancel)];
	 }
	 */
	if (ID) {
		[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Post finished", nil)];
	}
	
	[super finished:dic];
}

@end


@implementation PostDataRequest

- (NSDictionary *) param {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super param];
	
	if (self.dataList) {
		if (self.dataList.count == 1) {
			[mdic setObject:self.dataList[0] forKey:@"data"];
		} else if (self.dataList.count > 1) {
			[mdic setObject:self.dataList forKey:@"data"];
		}
	}
	if (self.caption) {
		[mdic setObject:self.caption forKey:@"caption"];
	}
	if (self.type) {
		[mdic setObject:self.type forKey:@"type"];
	}
	if (self.tags) {
		[mdic setObject:self.tags forKey:@"tags"];
	}
	
	return mdic;
}

- (NSString *) commentString {
	return self.caption;
}

- (NSString *) multipartBoundary {
	return @"------------0xKhTmLbOuNdArY";
}

@end


@implementation PostPhotoRequest

@synthesize link;

- (NSDictionary *) param {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super param];
	
	[mdic setObject:@"photo" forKey:@"type"];
	if (link) {
		[mdic setObject:link forKey:@"link"];
	}
	
	return mdic;
}

@end


@implementation PostLoadRequestDashboardMore

@synthesize lastPostID, periodOfpostID;

- (NSDictionary *) param {
	NSMutableDictionary *mdic = super.param ? [NSMutableDictionary dictionaryWithDictionary:super.param] : [NSMutableDictionary dictionary];
	
	[mdic setObject:@"0" forKey:@"offset"];
	if (![mdic objectForKey:@"limit"]) {
		[mdic setObject:[NSString stringWithFormat:@"%d", 50] forKey:@"limit"];
	}
	[mdic setObject:[NSString stringWithFormat:@"%lld", sinceID] forKey:@"since_id"];
	
	return mdic;
}

- (void) load:(NSMutableArray *)mary error:(NSError **)err {
	NSDictionary *dic = [super load];
	if ([dic objectForKey:@"Error"]) {
		*err = [dic objectForKey:@"Error"];
	} else {
		NSArray *ary = [dic valueForKeyPath:@"Result.posts"];
		if (ary.count > 0) {
			[mary insertObjects:ary atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, ary.count)]];
			/*
			 [mary addObjectsFromArray:ary];
			 [mary sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			 return [[NSNumber numberWithLongLong:[[obj2 objectForKey:@"id"] longLongValue]] compare:[NSNumber numberWithLongLong:[[obj1 objectForKey:@"id"] longLongValue]]];
			 }];
			 */
			
			NSDictionary *d = [mary objectAtIndex:0];
			long long maxID = [[d objectForKey:@"id"] longLongValue];
			d = [mary lastObject];
			long long minID = [[d objectForKey:@"id"] longLongValue];
			DLog(@"\n%lld\n%lld\n%lld", lastPostID, maxID, minID);
			if (maxID < lastPostID) {
				// まだ読む
				sinceID = maxID;
				[self load:mary error:err];
			} else if (minID >= lastPostID) {
				// さかのぼる
				[mary removeAllObjects];
				
				sinceID -= periodOfpostID * 60;
				[self load:mary error:err];
			}
		}
	}
}

- (id) load {
	sinceID = lastPostID - periodOfpostID * 60;
	
	NSMutableArray *mary = [NSMutableArray array];
	NSError *err = nil;
	[self load:mary error:&err];
	return [NSDictionary dictionaryWithObjectsAndKeys:[NSDictionary dictionaryWithObjectsAndKeys:mary, @"posts", nil], @"Result", err, @"Error", nil];
}

@end


