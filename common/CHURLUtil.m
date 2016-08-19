//
//  CHURLUtil.m
//  Echo
//
//  Created by Naomoto nya on 12/05/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CHURLUtil.h"

@implementation NSString(CHURLUtil)

- (NSString *) urlEncode {
	NSString *str = [(NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR(":/?#[]@!$ &'()*+,;=\"<>%{}|\\^~`"), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)) autorelease];
	if (str) {
		return str;
	}
	return @"";
}

+ (NSString *) stringWithURLParameter:(NSDictionary *)dic {
	NSMutableString *str = [NSMutableString string];
	if ([dic count] > 0) {			
		NSArray *keys = [dic allKeys];
		for (NSString *key in keys) {
			[str appendFormat:@"%@=%@", [key urlEncode], [[dic objectForKey:key] urlEncode]];
			if (key != [keys lastObject]) {
				[str appendString:@"&"];
			}
		}
	}
	return str;
}

+ (NSString *) stringWithURL:(NSString *)urlStr withParameter:(NSDictionary *)dic {
	NSMutableString *str = [NSMutableString stringWithString:urlStr];
	if ([dic count] > 0) {			
		if (![str hasSuffix:@"&"]) {
			if ([str rangeOfString:@"?"].location == NSNotFound) {
				[str appendString:@"?"];			
			} else {
				[str appendString:@"&"];			
			}
		}
		[str appendString:[self stringWithURLParameter:dic]];
	}
	return str;
}

@end


@implementation NSData(CHURLUtil)

+ (void) addValue:(id)val forKey:(NSString *)key toBody:(NSMutableData *)body withBoundary:(NSString *)boundary {
	if ([val isKindOfClass:[NSNumber class]]) {
		val = [val stringValue];
	}
	if ([val isKindOfClass:[NSString class]]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSData class]]) {
		[body appendData:[[NSString stringWithFormat:@"%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"file.jpg\"\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", @"image/jpeg"] dataUsingEncoding:NSUTF8StringEncoding]];
		//DLog(@"tumblr data: %@", [[[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding] autorelease]);
		[body appendData:val];
		[body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([val isKindOfClass:[NSArray class]]) {
		for (id v in val) {
			[self addValue:v forKey:key toBody:body withBoundary:boundary];
		}
	} else {
		assert(0);
	}
}

+ (NSData *) multipartBodyData:(NSDictionary *)dic boundary:(NSString *)boundary {	
	NSMutableData	*body = [NSMutableData data];
	
	if ([dic count] > 0) {			
		NSArray *keys = [[dic allKeys] sortedArrayUsingSelector:@selector(compare:)];
		for (NSString *key in keys) {
			id val = [dic objectForKey:key];
			[self addValue:val forKey:key toBody:body withBoundary:boundary];
		}
	}
	[body appendData:[[NSString stringWithFormat:@"%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return body;
}

+ (NSData *) multipartBodyData:(NSDictionary *)dic {	
	return [self multipartBodyData:dic boundary:[self multipartBoundary]];
}

+ (NSString *) multipartBoundary {
	return @"------------0xKhTmLbOuNdArY";
}

@end
