//
//  TestRouter.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 26.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "SmscConnectionErrorCode.h"
#import "SmscConnectionMessageProtocol.h"
#import "SmscConnectionReportProtocol.h"
#import "SmscConnectionProtocol.h"
#import "TestObject.h"
//#import "TestMessageCache.h"

@class SmscConnectionSMPP, TestRouterTransaction, TestDeliveryReport, TestMessage;

@interface TestRouter : TestObject <SmscConnectionRouterProtocol>
{
    NSMutableArray      *messages;
    NSMutableDictionary *outMessages;
    NSMutableDictionary *outReports;
    NSMutableDictionary *inMessages;
    NSString            *name;
    BOOL                mustQuit;
    
//    TestMessageCache    *messageCache;
    NSMutableArray      *hlrConnections;
    NSMutableArray      *incomingConnections;
    NSMutableDictionary *outgoingConnections;
    NSMutableArray      *listeningConnections;
    NSMutableArray      *sendingConnections;
    NSMutableDictionary *pendingTransactionsByRouterReference;
    NSMutableDictionary *pendingTransactionsByConnectionReference;
    NSMutableDictionary *pendingTransactionsByUserReference;
    NSString            *routerName;
}

@property(readwrite,retain) NSString *routerName;
@property(readwrite,retain) NSMutableDictionary *outMessages;
@property(readwrite,retain) NSMutableDictionary *outReports;
@property(readwrite,retain) NSMutableDictionary *inMessages;
@property(readwrite,assign) BOOL mustQuit;
@property(readwrite,assign) NSMutableArray *hlrConnections;
@property(readwrite,assign) NSMutableArray *incomingConnections;
@property(readwrite,assign) NSMutableDictionary *outgoingConnections;

- (void) setConnectionName:(NSString *)connectionName;
- (NSString *)connectionName;

- (TestRouter *) init;
- (void) dealloc;
- (NSString *)description;

- (void)setName:(NSString *)setName;

/* For the client side */
- (void) submitMessage:(TestMessage *)msg forObject:(id)sendingObject;
- (void) submitMessageSent:(id<SmscConnectionMessageProtocol>)msg forObject:(id)reportingObject;
- (void) submitMessageFailed:(id<SmscConnectionMessageProtocol>)msg withError:(SmscRouterError *)code forObject:(id)reportingObject;
- (void) submitReport:(id<SmscConnectionReportProtocol>)report forObject:(id)sendingObject;
- (void) submitReportSent:(id<SmscConnectionReportProtocol>)report  forObject:(id)reportingObject;
/* For the server side */
- (void) deliverReport:(id<SmscConnectionReportProtocol>)report forObject:(id) sendingObject;
- (void) deliverReportSent:(id<SmscConnectionReportProtocol>)report forObject:(id)reportingObject;
- (void) deliverReportFailed:(id<SmscConnectionReportProtocol>)report withError:(SmscRouterError *)code forObject:(id)reportingObject;
- (void) deliverMessage:(TestMessage *)msg forObject:(id)sendingObject;
- (void) deliverMessageSent:(id<SmscConnectionReportProtocol>)report forObject:(id)reportingObject;
- (void) deliverMessageFailed:(id<SmscConnectionReportProtocol>)report withError:(SmscRouterError *)code forObject:(id)reportingObject;

/* Method used for testing purposes: send deliver sm to proxy, which will resend it back to us*/
- (void) proxyDeliverMessage:(TestMessage *)msg forObject:(id)sendingObject;

- (id<SmscConnectionMessageProtocol>)createMessage;
- (id<SmscConnectionReportProtocol>)createReport;

- (void) registerIncomingSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection;
- (void) unregisterIncomingSmscConnection:(id<SmscConnectionProtocol>) smscConnection;
- (void) registerOutgoingSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection withKey:(NSString *)key;
- (void) unregisterOutgoingSmscConnection:(id<SmscConnectionProtocol>) smscConnection withKey:(NSString *)key;
- (void) registerListeningSmscConnection:(id<SmscConnectionProtocol>) smscConnection;
- (void) unregisterListeningSmscConnection:(id<SmscConnectionProtocol>) smscConnection;
- (void) registerSendingSmscConnection:(id<SmscConnectionProtocol>) smscConnection;
- (void) unregisterSendingSmscConnection:(id<SmscConnectionProtocol>) smscConnection;
- (void) registerHlrConnection:(id<SmscConnectionProtocol>) smscConnection;
- (void) unregisterHlrConnection:(id<SmscConnectionProtocol>) smscConnection;

