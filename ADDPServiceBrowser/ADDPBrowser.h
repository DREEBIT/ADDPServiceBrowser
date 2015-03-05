//
// Created by Toni Möckel on 05.03.15.
// Copyright (c) 2015 Toni Möckel. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ADDPBrowser;
@class ADDPDevice;


@protocol ADDPBrowserDelegate<NSObject>
- (void) addpBrowser:(ADDPBrowser *)browser didNotStartBrowsingForDevices:(NSError *)error;
- (void) addpBrowser:(ADDPBrowser *)browser didFindDevice:(ADDPDevice *)device;
@end


@interface ADDPBrowser : NSObject

@property(assign, nonatomic) id<ADDPBrowserDelegate> delegate;


- (void) startBrowsing;
- (void) stopBrowsing;



@end