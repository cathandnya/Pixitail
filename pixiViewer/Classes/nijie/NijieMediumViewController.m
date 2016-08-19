//
//  NijieMediumViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/06/23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NijieMediumViewController.h"
#import "NijieMediumParser.h"
#import "ScrapingMetadata.h"
#import "ScrapingConstants.h"
#import "ScrapingService.h"

@interface NijieMediumViewController ()

@end

@implementation NijieMediumViewController

- (BOOL) noRedirect {
	return NO;
}

- (id) parser {
	NijieMediumParser *parser = [[NijieMediumParser alloc] initWithEncoding:NSUTF8StringEncoding];
	parser.scrapingInfo = [self.service.constants valueForKey:@"medium"];
	parser.illustID = self.illustID;
	return [parser autorelease];
}

- (void) rating:(id)sender {
	[[self service] rating:1 withInfo:info_];
}

@end
