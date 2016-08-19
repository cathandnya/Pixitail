//
//  SeigaService.m
//  pixiViewer
//
//  Created by nya on 2014/10/16.
//
//

#import "SeigaService.h"
#import "SeigaConstants.h"
#import "SeigaMatrixParser.h"
#import "CHHtmlParserConnection.h"

@implementation SeigaService

- (NSTimeInterval) loginExpiredTimeInterval {
	if ([[SeigaConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"]) {
		return [[[SeigaConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"] doubleValue];
	} else {
		return DBL_MAX;
	}
}

- (NSError *) login {
	NSError *err = nil;
	NSURLResponse *res = nil;
	NSData *data = nil;
	NSMutableURLRequest *req;
	NSURL *url;
	NSString *body;
	NSString *str;
	
	// constants
	[[SeigaConstants sharedInstance] reloadSync];
	
	// logout
	url = [NSURL URLWithString:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.logout"]];
	req = [NSMutableURLRequest requestWithURL:url];
	data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	
	if (!err) {
		// login
		url = [NSURL URLWithString:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.login"]];
		req = [NSMutableURLRequest requestWithURL:url];
		
		body = [NSString stringWithFormat:@"mail=%@&password=%@&next_url=%@", encodeURIComponent(self.username), encodeURIComponent(self.password), encodeURIComponent(@"/")];
		[req setHTTPMethod:@"POST"];
		[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
		
		data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
		if (!err) {
			str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			if ([str rangeOfString:[[SeigaConstants sharedInstance] valueForKeyPath:@"constants.login_failed_str"]].location != NSNotFound) {
				err = [NSError errorWithDomain:@"" code:1 userInfo:nil];
			}
			if (!err) {
				// 春画用
				url = [NSURL URLWithString:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.shunga_submit"]];
				req = [NSMutableURLRequest requestWithURL:url];
				[req setHTTPMethod:@"POST"];
				[req setHTTPBody:[[[SeigaConstants sharedInstance] valueForKeyPath:@"constants.shunga_submit_param"] dataUsingEncoding:NSASCIIStringEncoding]];
				data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
				err = nil;		// 無視
				//DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
			}
		}
	}
	
	return err;
}

- (PixivMatrixParser *) makeParser:(NSString *)key method:(NSString *)method {
	SeigaMatrixParser *parser = [[SeigaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding];
	if (key) {
		NSDictionary *d = [[SeigaConstants sharedInstance] valueForKeyPath:key];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	return (PixivMatrixParser *)parser;
}

- (CHHtmlParserConnection *) makeConnection:(NSString *)method page:(int)page {
	NSString *str;
	page -= 1;
	if (page == 0) {
		str = [NSString stringWithFormat:@"%@%@", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], method];
	} else {
		if ([method rangeOfString:@"?"].location == NSNotFound) {
			str = [NSString stringWithFormat:@"%@%@?%@=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], method, [[SeigaConstants sharedInstance] valueForKeyPath:@"constants.page_param"], page + 1];
		} else {
			str = [NSString stringWithFormat:@"%@%@&%@=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], method, [[SeigaConstants sharedInstance] valueForKeyPath:@"constants.page_param"], page + 1];
		}
	}
	CHHtmlParserConnection *con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:str]];
	con.referer = [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
	return con;
}

@end
