//
//  CHXmlParser.m
//  pixiViewer
//
//  Created by nya on 10/01/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CHXmlParser.h"
#import <libxml/parser.h>


extern xmlSAXHandler saxHandler_;


@implementation CHXmlParser

- (void) createParser:(xmlCharEncoding)xmlEnc {
	parser = xmlCreatePushParserCtxt(
		&saxHandler_,
		self,
		NULL,
		0,
		nil
	);
}

- (void) parse:(const char *)buf len:(int)len end:(BOOL)b {
	xmlParseChunk(
		parser,
		buf,
		len,
		b
	);
}

- (void) disposeParser {
	xmlFreeParserCtxt(parser);
}

@end
