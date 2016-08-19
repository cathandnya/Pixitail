//
//  ImageDiskCache.h
//
//  Created by nya on 09/12/04.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageCache : NSObject {
	//long long diskFreeSize;
	NSUInteger cacheCount;
	NSMutableArray *keys;
}

@property(readwrite, assign) NSUInteger cacheCount;

+ (ImageCache *)pixivSmallCache;
+ (ImageCache *)pixivMediumCache;
+ (ImageCache *)pixivBigCache;

+ (ImageCache *)pixaSmallCache;
+ (ImageCache *)pixaMediumCache;
+ (ImageCache *)pixaBigCache;

+ (ImageCache *)tumblrSmallCache;
+ (ImageCache *)tumblrMediumCache;
+ (ImageCache *)tumblrBigCache;

+ (ImageCache *)tinamiSmallCache;
+ (ImageCache *)tinamiMediumCache;
+ (ImageCache *)tinamiBigCache;

+ (ImageCache *)danbooruSmallCache;
+ (ImageCache *)danbooruMediumCache;
+ (ImageCache *)danbooruBigCache;

+ (ImageCache *)seigaSmallCache;
+ (ImageCache *)seigaMediumCache;
+ (ImageCache *)seigaBigCache;

+ (ImageCache *) smallCacheForName:(NSString *)name;
+ (ImageCache *) mediumCacheForName:(NSString *)name;
+ (ImageCache *) bigCacheForName:(NSString *)name;

+ (void) cleanUp;
+ (void) cleanUp:(id)handler;
+ (void) cleanUpOld;
+ (void) cleanUpOld:(id)handler;
+ (BOOL) needsCleanUp;

- (BOOL)conteinsImageForKey:(NSString *)key;
- (NSData *)imageDataForKey:(NSString *)key;
- (UIImage *)imageForKey:(NSString *)key;
- (void)setImageData:(NSData *)data forKey:(NSString *)key;
- (BOOL)isGifPng:(NSString *)key;

- (void)removeAllCaches;
+ (void) removeAllCache;

@end


@interface ImageDiskCache : ImageCache {
	NSString *basePath;
}

- (id) initWithDirectory:(NSString *)path;
//- (long long) freeSize;
- (void) removeCacheForKey:(NSString *)key;

- (NSString *) pathForKey:(NSString *)key;

@end


@interface ImageMemoryCache : ImageCache {
	NSMutableDictionary *storage_;
	NSMutableArray *keys_;
}

@end

