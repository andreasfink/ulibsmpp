//
//  SmscConnectionRouterProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/framework.h>
#import <ulib/ulib.h>
#import <ulibsmpp/UniversalSMSUtilities.h>

#import <ulibsmpp/SmscConnectionUserProtocol.h>
#import <ulibsmpp/SmscConnectionProtocol.h>
#import <ulibsmpp/SmscConnectionRouterUserProtocol.h>

@protocol SmscConnectionRouterProtocol<NSObject,SmscConnectionRouterUserProtocol>

/* asking the router to provide a new message object */
- (UMMessageObject *)createMessage;
/* asking the router to provide a new report object */
- (UMMessageReport *)createReport;
- (NSString *)newSessionId;

/* generic stuff */

/* an incoming connection which is also a user */
- (void) registerIncomingSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;
- (void) unregisterIncomingSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;

/* outgoing conncetions which could be used for sending. They might not be connected yet */
- (void) registerOutgoingSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;
- (void) unregisterOutgoingSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;

/* listener objects */
- (void) registerListeningSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;
- (void) unregisterListeningSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;

/* connections which are actively connected for outgoing messages */
- (void) registerSendingSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;
- (void) unregisterSendingSmscConnection:(id<SmscConnectionRouterUserProtocol>) smscConnection;


- (id<SmscConnectionUserProtocol>) authenticateUser:(NSString *)username
                                       withPassword:(NSString *)password
                                          ipAddress:(NSString *)ipAddress
                                         systemType:(NSString *)systemType
                                   interfaceVersion:(NSNumber *)interfaceVersion
                                           bindType:(NSString *)bindType
                                            bindTon:(NSNumber *)bindTon
                                            bindNpi:(NSNumber *)bindNpi
                                        bindAddress:(NSString *)bindAddress
                                            session:(NSString *)session;

- (BOOL) userExists:(NSString *)username;

@optional

- (UMMessageObject *)queryMessage:(NSString *)msgid;
- (UMMessageObject *)queryMessage:(NSString *)msgid withNumber:(NSString *)msisdn ton:(UMTonType)ton npi:(UMNpiType)npi;

@optional
- (BOOL) isAddressWhitelisted:(NSString *)remoteIpAddress
                   remotePort:(NSNumber *)remotePort
               localIpAddress:(NSString *)localIpAddress
                    localPort:(NSNumber *)localPort
                  serviceType:(NSString *)serviceType
                         user:(NSString *)username;

@end
