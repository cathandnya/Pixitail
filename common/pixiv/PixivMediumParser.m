//
//  PixivMediumParser.m
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMediumParser.h"
#import "PixivMediumCommentParser.h"
#import "ScrapingMetadata.h"
#import "PixitailConstants.h"
#import "JSON.h"
#import "RegexKitLite.h"

/*
typedef enum {
	PixivMediumParserState_Initial =			0x00000001,
	PixivMediumParserState_InProfile =			0x00000002,
	PixivMediumParserState_InProfileA =			0x00000004,
	PixivMediumParserState_InContent2 =			0x00000008,
	PixivMediumParserState_InDate =				0x00000010,
	PixivMediumParserState_InDateDiv =			0x00000020,
	PixivMediumParserState_InTitle =			0x00000040,
	PixivMediumParserState_InComment =			0x00000080,
	PixivMediumParserState_InBigA =				0x00000100,
	PixivMediumParserState_InMangaA =			0x00000200,

	PixivMediumParserState_InRPCIllustID =		0x00000400,
	PixivMediumParserState_InRPCUserID =		0x00000800,
	PixivMediumParserState_InRPCEID =			0x00001000,
	PixivMediumParserState_InRPCSessionID =		0x00002000,

	PixivMediumParserState_InTagSpan =			0x00004000,
	PixivMediumParserState_InTagSpanA =			0x00008000,
	
	PixivMediumParserState_InOneCommentDiv =		0x00010000,
	PixivMediumParserState_InOneCommentDivP =		0x00020000,
	PixivMediumParserState_InOneCommentDivPName =	0x00040000,
	PixivMediumParserState_InOneCommentDivPTime =	0x00080000,
	PixivMediumParserState_InOneCommentDivPText =	0x00100000,

	PixivMediumParserState_InRating =			0x00200000,

	PixivMediumParserState_InRPCQR =			0x00400000,

	PixivMediumParserState_InCommentForm =		0x00800000,
	PixivMediumParserState_InWorksData =		0x01000000,
	PixivMediumParserState_InWorksArea =		0x02000000,
	
	PixivMediumParserState_InWorksP =			0x04000000,
} PixivMediumParserState;


static int ratingValue(NSString *str, NSString *key) {
	NSString	*name = NSLocalizedString(key, nil);
	NSScanner	*scanner = [NSScanner scannerWithString:str];
	NSString	*tmp = nil;
	
	[scanner scanUpToString:name intoString:nil];
	[scanner scanString:name intoString:nil];
	[scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&tmp];
	return [tmp intValue];
}

static int myRatingValue(NSString *str) {
	NSString	*name = NSLocalizedString(@"MyRate", nil);
	NSString	*stop = NSLocalizedString(@"Ten", nil);
	NSScanner	*scanner = [NSScanner scannerWithString:str];
	NSString	*tmp = nil;
	BOOL b;
	
	b = [scanner scanUpToString:name intoString:nil];
	if (!b) return -1;
	b = [scanner scanString:name intoString:nil];
	if (!b) return -1;
	b = [scanner scanUpToString:stop intoString:&tmp];
	if (!b) return -1;
	return [tmp intValue];
}
*/


@implementation PixivMediumParser

@synthesize info, noComments;

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"medium.scrap"]] autorelease];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"medium.scrap"]] autorelease];
	}
	return self;
}

#pragma mark-

- (void) startDocument {
	[super startDocument];
}

- (void) dealloc {
	self.info = nil;
	[super dealloc];
}

