//
//  ImageDiskCache.m
//
//  Created by nya on 09/12/04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"


#define SMALL_CACHE_COUNT		400


@implementation ImageCache

@synthesize cacheCount;

+ (BOOL) available {
	return YES;
	/*
	static BOOL checked = NO;
	static BOOL available = NO;
	if (!checked) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSError *err = nil;
			NSDictionary *info = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[a_paths objectAtIndex:0] error:&err];
			if ([info objectForKey:NSFileSystemFreeSize]) {
				long long free = [[info objectForKey:NSFileSystemFreeSize] longLongValue];
				available = (free > IMAGE_CACHE_AVAILABLE_MIN_FREE_SIZE);
				checked = YES;
			}
		}
	}
	return available;
	*/
}

+ (ImageCache *)pixivSmallCache {
    static ImageCache *sharedCache = nil;
    if (sharedCache == nil) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"PixivSmall"];
			sharedCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			sharedCache.cacheCount = SMALL_CACHE_COUNT;
		}
	}
    return sharedCache;
}

+ (ImageCache *)pixivMediumCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium].cache;
}

+ (ImageCache *)pixivBigCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig].cache;
}

+ (ImageCache *)pixaSmallCache {
    static ImageCache *sharedCache = nil;
    if (sharedCache == nil) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"PixaSmall"];
			sharedCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			sharedCache.cacheCount = SMALL_CACHE_COUNT;
		}
    }
    return sharedCache;
}

+ (ImageCache *)pixaMediumCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_PixaMedium].cache;
}

+ (ImageCache *)pixaBigCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_PixaBig].cache;
}

+ (ImageCache *)tumblrSmallCache {
    static ImageCache *sharedCache = nil;
    if (sharedCache == nil) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"TumblrSmall"];
			sharedCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			sharedCache.cacheCount = SMALL_CACHE_COUNT;
		}
	}
    return sharedCache;
}

+ (ImageCache *)tumblrMediumCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_Tumblr].cache;
}

+ (ImageCache *)tumblrBigCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_Tumblr].cache;
}

+ (ImageCache *)tinamiSmallCache {
    static ImageCache *sharedCache = nil;
    if (sharedCache == nil) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"TinamiSmall"];
			sharedCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			sharedCache.cacheCount = SMALL_CACHE_COUNT;
		}
	}
    return sharedCache;
}

+ (ImageCache *)tinamiMediumCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_Tinami].cache;
}

+ (ImageCache *)tinamiBigCache {
	return [ImageDiskCache tinamiMediumCache];
}

+ (ImageCache *)danbooruSmallCache {
    static ImageCache *sharedCache = nil;
    if (sharedCache == nil) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"DanbooruSmall"];
			sharedCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			sharedCache.cacheCount = SMALL_CACHE_COUNT;
		}
	}
    return sharedCache;
}

+ (ImageCache *)danbooruMediumCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_DanbooruMedium].cache;
}

+ (ImageCache *)danbooruBigCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_DanbooruBig].cache;
}

+ (ImageCache *)seigaSmallCache {
    static ImageCache *sharedCache = nil;
    if (sharedCache == nil) {
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		if ([a_paths count] > 0) {
			NSString *dirPath = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"SeigaSmall"];
			sharedCache = [[ImageDiskCache alloc] initWithDirectory:dirPath];
			sharedCache.cacheCount = SMALL_CACHE_COUNT;
		}
	}
    return sharedCache;
}

+ (ImageCache *)seigaMediumCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_SeigaMedium].cache;
}

+ (ImageCache *)seigaBigCache {
	return [ImageLoaderManager loaderWithType:ImageLoaderType_SeigaBig].cache;
}

+ (ImageCache *) smallCacheForName:(NSString *)name {
	return [ImageLoaderManager loaderWithName:[NSString stringWithFormat:@"%@_Small", name]].cache;
}

+ (ImageCache *) mediumCacheForName:(NSString *)name {
	return [ImageLoaderManager loaderWithName:[NSString stringWithFormat:@"%@_Medium", name]].cache;
}

+ (ImageCache *) bigCacheForName:(NSString *)name {
	return [ImageLoaderManager loaderWithName:[NSString stringWithFormat:@"%@_Big", name]].cache;
}

+ (void) removeAllCache {
	[ImageLoaderManager clearCache];
	
	[[self pixivSmallCache] removeAllCaches];
	[[self pixaSmallCache] removeAllCaches];
	[[self tinamiSmallCache] removeAllCaches];
	[[self tumblrSmallCache] removeAllCaches];
	[[self danbooruSmallCache] removeAllCaches];
	[[self seigaSmallCache] removeAllCaches];
}

