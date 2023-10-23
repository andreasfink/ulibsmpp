//
//  SmscRouterUserProtocol.h
//  smsclient
//
//  Created by Andreas Fink on 05.11.12.
//  Copyright (c) 2012 Andreas Fink. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SmscRouterUserProtocol <NSObject>

/* we get incoming messages or delivery reports from the router */
- (void) deliverReport:(id<SmscConnectionReportProtocol>)report;
- (void) deliverMessage:(id<SmscConnectionMessageProtocol>)message;

/* we get acknowledgment of outgoing messages we sent */
- (int) messageSent:(id<SmscConnectionMessageProtocol>)msg;
- (int) messageFailed:(id<SmscConnectionMessageProtocol>)msg withError:(int)code;

/* we get acknowledgment of outgoing reports we sent */
- (int) reportSent:(id<SmscConnectionReportProtocol>)report;
- (int) reportFailed:(id<SmscConnectionReportProtocol>)report withError:(int)code;

@end
