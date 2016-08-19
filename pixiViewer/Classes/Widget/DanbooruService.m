//
//  DanbooruService.m
//  pixiViewer
//
//  Created by nya on 2014/10/16.
//
//

#import "DanbooruService.h"
#import "CHHtmlParserConnection.h"
#import <CommonCrypto/CommonDigest.h>

#import "CHJsonParser.h"
#import "MatrixParser.h"
#import "Danbooru.h"
#import "RegexKitLite.h"


@interface DanbooruPostsParser : CHJsonParser {
	int maxPage;
}

@property(strong) NSString *urlBase;
@property(weak) id<MatrixParserDelegate> delegate;

@end


@implementation DanbooruPostsParser

@synthesize delegate;

- (void) parse {
	DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
	id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
	
	maxPage = INT_MAX;
	if ([obj isKindOfClass:[NSArray class]]) {
		for (NSDictionary *post in obj) {
			NSString *ext = [[post objectForKey:@"file_url"] pathExtension];
			if ([ext caseInsensitiveCompare:@"jpg"] != NSOrderedSame && [ext caseInsensitiveCompare:@"jpeg"] != NSOrderedSame && [ext caseInsensitiveCompare:@"png"] != NSOrderedSame && [ext caseInsensitiveCompare:@"gif"] != NSOrderedSame) {
				continue;
			}
			
			NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:post];
			
			if ([mdic objectForKey:@"id"]) {
				[mdic setObject:[[mdic objectForKey:@"id"] stringValue] forKey:@"IllustID"];
			}
			if ([mdic objectForKey:@"preview_url"]) {
				[mdic setObject:[mdic objectForKey:@"preview_url"] forKey:@"ThumbnailURLString"];
			}
			if ([mdic objectForKey:@"file_url"]) {
				[mdic setObject:[mdic objectForKey:@"file_url"] forKey:@"BigURLString"];
			}
			if ([mdic objectForKey:@"file_url"]) {
				[mdic setObject:[mdic objectForKey:@"file_url"] forKey:@"ImageURL"];
			}
			if ([mdic objectForKey:@"sample_url"]) {
				[mdic setObject:[mdic objectForKey:@"sample_url"] forKey:@"MediumURLString"];
			} else if ([mdic objectForKey:@"ImageURL"]) {
				[mdic setObject:[mdic objectForKey:@"ImageURL"] forKey:@"MediumURLString"];
			}
			
			if ([[mdic objectForKey:@"MediumURLString"] hasPrefix:@"/"]) {
				// 相対パス
				[mdic setObject:[self.urlBase stringByAppendingString:[mdic objectForKey:@"MediumURLString"]] forKey:@"MediumURLString"];
			}
			if ([[mdic objectForKey:@"BigURLString"] hasPrefix:@"/"]) {
				// 相対パス
				[mdic setObject:[self.urlBase stringByAppendingString:[mdic objectForKey:@"BigURLString"]] forKey:@"BigURLString"];
			}
			if ([[mdic objectForKey:@"ImageURL"] hasPrefix:@"/"]) {
				// 相対パス
				[mdic setObject:[self.urlBase stringByAppendingString:[mdic objectForKey:@"ImageURL"]] forKey:@"ImageURL"];
			}
			if ([[mdic objectForKey:@"ThumbnailURLString"] hasPrefix:@"/"]) {
				// 相対パス
				[mdic setObject:[self.urlBase stringByAppendingString:[mdic objectForKey:@"ThumbnailURLString"]] forKey:@"ThumbnailURLString"];
			} else if (![[mdic objectForKey:@"ThumbnailURLString"] hasPrefix:@"http"]) {
				// 無効なURL
				[mdic setObject:[NSString stringWithFormat:@"http://sonohara.donmai.us/data/preview/%@.jpg", [mdic objectForKey:@"md5"]] forKey:@"ThumbnailURLString"];
			}
			
			NSMutableArray *tags = [NSMutableArray array];
			for (NSString *tag in [[mdic objectForKey:@"tags"] componentsSeparatedByString:@" "]) {
				[tags addObject:[NSDictionary dictionaryWithObjectsAndKeys:tag, @"Name", nil]];
			}
			[mdic setObject:tags forKey:@"Tags"];
			
			// "source":"http://img40.pixiv.net/img/naoel/12334635_big_p1.jpg",
			NSString *link = [mdic objectForKey:@"source"];
			if ([link isMatchedByRegex:@"^http://(.*)\\.pixiv\\.net/"]) {
				NSScanner *scanner = [NSScanner scannerWithString:link];
				NSString *tmp = nil;
				BOOL b;
				
				if ([link isMatchedByRegex:@"illust_id="]) {
					[scanner scanUpToString:@"illust_id=" intoString:nil];
					[scanner scanString:@"illust_id=" intoString:nil];
					b = [scanner scanUpToString:@"&" intoString:&tmp];
					if (b && tmp) {
						// pixiv link
						[mdic setObject:@"Pixiv" forKey:@"PhotoType"];
						[mdic setObject:tmp forKey:@"PhotoLinkIllustID"];
					}
				} else {
					NSString *filename = [[link lastPathComponent] stringByDeletingPathExtension];
					scanner = [NSScanner scannerWithString:filename];
					b = [scanner scanUpToString:@"_" intoString:&tmp];
					if (tmp) {
						// pixiv link
						[mdic setObject:@"Pixiv" forKey:@"PhotoType"];
						[mdic setObject:tmp forKey:@"PhotoLinkIllustID"];
					}
				}
			} else if ([link hasPrefix:@"http://www.pixa.cc/illustrations/show/"]) {
				// pixa link
				[mdic setObject:@"Pixa" forKey:@"PhotoType"];
				[mdic setObject:[link lastPathComponent] forKey:@"PhotoLinkIllustID"];
			} else if ([link hasPrefix:@"http://www.tinami.com/view/"]) {
				// tinami link
				[mdic setObject:@"Tinami" forKey:@"PhotoType"];
				[mdic setObject:[link lastPathComponent] forKey:@"PhotoLinkIllustID"];
			} else {
				//[info setObject:@"Tumblr" forKey:@"PhotoType"];
			}
			[mdic setObject:link forKey:@"PhotoLink"];
						
			[self.delegate matrixParser:self foundPicture:mdic];
		}
		[self.delegate matrixParser:self finished:0];
		
		if ([obj count] < 20) {
			maxPage = 0;
		}
	} else {
		[self.delegate matrixParser:self finished:-1];
	}
}

