//
//  SkyDrive.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/07/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SkyDrive.h"
#import "LiveConnectClient.h"
#import "PostQueue.h"
#import "BigURLDownloader.h"
#import "ImageDownloader.h"
#import "AlertView.h"
#import "StatusMessageViewController.h"
#import "UserDefaults.h"


#define CLIENT_ID				SKYDRIVE_CLIENT_ID
#define CLIENT_SECRET			SKYDRIVE_CLIENT_SECRET


#define SCOPE		[NSArray arrayWithObjects:@"wl.signin", @"wl.skydrive_update", @"wl.offline_access", nil]
//#define SCOPE		[NSArray arrayWithObjects:@"wl.signin", @"wl.skydrive_update", nil]
#define ESCAPE_CHARS		@"\\/*?|<>:,;'\"　"


typedef enum {
	State_Initial = 0,
	State_FindFolder,
	State_NeedsCreateFolder,
	State_FolderIsExists,
	State_Uploaded,
} State;


@implementation SkyDrive

@dynamic available;

+ (SkyDrive *) sharedInstance {
	static SkyDrive *obj = nil;
	if (!obj) {
		obj = [[SkyDrive alloc] init];
	}
	return obj;
}

- (id) init {
	self = [super init];
	if (self) {
        if (!DISABLE_SKYDRIVE) {
            client = [[LiveConnectClient alloc] initWithClientId:CLIENT_ID delegate:self userState:@"genesis"];
        }
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

#pragma mark-

- (void) setAlbumID:(NSString *)str {
	UDSetString(str, @"SkyDriveAlbumID");
}

- (NSString *) albumID {
	return UDString(@"SkyDriveAlbumID");
}

#pragma mark-

- (BOOL) available {
	return client.session != nil;
}

- (void) login:(UIViewController *)viewController withDelegate:(id<SkyDriveLoginHandler>)del {
	loginDelegate = del;
	[client login:viewController scopes:SCOPE delegate:self userState:@"signin"];
}

- (void) logout {
	[client logoutWithDelegate:self userState:@"signout"];
	[self setAlbumID:nil];
}

#pragma mark-

- (void) authCompleted:(LiveConnectSessionStatus)status 
               session:(LiveConnectSession *)session 
             userState:(id)userState
{   
    if (session != nil) {
		[loginDelegate skyDrive:self loginFinished:nil];
    } else {
		[loginDelegate skyDrive:self loginFinished:[NSError errorWithDomain:NSStringFromClass([self class]) code:-1 userInfo:nil]];
	}
	loginDelegate = nil;
}

- (void) authFailed:(NSError *)error 
          userState:(id)userState
{
	[loginDelegate skyDrive:self loginFinished:error];
	loginDelegate = nil;
}

#pragma mark-

- (void) liveOperationSucceeded:(LiveOperation *)operation
{
	if (operation == createAlbumOperation) {
		[self createAlbumFinished:operation.result];
	} else if (operation == getAlbumInfoOperation) {
		[self getAlbumInfoFinished:operation.result];
	} else if (operation == uploadOperation) {
		[self uploadFileFinished:operation.result];
	} else if (operation == listOperation) {
		[self listFinished:operation.result];
	}
}

- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation*)operation {
	if (operation == createAlbumOperation) {
		[self createAlbumFinished:error];
	} else if (operation == getAlbumInfoOperation) {
		[self getAlbumInfoFinished:error];
	} else if (operation == uploadOperation) {
		[self uploadFileFinished:error];
	} else if (operation == listOperation) {
		[self listFinished:error];
	}
}

#pragma mark-

-(void) createAlbum:(NSString *)name description:(NSString *)desc {
    NSDictionary * newAlbum = [[NSDictionary dictionaryWithObjectsAndKeys:
                                name, @"name",
                                desc, @"description",
                                @"album",@"type",
                                nil] retain];
	
    createAlbumOperation = [client postWithPath:@"me/skydrive" 
									   dictBody:newAlbum
									   delegate:self];
    [newAlbum release];
}

- (void) createAlbumFinished:(id)result {
	if ([result isKindOfClass:[NSError class]]) {
		[self dispatch:result];
	} else {
		NSString *albumId = [result objectForKey:@"id"];
		//NSString *albumName = [result objectForKey:@"name"];
		//NSString *albumDescription = [result objectForKey:@"description"];
		//NSString *albumLink = [result objectForKey:@"link"];
		//NSString *albumType = [result objectForKey:@"type"];
		[self setAlbumID:albumId];
		
		state = State_FolderIsExists;
		[self dispatch:nil];
	}
	createAlbumOperation = nil;
}

#pragma mark-

- (void) listRootFolder {
	listOperation = [client getWithPath:@"me/skydrive/files" 
							   delegate:self];
}

- (void) listFinished:(id)result {
	if ([result isKindOfClass:[NSError class]]) {
		[self dispatch:result];
	} else {
		for (NSDictionary *d in [result valueForKey:@"data"]) {
			if ([[d valueForKey:@"name"] isEqual:[self folderName]]) {
				[self setAlbumID:[d valueForKey:@"id"]];
				break;
			}
		}		
		DLog(@"%@", [result description]);
		
		if ([self albumID]) {
			state = State_FolderIsExists;
		} else {
			state = State_NeedsCreateFolder;
		}
		[self dispatch:nil];
	}
	listOperation = nil;
}

#pragma mark-

- (void) getAlbumInfo:(NSString *)albumID {
    getAlbumInfoOperation = [client getWithPath:albumID 
									   delegate:self];
}

- (void) getAlbumInfoFinished:(id)result {
	if ([result isKindOfClass:[NSError class]]) {
		[self setAlbumID:nil];
		
		state = State_FindFolder;
		[self dispatch:nil];
	} else {
		NSString *albumId = [result objectForKey:@"id"];
		//NSString *albumName = [result objectForKey:@"name"];
		//NSString *albumDescription = [result objectForKey:@"description"];
		//NSString *albumLink = [result objectForKey:@"link"];
		//NSString *albumType = [result objectForKey:@"type"];
		
		[self setAlbumID:albumId];
		
		state = State_FolderIsExists;
		[self dispatch:nil];
	}
}

#pragma mark-

-(void) uploadFile:(NSData *)data withName:(NSString *)name to:(NSString *)pathOrID
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];	
    uploadOperation = [client uploadToPath:pathOrID
								  fileName:name 
									  data:data
								 overwrite:YES
								  delegate:self
								 userState:nil];
}

