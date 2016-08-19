//
//  CHHtmlParser.h
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


struct _xmlParserCtxt;
@interface CHHtmlParser : NSObject {
    struct _xmlParserCtxt	*parser;
	NSStringEncoding		encoding;
	
	BOOL async;
	NSMutableArray *asyncData;
	pthread_t thread;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
	BOOL needsStop;
}

/// 初期化
- (id) initWithEncoding:(NSStringEncoding)enc;
- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b;
- (NSStringEncoding) encoding;

/// データ追加
- (void) addData:(NSData *)data;
- (void) addDataEnd;

/// 以下pure virtual
- (void) startDocument;
- (void) endDocument;
- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes;
- (void) endElementName:(NSString *)name;
- (void) characters:(const unsigned char *)ch length:(int)len;

@end

// member_illust.php?mode=medium&illust_id=5691897
NSDictionary *CHHtmlParserParseParam(NSString *val);

