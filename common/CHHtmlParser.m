//
//  CHHtmlParser.m
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CHHtmlParser.h"
#import <libxml/HTMLparser.h>
#import <pthread.h>


static void startDocumentSAXProc(void *ctx) {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    [(CHHtmlParser*)ctx startDocument];
	[pool release];
}

static void endDocumentSAXProc(void *ctx) {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    [(CHHtmlParser*)ctx endDocument];
	[pool release];
}

static void startElementSAXProc(void *ctx, const xmlChar *nameChar, const xmlChar **atts) {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSString			*name = [NSString stringWithCString:(const char *)nameChar encoding:NSUTF8StringEncoding];
	NSMutableDictionary	*attr = [NSMutableDictionary dictionary];
	
	const xmlChar		**ptr = atts;
	while (ptr && *ptr) {
		if (ptr[1]) {
			NSString	*key = [NSString stringWithCString:(const char *)ptr[0] encoding:[(CHHtmlParser *)ctx encoding]];
			NSString	*val = [NSString stringWithCString:(const char *)ptr[1] encoding:[(CHHtmlParser *)ctx encoding]];
			//DLog(@"startElementSAXProc: [%@], [%@]", key, val);
			if (val && key) {
				[attr setObject:val forKey:key];
			}
			ptr += 2;
		} else {
			ptr++;
		}
	}

    [(CHHtmlParser*)ctx startElementName:name attributes:attr];
	[pool release];
}

static void endElementSAXProc(void *ctx, const xmlChar *nameChar) {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	NSString			*name = [NSString stringWithCString:(const char *)nameChar encoding:NSUTF8StringEncoding];
    [(CHHtmlParser*)ctx endElementName:name];
	[pool release];
}

static void charactersSAXProc(void *ctx, const xmlChar *ch, int len) {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    [(CHHtmlParser*)ctx characters:ch length:len];
	[pool release];
}

// SAXハンドラを設定
xmlSAXHandler saxHandler_ = {
.initialized    = XML_SAX2_MAGIC,
.startDocument	= startDocumentSAXProc,
.endDocument	= endDocumentSAXProc,
.startElement   = startElementSAXProc,
.endElement		= endElementSAXProc,
.characters		= charactersSAXProc
};


@interface CHHtmlParser(Private)
- (void *) addDataThread;
@end


static void *addDataThread(void *obj) {
	return [(CHHtmlParser *)obj addDataThread];
}


@implementation CHHtmlParser

- (void) createParser:(xmlCharEncoding)xmlEnc {
	parser = htmlCreatePushParserCtxt(
		&saxHandler_,
		self,
		NULL,
		0,
		nil,
		xmlEnc
	);
}

- (void) parse:(const char *)buf len:(int)len end:(BOOL)b {
	//DLog(@"parse: %@", [[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:buf length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]);
	htmlParseChunk(
		parser,
		buf,
		len,
		b
	);
}

