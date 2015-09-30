//
//  DigiDiscover.m
//  ASM Pocket
//
//  Created by ALBERT Eric on 20/05/11.
//  Copyright 2011 Adixen. All rights reserved.
//

#import "DigiDiscover.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netdb.h>

#include <stdio.h>
#include <stdlib.h>

@implementation DigiDiscover

@synthesize udpSocket;
@synthesize digiArray;

//Fonction maitre sur la detection des modules digi
- (void) startDigiDetection
{
	//On enleve pour les modules qui pourraient trainer d'une detection anthérieure
	//On on alloue la memoire pour un nouveau tableau
	if (self.digiArray)
		[self.digiArray removeAllObjects];
	else
		self.digiArray = [[NSMutableArray alloc] init];
	
	//'strChar' est a trame à envoyer sur le réseau
	//Pour découvrir les modules digi environants
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
	
	NSData *myData = [[NSData alloc] initWithBytes:strChar length:14];
	
	//Lance la fonction d'envoie de la trame
	[self broadcast:myData];
	
	//Detache un thread pour recevoir les données si un module à répondu
	[NSThread detachNewThreadSelector:@selector(getResponses) toTarget:self withObject:nil];
}

//Fonction d'envoie de la trame de découverte des modules digi
//Envoye en UDP avec Socket sur addr 224.0.5.128 port 2362 
- (void)broadcast:(NSData *)data {
	
	
	int fd = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
	self.udpSocket = fd;
	
	struct sockaddr_in addr4client;
	struct hostent *hostinfo = NULL;
	
	memset(&addr4client, 0, sizeof(addr4client));
	addr4client.sin_len = sizeof(addr4client);
	addr4client.sin_family = AF_INET;
	addr4client.sin_port = htons(2362);
	
	
	const char *hostname = "224.0.5.128";
	hostinfo = gethostbyname(hostname);	
	addr4client.sin_addr = *(struct	in_addr *) hostinfo->h_addr; 
	
	
	int yes = 1;
	if (setsockopt(self.udpSocket, SOL_SOCKET, SO_BROADCAST, (void *)&yes, sizeof(yes)) == -1) {
		//NSLog([NSString stringWithFormat:@"Failure to set broadcast! : %d", errno]);
	}

    
	char *toSend = (char *)[data bytes];
	if (sendto(self.udpSocket, toSend, [data length], 0, (struct sockaddr *)&addr4client, sizeof(addr4client)) == -1) {
		//NSLog([NSString stringWithFormat:@"Failure to send! : %d", errno]);
	}
	
}

//Receptionne les donnée de reponse d'un module digi
//Fonction 'Thread' découpe les données et les place dans des instanciation de 'DigiDevice'
- (void) getResponses
{
    @autoreleasepool{

        unsigned char buffRecep[200] = {};
        int test = 1;

        while ((test = recv(self.udpSocket, buffRecep, sizeof(buffRecep), 0)) > 0)
        {

            if (buffRecep)
            {
                NSLog(@"Received!");

//                DigiDevice *newDevice = [[DigiDevice alloc] init];
//
//                //RECUPERATION DE L'ADRESSE MAC
//                unsigned char adrMac[6] = {};
//                char adrMacHexa[20] = {};
//                [self getInformationAtIndex:10 withLenth:6 fromFrame:buffRecep inBuffer:adrMac];
//                sprintf(adrMacHexa, "%02X-%02X-%02X-%02X-%02X-%02X", adrMac[0], adrMac[1], adrMac[2], adrMac[3], adrMac[4], adrMac[5]);
//                NSString *nsstr_mac = [[NSString alloc] initWithBytes:(void *)adrMacHexa length:20 encoding:NSASCIIStringEncoding];
//
//                //RECUPERATION DE L'ADRESSE IP
//                unsigned char adrIp[4] = {};
//                char adrIpFormat[16];
//                [self getInformationAtIndex:18 withLenth:4 fromFrame:buffRecep inBuffer:adrIp];
//                sprintf(adrIpFormat, "%d.%d.%d.%d", adrIp[0], adrIp[1], adrIp[2], adrIp[3]);
//                NSString *nsstr_ip = [[NSString alloc] initWithBytes:(void *)adrIpFormat length:15 encoding:NSASCIIStringEncoding];
//
//
//                //RECUPERATION DU MASQUE DE SOUS RESEAU
//                unsigned char subnet[4] = {};
//                char adrSubnetFormat[16];
//                [self getInformationAtIndex:24 withLenth:4 fromFrame:buffRecep inBuffer:subnet];
//                sprintf(adrSubnetFormat, "%03d.%03d.%03d.%03d", subnet[0], subnet[1], subnet[2], subnet[3]);
//                NSString *nsstr_subnet = [[NSString alloc] initWithBytes:(void *)adrSubnetFormat length:16 encoding:NSASCIIStringEncoding];
//
//                //RECUPERATION DU NOM DU MODULE DIGI/
//                unsigned char name[32] = {};
//                [self getDeviceNameFromFrame:buffRecep inBuffer:name];
//                NSString *nsstr_name = [[NSString alloc] initWithBytes:(void *)name length:32 encoding:NSASCIIStringEncoding];
//
//                [newDevice setAddr_ip:nsstr_ip];
//                [newDevice setAddr_mac:nsstr_mac];
//                [newDevice setSub_mask:nsstr_subnet];
//                [newDevice setDeviceName:nsstr_name];
//                [newDevice setPort:@"23"];
//
//                [self.digiArray addObject:newDevice];
//                [newDevice release];
//                buffRecep[0] = '\0';
            }
            else
            {
                //pas de module digi sur ce réseau
            }
        }

        close(self.udpSocket);
    }

}

//Fonction de parsing pour certaines infos dans la trame recu
- (void) getInformationAtIndex:(NSInteger)index withLenth:(NSUInteger)len fromFrame:(unsigned char *)frame inBuffer:(unsigned char *)infos
{
	for (int i = index; i < (index + len); i++) {
		infos[i - index] = frame[i];
	}
	
}

//Fonction de parsing pour certaines infos dans la trame recu
- (void) getDeviceNameFromFrame:(unsigned char *)frame inBuffer:(unsigned char *)deviceName
{	
	int i = 0;
	
	while (frame[i + 36] != 0x12 && frame[i + 36] !=  0x10 && frame[i + 36] !=  0x0d) {
		deviceName[i] = frame[i + 36];
		i++;
	}
}

@end
