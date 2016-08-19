//
//  TumblrMatrixViewController.m
//  pixiViewer
//
//  Created by nya on 10/01/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrMatrixViewController.h"
#import "ImageDiskCache.h"
#import "TwitterParser.h"
//#import "Tumblr.h"
#import "TumblrParser.h"
#import "TumblrMediumViewController.h"
#import "AccountManager.h"
#import "TumblrSlideshowViewController.h"
#import "Reachability.h"
#import "PerformMainObject.h"


static NSString *removeHTML(NSString *str) {
	NSMutableString *ret = [NSMutableString string];
	NSScanner *scan = [NSScanner scannerWithString:str];
	NSString *tmp = nil;
	BOOL b;
	BOOL searchTerm = NO;
	
	while (1) {
		if (searchTerm == NO) {
			if ([[str substringFromIndex:[scan scanLocation]] hasPrefix:@"<"]) {
				searchTerm = YES;
			} else {
				b = [scan scanUpToString:@"<" intoString:&tmp];
				if (b && tmp) {
					[ret appendString:tmp];
					
					b = [scan scanString:@"<" intoString:nil];
					if (b) {
						searchTerm = YES;
					} else {
						break;
					}
				} else {
					break;
				}
			}
		} else {
			b = [scan scanUpToString:@">" intoString:&tmp];
			if (b) {
				b = [scan scanString:@">" intoString:nil];
				if (!b) {
					break;
				} else {
					searchTerm = NO;
				}
			} else {
				break;
			}
		}
	}
	
	return ret;
}


@interface TumblrMatrixViewController(Private)
- (void) tumblrLoader:(id)sender found:(NSDictionary *)info;
@end



@interface TumblrLoader : NSObject<MatrixParserDelegate, CHHtmlParserConnectionDelegate> {
	NSMutableDictionary *info_;
	
	CHHtmlParserConnection *tumblrConnection_;
	TumblrParser *tumblrParser_;
	
	TumblrMatrixViewController *delegate;
	int retryCount;
	
	PerformMainObject *foundMain;
	PerformMainObject *finishedMain;
}

@property(assign, readwrite, nonatomic) TumblrMatrixViewController *delegate;
@property(assign, readwrite, nonatomic) int retryCount;

- (id) initWithInfo:(NSMutableDictionary *)info;
- (NSString *) start;
- (void) stop;
- (NSDictionary *)info;

@end


@implementation TumblrLoader

@synthesize delegate, retryCount;

- (id) initWithInfo:(NSMutableDictionary *)info {
	self = [super init];
	if (self) {
		foundMain = [[PerformMainObject alloc] init];
		foundMain.target = self;
		foundMain.selector = @selector(matrixParserFoundPictureMain:);
		finishedMain = [[PerformMainObject alloc] init];
		finishedMain.target = self;
		finishedMain.selector = @selector(matrixParserFinishedMain:);

		info_ = [info mutableCopy];
	}
	return self;
}

- (void) dealloc {
	[self stop];
	[info_ release];

	foundMain.target = nil;
	[foundMain release];
	finishedMain.target = nil;
	[finishedMain release];
	
	[super dealloc];
}

- (NSDictionary *)info {
	return info_;
}