- (void) disposeParser {
	htmlFreeParserCtxt(parser);
	parser = NULL;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super init];
	if (self) {	
		xmlCharEncoding	xmlEnc = XML_CHAR_ENCODING_ERROR;;
		switch (enc) {
		case NSASCIIStringEncoding:
			xmlEnc = XML_CHAR_ENCODING_ASCII;
			break;
    	case NSJapaneseEUCStringEncoding:
			xmlEnc = XML_CHAR_ENCODING_EUC_JP;
			break;
    	case NSUTF8StringEncoding:
			xmlEnc = XML_CHAR_ENCODING_UTF8;
			break;
    	case NSShiftJISStringEncoding:
			xmlEnc = XML_CHAR_ENCODING_SHIFT_JIS;
			break;
    	case NSISO2022JPStringEncoding:
			xmlEnc = XML_CHAR_ENCODING_2022_JP;
			break;
    	case NSUTF16BigEndianStringEncoding:
			xmlEnc = XML_CHAR_ENCODING_UTF16BE;
			break;
    	case NSUTF16LittleEndianStringEncoding:
			xmlEnc = XML_CHAR_ENCODING_UTF16LE;
			break;
    	case NSNEXTSTEPStringEncoding:
    	case NSUnicodeStringEncoding:
    	case NSISOLatin2StringEncoding:
    	case NSISOLatin1StringEncoding:
    	case NSSymbolStringEncoding:
    	case NSNonLossyASCIIStringEncoding:
    	//case NSUTF16StringEncoding:   
    	case NSWindowsCP1251StringEncoding:
    	case NSWindowsCP1252StringEncoding:
    	case NSWindowsCP1253StringEncoding:
    	case NSWindowsCP1254StringEncoding:
    	case NSWindowsCP1250StringEncoding:
    	case NSMacOSRomanStringEncoding:
    	case NSUTF32StringEncoding:                  
    	case NSUTF32BigEndianStringEncoding:
    	case NSUTF32LittleEndianStringEncoding:
		default:
			[self release];
			return nil;
		}
		
		encoding = enc;
		[self createParser:xmlEnc];
		if (parser == nil) {
			[self release];
			return nil;
		}
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [self initWithEncoding:enc];
	if (self) {
		async = b;
		if (async) {
			asyncData = [[NSMutableArray alloc] init];
			pthread_mutex_init(&mutex, NULL);
			pthread_cond_init(&cond, NULL);
			
			pthread_create(&thread, NULL, addDataThread, self);
		}
	}
	return self;
}

- (NSStringEncoding) encoding {
	return encoding;
}

- (void) dealloc {
	if (async) {
		pthread_mutex_lock(&mutex);
		needsStop = YES;
		pthread_cond_signal(&cond);
		pthread_mutex_unlock(&mutex);
		
		void *ret;
		pthread_join(thread, &ret);
		
		pthread_mutex_destroy(&mutex);
		pthread_cond_destroy(&cond);
		
		[asyncData release];
	}
	
	if (parser) {
		//[self parse:NULL len:0 end:YES];
		[self disposeParser];
	}
	
	[super dealloc];
}

- (void) addData:(NSData *)data {
	if (async) {
		pthread_mutex_lock(&mutex);
		[asyncData addObject:data];
		pthread_cond_signal(&cond);
		pthread_mutex_unlock(&mutex);
	} else {
		[self parse:[data bytes] len:(int)[data length] end:NO];
	}
}

- (void) addDataEnd {
	if (async) {
		pthread_mutex_lock(&mutex);
		[asyncData addObject:[NSData data]];
		pthread_cond_signal(&cond);
		pthread_mutex_unlock(&mutex);
	} else if (parser) {
		[self parse:NULL len:0 end:YES];
	}
}

- (void *) addDataThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	while (1) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		NSData *data;
		
		pthread_mutex_lock(&mutex);
		while ([asyncData count] == 0 && needsStop == NO) {
			pthread_cond_wait(&cond, &mutex);
		}
		if (needsStop) {
			pthread_mutex_unlock(&mutex);
			[pool2 release];
			break;
		} else if ([asyncData count] > 0) {
			data = [[[asyncData objectAtIndex:0] retain] autorelease];
		} else {
			assert(0);
		}
		[asyncData removeObjectAtIndex:0];
		pthread_mutex_unlock(&mutex);
		
		if ([data length] > 0) {
			[self parse:[data bytes] len:(int)[data length] end:[data length] == 0];
		} else {
			[self parse:NULL len:0 end:YES];
		}
		//pthread_mutex_unlock(&mutex);

		[pool2 release];
	}
	[pool release];
	return NULL;
}

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
}

- (void) endElementName:(NSString *)name {
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end


NSDictionary *CHHtmlParserParseParam(NSString *val) {
	NSMutableDictionary		*info = [NSMutableDictionary dictionary];
	NSArray					*ary = [val componentsSeparatedByString:@"&"];
	
	for (NSString *str in ary) {
		NSArray *ary2 = [str componentsSeparatedByString:@"="];
		if ([ary2 count] == 2) {
			[info setObject:[ary2 objectAtIndex:1] forKey:[ary2 objectAtIndex:0]];
		}
	}
	
	return info;
}
