//
//  TumblrLoginParser.m
//  pixiViewer
//
//  Created by nya on 10/05/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrLoginParser.h"


/*
<?xml version="1.0" encoding="UTF-8"?>
<tumblr version="1.0">
  <user default-post-format="html" can-upload-audio="1" can-upload-aiff="1" can-ask-question="1" can-upload-video="1" max-video-bytes-uploaded="26214400"/>
  <tumblelog title="Untitled" is-admin="1" posts="3" name="cathandtest" url="http://cathandtest.tumblr.com/" type="public" followers="0" avatar-url="http://assets.tumblr.com/images/default_avatar_128.gif" is-primary="yes" backup-post-limit="30000"/>
</tumblr>
*/

@implementation TumblrLoginParser

@synthesize name;

- (void) dealloc {
	[name release];

	[super dealloc];
}

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)aname attributes:(NSDictionary *)attributes {
	if ([aname isEqual:@"tumblelog"] && [[attributes objectForKey:@"is-primary"] isEqual:@"yes"]) {
		self.name = [attributes objectForKey:@"name"];
	}
}


- (void) endElementName:(NSString *)name {
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
