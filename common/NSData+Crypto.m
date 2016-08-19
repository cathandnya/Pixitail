//
//
//  Created by Naomoto nya on 12/02/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NSData+Crypto.h"


@implementation NSData (Crypto)

@class NSString; 

- (NSData *) aesEncryptWithKey:(const char *)keyPtr {
    NSUInteger dataLength = [self length];
	
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
	
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

- (NSData *) aesDecryptWithKey:(const char *)keyPtr {
    NSUInteger dataLength = [self length];
	
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
	
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding | kCCOptionECBMode,
                                          keyPtr, kCCBlockSizeAES128,
                                          NULL,
                                          [self bytes], dataLength,
                                          buffer, bufferSize,
                                          &numBytesDecrypted);
	
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

+ (NSData*) dataWithHexString:(NSString*)hexString {
    if (hexString == nil) {
        return nil;
    }
    
    const char* ch = [[hexString lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* data = [NSMutableData data];
    while (*ch) {
        char byte = 0;
        if ('0' <= *ch && *ch <= '9') {
            byte = *ch - '0';
        } else if ('a' <= *ch && *ch <= 'f') {
            byte = *ch - 'a' + 10;
        }
        ch++;
        byte = byte << 4;
        if (*ch) {
            if ('0' <= *ch && *ch <= '9') {
                byte += *ch - '0';
            } else if ('a' <= *ch && *ch <= 'f') {
                byte += *ch - 'a' + 10;
            }
            ch++;
        }
        [data appendBytes:&byte length:1];
    }
    return data;
}

- (NSString *) hexString {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
	
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
	
    if (!dataBuffer)
        return [NSString string];
	
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
	
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
	
    return [NSString stringWithString:hexString];
}

@end


@implementation NSString(Crypto)

- (NSString *) cryptedString {
	if (self.length > 0) {
		NSString *str = [[[self dataUsingEncoding:NSUTF8StringEncoding] aesEncryptWithKey:CRYPTO_KEY] hexString];
		DLog(@"crypto: %@ -> %@", self, str);
		return str;
	} else {
		return @"";
	}
}

- (NSString *) decryptedString {
	if (self.length > 0) {
		NSString *str = [[[NSString alloc] initWithData:[[NSData dataWithHexString:self] aesDecryptWithKey:CRYPTO_KEY] encoding:NSUTF8StringEncoding] autorelease];
		DLog(@"decrypto: %@ -> %@", self, str);
		return str;
	} else {
		return @"";
	}
}

@end

