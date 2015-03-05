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

    self.data = [NSMutableArray array];

    self.browser = [[ADDPBrowser alloc] init];
    [self.browser setDelegate:self];
    [self.browser startBrowsing];
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
    cell.textLabel.text = device.mac;
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
        [self.tableView reloadData];
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