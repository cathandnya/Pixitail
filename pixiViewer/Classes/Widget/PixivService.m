//
//  PixivService.m
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import "PixivService.h"
#import "PixitailConstants.h"
#import "RegexKitLite.h"
#import "PixivMatrixParser.h"
#import "CHHtmlParserConnectionNoScript.h"

@implementation PixivService

- (NSTimeInterval) loginExpiredTimeInterval {
	if ([[PixitailConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"]) {
		return [[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.expired_seconds"] doubleValue];
	} else {
		return DBL_MAX;
	}
}

- (NSError *) login {
	[[PixitailConstants sharedInstance] reloadSync];
	
	NSString *url = [[PixitailConstants sharedInstance] valueForKeyPath:@"urls.login"];
	NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
	NSString				*body;
	
	body = [NSString stringWithFormat:@"mode=login&pixiv_id=%@&pass=%@&skip=1", encodeURIComponent(self.username), encodeURIComponent(self.password)];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else {
		NSString *retstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		
		NSRange	range = {-1, 0};
		if (retstr) range = [retstr rangeOfString:@"action=\"/login.php\""];
		if (range.location != NSNotFound && range.length > 0) {
			// ログイン失敗
			return [NSError errorWithDomain:@"PixivService" code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Load failed.", NSLocalizedDescriptionKey, nil]];
		} else {
			NSString *regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.tt_regex"];
			NSArray *ary = [retstr captureComponentsMatchedByRegex:regex];
			if (ary.count > 1) {
				self.authToken = [ary objectAtIndex:1];
				self.loginDate = [NSDate date];
				return nil;
			} else {
				return [NSError errorWithDomain:@"PixivService" code:-1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Load failed.", NSLocalizedDescriptionKey, nil]];
			}
		}
	}
}

- (PixivMatrixParser *) makeParser:(NSString *)key method:(NSString *)method {
	PixivMatrixParser *parser = [[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	if (key) {
		NSDictionary *d = [[PixitailConstants sharedInstance] valueForKeyPath:key];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	return parser;
}

- (CHHtmlParserConnection *) makeConnection:(NSString *)method page:(int)page {
	CHHtmlParserConnectionNoScript *con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@p=%d", method, page]]];
	con.referer = @"http://www.pixiv.net/mypage.php";
	return con;
}

@end
