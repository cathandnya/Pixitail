//
//
//  Created by Naomoto nya on 12/02/07.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>


const static char CRYPTO_KEY[] = {57, -83, 6, 53, 6, 118, -55, -29, 65, -7, 50, 31, 98, 120, -36, 88, 0};


@interface NSData(Crypto)

- (NSData *) aesDecryptWithKey:(const char *)keyPtr;
- (NSData *) aesEncryptWithKey:(const char *)keyPtr;
+ (NSData *) dataWithHexString:(NSString*)hexString;
- (NSString *) hexString;

@end


@interface NSString(Crypto)

- (NSString *) cryptedString;
- (NSString *) decryptedString;

@end