- (void) endDocument {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super evalResult:[[PixitailConstants sharedInstance] valueForKeyPath:@"medium.eval"]];
	self.info = mdic;
	
	id	num = [info objectForKey:@"MangaPageCount"];
	NSString *urlBase = [info objectForKey:@"MediumURLString"];
	if (num && urlBase) {
		NSArray *srcList = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.manga_replacement_src"];
		NSArray *dstList = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.manga_replacement_dst"];
		if (srcList.count == dstList.count) {
			for (NSInteger i = 0; i < srcList.count; i++) {
				NSString *src = srcList[i];
				NSString *dst = dstList[i];
				urlBase = [urlBase stringByReplacingOccurrencesOfString:src withString:dst];
			}
			
			int count = [num intValue];
			NSMutableArray *ary = [NSMutableArray array];
			for (NSInteger i = 0; i < count; i++) {
				NSString *url = [NSString stringWithFormat:urlBase, @(i)];
				DLog(@"%@", url);
				[ary addObject:@{@"URLString": url}];
			}
			
			[mdic setObject:ary forKey:@"Images"];
		}
	}
	
	
	if (!noComments && [info objectForKey:@"IllustID"] && [info objectForKey:@"UserID"]) {
		NSMutableURLRequest		*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[[PixitailConstants sharedInstance] valueForKeyPath:@"urls.comment_history"]]];
		NSString				*body;
		[req autorelease];
		
		body = [NSString stringWithFormat:@"i_id=%@&u_id=%@", [info objectForKey:@"IllustID"], [info objectForKey:@"UserID"]];
		
		[req setHTTPMethod:@"POST"];
		[req setHTTPBody:[body dataUsingEncoding:NSASCIIStringEncoding]];
		[req setValue:[NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", [info objectForKey:@"IllustID"]] forHTTPHeaderField:@"Referer"];
		//[req setHTTPShouldHandleCookies:NO];
		[req setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_3; ja-jp) AppleWebKit/533.16 (KHTML, like Gecko) Version/5.0 Safari/533.16" forHTTPHeaderField:@"User-Agent"];
		
		NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
		DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
		NSDictionary *dic = [[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease] JSONValue];
		NSString *keypath = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.comments_body_path"];
		NSString *html = keypath ? [dic valueForKeyPath:keypath] : nil;
		NSString *divider = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.comments_divide_str"];
		NSArray *ary = divider ? [html componentsSeparatedByString:divider] : nil;
		
		/*
		<li class="comment-item prof-image" data-comment-id="31919285">
		<a href="member.php?id=5934883"><span class="comment-prof-image" style="background-image:url('http://i1.pixiv.net/img119/profile/handsonic-angelbeats/6859404_s.jpg');"></span></a><a href="member.php?id=5934883">ノア(LETIZIA)</a>&nbsp;<span class="comment-date">2/5/2014 13:55</span><br />お疲れ様です!!!　全員可愛くて選べませんな!!!
		</li>
		 */
		NSMutableArray *comments = [NSMutableArray array];
		for (NSString *s in ary) {
			s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@""];
			s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@""];
			s = [s stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			
			NSArray *a;
			NSMutableDictionary *d = [NSMutableDictionary dictionary];
			NSString *regex;
			
			regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.comments_username_regex"];
			if (regex) {
				a = [s captureComponentsMatchedByRegex:regex];
				if (a.count == 2) {
					[d setObject:[a lastObject] forKey:@"UserName"];
				}
			}
			regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.comments_date_regex"];
			if (regex) {
				a = [s captureComponentsMatchedByRegex:regex];
				if (a.count == 2) {
					[d setObject:[a lastObject] forKey:@"DateString"];
				}
			}
			regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.comments_comment_regex"];
			if (regex) {
				a = [s captureComponentsMatchedByRegex:regex];
				if (a.count == 2) {
					NSString *str = [a lastObject];
					str = [str stringByReplacingOccurrencesOfString:@"<br[\\s/]*?>" withString:@"\n"];
					str = [str stringByReplacingOccurrencesOfRegex:@"<.*?>" withString:@""];
					str = [str stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
					str = [str stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
					str = [str stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
					str = [str stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
					str = [str stringByReplacingOccurrencesOfString:@"&apos;" withString:@"\'"];
					[d setObject:str forKey:@"Comment"];
				}
			}
			
			if (d[@"Comment"]) {
				[comments addObject:d];
				
			}
		}
		[info setObject:comments forKey:@"OneComments"];
		
		/*
		PixivMediumCommentParser *cparser = [[PixivMediumCommentParser alloc] initWithEncoding:NSUTF8StringEncoding];
		[cparser addData:data];
		[cparser addDataEnd];
		
		if (cparser.comments) {
			[info setObject:cparser.comments forKey:@"OneComments"];
		}
		[cparser release];
		 */
	}
}

#if 0
- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqualToString:@"div"]) {
		if ((state_ & PixivMediumParserState_InContent2) && [[attributes objectForKey:@"class"] isEqualToString:@"profile_area"]) {
			// profile
			state_ |= PixivMediumParserState_InProfile;
			//divCount_ = 1;
		} else if ((state_ == PixivMediumParserState_Initial) && [[attributes objectForKey:@"id"] isEqualToString:@"rpc_i_id"]) {
			// rpc iid
			stringBuf_ = [[NSMutableString alloc] init];
			state_ |= PixivMediumParserState_InRPCIllustID;
		} else if ((state_ == PixivMediumParserState_Initial) && [[attributes objectForKey:@"id"] isEqualToString:@"rpc_u_id"]) {
			// rpc user id
			stringBuf_ = [[NSMutableString alloc] init];
			state_ |= PixivMediumParserState_InRPCUserID;
		} else if ((state_ == PixivMediumParserState_Initial) && [[attributes objectForKey:@"id"] isEqualToString:@"rpc_e_id"]) {
			// rpc eid
			stringBuf_ = [[NSMutableString alloc] init];
			state_ |= PixivMediumParserState_InRPCEID;
		} else if ((state_ == PixivMediumParserState_Initial) && [[attributes objectForKey:@"id"] isEqualToString:@"rpc_s_id"]) {
			// rpc session id
			stringBuf_ = [[NSMutableString alloc] init];
			state_ |= PixivMediumParserState_InRPCSessionID;
		} else if ((state_ == PixivMediumParserState_Initial) && [[attributes objectForKey:@"id"] isEqualToString:@"rpc_qr"]) {
			// rpc qr
			stringBuf_ = [[NSMutableString alloc] init];
			state_ |= PixivMediumParserState_InRPCQR;
		} else if ((state_ & PixivMediumParserState_InProfile)) {
			divCount_++;
		} else if ((state_ == PixivMediumParserState_Initial) && [[attributes objectForKey:@"id"] hasPrefix:@"content"]) {
			// content2
			state_ |= PixivMediumParserState_InContent2;
			divCount_ = 1;
		} else if ([[attributes objectForKey:@"id"] hasPrefix:@"one_comment_area"]) {
			// 一言コメント
			state_ |= PixivMediumParserState_InOneCommentDiv;
			divCount_ = 1;

			[info setObject:[NSMutableArray array] forKey:@"OneComments"];
		} else if (state_ & PixivMediumParserState_InContent2) {
			divCount_++;
			if ([[attributes objectForKey:@"class"] isEqualToString:@"works_data"]) {
				// works data
				state_ |= PixivMediumParserState_InWorksData;
			} else if ([[attributes objectForKey:@"id"] isEqualToString:@"rating"]) {
				// rating
				state_ |= PixivMediumParserState_InRating;
				ratingEnable_ = NO;
				ratingDivCount = 1;
				stringBuf_ = [[NSMutableString alloc] init];
			} else if (state_ & PixivMediumParserState_InRating) {
				ratingDivCount++;
			}
		}
	} else if ([name isEqualToString:@"h3"] && (state_ & PixivMediumParserState_InWorksData)) {
		// title
		state_ |= PixivMediumParserState_InTitle;
		stringBuf_ = [[NSMutableString alloc] init];
	} else if ([name isEqualToString:@"p"] && (state_ & PixivMediumParserState_InWorksData)) {
		// works p
		state_ |= PixivMediumParserState_InWorksP;
		stringBuf_ = [[NSMutableString alloc] init];
	} else if ([name isEqualToString:@"a"]) {
		if (state_ & PixivMediumParserState_InProfile) {
			if ([[attributes objectForKey:@"href"] rangeOfString:@"member.php?"].location >= 0) {
				NSArray	*ary = [[attributes objectForKey:@"href"] componentsSeparatedByString:@"?"];
				if ([ary count] >= 2) {
					NSDictionary	*dic = CHHtmlParserParseParam([ary objectAtIndex:1]);
					if ([dic objectForKey:@"id"]) {
						// user ID
						//[info setObject:[dic objectForKey:@"id"] forKey:@"UserID"];
						
						state_ |= PixivMediumParserState_InProfileA;
					}
				}
			}
		} else if (state_ & PixivMediumParserState_InTagSpan) {
			// tag span a
			NSMutableArray		*tags = [info objectForKey:@"Tags"];
			if (tags) {
				NSMutableDictionary	*newTag = [NSMutableDictionary dictionary];
				if ([attributes objectForKey:@"href"]) {
					[newTag setObject:[attributes objectForKey:@"href"] forKey:@"Link"];
				}
				[tags addObject:newTag];
			}
			stringBuf_ = [[NSMutableString alloc] init];
			state_ |= PixivMediumParserState_InTagSpanA;
		} else if ([[attributes objectForKey:@"href"] hasPrefix:@"member_illust.php?mode=big"]) {
			// big
			state_ |= PixivMediumParserState_InBigA;
		} else if ([[attributes objectForKey:@"href"] hasPrefix:@"member_illust.php?mode=manga"]) {
			// manga
			state_ |= PixivMediumParserState_InMangaA;
		} else if (state_ & PixivMediumParserState_InRating) {
			// rating
			ratingEnable_ = YES;
		} else if ((state_ & PixivMediumParserState_InOneCommentDivP) && [[attributes objectForKey:@"href"] rangeOfString:@"member.php"].location >= 0) {
			state_ |= PixivMediumParserState_InOneCommentDivPName;
			stringBuf_ = [[NSMutableString alloc] init];
		}
	} else if ([name isEqualToString:@"img"]) {
		if (state_ & PixivMediumParserState_InProfileA) {
			if ([attributes objectForKey:@"alt"]) {
				// user name
				[info setObject:[attributes objectForKey:@"alt"] forKey:@"UserName"];
			}
			if ([attributes objectForKey:@"src"]) {
				NSRange	range = [[attributes objectForKey:@"src"] rangeOfString:@"/profile/"];
				if (range.location >= 0 && range.length > 0) {
					[info setObject:[attributes objectForKey:@"src"] forKey:@"UserPictureURLString"];
				}
			}
		} else if (state_ & PixivMediumParserState_InBigA) {
			[info setObject:[attributes objectForKey:@"src"] forKey:@"MediumURLString"];
			[info setObject:@"big" forKey:@"IllustMode"];
		} else if (state_ & PixivMediumParserState_InMangaA) {
			[info setObject:[attributes objectForKey:@"src"] forKey:@"MediumURLString"];
			[info setObject:@"manga" forKey:@"IllustMode"];
		}
	} else if ([name isEqualToString:@"span"]) {
		if ([[attributes objectForKey:@"id"] isEqualToString:@"tags"]) {
			// tags
			[info setObject:[NSMutableArray array] forKey:@"Tags"];
			state_ |= PixivMediumParserState_InTagSpan;
			tagsSpanCount_ = 1;
		} else if (state_ & PixivMediumParserState_InTagSpan) {
			tagsSpanCount_++;
			if (tagsSpanCount_ == 2) {
				NSMutableArray		*tags = [info objectForKey:@"Tags"];
				if (tags && [tags count] > 0) {
					NSMutableDictionary	*tag = [tags lastObject];
					[tag setObject:[NSNumber numberWithBool:YES] forKey:@"Asterisk"];
				}
			}
		} else if ((state_ & PixivMediumParserState_InOneCommentDivP) && [[attributes objectForKey:@"class"] isEqualToString:@"worksCommentDate"]) {
			state_ |= PixivMediumParserState_InOneCommentDivPTime;
			stringBuf_ = [[NSMutableString alloc] init];
		}
	} else if ((state_ & PixivMediumParserState_InCommentForm) && [name isEqualToString:@"input"]) {
		NSMutableDictionary *forminfo = [info objectForKey:@"FormInfo"];
		if ([attributes objectForKey:@"value"] && [attributes objectForKey:@"name"]) {
			[forminfo setObject:[attributes objectForKey:@"value"] forKey:[attributes objectForKey:@"name"]];
		}
	} else if ([name isEqualToString:@"form"] && [[attributes objectForKey:@"action"] isEqualToString:@"member_illust.php"] && [[attributes objectForKey:@"method"] isEqualToString:@"post"]) {
		state_ |= PixivMediumParserState_InCommentForm;
		NSMutableDictionary *forminfo = [NSMutableDictionary dictionary];
		[info setObject:forminfo forKey:@"FormInfo"];
	} else if ([info objectForKey:@"Title"] != nil && [info objectForKey:@"Comment"] == nil && [name isEqualToString:@"p"]) {
		// comment
		state_ |= PixivMediumParserState_InComment;
		stringBuf_ = [[NSMutableString alloc] init];
	} else if ((state_ & PixivMediumParserState_InOneCommentDiv) && [name isEqualToString:@"p"] && [[attributes objectForKey:@"class"] isEqualToString:@"worksComment"]) {
		state_ |= PixivMediumParserState_InOneCommentDivP;

		NSMutableArray	*ary = [info objectForKey:@"OneComments"];
		if (ary) {
			[ary addObject:[NSMutableDictionary dictionary]];
		}
	} else if ((state_ & PixivMediumParserState_InOneCommentDivP) && [name isEqualToString:@"br"]) {		
		NSMutableArray	*ary = [info objectForKey:@"OneComments"];
		if (ary && [ary count] > 0) {
			NSMutableDictionary	*oneComment = [ary lastObject];
			if ([oneComment objectForKey:@"UserName"] != nil && [oneComment objectForKey:@"DateString"] != nil && [oneComment objectForKey:@"Comment"] == nil) {
				state_ |= PixivMediumParserState_InOneCommentDivPText;
				stringBuf_ = [[NSMutableString alloc] init];
			}
		}		
	}
}