+ (void) cleanUpOld {
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
	if ([a_paths count] > 0) {
		NSString *base = [a_paths objectAtIndex:0];		
		NSArray *ary = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:base error:nil];
		for (NSString *name in ary) {
			if ([name hasSuffix:@"Small"] || [name hasSuffix:@"Medium"] || [name hasSuffix:@"Big"]) {
				NSString *path = [base stringByAppendingPathComponent:name];
				BOOL b;
				if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&b] && b) {
					[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
				}
			}
		}
	}
}

+ (void) cleanUpOldThread:(id)handler {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[ImageCache cleanUpOld];
	if ([handler respondsToSelector:@selector(imageCacheCleanUpOldFinished)]) {
		[handler performSelectorOnMainThread:@selector(imageCacheCleanUpOldFinished) withObject:nil waitUntilDone:NO];
	}
	[pool release];
}

+ (void) cleanUpOld:(id)handler {
	[NSThread detachNewThreadSelector:@selector(cleanUpOldThread:) toTarget:[ImageCache class] withObject:handler];
}

+ (void) cleanUp {
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	if ([a_paths count] > 0) {
		NSString *base = [a_paths objectAtIndex:0];		
		NSArray *ary = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:base error:nil];
		for (NSString *name in ary) {
			if ([name hasSuffix:@"Small"] || [name hasSuffix:@"Medium"] || [name hasSuffix:@"Big"]) {
				NSString *path = [base stringByAppendingPathComponent:name];
				BOOL b;
				if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&b] && b) {
					[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
				}
			}
		}
	}
}

+ (void) cleanUpThread:(id)handler {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[ImageCache cleanUp];
	if ([handler respondsToSelector:@selector(imageCacheCleanUpFinished)]) {
		[handler performSelectorOnMainThread:@selector(imageCacheCleanUpFinished) withObject:nil waitUntilDone:NO];
	}
	[pool release];
}

+ (void) cleanUp:(id)handler {
	[NSThread detachNewThreadSelector:@selector(cleanUpThread:) toTarget:[ImageCache class] withObject:handler];
}

+ (BOOL) needsCleanUp {
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	if ([a_paths count] > 0) {
		NSString *base = [a_paths objectAtIndex:0];		
		NSArray *ary = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:base error:nil];
		for (NSString *name in ary) {
			if ([name hasSuffix:@"Small"] || [name hasSuffix:@"Medium"] || [name hasSuffix:@"Big"]) {
				return YES;
			}
		}
	}
	return NO;
}

- (id) init {
	self = [super init];
	if (self) {
		keys = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[keys release];
	[super dealloc];
}

- (UIImage *)imageForKey:(NSString *)key {
	return nil;
}

- (BOOL)conteinsImageForKey:(NSString *)key {
	return NO;
}

- (NSData *)imageDataForKey:(NSString *)key {
	return nil;
}

- (void)setImageData:(NSData *)data forKey:(NSString *)key {
}

- (void)removeAllCaches {
}

- (BOOL)isGifPng:(NSString *)key {
	NSData *data = [self imageDataForKey:key];
	char *bytes = (char *)[data bytes];
	
	if ([data length] < 6) {
		return NO;
	}
	if (strncmp(bytes, "GIF87a", 6) == 0) {
		return YES;
	}
	if (strncmp(bytes, "GIF89a", 6) == 0) {
		return YES;
	}

	if ([data length] < 8) {
		return NO;
	}
	if (bytes[0] == (char)0x89) {
		if (strncmp(bytes + 1, "PNG", 3) == 0) {
			if (bytes[4] == 0x0d && bytes[5] == 0x0a && bytes[6] == 0x1a && bytes[7] == 0x0a) {
				return YES;
			}
		}
	}
	return NO;
}

@end


@implementation ImageDiskCache

/*
- (long long) freeSize {
	if (diskFreeSize < 0) {
		NSError *err = nil;
		NSDictionary *info = [[NSFileManager defaultManager] attributesOfFileSystemForPath:basePath error:&err];
		if ([info objectForKey:NSFileSystemFreeSize]) {
			diskFreeSize = [[info objectForKey:NSFileSystemFreeSize] longLongValue];
		}
	}
	return diskFreeSize;
}
*/

- (NSString *) keysPath {
	return [basePath stringByAppendingPathComponent:@"keys"];
}

- (void) load {
	[keys release];
	
	id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:[self keysPath]];
	if ([obj isKindOfClass:[NSArray class]]) {
		keys = [[NSMutableArray alloc] initWithArray:obj];
	} else {
		keys = [[NSMutableArray alloc] init];
	}
}

