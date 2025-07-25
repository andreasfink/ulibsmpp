//
//  SmscRouterUserProtocol.h
//  smsclient
//
//  Created by Andreas Fink on 05.11.12.
//  Copyright (c) 2012 Andreas Fink. All rights reserved.
//

#import <ulib/framework.h>

@protocol SmscRouterUserProtocol <NSObject>

/* we get incoming messages or delivery reports from the router */
- (void) deliverReport:(UMMessageReport * *)report;
- (void) deliverMessage:(UMMessageReport * *)message;

/* we get acknowledgment of outgoing messages we sent */
- (int) messageSent:(UMMessageReport * *)msg;
- (int) messageFailed:(UMMessageReport * *)msg withError:(int)code;

/* we get acknowledgment of outgoing reports we sent */
- (int) reportSent:(UMMessageReport * *)report;
- (int) reportFailed:(UMMessageReport * *)report withError:(int)code;

@end
