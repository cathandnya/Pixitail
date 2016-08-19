//
//  ImageDownloader.h
//  pixiViewer
//
//  Created by nya on 11/01/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageDownloader : NSObject {
	NSString *url;
	NSString *savePath;
	NSString *referer;
	id object;

	id delegate;
	
	NSURLConnection *imageConnection;
	NSFileHandle *fileHandle;
}

@property(readwrite, nonatomic, retain) NSString *url;
@property(readwrite, nonatomic, retain) NSString *savePath;
@property(readwrite, nonatomic, retain) NSString *referer;
@property(readwrite, nonatomic, retain) id object;
@property(readwrite, nonatomic, assign) id delegate;

/// - (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err;
- (void) download;
- (void) cancel;

@end