- (NSString *) start {
	NSString *text = [info_ objectForKey:@"text"];
	if ([text rangeOfString:@"[Photo]"].location != NSNotFound) {
		CHHtmlParserConnection *con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", [info_ objectForKey:@"User"], [info_ objectForKey:@"PostID"]]]];
		TumblrParser			*parser = [[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
		parser.delegate = self;
		con.delegate = self;
		con.timeout = 30;
		
		tumblrConnection_ = con;
		tumblrParser_ = parser;
		[con startWithParser:parser];
		
		return [info_ objectForKey:@"IllustID"];
	} else {
		return nil;
	}
}

- (void) stop {
	delegate  = nil;
	
	[tumblrParser_ addDataEnd];
	[tumblrParser_ release];
	tumblrParser_ = nil;
	[tumblrConnection_ cancel];
	[tumblrConnection_ release];
	tumblrConnection_ = nil;
}

- (void) urlDidReceiveResponse:(NSURLResponse *)response {
	NSString *url = [[response URL] absoluteString];
	NSString *user = nil;
	NSString *post = nil;
	
	if (url) {
		NSScanner *scanner = [NSScanner scannerWithString:url];
		NSString *tmp = nil;
		BOOL b;
			
		b = [scanner scanString:@"http://" intoString:&tmp];
		if (b && tmp) {
			b = [scanner scanUpToString:@"." intoString:&tmp];
			if (b && tmp) {
				user = tmp;
			}
		}
		b = [scanner scanUpToString:@"/post/" intoString:&tmp];
		if (b && tmp) {
			b = [scanner scanString:@"/post/" intoString:&tmp];
			if (b && tmp) {
				b = [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@" /\n\r\t"] intoString:&tmp];
				if (b) {
					post = tmp;
				}
			}
		}
	}
	DLog(@" -> [%@], [%@]", user, post);
	if (user && post) {
		[info_ setObject:user forKey:@"User"];
		[info_ setObject:post forKey:@"PostID"];
		//[info_ setObject:[NSString stringWithFormat:@"%@_%@", user, post] forKey:@"IllustID"];
		
		CHHtmlParserConnection *con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", user, post]]];
		TumblrParser			*parser = [[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding];
		parser.delegate = self;
		con.delegate = self;
		
		tumblrConnection_ = con;
		tumblrParser_ = parser;
		//[con startWithParser:parser];
		[self performSelectorOnMainThread:@selector(startTumblrParser) withObject:nil waitUntilDone:NO];
	} else {
		[delegate tumblrLoader:self found:nil];
	}
}

- (void) startTumblrParser {
	[tumblrConnection_ startWithParser:tumblrParser_];
}

- (void) matrixParserFoundPictureMain:(NSMutableDictionary *)pic {
	DLog(@"loader found: %@", pic);
	
	[pic removeObjectForKey:@"IllustID"];
	[info_ addEntriesFromDictionary:pic];
	
	NSMutableArray *keys = [NSMutableArray array];
	for (NSString *key in [pic allKeys]) {
		if ([key hasPrefix:@"Image_"]) {
			NSArray *tmp = [key componentsSeparatedByString:@"_"];
			if ([tmp count] == 2) {
				int size = [[tmp objectAtIndex:1] intValue];
				[keys addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					key,							@"Key",
					[NSNumber numberWithInt:size],	@"Size",
					nil]];
			}
		}
	}
	NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"Size" ascending:YES];
	[keys sortUsingDescriptors:[NSArray arrayWithObject:desc]];
	[desc release];
	DLog(@"keys: %@", [keys description]);
	
	NSString *smallKey = nil;
	NSString *mediumKey = nil;
	NSString *bigKey = [[keys lastObject] objectForKey:@"Key"];
	for (NSDictionary *key in keys) {
		if (smallKey == nil && [[key objectForKey:@"Size"] intValue] >= 100) {
			smallKey = [key objectForKey:@"Key"];
		}
		if (mediumKey == nil && [[key objectForKey:@"Size"] intValue] >= 400) {
			mediumKey = [key objectForKey:@"Key"];
		}
	}
	if (mediumKey == nil) {
		mediumKey = smallKey;
	}
	
	if (smallKey && mediumKey && bigKey) {
		[info_ setObject:[pic objectForKey:smallKey] forKey:@"ThumbnailURLString"];
		[info_ setObject:[pic objectForKey:mediumKey] forKey:@"MediumURLString"];
		[info_ setObject:[pic objectForKey:bigKey] forKey:@"BigURLString"];
	}
	
	if (0 && [info_ objectForKey:@"retweeted_status"]) {
		[info_ setObject:removeHTML([info_ objectForKey:@"retweeted_status"]) forKey:@"Title"];
	} else if ([info_ objectForKey:@"text"]) {
		[info_ setObject:removeHTML([info_ objectForKey:@"text"]) forKey:@"Title"];
	} else if ([info_ objectForKey:@"Caption"]) {
		[info_ setObject:removeHTML([info_ objectForKey:@"Caption"]) forKey:@"Title"];
	}
}

- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSDictionary *)pic {
	DLog(@"performselector foundPicture");
	[foundMain performSelectorOnMainThread:@selector(performMain:) withObject:pic waitUntilDone:NO];
	//[self performSelectorOnMainThread:@selector(matrixParserFoundPictureMain:) withObject:pic waitUntilDone:NO];
}

- (void) matrixParserFinishedMain:(NSNumber *)num {
	[tumblrParser_ release];
	tumblrParser_ = nil;
	
	if ([info_ objectForKey:@"ThumbnailURLString"]) {
		[delegate tumblrLoader:self found:info_];
	} else {
		[delegate tumblrLoader:self found:nil];
	}
}

- (void) matrixParser:(MatrixParser *)parser finished:(long)err {
	//[self matrixParserFinishedMain:[NSNumber numberWithLong:err]];
	DLog(@"performselector finish");
	[finishedMain performSelectorOnMainThread:@selector(performMain:) withObject:[NSNumber numberWithLong:err] waitUntilDone:NO];
	//[self performSelectorOnMainThread:@selector(matrixParserFinishedMain:) withObject:[NSNumber numberWithLong:err] waitUntilDone:NO];
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	[tumblrConnection_ release];
	tumblrConnection_ = nil;
}

@end


@implementation TumblrMatrixViewController

- (void) dealloc {
	for (TumblrLoader *l in loadingTumblrLoaders_) {
		[l stop];
	}
	[loadingTumblrLoaders_ release];
	[pendingTumblrLoaders_ release];
	[maxID_ release];
	
	[super dealloc];
}

- (ImageCache *) cache {
	return [ImageCache tumblrSmallCache];
}

- (NSString *) referer {
	return nil;
}

- (id) pixiv {
	return [Tumblr instance];
}

- (void) loadImage:(NSDictionary *)pic {
	if ([pic objectForKey:@"ThumbnailURLString"] == nil) {
		TumblrLoader *loader = [[TumblrLoader alloc] initWithInfo:(NSMutableDictionary *)pic];			
		loader.delegate = self;

		if ([loader start]) {
			UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
			prog.progress = 0.0;
			[progressViews_ setObject:prog forKey:[pic objectForKey:@"IllustID"]];
			[prog release];
			
			[loadingTumblrLoaders_ addObject:loader];
		}
		[loader release];
	} else if ([[self cache] conteinsImageForKey:[pic objectForKey:@"IllustID"]] == NO) {
		[super loadImage:pic];
	}
}

- (long) reload {
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == 0) {
		return 2;
	}
	if ([Tumblr instance].logined == NO) {
		return -1;
	}
	/*
		[Tumblr instance].username = account.username;
		[Tumblr instance].password = account.password;
	
		long err = [[Tumblr instance] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return err;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return 0;
	}
	 */

	if (loadingTumblrLoaders_ == nil) {
		loadingTumblrLoaders_ = [[NSMutableSet alloc] init];
	}
	if (pendingTumblrLoaders_ == nil) {
		pendingTumblrLoaders_ = [[NSMutableArray alloc] init];
	}
		
	if (storedContents) {
		[contents_ release];
		contents_ = [storedContents mutableCopy];
		[storedContents release];
		storedContents = nil;
		
		/*
		for (NSDictionary *p in contents_) {
			NSMutableDictionary *pic = [[p mutableCopy] autorelease];
			
			if ([pic objectForKey:@"ThumbnailURLString"] == nil) {
				TumblrLoader *loader = [[TumblrLoader alloc] initWithInfo:pic];			
				loader.delegate = self;

				if ([loader start]) {
					UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
					prog.progress = 0.0;
					[progressViews_ setObject:prog forKey:[pic objectForKey:@"IllustID"]];
					[prog release];
			
					[loadingTumblrLoaders_ addObject:loader];
				}
				[loader release];
			} else {
				pictureIsFound_ = YES;
				DLog(@"load: %@", [pic objectForKey:@"StatusID"]);
				
				NSData *data = [[self cache] imageDataForKey:[pic objectForKey:@"IllustID"]];
				if (data) {
					[self push:data withInfo:pic];
				}	
			}
		}
		*/
		
		showsNextButton_ = YES;
		[self.tableView reloadData];
		self.tableView.contentOffset = displayedOffset_;
		displayedOffset_ = CGPointZero;
		return 0;
	}
	
	TwitterParser			*parser = [[TwitterParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;

	pictureIsFound_ = NO;
	parser.delegate = self;
	//parser.method = self.method;
	
	NSString *url;
	if (maxID_) {
		url = [NSString stringWithFormat:@"http://www.tumblr.com/statuses/%@.xml?count=40&max_id=%@", self.method, maxID_];
	} else {
		url = [NSString stringWithFormat:@"http://www.tumblr.com/statuses/%@.xml?count=40", self.method];
	}
	
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:url]];
	con.user = account.username;
	con.pass = account.password;
	
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];	
	return 0;
}

