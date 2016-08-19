//
//  UnzipFile.m
//
//  Created by nya on 10/08/17.
//  Copyright 2010 Cores. All rights reserved.
//

#import "UnzipFile.h"
#import "unzip.h"


@interface UnzipFile()
@property(assign) BOOL cancelFlag;
@end


@implementation UnzipFile

@synthesize password;

- (id) initWithPath:(NSString *)str {
	self = [super init];
	if (self) {
		path = str;
	}
	return self;
}

- (void) dealloc {
}

- (unzFile) openFile {
	return unzOpen([path UTF8String]);
}

- (NSArray *) files {
	unzFile file = [self openFile];
	if (file == NULL) {
		return nil;
	}
	
	NSMutableArray *ary = [NSMutableArray array];
	int err = UNZ_OK;
	
	err = unzGoToFirstFile(file);
	if (err != UNZ_OK) {
		goto bail;
	}
	
	unz_file_info info;
	char nameBuf[1024];
	do {
		err = unzGetCurrentFileInfo(file, &info, nameBuf, 1023, NULL, 0, NULL, 0);
		if (err != UNZ_OK) {
			goto bail;
		}
		
		NSData *data = [NSData dataWithBytes:nameBuf length:strlen(nameBuf) + 1];
		if (data) {
			[ary addObject:data];
		}
		
		err = unzGoToNextFile(file);
		if (err == UNZ_END_OF_LIST_OF_FILE) {
			err = UNZ_OK;
			break;
		} else if (err != UNZ_OK) {
			goto bail;
		}
	} while (1);
	
bail:
	unzClose(file);
	if (err != UNZ_OK) {
		return nil;
	} else {
		return ary;
	}
}

- (BOOL) contentNeedsPassword:(NSData *)cstring {
	BOOL hasPassword = NO;
	
	unzFile file = [self openFile];
	if (file == NULL) {
		return NO;
	}
	
	NSMutableData *data = nil;
	int err = UNZ_OK;
	err = unzLocateFile(file, [cstring bytes], 1);
	if (err != UNZ_OK) {
		goto bail;
	}
	
	err = unzOpenCurrentFile(file);
	if (err != UNZ_OK) {
		goto bail;
	}
	
	int len = 1;
	data = [NSMutableData dataWithLength:len];
	char *buf = [data mutableBytes];
	err = unzReadCurrentFile(file, buf, len);
	hasPassword = (err == -3);

bail:
	if (data) {
		unzCloseCurrentFile(file);
	}
	unzClose(file);
	return hasPassword;
}

- (BOOL) contentPasswordIsValid:(NSData *)cstring password:(NSData *)pass {
	BOOL isValid = NO;
	
	unzFile file = [self openFile];
	if (file == NULL) {
		return NO;
	}
	
	NSMutableData *data = nil;
	int err = UNZ_OK;
	err = unzLocateFile(file, [cstring bytes], 1);
	if (err != UNZ_OK) {
		goto bail;
	}
	
	const char *passData = [pass bytes];
	err = unzOpenCurrentFilePassword(file, passData);
	if (err != UNZ_OK) {
		goto bail;
	}
	
	int len = 1;
	data = [NSMutableData dataWithLength:len];
	char *buf = [data mutableBytes];
	err = unzReadCurrentFile(file, buf, len);
	isValid = (err > 0);
	
bail:
	if (data) {
		unzCloseCurrentFile(file);
	}
	unzClose(file);
	return isValid;
}

- (NSData *) contentWithFilename:(NSData *)cstring {
	self.cancelFlag = NO;
	
	unzFile file = [self openFile];
	if (file == NULL) {
		return nil;
	}
	
	NSMutableData *data = nil;
	int err = UNZ_OK;
	err = unzLocateFile(file, [cstring bytes], 1);
	//err = unzGoToFirstFile(file);
	if (err != UNZ_OK) {
		goto bail;
	}
	
	if (self.password) {
		const char *pass = [password bytes];
		err = unzOpenCurrentFilePassword(file, pass);
	} else {
		err = unzOpenCurrentFile(file);
	}
	if (err != UNZ_OK) {
		goto bail;
	}
	
	int len = 1024 * 1024;
	data = [NSMutableData dataWithLength:len];
	char *buf = [data mutableBytes];
	do {
		err = unzReadCurrentFile(file, buf, len);
		if (self.cancelFlag) {
			err = -1;
			goto bail;
		}
		
		if (err == 0) {
			break;
		} else if (err > 0) {
			buf += err;
			len -= err;
			if (len == 0) {
				// 足りない
				len = (int)[data length];
				[data setLength:2 * [data length]];
				buf = (char *)[data mutableBytes] + len;
			}
		} else if (err != UNZ_OK) {
			goto bail;
		}
	} while (1);
	[data setLength:[data length] - len];

bail:
	if (data) {
		unzCloseCurrentFile(file);
	}
	unzClose(file);
	if (err != UNZ_OK) {
		return nil;
	} else {
		return data;
	}
}

- (void) cancelLoadContent {
	self.cancelFlag = YES;
}

@end
