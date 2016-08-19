//
//  ImageLoaderManager.m
//  Tumbltail
//
//  Created by nya on 10/09/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ImageLoaderManager.h"
#import "CHURLImageLoader.h"
#import "ImageDiskCache.h"
#import "NSData+GIF.h"
#import "UIImage+animatedGIF.h"


static NSString* encodeURIComponent(NSString* s) {
    return [((NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
																(CFStringRef)s,
																NULL,
																(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																kCFStringEncodingUTF8)) autorelease];
}


@implementation ImageLoaderManager

@synthesize referer, cache = diskCache;

- (id) initWithType:(ImageLoaderType)t {
	self = [super init];
	if (self) {
		type = t;
		loaders = [[NSMutableDictionary alloc] init];
		cache = nil;

		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *name = [NSString stringWithFormat:@"ImageLoader_%d", type];
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:name];
			diskCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			diskCache.cacheCount = 100;
		}

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelLoad) name:@"CurrentAccountWillChangeNotification" object:nil];
	}
	return self;
}

- (id) initWithName:(NSString *)obj {
	self = [super init];
	if (self) {
		type = INT_MAX;
		loaders = [[NSMutableDictionary alloc] init];
		cache = nil;
		
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *name = [NSString stringWithFormat:@"ImageLoader_%@", obj];
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:name];
			diskCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			diskCache.cacheCount = 100;
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelLoad) name:@"CurrentAccountWillChangeNotification" object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[loaders release];
	[cache release];
	[diskCache release];
	[referer release];
	[super dealloc];
}

static ImageLoaderManager *loadersList[ImageLoaderType_Count] = {0};
static NSMutableDictionary *loadersDict = nil;

+ (ImageLoaderManager *) loaderWithType:(ImageLoaderType)type {
	if (loadersList[type] == nil) {
		loadersList[type] = [[ImageLoaderManager alloc] initWithType:type];
	}
	return loadersList[type];
}

+ (ImageLoaderManager *) loaderWithName:(NSString *)name {
	if (!loadersDict) {
		loadersDict = [[NSMutableDictionary alloc] init];
	}
	ImageLoaderManager *loader = [loadersDict objectForKey:name];
	if (loader == nil) {
		loader = [[[ImageLoaderManager alloc] initWithName:name] autorelease];
		[loadersDict setObject:loader forKey:name];
	}
	return loader;
}

+ (void) clearCache {
	for (int i = 0; i < ImageLoaderType_Count; i++) {
		[loadersList[i].cache removeAllCaches];
	}
	for (ImageLoaderManager *m in [loadersDict allValues]) {
		[m.cache removeAllCaches];
	}
}

- (NSData *) dataWithID:(NSString *)idt {
	return [diskCache imageDataForKey:idt];
}

- (void) setData:(NSData *)data withID:(NSString *)idt {
	[diskCache setImageData:data forKey:idt];
}

#pragma mark-

- (void) clear {
	[cache removeAllObjects];
}

- (void) removeImageForID:(NSString *)idt {
	[diskCache removeCacheForKey:idt];
}

- (void) setImage:(UIImage *)img forID:(NSString *)idt {
	[diskCache setImageData:UIImageJPEGRepresentation(img, 0.8) forKey:idt];
}

- (UIImage *) inMemoryImageForID:(NSString *)idt0 {
	UIImage *img = [cache objectForKey:idt0];
	if (img) {
		return img;
	}
	return nil;
}

- (BOOL) imageIsLoadedForID:(NSString *)idt {
	if ([cache objectForKey:idt]) {
		return YES;
	}
	
	if ([cache objectForKey:idt] != nil) {
		return YES;
	} else {
		return [diskCache conteinsImageForKey:idt];
	}
}

- (BOOL) imageIsLoadingForID:(NSString *)idt {
	return [loaders objectForKey:idt] != nil;
}

- (NSInteger) imageLoadingPercentForID:(NSString *)idt {
	CHURLImageLoader *loader = [loaders objectForKey:idt];
	if (loader) {
		return loader.percent;
	} else {
		return 0;
	}
}

- (UIImage *) imageForID:(NSString *)idt {
	UIImage *img = [cache objectForKey:idt];
	if (img) {
		return img;
	}
	
	img = [cache objectForKey:idt];
	if (img) {
		[cache setObject:img forKey:idt];
		[self compact:idt];
		return img;
	} else {
		NSData *data = [self dataWithID:idt];
		if (data) {
			img = [data isGIF] ? [UIImage animatedImageWithAnimatedGIFData:data] : [UIImage imageWithData:data];
			if (img) {
				[cache setObject:img forKey:idt];
				[self compact:idt];
				return img;
			} else {
				assert(0);
			}
		}	
	}
	return nil;
}