- (void) viewDidLoad {
	[super viewDidLoad];	
}

//- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSMutableDictionary *)pic {
- (void) matrixParserFoundPictureMain:(NSMutableDictionary *)pic {
		TumblrLoader *loader = [[TumblrLoader alloc] initWithInfo:pic];
		NSString *iid;
		
		loader.delegate = self;
		if ((iid = [loader start])) {
			BOOL found = NO;
			pictureIsFound_ = YES;
			DLog(@"load: %@", [pic objectForKey:@"StatusID"]);
			
			[pic setObject:iid forKey:@"IllustID"];
			
			for (NSDictionary *dic in contents_) {
				if ([iid isEqualToString:[dic objectForKey:@"IllustID"]]) {
					// 既にある
					found = YES;
					break;
				}
			}
	
			if (!found) {
				UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
				prog.progress = 0.0;
				[progressViews_ setObject:prog forKey:[pic objectForKey:@"IllustID"]];
				[prog release];
				
				[contents_ addObject:pic];
			}
			
			[loadingTumblrLoaders_ addObject:loader];

			NSData *data = [[self cache] imageDataForKey:iid];
			if (data) {
				[self push:data withInfo:pic];
			}
		}
		[loader release];
		
		[maxID_ release];
		maxID_ = [[pic objectForKey:@"StatusID"] retain];
}

//- (void) matrixParser:(MatrixParser *)parser finished:(long)err {
- (void) matrixParserFinishedMain:(NSNumber *)num {
	//[parser_ addDataEnd];
	[parser_ release];
	parser_ = nil;
	
	long err = [num longValue];
	if (err == 0) {
		loadedPage_++;
		maxPage_ = 9999;//((PixivMatrixParser *)parser_).maxPage;
			
		showsNextButton_ = NO;
		if ([self.method hasPrefix:@"ranking"]) {
			if (loadedPage_ < 6) {
				showsNextButton_ = YES;
				//[[self matrixView] setShowsLoadNextButton:YES];
			}
		} else if (loadedPage_ < maxPage_) {
			showsNextButton_ = YES;
			//[[self matrixView] setShowsLoadNextButton:YES];
		}
	} else {
		showsNextButton_ = YES;
	}
	
	if (pictureIsFound_ == NO) {
		[self reload];
	} else {
		[self.tableView reloadData];	
	}
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	[connection_ release];
	connection_ = nil;		
}

