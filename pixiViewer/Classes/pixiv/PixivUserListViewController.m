//
//  PixivUserListViewController.m
//  pixiViewer
//
//  Created by nya on 09/10/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivUserListViewController.h"
#import "PixivUserListParser.h"
#import "PixivMatrixViewController.h"
#import "Pixiv.h"
#import "AccountManager.h"
#import "PixitailConstants.h"
#import "CHHtmlParserConnectionNoScript.h"


@interface URLCacheDataLoader : NSObject {
	id<URLCacheDataLoaderDelegate>	delegate;
	NSString						*urlString;
	NSString						*referer;
	
	NSURLConnection	*connection_;
	NSMutableData	*data_;
}

@property(readwrite, assign, nonatomic) id<URLCacheDataLoaderDelegate> delegate;
@property(readwrite, retain, nonatomic) NSString *urlString;
@property(readwrite, retain, nonatomic) NSString *referer;

- (long) start;
- (void) cancel;

@end


@implementation URLCacheDataLoader

@synthesize delegate;
@synthesize urlString;
@synthesize referer;

- (id) init {
	self = [super init];
	if (self) {
		data_ = [[NSMutableData alloc] init];
	}
	return self;
}

- (void) dealloc {
	[self cancel];
	[data_ release];
	
	self.urlString = nil;
	self.referer = nil;
		
	[super dealloc];
}

- (long) start {
	NSURLConnection		*con;
	NSMutableURLRequest	*req;
	
	if (!self.urlString) {
		return -1;
	}
	
	req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self.urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if (!req) {
		return -1;
	}
	
	con = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	[req release];
	if (!con) {
		return -1;
	}
	
	if (self.referer) {
		[req setValue:self.referer forHTTPHeaderField:@"Referer"];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	connection_ = con;
	[con start];
	return 0;
}

- (void) cancel {
	if (connection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
		[connection_ cancel];
		[connection_ release];
		connection_ = nil;
	}
}

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[data_ appendData:data];
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	
	[self.delegate loader:self loadFinished:nil];
	[connection_ release];
	connection_ = nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

	[self.delegate loader:self loadFinished:data_];
	[connection_ release];
	connection_ = nil;
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

@end


@implementation PixivUserListViewController

@synthesize method;
@synthesize account;
@synthesize scrapingInfoKey;

- (PixService *) pixiv {
	return [Pixiv sharedInstance];
}


/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)dealloc {
	[connection_ cancel];
	[connection_ release];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;

	for (URLCacheDataLoader *loader in imageLoaders_) {
		[loader cancel];
	}
	[imageLoaders_ release];
	imageLoaders_ = nil;
	[users_ release];
	users_ = nil;
	
	[method release];
	method = nil;

	[account release];
	self.scrapingInfoKey = nil;

    [super dealloc];
}

