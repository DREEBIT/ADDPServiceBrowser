//
// Created by Toni Möckel on 05.03.15.
// Copyright (c) 2015 Toni Möckel. All rights reserved.
//

@import UIKit;

#import "ADDPBrowser.h"


@interface BrowserViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, ADDPBrowserDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

- (IBAction) startBrowsing:(id)sender;
- (IBAction) stopBrowsing:(id)sender;

@end