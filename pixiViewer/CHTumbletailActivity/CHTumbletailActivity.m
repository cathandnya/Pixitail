//
//  CHTumbletailActivity.m
//  CHTumbletailActivity
//
//  Created by nya on 2012/10/02.
//  Copyright (c) 2012年 cathand.org. All rights reserved.
//

#import "CHTumbletailActivity.h"


#if __has_feature(objc_arc) && __clang_major__ >= 3
#define ARC_ENABLED
#endif


static NSString *createUrlEncodedString(NSString *str) {
	str = (NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
	if (str) {
		return str;
	}
	return nil;
}


@implementation CHTumbletailActivity

@end


@implementation CHTumbletailActivityPhoto

- (NSString *)activityType {
    return @"TumbletailPhoto";
}

- (NSString *)activityTitle {
    return @"Tumbletail Photo";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"tumbletail_photo"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems{
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tumbletail://"]]) {
		if (activityItems.count == 1) {
			id item = [activityItems objectAtIndex:0];
			return [item isKindOfClass:[UIImage class]];
		}
	}
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	id item = [activityItems objectAtIndex:0];
	[[UIPasteboard generalPasteboard] setImage:item];
	
	[super prepareWithActivityItems:activityItems];
}

- (void)performActivity{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tumbletail://org.cathand.tumbletail/post?type=photo"]];
	
	[self activityDidFinish:YES];
}

@end


@implementation CHTumbletailActivityQuote

- (NSString *)activityType {
    return @"TumbletailQuote";
}

- (NSString *)activityTitle {
    return @"Tumbletail Quote";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"tumbletail_quote"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems{
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tumbletail://"]]) {
		if (activityItems.count == 1) {
			id item = [activityItems objectAtIndex:0];
			return [item isKindOfClass:[NSString class]];
		}
	}
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	id item = [activityItems objectAtIndex:0];
	encodedString = createUrlEncodedString(item);
	
	[super prepareWithActivityItems:activityItems];
}

- (void)performActivity{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tumbletail://org.cathand.tumbletail/post?type=quote&quote=%@", encodedString]]];
#ifndef ARC_ENABLED
	[encodedString release];
#endif
	encodedString = nil;
	
	[self activityDidFinish:YES];
}

@end


@implementation CHTumbletailActivityLink

- (NSString *)activityType {
    return @"TumbletailLink";
}

- (NSString *)activityTitle {
    return @"Tumbletail Link";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"tumbletail_link"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems{
	if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tumbletail://"]]) {
		if (activityItems.count == 1) {
			id item = [activityItems objectAtIndex:0];
			return [item isKindOfClass:[NSString class]] || [item isKindOfClass:[NSURL class]];
		}
	}
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	id item = [activityItems objectAtIndex:0];
	if ([item isKindOfClass:[NSURL class]]) {
		item = [item absoluteString];
	}
	encodedString = createUrlEncodedString(item);
	
	[super prepareWithActivityItems:activityItems];
}

- (void)performActivity{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tumbletail://org.cathand.tumbletail/post?type=link&url=%@", encodedString]]];
#ifndef ARC_ENABLED
	[encodedString release];
#endif
	encodedString = nil;
	
	[self activityDidFinish:YES];
}

@end
