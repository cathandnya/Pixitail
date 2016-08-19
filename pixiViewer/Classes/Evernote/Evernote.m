//
//  Evernote.m
//  Evernote
//
//  Created by nya on 10/06/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Evernote.h"
#import "EvernoteSDK.h"
#import "CommonCrypto/CommonDigest.h"


#define EVERNOTE_HOST		@"www.evernote.com"
//#define EVERNOTE_HOST		@"sandbox.evernote.com"


@implementation Evernote

@dynamic logined, session, userStore, noteStore;

- (id) initWithConsumerKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if (self) {
		[EvernoteSession setSharedSessionHost:EVERNOTE_HOST consumerKey:key consumerSecret:secret];
    }
    return self;
}

- (void) dealloc {
    [super dealloc];
}

#pragma mark-

- (BOOL) logined {
    return self.session.isAuthenticated;
}

- (EvernoteSession *) session {
	return [EvernoteSession sharedSession];
}

- (EvernoteNoteStore *) noteStore {
	return [EvernoteNoteStore noteStore];
}

- (EvernoteUserStore *) userStore {
	return [EvernoteUserStore userStore];
}

#pragma mark-

- (EDAMNote *) noteWithTitle:(NSString *)title andContent:(NSString *)str forNotebook:(EDAMNotebook *)nb {
    EDAMNote *note = [[[EDAMNote alloc] init] autorelease];
    
    [note setTitle:title];
    [note setNotebookGuid:[nb guid]];
    [note setContent:str];
    [note setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
    
    return note;
}

- (NSString *) MD5DigestString:(NSData *)data {
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
 
	CC_MD5([data bytes], (CC_LONG)[data length], digest);
 
	char md5cstring[CC_MD5_DIGEST_LENGTH*2+1];
 
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
		sprintf(md5cstring+i*2, "%02x", digest[i]);
	}
	md5cstring[CC_MD5_DIGEST_LENGTH*2] = '\0';
 
	//return [NSString stringWithCString:md5cstring length:CC_MD5_DIGEST_LENGTH*2];
	return [NSString stringWithCString:md5cstring encoding:NSASCIIStringEncoding];
}

- (EDAMNote *) noteWithTitle:(NSString *)title andImage:(NSData *)data size:(CGSize)size forNotebook:(EDAMNotebook *)nb {	
	static const char pngBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
	NSData *png = [NSData dataWithBytes:pngBytes length:8];
	static const char gifBytes[3] = {0x47, 0x49, 0x46};
	NSData *gif = [NSData dataWithBytes:gifBytes length:3];
	
	NSString *mime = nil;
	if ([[data subdataWithRange:NSMakeRange(0, 8)] isEqualToData:png]) {
		mime = @"image/png";
	} else if ([[data subdataWithRange:NSMakeRange(0, 3)] isEqualToData:gif]) {
		mime = @"image/gif";
	} else {
		mime = @"image/jpeg";
	}
	
	EDAMData *edata = [[[EDAMData alloc] init] autorelease];
	edata.size = (int)[data length];
	edata.body = data;
	//edata.bodyHash = [self MD5DigestString:data];
	
	EDAMResource *res = [[[EDAMResource alloc] init] autorelease];
	res.data = edata;
	res.mime = mime;
	if (!CGSizeEqualToSize(CGSizeZero, size)) {
		res.width = size.width;
		res.height = size.height;
	}
	
	EDAMNote *note = [[[EDAMNote alloc] init] autorelease];
    [note setTitle:title];
    [note setNotebookGuid:[nb guid]];
	[note setResources:[NSArray arrayWithObject:res]];

    NSMutableString* contentString = [[[NSMutableString alloc] init] autorelease];
    [contentString setString:	@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    [contentString appendString:@"<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml.dtd\">"];
    [contentString appendString:@"<en-note>"];
    
    [contentString appendFormat:@"<en-media type=\"%@\" hash=\"%@\"/>", mime, [self MD5DigestString:data]];

    [contentString appendString:@"</en-note>"];
    [note setContent:contentString];
    [note setCreated:(long long)[[NSDate date] timeIntervalSince1970] * 1000];
	
	return note;
}

#pragma mark-

+ (NSString *) contentWithHTML:(NSString *)str {
    NSMutableString* contentString = [[[NSMutableString alloc] init] autorelease];
    [contentString setString:	@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"];
    [contentString appendString:@"<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml.dtd\">"];
    [contentString appendString:@"<en-note>"];
    
    // TODO html -> enml
    [contentString appendString:str];

    [contentString appendString:@"</en-note>"];
    return contentString;
}

@end
