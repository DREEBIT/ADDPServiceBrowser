# ADDPUtils
Advanced Device Discovery Protocol (ADDP) library for iOS

![Screenshot](/Screenshots/sample-screen.png "Screenshot")

## Features

- Looking for ADDP Digi Devices 
- Get Device Information (MAC, IP Address, netmask, title)
- Use addp protocols for simple integration in your UIViewControllers

```
pod 'ADDPServiceBrowser', :git => 'https://github.com/DREEBIT/ADDPServiceBrowser.git'
´´´
## Usage

#### Initialize the browser
```objective-c
  
  self.browser = [[ADDPBrowser alloc] init];
  [self.browser setDelegate:self];
  // Start browsing
  [self.browser startBrowsing];
  
  // Stop after a custom delay
  double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    
        [self.browser stopBrowsing];
        
    });

```

#### Implement the protocol methods
```objective-c
  
- (void)addpBrowser:(ADDPBrowser *)browser didFindDevice:(ADDPDevice *)device {

    NSLog(@"New device found: %@", [device description]);

}

- (void)addpBrowser:(ADDPBrowser *)browser didNotStartBrowsingForDevices:(NSError *)error {

    NSLog(@"Browser hung up: %@", [error localizedDescription]);

}

```

## Emulation

- There is a nice Phyton Script available for test purposes: [Python ADDP library and utilities](https://github.com/zdavkeos/addp)

## Credits

- For further details see: [advanced-digi-discovery-protocol](http://qbeukes.blogspot.de/2009/11/advanced-digi-discovery-protocol_21.html)




