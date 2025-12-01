//
//  SmscRouterProtocol.h
//  smsclient
//
//  Created by Andreas Fink on 05.11.12.
//  Copyright (c) 2012 Andreas Fink. All rights reserved.
//

#pragma error dont use anymore

#import <ulib/framework.h>


/*
 tis protocol specifies what a SMSRouter has to offer in the perspectice of a Router User
 which means an object which uses the router to send messages.
 That object has to follow the SmscRouterUserProtocol.
*/

@protocol SmscRouterProtocolForUser    <SmscConnectionWellProtocol,
                                        SmscReportWellProtocol,
                                        SmscConnectoinMessagePassingProtocol>


//- (SmscConnectionErrorCode) submitMessage:(UMMessageReport * *)msg;
//- (SmscConnectionErrorCode) submitReport:(UMMessageReport * *)report;

//- (SmscConnectionErrorCode) deliverMessage:(UMMessageReport * *)msg;
//- (SmscConnectionErrorCode) deliverReport:(UMMessageReport * *)report;

/* upon reception of deliverReport, the Router user calls back those methods */
//- (int) reportSent:(UMMessageReport * *)report;
//- (int) reportFailed:(UMMessageReport * *)report withError:(int)code;

/* upon reception of deliverMessage, the Router user calls back those methods */
//- (int) messageSent:(UMMessageReport * *)msg;
//- (int) messageFailed:(UMMessageReport * *)msg withError:(int)code;

/* generic stuff */
- (int) registerRouterUser:(id) routerUser;
- (int) unregisterRouterUser:(id) routerUser;

@end

