//
//  SmscConnectionRouterUserProtocol.h
//  smsclient
//
//  Created by Andreas Fink on 05.11.12.
//  Copyright (c) 2012 Andreas Fink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SmscConnectionMessagePassingProtocol.h"

@protocol SmscConnectionMessageProtocol;
@protocol SmscConnectionReportProtocol;
@protocol SmscConnectionRouterProtocol;

/* all participants who talk to a router must implement those methods as well as the router itself */
/* this is the basic message forwarding API between the objects */

@protocol SmscConnectionRouterUserProtocol<NSObject,SmscConnectionMessagePassingProtocol>

/* this is only for the User of a router to be implemented */
- (void)  registerMessageRouter:(id<SmscConnectionRouterProtocol>) router;
- (void)  unregisterMessageRouter:(id<SmscConnectionRouterProtocol>) router; 
- (void) setConnectionName:(NSString *)connectionName;
- (NSString *)connectionName;

/* this is for user and router to be implemented */
- (void) setRouterName:(NSString *)routerName;
- (NSString *)routerName;

- (void)startListener;

@optional

- (BOOL) sendHlrReport;
- (void) hlrReport:(id<SmscConnectionReportProtocol>)report forObject:(id)sendingObject;

@end

