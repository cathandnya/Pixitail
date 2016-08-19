//
//  Entries.m
//  pview
//
//  Created by Naomoto nya on 12/03/18.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//


#import "Entries.h"
#import "PixivMatrixParser.h"
#import "PixitailConstants.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "Service.h"
#import "Entry.h"


@implementation Entries

@synthesize list, isLoading, canLoadMore, name;

+ (Entries *) entriesWithInfo:(NSDictionary *)dic {
	if (dic) {
		return [[[NSClassFromString([dic objectForKey:@"class"]) alloc] initWithInfo:dic] autorelease];
	} else {
		return nil;
	}
}

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
	
	[mdic setObject:NSStringFromClass([self class]) forKey:@"class"];
	if (name) [mdic setObject:self.name forKey:@"name"];
	
	return mdic;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super init];
	if (self) {
		list = [[NSMutableArray alloc] init];
		self.name = [dic objectForKey:@"name"];
	}
	return self;
}

- (void) dealloc {
	[list release];
	[name release];
	[super dealloc];
}

- (void) addEntries:(NSArray *)ary {
	if (!list) {
		list = [[NSMutableArray alloc] init];
	}
	[list addObjectsFromArray:ary];
}

- (id) refreshSync {
	return nil;
}

- (id) moreSync {
	return nil;
}

- (void) refresh:(void (^)(NSError *))completionBlock {
	if (isLoading) {
		return;
	}
	isLoading = YES;
	
	void (^block)(NSError *) = Block_copy(completionBlock);

	[list removeAllObjects];
	block(nil);

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStart" object:self];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		id ret = [[self refreshSync] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			isLoading = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStop" object:self];
			
			NSError *err = nil;
			if ([ret isKindOfClass:[NSError class]]) {
				err = ret;
			} else if ([ret isKindOfClass:[NSArray class]]) {
				[self addEntries:ret];
			}
			block(err);
			[ret autorelease];
			Block_release(block);
		});
	});
}

- (NCUpdateResult) refresh {
	if (isLoading) {
		return NCUpdateResultNoData;
	}
	
	isLoading = YES;
	id ret = nil;
	@try {
		ret = [self refreshSync];
	}
	@catch (NSException *exception) {
		ret = nil;
	}
	@finally {
	}
	isLoading = NO;

	if ([ret isKindOfClass:[NSArray class]]) {
		//BOOL same = [((Entry *)list.firstObject).illust_id isEqual:((Entry *)((NSArray *)ret).firstObject).illust_id];
		
		[list removeAllObjects];
		[self addEntries:ret];
		return NCUpdateResultNewData;
	} else {
		return NCUpdateResultFailed;
	}
}

- (void) more:(void (^)(NSError *))completionBlock {
	if (isLoading) {
		return;
	}
	isLoading = YES;
	
	void (^block)(NSError *) = Block_copy(completionBlock);

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStart" object:self];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		id ret = [[self moreSync] retain];
		dispatch_async(dispatch_get_main_queue(), ^{
			isLoading = NO;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStop" object:self];
			
			NSError *err = nil;
			if ([ret isKindOfClass:[NSError class]]) {
				err = ret;
			} else if ([ret isKindOfClass:[NSArray class]]) {
				[self addEntries:ret];
			}
			block(err);
			[ret autorelease];
			Block_release(block);
		});
	});
}

- (NSString *) description {
	return self.name ? self.name : @"";
}

- (NSString *) identifier {
	NSMutableString *str = [[self.service.username mutableCopy] autorelease];
	if (self.name) {
		[str appendString:self.name];
	}
	return [@(str.hash) stringValue];
}

- (NSString *) cachePath {
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	return [[a_paths.firstObject stringByAppendingString:[self identifier]] stringByAppendingPathExtension:@"json"];
}