- (void) uploadFileFinished:(id)result {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	if ([result isKindOfClass:[NSError class]]) {
		[self dispatch:result];
	} else {
		//NSString *fileId = [result objectForKey:@"id"];
		//NSString *fileName = [result objectForKey:@"name"];
		//NSString *fileDescription = [result objectForKey:@"description"];
		//NSString *fileSize = [result objectForKey:@"size"];
		
		// 成功
		state = State_Uploaded;
		[self dispatch:nil];
	}
	uploadOperation = nil;
}

#pragma mark-

- (void) folderCheck {
	NSString *albumID = [self albumID];
	if (albumID) {
		[self getAlbumInfo:albumID];
	} else {
		state = State_FindFolder;
		[self dispatch:nil];
	}
}

- (void) findFolder {
	[self listRootFolder];
}

- (void) createFolder {
	[self createAlbum:[self folderName] description:@""];
}

- (void) upload {
	[self uploadFile:upData withName:upName to:[self albumID]];
}

- (void) dispatch:(NSError *)err {
	if (err) {
		[self uploadFailed:err];
		state = State_Initial;
		return;
	}
	
	switch (state) {
		case State_Initial:
			[self folderCheck];
			break;
		case State_FindFolder:
			[self findFolder];
			break;
		case State_NeedsCreateFolder:
			[self createFolder];
			break;
		case State_FolderIsExists:
			[self upload];
			break;
		case State_Uploaded:
			[[StatusMessageViewController sharedInstance] showMessage:NSLocalizedString(@"Sharing to SkyDrive is finished.", nil)];
			[self uploadFinished:postQueue];
			state = State_Initial;
			break;
		default:
			break;
	}
}

- (void) uploadFile:(NSData *)data withName:(NSString *)name {
	assert(state == State_Initial);
	state = State_Initial;
	
	[upData release];
	[upName release];
	upData = [data retain];
	upName = [name retain];
	
	[self dispatch:nil];
}

#pragma mark-

- (NSString *) errorMessage:(NSError *)err {
	return [err localizedDescription];
}

- (void) uploadFailed:(NSError *)err {	
	NSString *msg = [self errorMessage:err];
	AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to SkyDrive.", nil) message:msg delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
	alert.object = uploadingInfo;
	[alert show];
}

- (void) uploadFinished:(id)obj {
	[obj post:self finished:0];
}

- (void) uploadCancel {
}

- (void)alertView:(AlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	[self uploadFinished:postQueue];
	if (buttonIndex == 1) {
		NSDictionary *dic = alertView.object;
		[self upload:dic];
	}
}

#pragma mark-

