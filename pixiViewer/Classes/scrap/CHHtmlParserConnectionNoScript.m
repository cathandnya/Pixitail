//
//  CHHtmlParserConnectionNoScript.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "CHHtmlParserConnectionNoScript.h"
#import "RegexKitLite.h"
#import "CHHtmlParser.h"


@implementation CHHtmlParserConnectionNoScript

- (void) dealloc {
	self.scripts = nil;
	[super dealloc];
}

- (void) removeScripts:(NSMutableString *)mstr {
	self.scripts = nil;
	self.scripts = [[[NSMutableArray alloc] init] autorelease];
	
	BOOL doLoop = YES;
	while (doLoop) {
		doLoop = NO;
		
		
		NSUInteger start = [mstr rangeOfString:@"<!--" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mstr.length)].location;
		if (start != NSNotFound) {
			NSRange endRange = [mstr rangeOfString:@"-->" options:NSCaseInsensitiveSearch range:NSMakeRange(start, mstr.length - start)];
			if (endRange.location != NSNotFound) {
				[self.scripts addObject:[mstr substringWithRange:NSMakeRange(start, endRange.location + endRange.length - start)]];
				DLog(@"remove: %@", self.scripts.lastObject);
				[mstr replaceCharactersInRange:NSMakeRange(start, endRange.location + endRange.length - start) withString:@""];
				doLoop = YES;
			}
		}
	}
	
	doLoop = YES;
	while (doLoop) {
		doLoop = NO;
		
		
		NSUInteger start = [mstr rangeOfString:@"<script" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mstr.length)].location;
		if (start != NSNotFound) {
			NSRange endRange = [mstr rangeOfString:@"</script>" options:NSCaseInsensitiveSearch range:NSMakeRange(start, mstr.length - start)];
			if (endRange.location != NSNotFound) {
				[self.scripts addObject:[mstr substringWithRange:NSMakeRange(start, endRange.location + endRange.length - start)]];
				DLog(@"remove: %@", self.scripts.lastObject);
				[mstr replaceCharactersInRange:NSMakeRange(start, endRange.location + endRange.length - start) withString:@""];
				doLoop = YES;
			}
		}
		
		/*
		 NSScanner *scan = [NSScanner scannerWithString:mstr];
		 [scan scanUpToString:@"<![CDATA[" intoString:nil];
		 NSUInteger start = [scan scanLocation];
		 if ([scan scanString:@"<![CDATA[" intoString:nil]) {
		 NSUInteger end;
		 
		 [scan scanUpToString:@"]]>" intoString:nil];
		 if ([scan scanString:@"]]>" intoString:nil]) {
		 end = [scan scanLocation];
		 [mstr replaceCharactersInRange:NSMakeRange(start, end - start) withString:@""];
		 doLoop = YES;
		 }
		 }
		 */
	}
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	NSStringEncoding enc = NSUTF8StringEncoding;
	if ([parser isKindOfClass:[CHHtmlParser class]]) {
		enc = [(CHHtmlParser *)parser encoding];
	}
	NSMutableString *mstr = [[[NSMutableString alloc] initWithData:receivedData encoding:enc] autorelease];
	[self removeScripts:mstr];
		
	//[mstr replaceOccurrencesOfRegex:@"<script[\\s>].*<\\/script>" withString:@""];
	[receivedData release];
	receivedData = [[NSMutableData alloc] initWithData:[mstr dataUsingEncoding:enc]];
	//[receivedData writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"noscript.html"] atomically:YES];
	
	//[receivedData writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"data.html"] atomically:YES];
	
	[super connectionDidFinishLoading:con];
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
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		NSMutableString *mstr = [[[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[self removeScripts:mstr];
		data = [[[NSMutableData alloc] initWithData:[mstr dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
		
		[p addData:data];
		[p addDataEnd];
		[pool release];
	}
	return err;
}

@end