- (void) tumblrLoader:(TumblrLoader *)sender found:(NSDictionary *)info {
	[sender stop];
	
	if (info) {
		//info = [[info mutableCopy] autorelease];
		
		DLog(@"tumblrLoaders found: %@", [info objectForKey:@"IllustID"]);
		
		int idx = 0;
		for (NSDictionary *dic in contents_) {
			if ([[info objectForKey:@"IllustID"] isEqualToString:[dic objectForKey:@"IllustID"]]) {
				// 既にある
				break;
			}
			idx++;
		}
		[contents_ replaceObjectAtIndex:idx withObject:info];

		//NSData *data = [[self cache] imageDataForKey:[info objectForKey:@"IllustID"]];
		if (![[self cache] conteinsImageForKey:[info objectForKey:@"IllustID"]]) {
			CHURLImageLoader *loader = [[CHURLImageLoader alloc] init];
			loader.delegate = self;
			loader.object = info;
			loader.referer = [self referer];
			loader.url = [NSURL URLWithString:[[info objectForKey:@"ThumbnailURLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
			if ([loadingLoaders_ count] > MATRIXPARSER_IMAGELOADER_COUNT) {
				[pendingLoaders_ addObject:loader];
			} else {
				[loader load];
				[loadingLoaders_ addObject:loader];
			}
			[loader release];

			//[loaders_ addObject:loader];
			//[loader load];
			//[loader release];
		} else {
			NSData *data = [[self cache] imageDataForKey:[info objectForKey:@"IllustID"]];
			[self push:data withInfo:info];
			[progressViews_ removeObjectForKey:[[sender info] objectForKey:@"IllustID"]];
		}
		
		ButtonImageView *btn = [imageViews_ objectForKey:[info objectForKey:@"IllustID"]];
		if (btn) {
			btn.object = info;
		}

		//[progressViews_ removeObjectForKey:[[sender info] objectForKey:@"IllustID"]];
		[loadingTumblrLoaders_ removeObject:sender];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TumblrInfoUpdated" object:self userInfo:info];
		[self.tableView reloadData];
	} else {
		DLog(@"tumblrLoaders not found: %@", [[sender info] objectForKey:@"IllustID"]);
		/*
		TumblrLoader *loader = [[TumblrLoader alloc] initWithInfo:(NSMutableDictionary *)[sender info]];
		NSString *iid;		
		loader.delegate = self;
		if (iid = [loader start]) {
			[tumblrLoaders_ setObject:loader forKey:[[sender info] objectForKey:@"StatusID"]];
			[loader release];
		} else {
			[tumblrLoaders_ removeObjectForKey:[[sender info] objectForKey:@"StatusID"]];
		}
		*/

		if (sender.retryCount > 8) {
			[progressViews_ removeObjectForKey:[[sender info] objectForKey:@"IllustID"]];
			[loadingTumblrLoaders_ removeObject:sender];
			[self.tableView reloadData];
		} else {
			[self performSelector:@selector(retryLoad:) withObject:sender afterDelay:0.5];
		}
	}
}

- (void) retryLoad:(TumblrLoader *)obj {
	NSMutableDictionary *info = (NSMutableDictionary *)obj.info;
	DLog(@"tumblrLoaders retryLoad: %@", [info description]);

	TumblrLoader *loader = [[TumblrLoader alloc] initWithInfo:info];
	NSString *iid;		
	loader.delegate = self;
	loader.retryCount = obj.retryCount + 1;
	[loadingTumblrLoaders_ removeObject:obj];
	if ((iid = [loader start])) {
		[loadingTumblrLoaders_ addObject:loader];
	}
	[loader release];
}

- (void) reflesh {
	for (TumblrLoader *l in loadingTumblrLoaders_) {
		[l stop];
	}
	[loadingTumblrLoaders_ removeAllObjects];
	
	[maxID_ release];
	maxID_ = nil;
	[super reflesh];
}

- (void) selectImage:(ButtonImageView *)sender {
	id senderObject = sender.object;
	//if ([senderObject objectForKey:@"MediumURLString"] == nil) {
	//	return;
	//}
	
	TumblrMediumViewController *controller = [[TumblrMediumViewController alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.info = senderObject;
	controller.account = self.account;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (IBAction) doSlideshow:(BOOL)random reverse:(BOOL)rev {
	TumblrSlideshowViewController *controller = [[TumblrSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = self.method;
	controller.maxID = maxID_;
	[controller setPage:loadedPage_];
	[controller setMaxPage:maxPage_];
	[controller setContents:contents_ random:random reverse:rev];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (BOOL) enableShuffle {
	return NO;
}

- (BOOL) enableAdd {
	return NO;
}

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	if (maxID_) {
		[info setObject:maxID_ forKey:@"MaxID"];
	}
	
	return info;
}

- (BOOL) restore:(NSDictionary *)info {
	if ([super restore:info] == NO) {
		return NO;
	}
	
	[maxID_ release];
	maxID_ = [[info objectForKey:@"MaxID"] retain];
	
	return YES;
}

@end
