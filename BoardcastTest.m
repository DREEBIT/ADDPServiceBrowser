//
// Created by Toni Möckel on 03.08.15.
//

#import "BoardcastTest.h"
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>



@implementation BoardcastTest {

    NSTimer *_connectionTimer;

}

- (void)broadCast
{
    int socketSD = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (socketSD <= 0) {
        NSLog(@"Error: Could not open socket.");
        return;
    }

    // set socket options enable broadcast
    int broadcastEnable = 1;
    int ret = setsockopt(socketSD, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable));
    if (ret) {
        NSLog(@"Error: Could not open set socket to broadcast mode");
        close(socketSD);
        return;
    }

    // Configure the port and ip we want to send to
    struct sockaddr_in broadcastAddr;
    memset(&broadcastAddr, 0, sizeof(broadcastAddr));
    broadcastAddr.sin_family = AF_INET;
    inet_pton(AF_INET, "224.0.5.128", &broadcastAddr.sin_addr);
    broadcastAddr.sin_port = htons(2362);


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

    ret = sendto(socketSD, strChar, strlen(strChar), 0, (struct sockaddr*)&broadcastAddr, sizeof(broadcastAddr));
    if (ret < 0) {
        NSLog(@"Error: Could not open send broadcast.");
        close(socketSD);
        return;
    }

    close(socketSD);

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self listenForPackets];
    });



    [_connectionTimer invalidate];
    _connectionTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(checkConnection) userInfo:nil repeats:NO];
}

- (void)checkConnection {

}

- (void)listenForPackets
{
    int listeningSocket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (listeningSocket <= 0) {
        NSLog(@"Error: listenForPackets - socket() failed.");
        return;
    }

    // set timeout to 2 seconds.
    struct timeval timeV;
    timeV.tv_sec = 2;
    timeV.tv_usec = 0;

    if (setsockopt(listeningSocket, SOL_SOCKET, SO_RCVTIMEO, &timeV, sizeof(timeV)) == -1) {
        NSLog(@"Error: listenForPackets - setsockopt failed");
        close(listeningSocket);
        return;
    }

    // bind the port
    struct sockaddr_in sockaddr;
    memset(&sockaddr, 0, sizeof(sockaddr));

    sockaddr.sin_len = sizeof(sockaddr);
    sockaddr.sin_family = AF_INET;
    sockaddr.sin_port = htons(2362);
    sockaddr.sin_addr.s_addr = htonl(INADDR_ANY);

    int status = bind(listeningSocket, (struct sockaddr *)&sockaddr, sizeof(sockaddr));
    if (status == -1) {
        close(listeningSocket);
        NSLog(@"Error: listenForPackets - bind() failed.");
        return;
    }

    // receive
    struct sockaddr_in receiveSockaddr;
    socklen_t receiveSockaddrLen = sizeof(receiveSockaddr);

    size_t bufSize = 9216;
    void *buf = malloc(bufSize);
    ssize_t result = recvfrom(listeningSocket, buf, bufSize, 0, (struct sockaddr *)&receiveSockaddr, &receiveSockaddrLen);

    NSData *data = nil;

    if (result > 0) {
        if ((size_t)result != bufSize) {
            buf = realloc(buf, result);
        }
        data = [NSData dataWithBytesNoCopy:buf length:result freeWhenDone:YES];

        char addrBuf[INET_ADDRSTRLEN];
        if (inet_ntop(AF_INET, &receiveSockaddr.sin_addr, addrBuf, (size_t)sizeof(addrBuf)) == NULL) {
            addrBuf[0] = '\0';
        }

        NSString *address = [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self didReceiveMessage:msg fromAddress:address];
        });

    } else {
        free(buf);
    }

    close(listeningSocket);
}

- (void)didReceiveMessage:(NSString *)message fromAddress:(NSString *)address
{
}

@end