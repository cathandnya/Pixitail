//
//  PixivUgoIllust.h
//  pixiViewer
//
//  Created by nya on 2014/06/30.
//
//

#import <Foundation/Foundation.h>


@protocol PixivUgoIllustDelegate <NSObject>
- (void) ugoIllustLoaded:(id)sender error:(NSError *)err;
@end


@interface PixivUgoIllust : NSObject

@property(readonly) UIImage *firstImage;
@property(readonly) BOOL isLoaded;
@property(readonly) NSData *zipData;
@property(readonly) NSData *gifData;
@property(readonly) NSData *gifDataForTumblr;
@property(weak) id<PixivUgoIllustDelegate> delegate;

- (id) initWithInfo:(NSDictionary *)info;
- (void) load;

@end


@protocol PixivUgoIllustPlayerDelegate <NSObject>
- (void) frameChanged:(id)sender image:(UIImage *)image;
@end


@interface PixivUgoIllustPlayer : NSObject

- (id) initWithUgoIllust:(PixivUgoIllust *)ui;

@property(strong) PixivUgoIllust *ugoIllust;
@property(weak) id<PixivUgoIllustPlayerDelegate> delegate;
@property(assign) BOOL repeat;
@property(readonly) BOOL isPlaying;
- (void) play;
- (void) stop;

@end
