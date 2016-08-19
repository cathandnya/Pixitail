//
//  Evernote.h
//  Evernote
//
//  Created by nya on 10/06/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class EvernoteSession;
@class EvernoteNoteStore;
@class EvernoteUserStore;
@class EDAMNote;
@class EDAMNotebook;


@interface Evernote : NSObject {
}

@property(readonly, nonatomic, assign) BOOL logined;
@property(readonly, nonatomic, assign) EvernoteSession *session;
@property(readonly, nonatomic, assign) EvernoteNoteStore *noteStore;
@property(readonly, nonatomic, assign) EvernoteUserStore *userStore;

- (id) initWithConsumerKey:(NSString *)key andSecret:(NSString *)secret;

- (EDAMNote *) noteWithTitle:(NSString *)title andContent:(NSString *)str forNotebook:(EDAMNotebook *)nb;
- (EDAMNote *) noteWithTitle:(NSString *)title andImage:(NSData *)data size:(CGSize)size forNotebook:(EDAMNotebook *)nb;

+ (NSString *) contentWithHTML:(NSString *)str;

@end


/*
    login -> loginFinished:(NSError *)err
*/
