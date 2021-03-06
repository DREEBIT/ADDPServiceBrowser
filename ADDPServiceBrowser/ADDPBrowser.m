//
// Created by Toni Möckel on 05.03.15.
// Copyright (c) 2015 Toni Möckel. All rights reserved.
//

#import <ADDPServiceBrowser/DigiDiscover.h>
#import "ADDPBrowser.h"
#import "GCDAsyncUdpSocket.h"
#import "AsyncUdpSocket.h"
#include "TargetConditionals.h"
#include "ADDPInterfaceModel.h"


#include <sys/types.h>
#include <ifaddrs.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

NSString *const ADDPMulticastGroupAddress = @"224.0.5.128";
int const ADDPPort = 2362;


@interface ADDPBrowser ()
@property(nonatomic, strong) GCDAsyncUdpSocket *asyncSocket;
@property(nonatomic, strong) NSMutableArray *socketArray;
@property(nonatomic, strong) id socket;
@end

@implementation ADDPBrowser {

}

- (void)startBrowsing:(int)delay {

    [self startBrowsing];

//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//
//        [self stopBrowsing];
//
//    });

}

- (void)startBrowsing {

    [self sendViaAsyncUdpSocket];
//    [self sendViaClassicSocket];

}

- (void)sendViaClassicSocket {


    DigiDiscover *digiDiscover = [[DigiDiscover alloc] init];
    [digiDiscover startDigiDetection];

}


- (NSMutableArray *) enumerateAndGetDetailsOfAllNetworkInterfaces
{
    NSMutableArray *interfaceArray = [[NSMutableArray alloc] init];
    struct ifaddrs *ifap, *ifa;
    struct sockaddr_in *sa;
    char *addr;
    
    getifaddrs (&ifap);
    
    for (ifa = ifap; ifa; ifa = ifa->ifa_next)
    {
        if (ifa->ifa_addr->sa_family==AF_INET)
        {
            ADDPInterfaceModel *interfaceModel = [[ADDPInterfaceModel alloc] init];
            
            sa = (struct sockaddr_in *) ifa->ifa_addr;
            addr = inet_ntoa(sa->sin_addr);
            printf("Interface: %s\tAddress: %s\n", ifa->ifa_name, addr);
            
            interfaceModel.interfaceName = [NSString stringWithCString:ifa->ifa_name encoding:NSUTF8StringEncoding];
            interfaceModel.interfaceIPAddress = [NSString stringWithCString:addr encoding:NSUTF8StringEncoding];
            
            [interfaceArray addObject:interfaceModel];
        }
    }
    
    freeifaddrs(ifap);
    return interfaceArray;
}



- (void)sendViaAsyncUdpSocket{
    
    NSError *error;
    
    char strChar[14] = "";
    strChar[0] = 'D';
    strChar[1] = 'I';
    strChar[2] = 'G';
    strChar[3] = 'I';
    strChar[4] = 0x00;
    strChar[5] = 0x01;
    strChar[6] = 0x00;
    strChar[7] = 0x06;
    strChar[8] = 0xff;
    strChar[9] = 0xff;
    strChar[10] = 0xff;
    strChar[11] = 0xff;
    strChar[12] = 0xff;
    strChar[13] = 0xff;
    
    NSData *data = [[NSData alloc] initWithBytes:strChar length:14];
    
    self.socketArray = [NSMutableArray array];


//    NSString *interfaceIndex = TARGET_IPHONE_SIMULATOR ? @"en1" : @"en0";
    
    NSMutableArray *interfaceArray = [self enumerateAndGetDetailsOfAllNetworkInterfaces];

    
    int i = 1;
    
    for(ADDPInterfaceModel *interfaceModel in interfaceArray)
    {
        
        NSError *error;
        
        NSInteger udpPort =  ADDPPort;
        
        GCDAsyncUdpSocket *gcdAsyncUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                                                             delegateQueue:dispatch_get_main_queue()];
        [gcdAsyncUdpSocket bindToPort:udpPort interface:interfaceModel.interfaceName error:&error];
        gcdAsyncUdpSocket.delegate = self;
        [gcdAsyncUdpSocket setPreferIPv6];
        
        if (![gcdAsyncUdpSocket enableBroadcast:YES error:&error]) {
            NSLog(@"Error enableBroadcast:%@",error);
            return;
        }
        
        [gcdAsyncUdpSocket  beginReceiving:&error];
        
        [gcdAsyncUdpSocket  sendData:data toHost:ADDPMulticastGroupAddress port:ADDPPort withTimeout:-1 tag:i++];
        
        
        if(error == nil)
        {
            [self.socketArray addObject:gcdAsyncUdpSocket];
        }

        
        
    }


}

