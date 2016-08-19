//
//  CHMatrixView.m
//  pixiViewer
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHMatrixView.h"
#import "CHURLImageView.h"


@implementation CHMatrixView

@synthesize matrixDelegate;
@synthesize topMargin;
@synthesize referer;
@synthesize columnCount;


- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		columnCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"MatrixViewColumnCount"];
		if (columnCount < 2 || 4 < columnCount) {
			columnCount = 4;
		}
	}
	return self;
}

- (void) dealloc {
	for (CHURLImageView *imgView in self.subviews) {
		if ([imgView isKindOfClass:[CHURLImageView class]]) {
			[imgView cancel];
		}
	}

	if (loadNextButton_) {
		[loadNextButton_ removeFromSuperview];
		[loadNextButton_ release];
	}
	loadNextButton_ = nil;
	
	self.referer = nil;

	[super dealloc];
}


- (NSInteger) count {
	return [[self.matrixDelegate matrixViewContents:self] count];
}

- (id) objectAtIndex:(NSInteger)idx {
	if (idx < [[self.matrixDelegate matrixViewContents:self] count]) {
		return [[self.matrixDelegate matrixViewContents:self] objectAtIndex:idx];
	} else {
		return nil;
	}
}

- (CGFloat) imageWidth {
	switch (self.columnCount) {
	case 4:
		return 75;
	case 3:
		return 100;
	case 2:
		return 150;
	default:
		assert(0);
		return 75;
	}
}

- (CGFloat) imageHeight {
	return [self imageWidth];
}

- (float) columnSpacing {
	switch (self.columnCount) {
	case 4:
		return 5;
	case 3:
		return 5;
	case 2:
		return 6;
	default:
		assert(0);
		return 5;
	}
}

- (float) columnSpacingEdge {
	switch (self.columnCount) {
	case 4:
	case 3:
	default:
		return [self columnSpacing];
	case 2:
		return 7;
	}
}

- (float) width {
	return self.frame.size.width;
}

- (int) rowCount {
	return ([self count] - 1) / self.columnCount + 1;
}

- (float) rowSpacing {
	return [self columnSpacing];//(self.frame.size.height - [self imageHeight] * [self rowCount]) / ([self rowCount] + 1);
}

- (float) height {
	return [self imageHeight] * [self rowCount] + [self rowSpacing] * ([self rowCount] + 1) + 44 + self.topMargin;
}

- (UIImage *) topImage {
	UIImage		*img = nil;
	for (CHURLImageView *view in [self subviews]) {
		if ([view isKindOfClass:[CHURLImageView class]]) {
			img = [view imageForState:UIControlStateNormal];
			if (img) {
				break;
			}
		}
	}
	return img;
}


- (void) garbgeCollect {
	CGRect	selfFrame = self.frame;//CGRectInset(self.frame, 0.0, self.frame.size.height);
	selfFrame.origin.y -= selfFrame.size.height;
	selfFrame.size.height *= 2;
	for (CHURLImageView *view in self.subviews) {
		if ([view isKindOfClass:[CHURLImageView class]]) {
			if (CGRectIntersectsRect(selfFrame, view.frame)) {
				[view setNeedsDisplay];
			} else {
				[view clear];
			}
		}
	}
}


- (void) cellAction:(id)sender {
	[matrixDelegate matrixView:self action:((CHURLImageView *)sender).object];
}

