//
//  Entry.m
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import "Entry.h"

@implementation Entry

@dynamic info;

- (id) initWithInfo:(NSDictionary *)info {
	self = [super init];
	if (self) {
		self.illust_id = info[@"illust_id"];
		self.thumbnail_url = info[@"thumbnail_url"];
		self.service_name = info[@"service_name"];
		self.other_info = info[@"other_info"];
	}
	return self;
}

- (NSDictionary *) info {
	NSMutableDictionary *mdic = [@{
			 @"illust_id": self.illust_id,
			 @"thumbnail_url": self.thumbnail_url,
			 @"service_name": self.service_name
			 } mutableCopy];
	if (self.other_info) {
		mdic[@"other_info"] = self.other_info;
	}
	return mdic;
}

@end