- (void) load {
	long	err = [[self pixiv] allertReachability];
	if (err) {
		return;
	}
	/*
	if (err == -1) {
		[self pixiv].username = account.username;
		[self pixiv].password = account.password;

		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return;
	} else if (err) {
		return;
	}
	 */
	
	PixivUserListParser		*parser = [[PixivUserListParser alloc] initWithEncoding:NSUTF8StringEncoding];
	if (scrapingInfoKey) {
		NSDictionary *d = [[PixitailConstants sharedInstance] valueForKeyPath:scrapingInfoKey];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	CHHtmlParserConnection	*con;
	
	con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@p=%d", self.method, loadedPage_ + 1]]];
	
	con.referer = @"http://www.pixiv.net/mypage.php";
	con.delegate = self;
	parser.method = self.method;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.tableView.rowHeight = 44;
	
	[users_ release];
	users_ = [[NSMutableArray alloc] init];
	[imageLoaders_ release];
	imageLoaders_ = [[NSMutableArray alloc] init];
	loadedPage_ = 0;
	
	[self load];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	//[self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
/*
	[connection_ cancel];
	[connection_ release];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;

	for (URLCacheDataLoader *loader in imageLoaders_) {
		[loader cancel];
	}
	[imageLoaders_ release];
	imageLoaders_ = nil;
	[users_ release];
	users_ = nil;
*/
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger	ret = [users_ count];
	if (ret > 0 && (connection_ || loadedPage_ < maxPage_)) {
		ret += 1;
	}
    return ret;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"UserListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (indexPath.row < [users_ count]) {
		NSDictionary	*info = [users_ objectAtIndex:indexPath.row];
		cell.textLabel.text = [info objectForKey:@"UserName"];
		cell.imageView.image = [info objectForKey:@"Image"] ? [info objectForKey:@"Image"] : [UIImage imageNamed:@"dummy.png"];
		cell.textLabel.textAlignment = UITextAlignmentLeft;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else if (connection_) {
		cell.textLabel.text = @"";
		cell.imageView.image = [UIImage imageNamed:@"dummy.png"];
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		cell.textLabel.text = NSLocalizedString(@"Load next users...", nil);
		cell.imageView.image = nil;
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [users_ count]) {
		NSDictionary	*info = [users_ objectAtIndex:indexPath.row];
		PixivMatrixViewController *controller = [[PixivMatrixViewController alloc] init];
		controller.method = [NSString stringWithFormat:@"member_illust.php?id=%@&", [info objectForKey:@"UserID"]];
		controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Illust by %@", nil), [info objectForKey:@"UserName"]];
		controller.account = account;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	} else if (!connection_) {
		// load next
		[self load];
		[(UITableView *)self.view reloadData];
	}
}


- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	if (err) {
		// 失敗

	} else {
		// 成功
		[users_ addObjectsFromArray:parser_.list];
		maxPage_ = parser_.maxPage;
		loadedPage_++;
		
		for (NSDictionary *info in parser_.list) {
			if ([info objectForKey:@"ImageURLString"]) {
				URLCacheDataLoader	*loader = [[URLCacheDataLoader alloc] init];
				loader.delegate = self;
				loader.urlString = [info objectForKey:@"ImageURLString"];
				loader.referer = @"http://www.pixiv.net/";
				[loader start];
				
				[imageLoaders_ addObject:loader];
				[loader release];
			}
		}
	}
	
	[parser_ release];
	parser_ = nil;
	[connection_ release];
	connection_ = nil;

	[(UITableView *)self.view reloadData];
}


- (void) loader:(URLCacheDataLoader *)sender loadFinished:(NSData *)data {
	if (data == nil) {
		return;
	}

	for (NSMutableDictionary *info in users_) {
		if ([[info objectForKey:@"ImageURLString"] isEqualToString:sender.urlString]) {
			UIImage	*img = [[UIImage alloc] initWithData:data];
			if (img) {

				// リサイズ
				CGSize newSize = CGSizeMake(40, 40);
				UIGraphicsBeginImageContext(newSize);
				[img drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
				[img release];
				img = UIGraphicsGetImageFromCurrentImageContext();
				UIGraphicsEndImageContext();

				[info removeObjectForKey:@"ImageURLString"];
				[info setObject:img forKey:@"Image"];
				
				if ([users_ objectAtIndex:0] == info) {
					[[NSNotificationCenter defaultCenter] postNotificationName:@"TopImageChangedNotification" object:self.account userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
						img,			@"Image",
						self.method,	@"Method",
						nil]];
				}
				
				[(UITableView *)self.view reloadData];
			}
			
			[imageLoaders_ removeObject:sender];
			return;
		}
	}
}

#pragma mark-

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			[self.navigationController popToRootViewControllerAnimated:YES];
			return;
		}
	} else {
		[self load];
	}
}

- (void) progressCancel:(ProgressViewController *)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	[[self pixiv] loginCancel];
	[self.navigationController popToRootViewControllerAnimated:YES];
	
	[self hideProgress];
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[account info] forKey:@"Account"];
	[info setObject:method forKey:@"Method"];

	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	if ([super restore:info] == NO) {
		return NO;
	}
	
	obj = [info objectForKey:@"Method"];
	if (obj == nil) {
		return NO;
	}
	self.method = obj;

	obj = [info objectForKey:@"Account"];
	PixAccount *acc = [[AccountManager sharedInstance] accountWithInfo:obj];
	if (acc == nil) {
		return NO;
	}	
	self.account = acc;

	return YES;
}

- (void) loginFinished:(NSNotification *)notif {
	[self load];
}

@end

