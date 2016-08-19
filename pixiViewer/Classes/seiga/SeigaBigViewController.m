//
//  SeigaBigViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaBigViewController.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"
#import "Seiga.h"
#import "SeigaConstants.h"
#import "SeigaBigParser.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "SharedAlertView.h"


@interface SeigaBigViewController()
@end


@implementation SeigaBigViewController

- (ImageCache *) cache {
	return [ImageCache danbooruBigCache];
}

- (NSString *) referer {
	return [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_SeigaBig];
	loader.referer = [self referer];
	return loader;
}

- (PixService *) pixiv {
	return [Seiga sharedInstance];
}

- (NSString *) serviceName {
	return NSLocalizedString(@"Seiga", nil);
}

- (NSString *) url {
	return [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.big"], self.illustID];
}

- (Class) mangaClass {
	return nil;
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:[[self pixiv] infoForIllustID:iid]];
	return mdic;
}

- (void) startParser {
	SeigaBigParser			*parser = [[SeigaBigParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[self url]]];
	con.referer = [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	
	[con startWithParser:parser];
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	NSString *url = [parser_ urlString];
	if (url) {
		NSString *host = [[NSURL URLWithString:con.lastUrl] host];
		((SeigaBigParser *)parser_).urlString = [NSString stringWithFormat:@"http://%@%@", host, url];
	}
	[super connection:con finished:err];
}

@end
