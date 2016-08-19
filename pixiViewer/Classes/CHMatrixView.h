//
//  CHMatrixView.h
//  pixiViewer
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ImageCache;


@class CHMatrixView;
@protocol CHMatrixViewDeleagate
- (void) matrixView:(CHMatrixView *)view action:(id)senderObject;
- (void) matrixView:(CHMatrixView *)view loadNext:(id)senderObject;
- (ImageCache *) matrixViewGetCache:(CHMatrixView *)view;

- (void) matrixViewBeginLayout:(CHMatrixView *)view;
- (void) matrixViewEndLayout:(CHMatrixView *)view;

- (NSArray *) matrixViewContents:(CHMatrixView *)view;
- (BOOL) matrixViewShowsNextButton:(CHMatrixView *)view;
@end


@interface CHMatrixView : UIScrollView {
	UIButton		*loadNextButton_;
	id<CHMatrixViewDeleagate> matrixDelegate;
	CGFloat			topMargin;
	NSString		*referer;
	int				columnCount;
}

@property(assign, readwrite, nonatomic) id<CHMatrixViewDeleagate> matrixDelegate;
@property(assign, readonly, nonatomic) UIImage *topImage;
@property(assign, readwrite, nonatomic) CGFloat topMargin;
@property(retain, readwrite, nonatomic) NSString *referer;
@property(assign, readwrite, nonatomic) int columnCount;

//- (id) initWithFrame:(CGRect)frame;

- (void) addContent:(NSDictionary *)info;
- (void) addContents:(NSArray *)ary;
- (void) removeAllContents;
- (void) garbgeCollect;
- (void) layout;

- (void) setShowsLoadNextButton:(BOOL)b;

- (int) count;
- (int) indexOfIllustID:(NSString *)iid;
- (NSDictionary *) infoAtIndex:(int)idx;

@end
