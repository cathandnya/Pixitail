//
//  PixivWidgetSettingViewController.m
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import "WidgetContentSettingViewController.h"
#import "PixitailConstants.h"
#import "NSData+Crypto.h"
#import "Tinami.h"
#import "SeigaConstants.h"

@interface WidgetContentSettingViewController ()
@property(strong) NSArray *list;
@property(strong) NSArray *tags;
@end

@implementation WidgetContentSettingViewController

- (NSString *) saveName {
#ifdef PIXITAIL
	return @"SavedTags";
#else
	if ([self.account.serviceName isEqualToString:@"Danbooru"]) {
		return @"SavedTagsDanbooru";
	} else {
		return @"";
	}
#endif
}

- (NSString *) methodWithTag:(NSString *)tag {
#ifdef PIXITAIL
	NSData				*data = [tag dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithString:@"tags.php?tag="];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	[method appendString:@"&"];
	
	return method;
#else
	if ([self.account.serviceName isEqualToString:@"Danbooru"]) {
		NSData				*data = [tag dataUsingEncoding:NSUTF8StringEncoding];
		NSMutableString		*method = [NSMutableString stringWithFormat:@"http://%@/post/index.json?tags=", self.account.hostname];
		int					i;
		
		for (i = 0; i < [data length]; i++) {
			[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
		}
		[method appendString:@"&"];
		
		return method;
	} else {
		return nil;
	}
#endif
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	NSMutableArray *mary = [NSMutableArray new];
#ifdef PIXITAIL
	for (NSDictionary *sec in [[PixitailConstants sharedInstance] valueForKeyPath:@"menu"]) {
		for (NSDictionary *row in sec[@"rows"]) {
			if (!row[@"class"]) {
				[mary addObject:row];
			}
		}
	}
#else
	if ([self.account.serviceName isEqualToString:@"TINAMI"]) {
		const int count = 16;
		NSString *methods[16] = {
			@"bookmark/content/list?perpage=20",
			@"watchkeyword/content/list?perpage=20",
			@"friend/recommend/content/list?perpage=20",
			@"collection/list?perpage=20",
			@"content/search?sort=new",
			@"content/search?cont_type[]=1",
			@"content/search?cont_type[]=2",
			@"content/search?cont_type[]=3",
			@"content/search?cont_type[]=5",
			@"content/search?cont_type[]=4",
			@"ranking?category=0",
			@"ranking?category=1",
			@"ranking?category=2",
			@"ranking?category=3",
			@"ranking?category=5",
			@"ranking?category=4"
		};
		NSString *names[16] = {
			@"お気に入りクリエイター新着",
			@"ウォッチキーワード新着",
			@"友達の支援履歴",
			@"コレクション",
			@"新着／総合",
			@"新着／イラスト",
			@"新着／マンガ",
			@"新着／モデル",
			@"新着／コスプレ",
			@"新着／小説",
			@"ランキング／総合",
			@"ランキング／イラスト",
			@"ランキング／マンガ",
			@"ランキング／モデル",
			@"ランキング／コスプレ",
			@"ランキング／小説"
		};
		for (int i = 0; i < count; i++) {
			[mary addObject:@{@"name": names[i], @"method": methods[i]}];
		}
	} else if ([self.account.serviceName isEqualToString:@"Danbooru"]) {
		[mary addObject:@{@"name": @"Posts", @"method": [NSString stringWithFormat:@"http://%@/post/index.json?limit=20", self.account.hostname]}];
	} else if ([self.account.serviceName isEqualToString:@"Seiga"]) {
		for (NSDictionary *sec in [[SeigaConstants sharedInstance] valueForKeyPath:@"menu"]) {
			for (NSDictionary *row in sec[@"rows"]) {
				if (!row[@"class"]) {
					[mary addObject:row];
				}
			}
		}
	}
#endif
	self.list = mary;
	
	self.tags = [[[NSUserDefaults standardUserDefaults] objectForKey:[self saveName]] mutableCopy];
	if (!self.tags) {
		self.tags = [NSArray new];
	}
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
}

- (void) cancelAction:(id)sender {
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) containsItem:(NSDictionary *)item {
	for (NSDictionary *d in self.widgets) {
		if ([self.account.username isEqualToString:d[@"username"]] && [item[@"method"] isEqualToString:d[@"method"]]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL) containsTag:(NSString *)tag {
	for (NSDictionary *d in self.widgets) {
		if ([self.account.username isEqualToString:d[@"username"]] && [[self methodWithTag:tag] isEqualToString:d[@"method"]]) {
			return YES;
		}
	}
	return NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return self.list.count;
		case 1:
			return self.tags.count;
		default:
			return 0;
	}
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section) {
		case 0:
			return @"";
		case 1:
			return self.tags.count > 0 ? @"タグブックマーク" : nil;
		default:
			return nil;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
	}
	
	BOOL enabled;
	if (indexPath.section == 0) {
		NSDictionary *d = self.list[indexPath.row];
		cell.textLabel.text = d[@"name"];
		enabled = ![self containsItem:d];
	} else if (indexPath.section == 1) {
		NSString *tag = self.tags[indexPath.row];
		cell.textLabel.text = tag;
		enabled = ![self containsTag:tag];
	}
	cell.textLabel.textColor = enabled ? [UIColor darkTextColor] : [UIColor lightGrayColor];
	cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
	
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSDictionary *item = nil;
	if (indexPath.section == 0) {
		NSDictionary *d = self.list[indexPath.row];
		if (![self containsItem:d]) {
			item = d;
		}
	} else if (indexPath.section == 1) {
		NSString *tag = self.tags[indexPath.row];
		if (![self containsTag:tag]) {
			item = @{@"name": [NSString stringWithFormat:@"タグブックマーク: %@", tag],
					 @"method": [self methodWithTag:tag]};
		}
	}
	
	if (item) {
		NSMutableDictionary *d = [item mutableCopy];
		d[@"username"] = self.account.username;
		d[@"password"] = [self.account.password cryptedString];

#ifdef PIXITAIL
		d[@"service"] = @"pixiv";
#else
		d[@"service"] = self.account.serviceName;
#endif
		
		[self.delegate performSelector:@selector(addItem:) withObject:d];
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