- (void) endElementName:(NSString *)name {
	if ([name isEqualToString:@"div"]) {
		if (state_ & PixivMediumParserState_InProfile) {
			divCount_--;
			if (divCount_ == 0) {
				// profile終了
				state_ &= ~PixivMediumParserState_InProfile;
			}
		} else if (state_ & PixivMediumParserState_InContent2) {
			divCount_--;
			if (state_ & PixivMediumParserState_InWorksData) {
				state_ &= ~PixivMediumParserState_InWorksData;
			} else if (state_ & PixivMediumParserState_InRating) {
				ratingDivCount--;
				if (ratingDivCount == 0 && stringBuf_) {
					int	val;
					NSString *key;
				
					key = @"RatingViewCount";
					val = ratingValue(stringBuf_, key);
					[info setObject:[NSNumber numberWithInt:val] forKey:key];
					key = @"RatingCount";
					val = ratingValue(stringBuf_, key);
					[info setObject:[NSNumber numberWithInt:val] forKey:key];
					key = @"RatingScore";
					val = ratingValue(stringBuf_, key);
					[info setObject:[NSNumber numberWithInt:val] forKey:key];

					val = myRatingValue(stringBuf_);
					if (val > 0) {
						[info setObject:[NSNumber numberWithInt:val] forKey:@"MyRate"];
					}
					[info setObject:[NSNumber numberWithBool:ratingEnable_] forKey:@"RatingEnable"];
					
					[stringBuf_ release];
					stringBuf_ = nil;

					state_ &= ~PixivMediumParserState_InRating;
				}
			}
			
			if (divCount_ == 0) {
				// content2終了
				state_ &= ~PixivMediumParserState_Initial;
			}
		} else if (state_ & PixivMediumParserState_InRPCIllustID) {
			if (stringBuf_) {
				[info setObject:stringBuf_ forKey:@"IllustID"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InRPCIllustID;
		} else if (state_ & PixivMediumParserState_InRPCUserID) {
			if (stringBuf_) {
				[info setObject:stringBuf_ forKey:@"UserID"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InRPCUserID;
		} else if (state_ & PixivMediumParserState_InRPCEID) {
			if (stringBuf_) {
				[info setObject:stringBuf_ forKey:@"EID"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InRPCEID;
		} else if (state_ & PixivMediumParserState_InRPCSessionID) {
			if (stringBuf_) {
				[info setObject:stringBuf_ forKey:@"SessionID"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InRPCSessionID;
		} else if (state_ & PixivMediumParserState_InRPCQR) {
			if (stringBuf_) {
				[info setObject:stringBuf_ forKey:@"QR"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InRPCQR;
		} else if (state_ & PixivMediumParserState_InOneCommentDiv) {
			divCount_--;
			if (divCount_ == 0) {
				state_ &= ~PixivMediumParserState_InOneCommentDiv;
			}
		}
	} else if ([name isEqualToString:@"a"]) {
		if (state_ & PixivMediumParserState_InProfileA) {
			state_ &= ~PixivMediumParserState_InProfileA;
		} else if (state_ & PixivMediumParserState_InBigA) {
			state_ &= ~PixivMediumParserState_InBigA;
		} else if (state_ & PixivMediumParserState_InMangaA) {
			state_ &= ~PixivMediumParserState_InMangaA;
		} else if (state_ & PixivMediumParserState_InTagSpanA) {
			NSMutableArray		*tags = [info objectForKey:@"Tags"];
			if (tags && [tags count] > 0) {
				if ([stringBuf_ length] > 0) {
					NSMutableDictionary	*tag = [tags lastObject];
					[tag setObject:stringBuf_ forKey:@"Name"];
				} else {
					[tags removeLastObject];
				}
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InTagSpanA;
		} else if (state_ & PixivMediumParserState_InOneCommentDivPName) {
			NSMutableArray	*ary = [info objectForKey:@"OneComments"];
			if (ary && [ary count] > 0) {
				NSMutableDictionary	*oneComment = [ary lastObject];
				[oneComment setObject:stringBuf_ forKey:@"UserName"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InOneCommentDivPName;
		}
	} else if ([name isEqualToString:@"span"]) {
		if (state_ & PixivMediumParserState_InTagSpan) {
			tagsSpanCount_--;
			if (tagsSpanCount_ == 0) {
				state_ &= ~PixivMediumParserState_InTagSpan;
			}
		} else if (state_ & PixivMediumParserState_InOneCommentDivPTime) {
			NSMutableArray	*ary = [info objectForKey:@"OneComments"];
			if (ary && [ary count] > 0) {
				NSMutableDictionary	*oneComment = [ary lastObject];
				[oneComment setObject:stringBuf_ forKey:@"DateString"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InOneCommentDivPTime;
		}
	} else if ((state_ & PixivMediumParserState_InCommentForm) && [name isEqualToString:@"form"]) {
		state_ &= ~PixivMediumParserState_InCommentForm;
	} else if ((state_ & PixivMediumParserState_InTitle) && [name isEqualToString:@"h3"]) {
		if (stringBuf_) {
			[info setObject:stringBuf_ forKey:@"Title"];
			[stringBuf_ release];
			stringBuf_ = nil;
					
			// title終了
			state_ &= ~PixivMediumParserState_InTitle;
		}	
	} else if ((state_ & PixivMediumParserState_InComment) && [name isEqualToString:@"p"]) {
		if (stringBuf_) {
			[info setObject:stringBuf_ forKey:@"Comment"];
			[stringBuf_ release];
			stringBuf_ = nil;
					
			// comment終了
			state_ &= ~PixivMediumParserState_InComment;
		}
	} else if ((state_ & PixivMediumParserState_InOneCommentDivP) && [name isEqualToString:@"p"]) {
		if (state_ & PixivMediumParserState_InOneCommentDivPText) {
			NSMutableArray	*ary = [info objectForKey:@"OneComments"];
			if (ary && [ary count] > 0) {
				NSMutableDictionary	*oneComment = [ary lastObject];
				[oneComment setObject:stringBuf_ forKey:@"Comment"];
			}
			[stringBuf_ release];
			stringBuf_ = nil;
			state_ &= ~PixivMediumParserState_InOneCommentDivPText;
		}
		
		state_ &= ~PixivMediumParserState_InOneCommentDivP;
	} else if ((state_ & PixivMediumParserState_InWorksP) && [name isEqualToString:@"p"]) {
		if (stringBuf_) {
			NSArray *ary = [stringBuf_ componentsSeparatedByString:@"｜"];
			if ([ary count] > 0) {
				[info setObject:[ary objectAtIndex:0] forKey:@"DateString"];
			}
			if ([ary count] > 1) {
				NSString *tmp = [ary objectAtIndex:1];
				if ([tmp hasPrefix:@"漫画"] || [tmp hasPrefix:@"Manga"]) {
					NSScanner *scan = [[[NSScanner alloc] initWithString:tmp] autorelease];
					NSString *tmp2 = nil;
					BOOL b;
					b = [scan scanUpToString:@" " intoString:&tmp2];
					[scan scanString:@" " intoString:nil];
					if (b && tmp2 != nil) {
						b = [scan scanUpToString:@"P" intoString:&tmp2];
						if (b && tmp2 != nil) {
							[info setObject:tmp2 forKey:@"MangaPageCount"];
						}
					}					
				}
			}
			
			[stringBuf_ release];
			stringBuf_ = nil;
					
			// title終了
			state_ &= ~PixivMediumParserState_InWorksP;
		}	
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (stringBuf_) {
		[stringBuf_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]];
	}
}

#endif

@end
