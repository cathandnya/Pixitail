//
//  TinamiService.m
//  pixiViewer
//
//  Created by nya on 2014/10/16.
//
//

#import "TinamiService.h"
#import "TinamiAuthParser.h"
#import "TinamiMatrixParser.h"
#import "CHHtmlParserConnection.h"

@implementation TinamiService

- (NSTimeInterval) loginExpiredTimeInterval {
	return 3600;
}

- (NSError *) login {
	NSMutableURLRequest	*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.tinami.com/api/logout?api_key=%@", TINAMI_API_KEY]]];
	[req setHTTPMethod:@"GET"];
	NSURLResponse *res = nil;
	NSError *err = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	
	NSString *body = [NSString stringWithFormat:@"api_key=%@&email=%@&password=%@", TINAMI_API_KEY, encodeURIComponent(self.username), encodeURIComponent(self.password)];
	req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://www.tinami.com/api/auth"]];
	[req setHTTPMethod:@"POST"];
	[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
	data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	}
	TinamiAuthParser *parser = [[TinamiAuthParser alloc] initWithEncoding:NSUTF8StringEncoding];
	[parser addData:data];
    self.authKey = parser.authKey;
	if (self.authKey == nil) {
		return [NSError errorWithDomain:@"TINAMI" code:-1 userInfo:nil];
	}
	
	return nil;
}

- (PixivMatrixParser *) makeParser:(NSString *)key method:(NSString *)method {
	return (PixivMatrixParser *)[[TinamiMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
}

- (CHHtmlParserConnection *) makeConnection:(NSString *)method page:(int)page {
	CHHtmlParserConnection *con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.tinami.com/api/%@&api_key=%@&auth_key=%@&page=%d", method, TINAMI_API_KEY, self.authKey, page]]];
	con.referer = @"http://www.tinami.com/";
	return con;
}

@end
