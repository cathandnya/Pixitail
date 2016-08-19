//
//  PixaBigViewController.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaBigViewController.h"
#import "PixaBigParser.h"
#import "Pixa.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"


@implementation PixaBigViewController

- (ImageCache *) cache {
	return [ImageCache pixaBigCache];
}

- (void) startParser {
	PixaBigParser			*parser = [[PixaBigParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show_original/%@", self.illustID]]];
		
	//con.referer = @"http://www.pixiv.net/";
	con.referer = [NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
}

- (NSString *) referer {
	return @"http://www.pixa.cc/";
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_PixaBig];
	loader.referer = [self referer];
	return loader;
}

- (PixService *) pixiv {
	return [Pixa sharedInstance];
}

- (NSString *) serviceName {
	return @"PiXA";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID];
}

@end
