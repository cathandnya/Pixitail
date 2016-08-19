//
//  TinamiUserListViewController.m
//  pixiViewer
//
//  Created by nya on 10/03/13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiUserListViewController.h"
#import "TinamiUserlistParser.h"
#import "Tinami.h"
#import "TinamiMatrixViewController.h"
#import "AccountManager.h"


@implementation TinamiUserListViewController

- (PixService *) pixiv {
	return [Tinami sharedInstance];
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
	
	TinamiUserlistParser		*parser = [[TinamiUserlistParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con;
	
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.tinami.com/%@&api_key=4baafbbe9fbd0&page=%d", self.method, loadedPage_ + 1]]];
	
	con.delegate = self;
	parser.method = self.method;
	parser_ = (PixivUserListParser *)parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [users_ count]) {
		NSDictionary	*info = [users_ objectAtIndex:indexPath.row];
		TinamiMatrixViewController *controller = [[TinamiMatrixViewController alloc] init];
		controller.method = [NSString stringWithFormat:@"content/search?prof_id=%@", [info objectForKey:@"UserID"]];
		controller.navigationItem.title = [NSString stringWithFormat:@"%@の作品", [info objectForKey:@"UserName"]];
		controller.account = account;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	} else if (!connection_) {
		// load next
		[self load];
		[(UITableView *)self.view reloadData];
	}
}

@end
