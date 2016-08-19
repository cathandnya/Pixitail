//
//  ImageLoaderManager.h
//  Tumbltail
//
//  Created by nya on 10/09/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CHURLImageLoader.h"

//#define USE_REBLOGGED_SOURCE


typedef enum {
	ImageLoaderType_PixivMedium = 0,
	ImageLoaderType_PixivBig,
	ImageLoaderType_PixaMedium,
	ImageLoaderType_PixaBig,
	ImageLoaderType_Tinami,
	ImageLoaderType_Tumblr,
	ImageLoaderType_DanbooruMedium,
	ImageLoaderType_DanbooruBig,
	ImageLoaderType_SeigaMedium,
	ImageLoaderType_SeigaBig,
	
	ImageLoaderType_PixivThumbnail,
	
	ImageLoaderType_Count,
} ImageLoaderType;


@class ImageDiskCache;
@interface ImageLoaderManager : NSObject<CHURLImageLoaderDelegate> {
	NSMutableDictionary *loaders;
	NSMutableDictionary *cache;
	ImageDiskCache *diskCache;
	NSString *referer;
	ImageLoaderType type;
}

@property(readwrite, nonatomic, retain) NSString *referer;
@property(readonly, nonatomic, assign) ImageDiskCache *cache;

+ (ImageLoaderManager *) loaderWithType:(ImageLoaderType)type;
+ (ImageLoaderManager *) loaderWithName:(NSString *)name;
+ (void) clearCache;

- (BOOL) imageIsLoadedForID:(NSString *)idt;
- (BOOL) imageIsLoadingForID:(NSString *)idt;
- (NSInteger) imageLoadingPercentForID:(NSString *)idt;
- (UIImage *) imageForID:(NSString *)idt;
- (long) loadImageForID:(NSString *)idt url:(NSString *)urlString;
- (UIImage *) inMemoryImageForID:(NSString *)idt;
- (NSData *) dataWithID:(NSString *)idt;

- (void) removeImageForID:(NSString *)idt;
- (void) setImage:(UIImage *)img forID:(NSString *)idt;
- (void) clear;
- (void) compact:(NSString *)idt;

- (NSString *) cachePathForID:(NSString *)idt;

- (void) removeAll;

@end