- (void) notifyDelegateWithError:(NSError *)error
{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            [_delegate addpBrowser:self didNotStartBrowsingForDevices:error];
        }
    });
}

- (void)stopBrowsing {

    for (GCDAsyncUdpSocket *socket in self.socketArray){
        if (!socket.isClosed){
            [socket close];
        }
    }

}

- (BOOL) allSocketsClosed {
    BOOL allClosed = YES;
    for (GCDAsyncUdpSocket *socket in self.socketArray){
        if (!socket.isClosed){
            allClosed = NO;
        }
    }
    return allClosed;
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    if ([self.delegate respondsToSelector:@selector(addpBrowser:didStartBrowsing:)]){
        [self.delegate addpBrowser:self didStartBrowsing:address];
    }
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {

    if ([self allSocketsClosed]){
        [self notifyDelegateWithError:error];
    }

}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext{

    ADDPDevice *device = [self parseDeviceFromMessage:data];
    if (device.mac && [self.delegate respondsToSelector:@selector(addpBrowser:didFindDevice:)]){
        [self.delegate addpBrowser:self didFindDevice:device];
    }

}

- (ADDPDevice *)parseDeviceFromMessage:(NSData *)data {

    if (![data bytes]){
        return nil;
    }

    ADDPDevice *newDevice = [[ADDPDevice alloc] init];

    unsigned char* buffer = (unsigned char*) [data bytes];

    //MAC Address
    unsigned char mac[6] = {};
    char hexMac[20] = {};
    [self insertCharsFromIndex:10 withLenth:6 fromBuffer:buffer inBuffer:mac];
    sprintf(hexMac, "%02X-%02X-%02X-%02X-%02X-%02X", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
    NSString *macString = [[NSString alloc] initWithBytes:(void *)hexMac length:20 encoding:NSASCIIStringEncoding];
    if (macString.length>0){
        newDevice.mac = macString;
    }

    //IP Address
    unsigned char ip[4] = {};
    char ipFormatted[16];
    [self insertCharsFromIndex:18 withLenth:4 fromBuffer:buffer inBuffer:ip];
    sprintf(ipFormatted, "%d.%d.%d.%d", ip[0], ip[1], ip[2], ip[3]);
    NSString *ipString = [[NSString alloc] initWithBytes:(void *)ipFormatted length:15 encoding:NSASCIIStringEncoding];
    if (ipString.length>0){
        newDevice.ip = ipString;
    }

    //Subnet mask
    unsigned char subnet[4] = {};
    char subnetFormat[16];
    [self insertCharsFromIndex:24 withLenth:4 fromBuffer:buffer inBuffer:subnet];
    sprintf(subnetFormat, "%03d.%03d.%03d.%03d", subnet[0], subnet[1], subnet[2], subnet[3]);
    NSString *subnetString = [[NSString alloc] initWithBytes:(void *) subnetFormat length:16 encoding:NSASCIIStringEncoding];
    if (subnetString.length>0){
        newDevice.submask = subnetString;
    }


    //Device title
    unsigned char name[32] = {};

    NSString *titleString = [self parseUntilBreakPointFromBuffer:buffer fromIndex:31 toBuffer:name];//[[NSString alloc] initWithBytes:(void *)name length:32 encoding:NSASCIIStringEncoding];
    if (titleString.length>0){
        newDevice.title = titleString;
    }

    return newDevice;
}

- (NSString *) parseUntilBreakPointFromBuffer:(unsigned char *)frame fromIndex:(int)startIndex toBuffer:(unsigned char *)deviceName
{
    int i = 0;
    int j = 0;

    while (frame[i + startIndex] != 0x12 && frame[i + startIndex] !=  0x10 && frame[i + startIndex] !=  0x0d ) {
        unsigned char character =  frame[i + startIndex];
        if (character != '\0' && character != '\x06' && character != '\x04' && character != '\x01' && character != '\b' && character != '\xfe' && character != '\x16' && character != '\xfe'){
            deviceName[j++] = character;
        }
        i++;
    }

    NSString *deviceString = [NSString stringWithCString:(char const *) deviceName encoding:NSASCIIStringEncoding];
    deviceString = [deviceString stringByReplacingOccurrencesOfString:@"þ" withString:@""];
    return deviceString;
}

- (void) insertCharsFromIndex:(NSInteger)index withLenth:(NSUInteger)len fromBuffer:(unsigned char *)source inBuffer:(unsigned char *)target
{
    for (int i = index; i < (index + len); i++) {
        target[i - index] = source[i];
    }

}



@end