- (int) maxPage {
	return maxPage;
}

@end


@implementation DanbooruService

+ (NSString *)sha1:(NSString *)inputString {
	const char *str = [inputString UTF8String];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1(str, (int)strlen(str), result);
	return [NSString
			stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15],
			result[16], result[17], result[18], result[19]];
}

+ (NSString *) hashedPassword:(NSString *)pass {
	NSString *str = [NSString stringWithFormat:@"choujin-steiner--%@--", pass];
	return [[self class] sha1:str];
}

- (NSTimeInterval) loginExpiredTimeInterval {
	return DBL_MAX;
}

- (NSError *) login {
	return nil;
}

- (PixivMatrixParser *) makeParser:(NSString *)key method:(NSString *)method {
	DanbooruPostsParser	*parser = [[DanbooruPostsParser alloc] init];
	parser.urlBase = [NSString stringWithFormat:@"%@://%@", [[NSURL URLWithString:method] scheme], [[NSURL URLWithString:method] host]];
	return (PixivMatrixParser *)parser;
}

- (CHHtmlParserConnection *) makeConnection:(NSString *)method page:(int)page {
	return [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@&login=%@&password_hash=%@&page=%d", method, encodeURIComponent(self.username), [[self class] hashedPassword:self.password], page - 1]]];
}

@end
