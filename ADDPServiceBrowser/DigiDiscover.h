//
//  DigiDiscover.h
//  ASM Pocket
//
//  Created by ALBERT Eric on 20/05/11.
//  Copyright 2011 Adixen. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DigiDiscover : NSObject {

	int					udpSocket;
	NSMutableArray		*digiArray;
	
}

@property (readwrite)	int					udpSocket;
@property (retain)		NSMutableArray		*digiArray;


- (void) startDigiDetection;
- (void)broadcast:(NSData *)data;
- (void) getResponses;

- (void) getInformationAtIndex:(NSInteger)index withLenth:(NSUInteger)len fromFrame:(unsigned char *)frame inBuffer:(unsigned char *)infos;
- (void) getDeviceNameFromFrame:(unsigned char *)frame inBuffer:(unsigned char *)deviceName;

@end
