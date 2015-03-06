//
//  ADDPDevice.h
//  
//
//  Created by Toni Möckel on 05.03.15.
//
//

#import <Foundation/Foundation.h>

@interface ADDPDevice : NSObject

@property (nonatomic, strong) NSString *ip;
@property (nonatomic, strong) NSString *mac;
@property (nonatomic, strong) NSString *submask;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *gateway;

@end