- (id<SmscConnectionUserProtocol>) authenticateUser:(NSString *)username withPassword:(NSString *)password;
- (BOOL) userExists:(NSString *)username;
- (void) sendFailedDeliveryReportWithTransaction:(TestRouterTransaction *)transaction withMessage:(TestMessage *)message andReport:(TestDeliveryReport *)report;
- (TestMessage *)parseReport:(TestDeliveryReport *)report toMessage:(TestMessage *)message;
- (void)HLRQueryForTransaction:(TestRouterTransaction *)transaction;

-(void)eventSubmitMessage:(TestRouterTransaction *)transaction;
-(void)eventSubmitMessageSent:(TestRouterTransaction *)transaction;
-(void)eventSubmitMessageFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)eventDeliverMessage:(TestRouterTransaction *)transaction;
-(void)eventDeliverMessageSent:(TestRouterTransaction *)transaction;
-(void)eventDeliverMessageFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)eventSubmitReport:(TestRouterTransaction *)transaction;
-(void)eventSubmitReportSent:(TestRouterTransaction *)transaction;
-(void)eventSubmitReportFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)eventDeliverReport:(TestRouterTransaction *)transaction;
-(void)eventDeliverReportSent:(TestRouterTransaction *)transaction;
-(void)eventDeliverReportFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)eventTransactionTimeout:(TestRouterTransaction *)transaction;
#pragma mark -
#pragma mark STATEMACHINE_ACTIONS
-(void)statemachine_eventSubmitMessage_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessage_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessage_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessage_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessage_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessage_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessage_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageSent_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitMessageFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitMessageFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitMessageFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitMessageFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitMessageFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitMessageFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitMessageFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessage_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessage_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessage_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessage_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessage_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessage_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessage_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageSent_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverMessageFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessageFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessageFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessageFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessageFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessageFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverMessageFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReport_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReport_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReport_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReport_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReport_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReport_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReport_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportSent_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventSubmitReportFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReportFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReportFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReportFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReportFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReportFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventSubmitReportFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReport_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReport_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReport_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReport_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReport_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReport_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReport_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportSent_stateFinal:(TestRouterTransaction *)transaction;
-(void)statemachine_eventDeliverReportFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReportFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReportFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReportFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReportFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReportFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventDeliverReportFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err;
-(void)statemachine_eventTransactionTimeout_stateNew:(TestRouterTransaction *)transaction;
-(void)statemachine_eventTransactionTimeout_stateSubmittedToHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventTransactionTimeout_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction;
-(void)statemachine_eventTransactionTimeout_stateSubmittedToForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventTransactionTimeout_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction;
-(void)statemachine_eventTransactionTimeout_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction;
-(void)statemachine_eventTransactionTimeout_stateFinal:(TestRouterTransaction *)transaction;

- (void)updateConnectionReferenceInTransaction:(TestRouterTransaction *)transaction newReference:(NSString *)newConnectionReference;
- (TestRouterTransaction *) findPendingTransactionByRouterReference:(NSString *)ref;
- (TestRouterTransaction *) findPendingTransactionByConnectionReference:(NSString *)ref;
- (void)addPendingTransaction:(TestRouterTransaction *)transaction;
- (void)removePendingTransaction:(TestRouterTransaction *)transaction;
- (void)cleanupTransaction:(TestRouterTransaction *)transaction;
- (void)eventLog:(NSString *)event forTransaction:(TestRouterTransaction *)transaction;
- (void)actionUnimplemented:(NSString *)action forTransaction:(TestRouterTransaction *)transaction;
- (void)actionLog:(NSString *)action forTransaction:(TestRouterTransaction *)transaction;

- (NSString *)htmlStatus;

@end
