//
//  CHHtmlParserConnection.m
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParserConnection.h"
#import "CHHtmlParser.h"


@implementation CHHtmlParserConnection

@synthesize delegate;
@synthesize referer;
@synthesize method;
@synthesize user, pass;
@synthesize timeout;
@synthesize postBody;
@synthesize noRedirect;

- (id) initWithURL:(NSURL *)val {
	self = [super init];
	if (self) {
		url = [val retain];
		timeout = -1;
	}
	return self;
}

- (void) dealloc {
	delegate = nil;
	
	assert(connection == nil);
	[url release];
	self.referer = nil;
	self.method = nil;
	self.user = nil;
	self.pass = nil;
	self.postBody = nil;
	self.lastUrl = nil;
	[super dealloc];
}

- (void) startWithParser:(CHHtmlParser *)p {
	//DLog(@"startWithParser before: %d, %@", [self retainCount], [url absoluteString]);
	NSMutableURLRequest	*req = [[NSMutableURLRequest alloc] initWithURL:url];
	//DLog(@"startWithParser after: %d", [self retainCount]);
	if (self.referer) {
		[req setValue:self.referer forHTTPHeaderField:@"Referer"];
	}
	if (self.method) {
		[req setHTTPMethod:self.method];
	}
	if (self.postBody) {
		[req setHTTPBody:self.postBody];
	}
	
	[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
	
	NSURLConnection		*con = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[req release];
	
	parser = [p retain];
	connection = con;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	[con start];
	//DLog(@"startWithParser started: %d", [self retainCount]);
	
	if (timeout > 0) {
		timeoutTimer = nil;//[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(timedOut:) userInfo:nil repeats:NO];
	}
}

- (NSError *) startWithParserSync:(CHHtmlParser *)p {
	NSMutableURLRequest	*req = [[NSMutableURLRequest alloc] initWithURL:url];
	//DLog(@"startWithParser after: %d", [self retainCount]);
	if (self.referer) {
		[req setValue:self.referer forHTTPHeaderField:@"Referer"];
	}
	if (self.method) {
		[req setHTTPMethod:self.method];
	}
	if (self.postBody) {
		[req setHTTPBody:self.postBody];
	}
	
	[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	[req release];
	if (!err) {
		[p addData:data];
		[p addDataEnd];
	}
	return err;
}

- (void) cancel {
	delegate = nil;

	if (parser) {
		if ([parser respondsToSelector:@selector(setDelegate:)]) {
			[parser performSelector:@selector(setDelegate:) withObject:nil];
		}
		[parser addDataEnd];
		[parser release];
		parser = nil;	
	}

	if (connection) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		[connection cancel];
		[connection release];
		connection = nil;
	}	
}

- (void) timedOut:(NSTimer *)timer {
	timeoutTimer = nil;
	[self cancel];

	[delegate connection:self finished:-1];
}

#pragma mark-

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSHTTPURLResponse *)redirectResponse {
	DLog(@"redirect: %@", [[request URL] absoluteString]);
	if (noRedirect) {
		if (![[request URL] isEqual:url]) {
			NSMutableURLRequest	*req = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
			//DLog(@"startWithParser after: %d", [self retainCount]);
			if (self.referer) {
				[req setValue:self.referer forHTTPHeaderField:@"Referer"];
			}
			if (self.method) {
				[req setHTTPMethod:self.method];
			}
			if (self.postBody) {
				[req setHTTPBody:self.postBody];
			}
			
			[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
			return req;
		} else {
			return request;
		}		
	} else {
		self.lastUrl = [[request URL] absoluteString];
		return request;
	}
}

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	//DLog(@"didReceiveResponse: %d", [response expectedContentLength]);
	if (![[response URL] isEqual:url]) {
		// 転送された
		
	}
}


- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	//DLog(@"didReceiveData: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    /* Append the new data to the received data. */
	//DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    [parser addData:data];
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[timeoutTimer invalidate];
	timeoutTimer = nil;

	//DLog(@"didFailWithError");
	[parser addDataEnd];

	[connection release];
	connection = nil;
	[parser release];
	parser = nil;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

	[delegate connection:self finished:[error code]];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[timeoutTimer invalidate];
	timeoutTimer = nil;
	
	[parser retain];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[parser addDataEnd];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[connection release];
			connection = nil;
			[parser release];
			[parser release];
			parser = nil;
			
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
			
			[delegate connection:self finished:0];
		});	
	});
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return ([self.user length] > 0 && [self.pass length] > 0);
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:self.user
                                                 password:self.pass
                                              persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

@end


@implementation CHHtmlParserConnectionOnce

- (void) startWithParser:(CHHtmlParser *)p {
	receivedData = [[NSMutableData alloc] init];
	[super startWithParser:p];
}

- (void) cancel {
	[super cancel];
	[receivedData release];
	receivedData = nil;
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[receivedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[parser addData:receivedData];
	[receivedData release];
	receivedData = nil;
	[super connectionDidFinishLoading:con];
}

@end
