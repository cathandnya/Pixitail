//
//  Constants.h
//  pixiViewer
//
//  Created by nya on 8/18/16.
//
//

#ifndef Constants_h
#define Constants_h

// admob
#ifdef PIXITAIL
    #define ADMOB_UNIT_ID       @""
#else
    #define ADMOB_UNIT_ID       @""
#endif
#define DISABLE_AD              ([ADMOB_UNIT_ID length] == 0)

// dropbox
#ifdef PIXITAIL
    #define DROPBOX_CONSUMER_KEY		@""
    #define DROPBOX_CONSUMER_SECRET		@""
#else
    #define DROPBOX_CONSUMER_KEY		@""
    #define DROPBOX_CONSUMER_SECRET		@""
#endif
#define DISABLE_DROPBOX                 ([DROPBOX_CONSUMER_KEY length] == 0)

// evernote
#ifdef PIXITAIL
    #define EVERNOTE_CONSUMER_KEY		@""
    #define EVERNOTE_CONSUMER_SECRET	@""
    #define EVERNOTE_NOTE_NAME			@"Pixitail"
#else
    #define EVERNOTE_CONSUMER_KEY		@""
    #define EVERNOTE_CONSUMER_SECRET	@""
    #define EVERNOTE_NOTE_NAME			@"Illustail"
#endif
#define DISABLE_EVERNOTE                ([EVERNOTE_CONSUMER_KEY length] == 0)

// google drive
#define GOOGLE_CLIENT_ID                @""
#define GOOGLE_CLIENT_SECRET            @""
#define DISABLE_GOOGLEDRIVE             ([GOOGLE_CLIENT_ID length] == 0)

// tumblr
#ifdef PIXITAIL
    #define	TUMBLR_CONSUMER_KEY         @""
    #define TUMBLR_CONSUMER_SECRET      @""
#elif defined ILLUSTAIL
    #define	TUMBLR_CONSUMER_KEY         @""
    #define TUMBLR_CONSUMER_SECRET      @""
#endif
#define DISABLE_TUMBLR                  ([TUMBLR_CONSUMER_KEY length] == 0)

// sugarsync
#ifdef PIXITAIL
    #define SUGARSYNC_APPLICATION_ID	@""
#else
    #define SUGARSYNC_APPLICATION_ID	@""
#endif
#define SUGARSYNC_PUBLIC_ACCESS_KEY     @""
#define SUGARSYNC_PRIVATE_ACCESS_KEY    @""
#define DISABLE_SUGARSYNC               ([SUGARSYNC_APPLICATION_ID length] == 0)

// skydrive
#ifdef PIXITAIL
    #define SKYDRIVE_CLIENT_ID          @""
    #define SKYDRIVE_CLIENT_SECRET      @""
#else
    #define SKYDRIVE_CLIENT_ID          @""
    #define SKYDRIVE_CLIENT_SECRET      @""
#endif
#define DISABLE_SKYDRIVE               ([SKYDRIVE_CLIENT_ID length] == 0)


#endif /* Constants_h */