- (void) save {
	NSMutableArray *mary = [NSMutableArray array];
	for (Entry *e in self.list) {
		[mary addObject:e.info];
	}
	NSData *data = [NSJSONSerialization dataWithJSONObject:mary options:0 error:nil];
	[data writeToFile:[self cachePath] atomically:YES];
}

- (void) load {
	NSData *data = [NSData dataWithContentsOfFile:[self cachePath]];
	if (data) {
		id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		if ([obj isKindOfClass:[NSArray class]]) {
			[list release];
			list = [NSMutableArray new];
			for (NSDictionary *d in obj) {
				[list addObject:[[[Entry alloc] initWithInfo:d] autorelease]];
			}
		}
	}
}

@end


@implementation MatrixEntries

@synthesize scrapingInfoKey, method, currentPage;

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [super info];
	
	if (scrapingInfoKey) [mdic setObject:self.scrapingInfoKey forKey:@"scrapingInfoKey"];
	if (method) [mdic setObject:self.method forKey:@"method"];
	
	return mdic;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super initWithInfo:dic];
	if (self) {
		self.scrapingInfoKey = [dic objectForKey:@"scrapingInfoKey"];
		self.method = [dic objectForKey:@"method"];
	}
	return self;
}

- (void) dealloc {
	[method release];
	[scrapingInfoKey release];
	[super dealloc];
}

- (id) loadSync:(int)page {
	NSError *err = nil;
	@synchronized(self.service) {
		if (self.service.needsLogin) {
			err = [self.service login];
			if (err) {
				return err;
			}
		}
	}
	
	[tmpList release];
	tmpList = [[NSMutableArray alloc] init];
	
	PixivMatrixParser *parser = [self.service makeParser:scrapingInfoKey method:self.method];
	parser.delegate = (id)self;
	CHHtmlParserConnection *con = [self.service makeConnection:self.method page:page];
	
	err = [con startWithParserSync:parser];
	if (err) {
		[tmpList release];
		tmpList = nil;
		return err;
	} else {
		NSArray *ary = [NSArray arrayWithArray:tmpList];
		[tmpList autorelease];
		tmpList = nil;
		
		if ([self.method hasPrefix:@"ranking"]) {
			self.canLoadMore = (page < 6);
		} else {
			self.canLoadMore = (page < parser.maxPage);
		}
		return ary;
	}
}

- (id) refreshSync {
	NSError *err = [self loadSync:1];
	if ([err isKindOfClass:[NSArray class]]) {
		currentPage = 1;
	}
	return err;
}

- (id) moreSync {
	NSError *err = [self loadSync:self.currentPage + 1];
	if ([err isKindOfClass:[NSArray class]]) {
		currentPage++;
	}
	return err;
}

- (void) matrixParser:(id)parser foundPicture:(NSDictionary *)pic {
	Entry *e = [Entry new];
	e.illust_id = [pic objectForKey:@"IllustID"];
	e.thumbnail_url = [pic objectForKey:@"ThumbnailURLString"];
	e.service_name = self.service.name;
	if ([self.service.name isEqualToString:@"Danbooru"]) {
		NSMutableDictionary *mdic = [[pic mutableCopy] autorelease];
		mdic[@"method"] = self.method;
		for (id key in [mdic allKeys]) {
			if ([mdic[key] isKindOfClass:[NSNull class]]) {
				[mdic removeObjectForKey:key];
			}
		}
		e.other_info = mdic;
	}
	[tmpList addObject:e];
}

- (void) matrixParser:(id)parser finished:(long)err {
}

- (NSString *) identifier {
	NSMutableString *str = [[self.service.username mutableCopy] autorelease];
	if (self.method) {
		[str appendString:self.method];
	}
	return [@(str.hash) stringValue];
}

@end


@implementation StaccEntries

@synthesize scrapingInfoKey, method, nextMaxSID;

- (NSMutableDictionary *) info {
	NSMutableDictionary *mdic = [super info];
	
	if (scrapingInfoKey) [mdic setObject:self.scrapingInfoKey forKey:@"scrapingInfoKey"];
	if (method) [mdic setObject:self.method forKey:@"method"];
	
	return mdic;
}

