//
// Created by Toni Möckel on 05.03.15.
// Copyright (c) 2015 Toni Möckel. All rights reserved.
//

#import "ADDPBrowser.h"
#import "GCDAsyncUdpSocket.h"
#import "ADDPDevice.h"

#import <ifaddrs.h>
#import <sys/socket.h>
#import <net/if.h>
#import <arpa/inet.h>
#include <netinet/in.h>
#import <netdb.h>


NSString *const ADDPMulticastGroupAddress = @"224.0.5.128";
int const ADDPPort = 2362;


@interface ADDPBrowser ()
@property(nonatomic, strong) id socket;
@end

@implementation ADDPBrowser {

}

- (void)startBrowsing {

    self.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self.socket setIPv6Enabled:NO];

    NSError *err = nil;

    NSDictionary *interfaces = [ADDPBrowser availableNetworkInterfaces];

    id sourceAddress = [[interfaces allValues] firstObject];



//
//    if(![self.socket bindToPort:ADDPPort error:&err]) {
//        [self notifyDelegateWithError:err];
//        return;
//    }



    if(![self.socket enableBroadcast:YES error:&err]) {
        [self notifyDelegateWithError:err];
        return;
    }
//
//    if(![self.socket joinMulticastGroup:ADDPMulticastGroupAddress error:&err]) {
//        [self notifyDelegateWithError:err];
//        return;
//    }


    if(![self.socket beginReceiving:&err]) {
        [self notifyDelegateWithError:err];
        return;
    }


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


    [self.socket sendData:data toHost:ADDPMulticastGroupAddress port:ADDPPort withTimeout:-1 tag:0];


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

    [self.socket close];

}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    if( error ) {
        [self notifyDelegateWithError:error];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    NSLog(@"didConnectToAddress");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error{
    NSLog(@"didNotConnect: %@", [error localizedDescription]);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"didSendDataWithTag: %d", tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"didNotSendDataWithTag: %@", [error localizedDescription]);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext{



    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"didReceiveData: %@",msg);
    if( msg ) {

        ADDPDevice *device = [self parseDeviceFromMessage:msg];
        if (device.mac && [self.delegate respondsToSelector:@selector(addpBrowser:didFindDevice:)]){
            [self.delegate addpBrowser:self didFindDevice:device];
        }

    }
    else {
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];

        NSLog(@"Got unknown Message: %@:%hu", host, port);
    }

}

- (ADDPDevice *)parseDeviceFromMessage:(NSString *)msg {

    ADDPDevice *newDevice = [[ADDPDevice alloc] init];


    char* adrMac = (char *) [[msg substringWithRange:NSMakeRange(10, 6)] UTF8String];
    newDevice.mac = [NSString stringWithFormat:@"%02X-%02X-%02X-%02X-%02X-%02X", adrMac[0], adrMac[1], adrMac[2], adrMac[3], adrMac[4], adrMac[5]];

    char* ipAdr = (char *) [[msg substringWithRange:NSMakeRange(18, 4)] UTF8String];
    newDevice.ip = [NSString stringWithFormat:@"%d.%d.%d.%d", ipAdr[0], ipAdr[1], ipAdr[2], ipAdr[3]];

    char* subnet = (char *) [[msg substringWithRange:NSMakeRange(24, 4)] UTF8String];
    newDevice.submask = [NSString stringWithFormat:@"%03d.%03d.%03d.%03d", subnet[0], subnet[1], subnet[2], subnet[3]];

    char* name = (char *) [[msg substringFromIndex:32] UTF8String];
    newDevice.title = [[NSString alloc] initWithBytes:(void *)name length:32 encoding:NSASCIIStringEncoding];

    return newDevice;
}

- (void) getInformationAtIndex:(NSInteger)index withLenth:(NSUInteger)len fromFrame:(unsigned char *)frame inBuffer:(unsigned char *)infos
{
    for (int i = index; i < (index + len); i++) {
        infos[i - index] = frame[i];
    }

}


- (NSString *)sourceAddress {
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:[_socket localAddress]];
    return host;
}


+ (NSDictionary *) availableNetworkInterfaces {
    NSMutableDictionary *addresses = [NSMutableDictionary dictionary];
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *ifa = NULL;

    // retrieve the current interfaces - returns 0 on success
    if( getifaddrs(&interfaces) == 0 ) {
        for( ifa = interfaces; ifa != NULL; ifa = ifa->ifa_next ) {
            if( (ifa->ifa_addr->sa_family == AF_INET) && !(ifa->ifa_flags & IFF_LOOPBACK) && !strncmp(ifa->ifa_name, "en", 2)) {
                NSData *data = [NSData dataWithBytes:ifa->ifa_addr length:sizeof(struct sockaddr_in)];
                NSString *if_name = [NSString stringWithUTF8String:ifa->ifa_name];
                [addresses setObject:data forKey:if_name];
            }
        }

        freeifaddrs(interfaces);
    }

    return addresses;
}


@end