- (void) layoutContent:(NSDictionary *)info atIndex:(int)idx {
	CHURLImageView		*view;
	CGRect				frame;
	int		col;
	int		x, y;
	
	col = self.columnCount;
	
	[[NSUserDefaults standardUserDefaults] setInteger:col forKey:@"MatrixViewColumnCount"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	x = idx % col;
	y = idx / col;
				
	frame.origin.x = [self columnSpacing] + x * ([self imageWidth] + [self columnSpacing]);
	frame.origin.y = /*[self height] -*/ ([self rowSpacing] + y * ([self imageHeight] + [self rowSpacing])) + self.topMargin;
	frame.size = CGSizeMake([self imageWidth], [self imageHeight]);
				
	view = [[CHURLImageView alloc] initWithFrame:frame];
	if (self.columnCount == 2) {
		view.imagePosition = CHURLImageViewImagePosition_MaxCenter;
	} else {
		view.imagePosition = CHURLImageViewImagePosition_Fill;
	}
	view.object = info;
	view.referer = self.referer;
	view.cache = [self.matrixDelegate matrixViewGetCache:self];
	view.urlString = [info objectForKey:@"ThumbnailURLString"];
	[view addTarget:self action:@selector(cellAction:) forControlEvents:UIControlEventTouchUpInside];
	[self addSubview:view];
	[view setNeedsDisplay];
	[view release];
}

- (void) addContent:(NSDictionary *)info {
	// content size
	self.contentSize = CGSizeMake([self width], [self height] + 35);
	
	[self layoutContent:info atIndex:[self count] - 1];
}

- (void) addContents:(NSArray *)ary {
	// content size
	int row = ([self count] + [ary count] - 1) / self.columnCount + 1;
	int height = [self imageHeight] * row + [self rowSpacing] * (row + 1) + 44 + self.topMargin;

	self.contentSize = CGSizeMake([self width], height + 35);
	
	int idx = [self count];
	for (NSDictionary *info in ary) {
		[self layoutContent:info atIndex:idx++];
	}
}

- (void) layoutDelay {
	int idx = 0;

	self.contentSize = CGSizeMake([self width], [self height] + 35);

	for (NSDictionary *info in [self.matrixDelegate matrixViewContents:self]) {
		[self layoutContent:info atIndex:idx++];
	}

	if (loadNextButton_) {
		[loadNextButton_ release];
		loadNextButton_ = nil;
		[self setShowsLoadNextButton:YES];
	}

	[self.matrixDelegate matrixViewEndLayout:self];
}

- (void) layout {	
	[self.matrixDelegate matrixViewBeginLayout:self];

	for (UIView *view in self.subviews) {
		[view removeFromSuperview];
	}
	
	[self performSelector:@selector(layoutDelay) withObject:nil afterDelay:0.0];
}

- (void) removeAllContents {
	for (UIView *view in self.subviews) {
		[view removeFromSuperview];
	}
}

- (void) loadNext:(id)sender {
	[matrixDelegate matrixView:self loadNext:sender];
}

- (void) setShowsLoadNextButton:(BOOL)b {
	if (b && !loadNextButton_) {
		CGRect	frame;
		
		frame.origin.x = [self columnSpacing];
		frame.origin.y = [self height] + [self columnSpacing] - 44;
		frame.size.width = [self width] - [self columnSpacing] * 2;
		frame.size.height = 35;
		
		loadNextButton_ = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
		loadNextButton_.frame = frame;
		[loadNextButton_ setTitle:NSLocalizedString(@"Load next illist...", nil) forState:UIControlStateNormal];
		[loadNextButton_ addTarget:self action:@selector(loadNext:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:loadNextButton_];
		
		self.contentSize = CGSizeMake([self width], [self height] + [loadNextButton_ frame].size.height + [self rowSpacing] * 2);
	} else if (!b && loadNextButton_) {
		[loadNextButton_ removeFromSuperview];
		[loadNextButton_ release];
		loadNextButton_ = nil;
		
		//self.contentSize = CGSizeMake([self width], [self height]);
	}
}

- (int) indexOfIllustID:(NSString *)iid {
	NSDictionary	*tmp = nil;
	for (NSDictionary *info in [self.matrixDelegate matrixViewContents:self]) {
		if ([iid isEqualToString:[info objectForKey:@"IllustID"]]) {
			tmp = info;
			break;
		}
	}
	if (tmp) {
		return [[self.matrixDelegate matrixViewContents:self] indexOfObject:tmp];
	} else {
		return -1;
	}
}

- (NSDictionary *) infoAtIndex:(int)idx {
	if (0 <= idx && idx < [self count]) {
		return [[self.matrixDelegate matrixViewContents:self] objectAtIndex:idx];
	} else {
		return nil;
	}
}

@end
