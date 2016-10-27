//
//  SmscConnectionProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import "ulib/ulib.h"

#import "SmscConnectionMessageProtocol.h"
#import "SmscConnectionReportProtocol.h"
#import "SmscConnectionRouterProtocol.h"
#import "SmscConnectionRouterUserProtocol.h"
#import "SmscConnectionTransactionProtocol.h"

/* this is what a object which wants to submit messages to the router should obey */

@protocol SmscConnectionSubmitterProtocol

- (void) ackIncomingTransaction:(id<SmscConnectionTransactionProtocol>)transaction;
- (void) nackIncomingTransaction:(id<SmscConnectionTransactionProtocol>)transaction err:(SmscRouterError *)code;

@end

@protocol SmscConnectionProtocol <SmscConnectionRouterUserProtocol>
- (id<SmscConnectionUserProtocol>)user;
- (void)setUser:(id<SmscConnectionUserProtocol>)user;

- (void)  registerMessageRouter:(id<SmscConnectionRouterProtocol>) router; /* returns success */
- (void)  unregisterMessageRouter:(id<SmscConnectionRouterProtocol>) router;  /* returns success */
- (BOOL) isConnected;
- (BOOL) isAuthenticated;
- (NSString *) getName;
- (NSString *) getType;

- (void) setName: (NSString *)name;
- (void) setType: (NSString *)type;
- (void) setLocalPort:  (int) port;
- (void) setVersion:  (NSString *) version;
- (void) setLocalHost:  (UMHost *) host;
- (void) setReceivePollTimeoutMs:(int)receiveTimeout;
- (void) setTransmitTimeout:(int)transmitTimeout;
- (void) setKeepAlive:(int)keepAlive;
- (void) setIsListener:(BOOL)isListener;
- (void) setWindowSize:(int)windowSize;
- (void) setRouterName:(NSString *)routerName;
- (void) setRemoteHost: (UMHost *) host;
- (void) setRemotePort: (int) port;

- (int) setConfig: (NSDictionary *) dict;
- (NSDictionary *) getConfig;
+ (NSDictionary *) getDefaultConnectionConfig;
+ (NSDictionary *) getDefaultListenerConfig;
- (NSString *)htmlStatus;

@end
