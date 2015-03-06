//
// Created by Toni Möckel on 05.03.15.
// Copyright (c) 2015 Toni Möckel. All rights reserved.
//

#import "BrowserViewController.h"
#import "ADDPDevice.h"
#import "ADDPBrowser.h"


@interface BrowserViewController ()
@property(nonatomic, strong) NSMutableArray *data;
@property(nonatomic, strong) ADDPBrowser *browser;
@end

@implementation BrowserViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];



    self.browser = [[ADDPBrowser alloc] init];
    [self.browser setDelegate:self];

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

    [self refresh:refreshControl];

}

- (void)refresh:(UIRefreshControl *)refreshControl {

    self.data = [NSMutableArray array];
    [self.tableView reloadData];

    [refreshControl beginRefreshing];
    [self startBrowsing:refreshControl];

    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self stopBrowsing:refreshControl];
        [refreshControl endRefreshing];
    });

}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    ADDPDevice *device = self.data[(NSUInteger) indexPath.row];
    cell.textLabel.text = device.title;
    cell.detailTextLabel.text = device.ip;

    return cell;
}

- (void)addpBrowser:(ADDPBrowser *)browser didFindDevice:(ADDPDevice *)device {

    bool exists = NO;
    for (ADDPDevice *existingDevice in self.data){
        if ([existingDevice.mac isEqualToString:device.mac]){
            exists = YES;
        }
    }
    if (!exists){
        [self.data addObject:device];

        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[self.data count]-1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

}

- (void)addpBrowser:(ADDPBrowser *)browser didNotStartBrowsingForDevices:(NSError *)error {

    NSLog(@"Browser hung up: %@", [error localizedDescription]);

}

- (IBAction)startBrowsing:(id)sender {
    [self.browser startBrowsing];
}

- (IBAction)stopBrowsing:(id)sender {
    [self.browser stopBrowsing];
}

@end