- (long) loadImageForID:(NSString *)idt url:(NSString *)urlString {
	if ([self imageIsLoadingForID:idt] || [self imageIsLoadedForID:idt]) {
		return 1;
	}
	
	CHURLImageLoader *loader = [[[CHURLImageLoader alloc] init] autorelease];
	loader.referer = self.referer;
	NSString *str = urlString;
		
	loader.url = str ? [NSURL URLWithString:str] : nil;
	if (loader.url == nil && str != nil) {
		NSString *dirname = [str stringByDeletingLastPathComponent];
		NSString *filename = [[str lastPathComponent] stringByDeletingPathExtension];
		NSString *ext = [str pathExtension];
		filename = encodeURIComponent(filename);
		str = [dirname stringByAppendingPathComponent:[filename stringByAppendingPathExtension:ext]];
		loader.url = str ? [NSURL URLWithString:str] : nil;
	}
	if (loader.url == nil) {
		return 1;
	}
	assert(loader.url);
	loader.delegate = self;
	loader.object = idt;
	
	[loader load];
	[loaders setObject:loader forKey:idt];
	return 0;
}

#pragma mark-

- (void) loader:(CHURLImageLoader *)loader progress:(NSInteger)percent {
	NSString *idt = loader.object;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoaderManagerProgressNotification" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger:percent],		@"Progress",
		idt,									@"ID",
		nil]];
	
#ifdef USE_REBLOGGED_SOURCE
	if (type != ImageLoaderManagerType_Avatar) {
		Photo *p = [[PostCache sharedInstance] photoWithID:idt];
		for (Post *tmp in p.reblogedPosts) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoaderManagerProgressNotification" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:percent],		@"Progress",
				tmp.ID,									@"ID",
				nil]];			
		}
	}
#endif
}

- (void) loader:(CHURLImageLoader *)loader finished:(NSData *)data {
	NSString *idt = loader.object;
	
	UIImage *img = [data isGIF] ? [UIImage animatedImageWithAnimatedGIFData:data] : [UIImage imageWithData:data];
	if (img) {
		[cache setObject:img forKey:idt];
		[self setData:data withID:idt];
		[self compact:idt];
		//[[PostCache sharedInstance] update:p];
		//[[PostCache sharedInstance] save];

		[loaders removeObjectForKey:idt];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoaderManagerFinishedNotification" object:self userInfo:[NSDictionary dictionaryWithObject:idt forKey:@"ID"]];	
	} else {
		DLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
		[loaders removeObjectForKey:idt];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"ImageLoaderManagerFinishedNotification" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:idt, @"ID", [NSError errorWithDomain:@"ImageLoaderManager" code:-1 userInfo:nil], @"Error", nil]];	
	}	
}

- (void) cancelLoad {
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	for (CHURLImageLoader *l in [loaders allValues]) {
		[l cancel];
	}
	[loaders removeAllObjects];
}

#define COMPACT_SIZE			400
- (void) compact:(NSString *)idt {
	NSArray *keys = [[[[cache allKeys] sortedArrayUsingSelector:@selector(compare:)] retain] autorelease];
	if ([keys count] < COMPACT_SIZE * 2) {
		return;
	}
	
	NSUInteger idx = [keys indexOfObject:idt];
	if (idx == NSNotFound) {
		idx = 0;
	}
	
	NSInteger min = idx - COMPACT_SIZE / 2;
	NSInteger max = idx + COMPACT_SIZE /2;
	if (min < 0) {
		max += -min;
		min = 0;
	}
	if (max >= [keys count]) {
		max = [keys count] - 1;
	}
	
	for (NSInteger i = 0; i < min; i++) {
		[cache removeObjectForKey:[keys objectAtIndex:i]];
	}
	for (NSInteger i = max; i < [keys count]; i++) {
		[cache removeObjectForKey:[keys objectAtIndex:i]];
	}
}

- (NSString *) cachePathForID:(NSString *)idt {
	return [diskCache pathForKey:idt];
}

- (void) removeAll {
	[diskCache removeAllCaches];
	[cache removeAllObjects];
}

@end