- (id) initWithInfo:(NSDictionary *)dic {
	self = [super initWithInfo:dic];
	if (self) {
		self.scrapingInfoKey = [dic objectForKey:@"scrapingInfoKey"];
		self.method = [dic objectForKey:@"method"];
	}
	return self;
}

- (void) dealloc {
	[method release];
	[scrapingInfoKey release];
	[nextMaxSID release];
	[super dealloc];
}

- (id) loadSync:(BOOL)more {
	NSError *err = nil;
	@synchronized(self.service) {
		if (self.service.needsLogin) {
			err = [self.service login];
			if (err) {
				return err;
			}
		}
	}
	
	NSString *url;
	if (more && nextMaxSID) {
		url = [NSString stringWithFormat:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_url_format"], self.method, self.nextMaxSID, self.service.authToken];
	} else {
		url = [NSString stringWithFormat:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_url_format"], self.method, @"", self.service.authToken];
	}
	NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	[req setValue:@"http://www.pixiv.net/mypage.php" forHTTPHeaderField:@"Referer"];
	DLog(@"load: %@", url);
	
	NSURLResponse *res = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
	if (err) {
		return err;
	} else {
		NSMutableArray *mary = [NSMutableArray array];
		
		DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
		id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
		
		self.nextMaxSID = [json valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_next_max_id_key"]];
		self.canLoadMore = ([[json valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_is_last_page_key"]] intValue] == 0);
		
		id status = [json valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_status_key"]];
		id illust = [json valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_illust_key"]];
		//id user = [json valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_user_key"]];
		for (NSString *key in [[status allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			return [[NSNumber numberWithInt:[obj2 intValue]] compare:[NSNumber numberWithInt:[obj1 intValue]]];
		}]) {
			NSDictionary *d = [status objectForKey:key];
			NSString *iid = [d valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_illust_id_key"]];
			if (iid) {
				if ([iid isKindOfClass:[NSNumber class]]) {
					iid = [(NSNumber *)iid stringValue];
				}
				NSDictionary *i = [illust valueForKeyPath:iid];
				if (i) {
					NSString *uid = [i valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_user_id_key"]];
					if ([uid isKindOfClass:[NSNumber class]]) {
						uid = [(NSNumber *)uid stringValue];
					}
					//NSDictionary *u = [user valueForKeyPath:uid];
					Entry *e = [Entry new];
					e.illust_id = iid;
					e.thumbnail_url = [i valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_thumbnail_url_key"]];
					e.service_name = self.service.name;
					/*
					if (e) {
						e.title = [i valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_title_key"]];
						e.comment = [i valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_comment_key"]];
						e.userID = [u valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_user_id_key"]];
						e.userName = [u valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_entry_user_name_key"]];
						
						e.thumbnailImageURL = [i valueForKeyPath:[[PixitailConstants sharedInstance] valueForKeyPath:@"constants.stacc_thumbnail_url_key"]];
						NSString *base = [e.thumbnailImageURL stringByDeletingPathExtension];
						NSString *ext = [e.thumbnailImageURL pathExtension];
						e.mediumImageURL = [[[base substringToIndex:base.length - 1] stringByAppendingString:@"m"] stringByAppendingPathExtension:ext];
						//e.bigImageURL = [[base substringToIndex:base.length - 2] stringByAppendingPathExtension:ext];
						
						//[e load];
						//[e loadAsync];
						
						//e.needsLoad = NO;
					}
					 */
					[mary addObject:e];
				}
			}
		}
		
		return mary;
	}
}

- (id) refreshSync {
	NSError *err = [self loadSync:NO];
	if ([err isKindOfClass:[NSArray class]]) {
		
	}
	return err;
}

- (id) moreSync {
	NSError *err = [self loadSync:YES];
	if ([err isKindOfClass:[NSArray class]]) {

	}
	return err;
}

@end
