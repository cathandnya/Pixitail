//
//  RoundedRectView.m
//
//  Created by nya on 11/04/13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RoundedRectView.h"


@implementation RoundedRectView

@synthesize color, radius;

- (void)dealloc {
	self.color = nil;
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect r = rect;
	r.origin = CGPointZero;
	
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextSetLineWidth( context, 0 );
	
	CGContextMoveToPoint( context, CGRectGetMinX( r ), CGRectGetMidY( r ));
	CGContextAddArcToPoint( context, CGRectGetMinX( r ), CGRectGetMinY( r ), CGRectGetMidX( r ), CGRectGetMinY( r ), radius );
	CGContextAddArcToPoint( context, CGRectGetMaxX( r ), CGRectGetMinY( r ), CGRectGetMaxX( r ), CGRectGetMidY( r ), radius );
	CGContextAddArcToPoint( context, CGRectGetMaxX( r ), CGRectGetMaxY( r ), CGRectGetMidX( r ), CGRectGetMaxY( r ), radius );	
	CGContextAddArcToPoint( context, CGRectGetMinX( r ), CGRectGetMaxY( r ), CGRectGetMinX( r ), CGRectGetMidY( r ), radius );
	CGContextClosePath( context );
	CGContextDrawPath( context, kCGPathFill );
}

- (void) setColor:(UIColor *)c {
	if (color != c) {
		[color release];
		color = [c retain];
		
		[self setNeedsDisplay];
	}
}

- (void) setRadius:(CGFloat)r {
	radius = r;
	
	[self setNeedsDisplay];
}

@end