- (void) bigURLDownloader:(BigURLDownloader *)sender finished:(NSError *)err {
	[urlDownloader autorelease];
	urlDownloader = nil;
	
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to SkyDrive.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = sender.object;
		[alert show];
		
		[urlDownloadHandler post:self finished:0];
	} else {
		int i = 0;
		for (NSString *url in sender.imageURLs) {
			NSMutableDictionary *info = [[sender.object mutableCopy] autorelease];
			[info setObject:url forKey:@"ImageURL"];
			if (i > 0) {
				NSString *p = [info objectForKey:@"Path"];
				p = [p stringByAppendingFormat:@"_%d", i];
				[info setObject:p forKey:@"Path"];
			}
			if (sender.imageURLs.count > 1) {
				NSString *n = [info objectForKey:@"Name"];
				
				[info setObject:[[n copy] autorelease] forKey:@"Directory"];
				
				n = [n stringByAppendingFormat:@"_%03d", i + 1];
				[info setObject:n forKey:@"Name"];				
			}
			i++;
			
			[[PostQueue skyDriveQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
		}
		[urlDownloadHandler post:self finished:0];
	}	
	urlDownloadHandler = nil;
}

- (void) imageDownloader:(ImageDownloader *)sender finished:(NSError *)err {
	NSDictionary *info = [[sender.object retain] autorelease];
	[imageDownloader autorelease];
	imageDownloader = nil;
	
	if (err) {
		AlertView *alert = [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Failed to upload to SkyDrive.", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), NSLocalizedString(@"Retry", nil), nil] autorelease];
		alert.object = info;
		[alert show];
		
		[imageDownloadHandler post:self finished:0];
	} else {
		[self uploadPhoto:info handler:imageDownloadHandler];
	}	
	imageDownloadHandler = nil;
}

#pragma mark-

- (NSString *) folderName {
	NSString *name;
#ifdef PIXITAIL
	name = @"Pixitail";
#else
	name = @"Illustail";
#endif
	return name;
}

- (long) uploadPhoto:(NSDictionary *)info handler:(id<PostQueueTargetHandlerProtocol>)obj {
	if (!self.available) {
		[self performSelector:@selector(uploadFinished:) withObject:obj afterDelay:0.1];
		return 0;
	}
	
	NSString *imgPath = [info objectForKey:@"Path"];
	DLog(@"upload: %@", imgPath);
	if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath] == NO) {
		NSString *imgURL = [info objectForKey:@"ImageURL"];
		if (imgURL) {
			imageDownloader = [[ImageDownloader alloc] init];
			imageDownloader.url = imgURL;
			imageDownloader.savePath = imgPath;
			imageDownloader.referer = [info objectForKey:@"Referer"];
			imageDownloader.object = info;
			imageDownloader.delegate = self;
			imageDownloadHandler = obj;
			
			[imageDownloader download];			
			DLog(@" -> download image");
		} else {
			urlDownloader = [[BigURLDownloader alloc] init];
			urlDownloader.parserClassName = [info objectForKey:@"ParserClass"];
			urlDownloader.bigSourceURL = [info objectForKey:@"SourceURL"];
			urlDownloader.referer = [info objectForKey:@"Referer"];
			urlDownloader.object = info;
			urlDownloader.delegate = self;
			urlDownloadHandler = obj;
			
			[urlDownloader download];
			DLog(@" -> download url");
		}
		return 0;
	}
	DLog(@" -> upload");
	
	static const char pngBytes[8] = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};
	NSData *png = [NSData dataWithBytes:pngBytes length:8];
	static const char gifBytes[3] = {0x47, 0x49, 0x46};
	NSData *gif = [NSData dataWithBytes:gifBytes length:3];
	
	NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:[info objectForKey:@"Path"]];
	NSData *data = [fh readDataOfLength:8];
	
	NSString *mime = nil;
	NSString *ext = nil;
	if ([[data subdataWithRange:NSMakeRange(0, 8)] isEqualToData:png]) {
		ext = @"png";
		mime = @"image/png";
	} else if ([[data subdataWithRange:NSMakeRange(0, 3)] isEqualToData:gif]) {
		ext = @"gif";
		mime = @"image/gif";
	} else {
		ext = @"jpg";
		mime = @"image/jpeg";
	}
	
	NSString *name = [info objectForKey:@"Name"];
	NSString *replacement = ESCAPE_CHARS;
	for (int i = 0; i < replacement.length; i++) {
		NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
		name = [name stringByReplacingOccurrencesOfString:s withString:@"#"];
	}
	if ([info objectForKey:@"Username"]) {
		NSString *uname = [info objectForKey:@"Username"];
		NSString *replacement = ESCAPE_CHARS;
		for (int i = 0; i < replacement.length; i++) {
			NSString *s = [replacement substringWithRange:NSMakeRange(i, 1)];
			uname = [uname stringByReplacingOccurrencesOfString:s withString:@"#"];
		}
		
		name = [uname stringByAppendingFormat:@"_%@", name];
	} else {
		//path = [path stringByAppendingPathComponent:@"Unknown"];
	}
	
	NSString *local = [info objectForKey:@"Path"];
	name = [name stringByAppendingPathExtension:ext];
	
	postQueue = obj;
	[uploadingInfo release];
	uploadingInfo = [info retain];
	
	[self uploadFile:[NSData dataWithContentsOfFile:local] withName:name];
	return 0;
}

- (void) upload:(NSDictionary *)info {
	[[PostQueue skyDriveQueue] pushObject:info toTarget:self action:@selector(uploadPhoto:handler:) cancelAction:@selector(uploadCancel)];
}

@end
