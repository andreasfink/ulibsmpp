//
//  SmscRouterProtocol.h
//  smsclient
//
//  Created by Andreas Fink on 05.11.12.
//  Copyright (c) 2012 Andreas Fink. All rights reserved.
//

#pragma error dont use anymore

#import <Foundation/Foundation.h>


/*
 tis protocol specifies what a SMSRouter has to offer in the perspectice of a Router User
 which means an object which uses the router to send messages.
 That object has to follow the SmscRouterUserProtocol.
*/

@protocol SmscRouterProtocolForUser    <SmscConnectionWellProtocol,
                                        SmscReportWellProtocol,
                                        SmscConnectoinMessagePassingProtocol>


//- (SmscConnectionErrorCode) submitMessage:(id<SmscConnectionMessageProtocol>)msg;
//- (SmscConnectionErrorCode) submitReport:(id<SmscConnectionReportProtocol>)report;

//- (SmscConnectionErrorCode) deliverMessage:(id<SmscConnectionMessageProtocol>)msg;
//- (SmscConnectionErrorCode) deliverReport:(id<SmscConnectionReportProtocol>)report;

/* upon reception of deliverReport, the Router user calls back those methods */
//- (int) reportSent:(id<SmscConnectionReportProtocol>)report;
//- (int) reportFailed:(id<SmscConnectionReportProtocol>)report withError:(int)code;

/* upon reception of deliverMessage, the Router user calls back those methods */
//- (int) messageSent:(id<SmscConnectionMessageProtocol>)msg;
//- (int) messageFailed:(id<SmscConnectionMessageProtocol>)msg withError:(int)code;

/* generic stuff */
- (int) registerRouterUser:(id) routerUser;
- (int) unregisterRouterUser:(id) routerUser;

@end