- (void) save {
	[NSKeyedArchiver archiveRootObject:keys toFile:[self keysPath]];
}

- (id) initWithDirectory:(NSString *)path {
    self = [super init];
    if (self) {
		basePath = [path retain];
		if ([[NSFileManager defaultManager] fileExistsAtPath:basePath] == NO) {
			[[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
		}
		//diskFreeSize = -1;

		[self load];
    }
    return self;
}

- (void)dealoc {
	[basePath release];
	
    [super dealloc];
}

- (NSString *) pathForKey:(NSString *)key {
	return [basePath stringByAppendingPathComponent:[key lastPathComponent]];
}

- (NSData *) dataForKey:(NSString *)key {
	NSString *path = [self pathForKey:key];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		return [NSData dataWithContentsOfFile:path];
	}
	return nil;
}

- (BOOL)conteinsImageForKey:(NSString *)key {
	if ([keys containsObject:key]) {
		return YES;
	}
	
	NSString *path = [self pathForKey:key];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[keys addObject:key];
		[self save];
		return YES;
	} else {
		return NO;
	}
}

- (NSData *)imageDataForKey:(NSString *)urlString {
	NSString *path = [self pathForKey:urlString];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		NSData *data = [NSData dataWithContentsOfFile:path];
		if (data) {
			return data;
		}
	}
	return nil;
}

- (UIImage *)imageForKey:(NSString *)urlString {
	NSString *path = [self pathForKey:urlString];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		UIImage *img = [UIImage imageWithContentsOfFile:path];
		if (img) {
			return img;
		}
	}
	return nil;
}

- (void)setImageData:(NSData *)data forKey:(NSString *)urlString {
    NSString *path = [self pathForKey:urlString];
	BOOL b = [data writeToFile:path atomically:YES];
	//assert(b);
	//if (b && diskFreeSize >= 0) {
	//	diskFreeSize -= [data length];
	//}

	if (b && ![keys containsObject:urlString]) {
		[keys addObject:urlString];
		while (self.cacheCount < [keys count]) {
			NSString *k = [keys objectAtIndex:0];
			[[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:k] error:nil];
			[keys removeObject:k];
		}
		[self save];
	}
}

- (void)removeAllCaches {
	if ([[NSFileManager defaultManager] fileExistsAtPath:basePath]) {
		[[NSFileManager defaultManager] removeItemAtPath:basePath error:nil];
		[[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	[keys removeAllObjects];
}

- (void) removeCacheForKey:(NSString *)key {
	if ([self conteinsImageForKey:key]) {
		NSString *path = [self pathForKey:key];
		//int len = [[self imageDataForKey:key] length];
		if ([[NSFileManager defaultManager] removeItemAtPath:path error:nil]) {
			//diskFreeSize += len;
			
			[keys removeObject:key];
			[self save];
		}
	}
}

@end


@implementation ImageMemoryCache

- (id) init {
	self = [super init];
	if (self) {
		storage_ = [[NSMutableDictionary alloc] init];
		keys_ = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[storage_ release];
	[keys_ release];

	[super dealloc];
}

- (BOOL)conteinsImageForKey:(NSString *)key {
	BOOL b;
	@synchronized(self) {
		b = [keys_ containsObject:key];
	}
	return b;
}

- (NSData *)imageDataForKey:(NSString *)key {
	NSData *data;
	@synchronized(self) {
	if ([keys_ containsObject:key]) {
		[keys_ removeObject:key];
		[keys_ addObject:key];
		data = [storage_ objectForKey:key];
	} else {
		data = nil;
	}
	}
	return data;
}

- (UIImage *)imageForKey:(NSString *)key {
	UIImage *img;
	@synchronized(self) {
	if ([keys_ containsObject:key]) {
		[keys_ removeObject:key];
		[keys_ addObject:key];
		img = [storage_ objectForKey:key] ? [UIImage imageWithData:[storage_ objectForKey:key]] : nil;
	} else {
		img = nil;
	}
	}
	return img;
}

- (void)setImageData:(NSData *)data forKey:(NSString *)key {
	if (data) {
		@synchronized(self) {
			[storage_ setObject:data forKey:key];
			[keys_ addObject:key];
			if (self.cacheCount < [keys_ count]) {
				id key = [keys_ objectAtIndex:0];
				[storage_ removeObjectForKey:key];
				[keys_ removeObjectAtIndex:0];
			}
		}
	}
}

- (void)removeAllCaches {	
	@synchronized(self) {
		[storage_ removeAllObjects];
		[keys_ removeAllObjects];
	}
}

@end

