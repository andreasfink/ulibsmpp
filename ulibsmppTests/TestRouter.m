//
//  TestRouter.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 26.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestRouter.h"

#include <uuid/uuid.h>

#import "TestMessage.h"
#import "TestDeliveryReport.h"
#import "TestUser.h"
#import "SmscConnectionSMPP.h"
#import "TestDelegate.h"
#import "TestDeliveryReport.h"
#import "ulib/ulib.h"

extern TestDelegate *global_appDelegate;

@implementation TestRouter

@synthesize outMessages;
@synthesize outReports;
@synthesize inMessages;
@synthesize routerName;
@synthesize mustQuit;
@synthesize hlrConnections;
@synthesize incomingConnections;
@synthesize outgoingConnections;

- (void) setConnectionName:(NSString *)connectionName
{
}

- (NSString *)connectionName
{
    return routerName;
}

- (void)setName:(NSString *)inName
{
    name = inName;
}

- (TestRouter *) init
{
    if ((self = [super init]))
    {
        messages = [[NSMutableArray alloc] init];
        outMessages = [[NSMutableDictionary alloc] init];
        outReports = [[NSMutableDictionary alloc] init];
        inMessages = [[NSMutableDictionary alloc] init];
        messageCache = [[TestMessageCache alloc] init];
        hlrConnections = [[NSMutableArray alloc] init];
        incomingConnections = [[NSMutableArray alloc] init];
        outgoingConnections  = [[NSMutableDictionary alloc] init];
        listeningConnections  = [[NSMutableArray alloc] init];
        sendingConnections  = [[NSMutableArray alloc] init];
        pendingTransactionsByRouterReference = [[NSMutableDictionary alloc] init];
        pendingTransactionsByConnectionReference = [[NSMutableDictionary alloc] init];
        pendingTransactionsByUserReference = [[NSMutableDictionary alloc] init];
        
        mustQuit = NO;
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"Router dump starts\r\n"];
    [desc appendString:@"router dump ends\r\n"];
    
    return desc;
}

- (void) submitMessage:(TestMessage *)msg forObject:(id)sendingObject
{
    if(msg.routerReference == NULL)
    {
        msg.routerReference = [SmscConnection uniqueMessageId];
    }
    
    [messageCache addMessageToCache:msg];
    
    [msg setState:accepted];
    [outMessages setObject:msg forKey:msg.routerReference];
    
    TestRouterTransaction *transaction = msg.routerTransaction;
    if(transaction == NULL)
    {
        if(([hlrConnections count]<1) || ([outgoingConnections count]<1))
        {
            [sendingObject submitMessageFailed:msg withError:SMSC_CONNECTION_ERR_NO_ROUTE_TO_DESTINATION forObject:self];
        }
        id<SmscConnectionProtocol> hlrConnection = [hlrConnections objectAtIndex:0];
        id<SmscConnectionProtocol> smscConnection = [outgoingConnections objectForKey:@"myforwarder"];
        
        transaction = [[TestRouterTransaction alloc];
        transaction.transactionType = SUBMIT_SM;
        transaction.message = msg;
        transaction.originalMessage = msg;
        transaction.userReference = msg.userReference;
        transaction.routerReference = msg.routerReference;
        transaction.connectionReference = msg.connectionReference;
        transaction.upperObject = sendingObject;
        transaction.state = stateNew;
        transaction.connectionForHlr = hlrConnection;
        transaction.connectionForForwarding = smscConnection;
        msg.routerTransaction = transaction;
    }
    NSLog(@"submit message: we have connection reference %@\r\n", msg.connectionReference);
    [self eventSubmitMessage:transaction];
    [self cleanupTransaction:transaction];
}

/* For testing purposes: sending deliver_sm to proxy. (It will send it back, a legimate deliver_sm operation.)*/
- (void) proxyDeliverMessage:(TestMessage *)msg forObject:(id)sendingObject
{
    if(msg.routerReference == NULL)
    {
        msg.routerReference = [SmscConnection uniqueMessageId];
    }
    
    [messageCache addMessageToCache:msg];
    
    [msg setDeliverState:deliverAccepted];
    [inMessages setObject:msg forKey:msg.routerReference];
    
    id<SmscConnectionProtocol> proxyConnection = [outgoingConnections objectForKey:@"myproxy"];
    
    TestRouterTransaction *transaction = [[TestRouterTransaction alloc]init];
    transaction.transactionType = DELIVER_SM;
    transaction.message = msg;
    transaction.originalMessage = msg;
    transaction.userReference = msg.userReference;
    transaction.routerReference = msg.routerReference;
    transaction.connectionReference = msg.connectionReference;
    transaction.upperObject = sendingObject;
    transaction.state = stateNew;
    transaction.connectionForProxy = proxyConnection;
    msg.routerTransaction = transaction;
    
    NSLog(@"deliver sm: we have connection reference %@ (passing the message to the proxy)\r\n", msg.connectionReference);
    [self eventDeliverMessage:transaction];
    [self cleanupTransaction:transaction];
}

/* Indicates receiving deliver_sm*/
- (void) deliverMessage:(TestMessage *)msg forObject:(id)sendingObject
{
    if(msg.routerReference == NULL)
    {
        msg.routerReference = [SmscConnection uniqueMessageId];
    }
    
    [messageCache addMessageToCache:msg];
    
    [msg setDeliverState:deliverAccepted];
    [inMessages setObject:msg forKey:msg.routerReference];
    
    id<SmscConnectionProtocol> proxyConnection = [outgoingConnections objectForKey:@"myproxy"];
        
    TestRouterTransaction *transaction = [[TestRouterTransaction alloc]init];
    transaction.transactionType = DELIVER_SM;
    transaction.message = msg;
    transaction.originalMessage = msg;
    transaction.userReference = msg.userReference;
    transaction.routerReference = msg.routerReference;
    transaction.connectionReference = msg.connectionReference;
    transaction.upperObject = sendingObject;
    transaction.state = stateNew;
    transaction.connectionForProxy = proxyConnection;
    msg.routerTransaction = transaction;
    
    NSLog(@"deliver sm: we have connection reference %@ (passing the message to the proxy)\r\n", msg.connectionReference);
    [self eventDeliverMessage:transaction];
    [self cleanupTransaction:transaction];
}

- (void) submitMessageSent:(TestMessage *)msg forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = msg.routerTransaction;
    [self updateConnectionReferenceInTransaction:transaction newReference:msg.connectionReference];
    [self eventSubmitMessageSent:transaction];
    [self cleanupTransaction:transaction];
    
    NSString *contentString = [[NSString alloc] initWithData:[[msg dbPduContent] data] encoding:NSUTF8StringEncoding];
    NSString *ourName = [reportingObject name];
    NSLog(@"submit message sent: we have connection reference %@\r\n for message %@ (type %@) to %@", msg.connectionReference, contentString, [transaction transactionTypeToString], ourName);
    
    TestMessage *outMessage = [outMessages objectForKey:msg.routerReference];
    TestMessage *inMessage = [inMessages objectForKey:msg.routerReference];
    
    if ([ourName compare:@"hlr"] == 0)
    {
        if (transaction.transactionType == SUBMIT_SM)
            [outMessage setState:hlrResponse];
        else if (transaction.transactionType == DELIVER_SM)
            [inMessage setDeliverState:deliverHlrResponse];
    }
    else if ([ourName compare:@"myforwarder"] == 0)
    {
        if (transaction.transactionType == SUBMIT_SM)
            [outMessage setState:acked];
        else if (transaction.transactionType == DELIVER_SM)
            [inMessage setDeliverState:deliverAcked];
    }
        
    if (outMessage)
    {
        [outMessages removeObjectForKey:msg.routerReference];
        [outMessages setObject:outMessage forKey:msg.routerReference];
    }
    
    if (inMessage)
    {
        [inMessages removeObjectForKey:msg.routerReference];
        [inMessages setObject:inMessage forKey:msg.routerReference];
    }
}

- (void) submitMessageFailed:(id<SmscConnectionMessageProtocol>)msg withError:(SmscRouterError *)code forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = msg.routerTransaction;
    [self updateConnectionReferenceInTransaction:transaction newReference:msg.connectionReference];
    [self eventSubmitMessageFailed:transaction withError:code];
    [self cleanupTransaction:transaction];
    NSLog(@"submit message failed: we have connection reference %@\r\n", msg.connectionReference);
    TestMessage *outMessage = [outMessages objectForKey:msg.routerReference];
    TestMessage *inMessage = [inMessages objectForKey:msg.routerReference];
    
     NSString *ourName = [reportingObject name];
    if ([ourName compare:@"hlr"] == 0)
    {
        if (transaction.transactionType == SUBMIT_SM)
            [outMessage setState:noHlrResponse];
        else if (transaction.transactionType == DELIVER_SM)
            [inMessage setDeliverState:deliverNoHlrResponse];
    }
    else if ([ourName compare:@"myforwarder"] == 0)
    {
        if (transaction.transactionType == SUBMIT_SM)
            [outMessage setState:notSent];
        else if (transaction.transactionType == DELIVER_SM)
            [inMessage setDeliverState:deliverNotSent];
    }
        
    if (outMessage)
    {
        [outMessages removeObjectForKey:msg.routerReference];
        [outMessages setObject:outMessage forKey:msg.routerReference];
    }
    
    if (inMessage)
    {
        [inMessages removeObjectForKey:msg.routerReference];
        [inMessages setObject:inMessage forKey:msg.routerReference];
    }
}

- (void) deliverMessageSent:(TestMessage *)msg forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = msg.routerTransaction;
    [self updateConnectionReferenceInTransaction:transaction newReference:msg.connectionReference];
    [self eventDeliverMessageSent:transaction];
    [self cleanupTransaction:transaction];
    
    NSString *contentString = [[NSString alloc] initWithData:[[msg dbPduContent] data] encoding:NSUTF8StringEncoding];
    NSLog(@"deliver message sent: we have connection reference %@ for msg %@\r\n", msg.connectionReference, contentString);
    
    TestMessage *inMessage = [inMessages objectForKey:msg.routerReference];
    
    [inMessage setDeliverState:deliverAcked];
    
    if (inMessage)
    {
        [inMessages removeObjectForKey:msg.routerReference];
        [inMessages setObject:inMessage forKey:msg.routerReference];
    }

}

- (void) deliverMessageFailed:(TestMessage *)msg withError:(SmscRouterError *)code forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = msg.routerTransaction;
    [self updateConnectionReferenceInTransaction:transaction newReference:msg.connectionReference];
    [self eventDeliverMessageFailed:transaction withError:code];
    [self cleanupTransaction:transaction];
    NSLog(@"deliver message failed: we have connection reference %@\r\n", msg.connectionReference);
    TestMessage *inMessage = [inMessages objectForKey:msg.routerReference];
    
    [inMessage setDeliverState:deliverNotSent];
    
    [inMessages removeObjectForKey:msg.routerReference];
    [inMessages setObject:inMessage forKey:msg.routerReference];

}

- (void) deliverReport:(TestDeliveryReport *)report forObject:(id) sendingObject
{
    NSString *ourName = [sendingObject name];
    TestRouterTransaction *transaction = [self findPendingTransactionByConnectionReference:report.connectionReference];
    TestMessage *outMessage, *inMessage;
    
    outMessage = [outMessages objectForKey:transaction.routerReference];
    inMessage = [inMessages objectForKey:transaction.routerReference];
    outMessage = [self parseReport:report toMessage:outMessage];
    inMessage = [self parseReport:report toMessage:inMessage];
    
    BOOL message_rejected = report.reportType == SMS_REPORT_EXPIRED || report.reportType == SMS_REPORT_DELETED || report.reportType == SMS_REPORT_UNDELIVERABLE || report.reportType == SMS_REPORT_REJECTED;
    
    NSLog(@"deliver report: we have connection reference %@ for report %@ (transaction type %@) from %@\r\n", report.connectionReference, report.reportText, [transaction transactionTypeToString], ourName);
    if(transaction==NULL) {
        /* move it off the queue */
        [sendingObject deliverReportSent:report forObject:self];
        /* End test, if we got a delivery report with no matching transaction */
        mustQuit = YES;       
        
        if (outMessage)
        {
            if ([ourName compare:@"hlr"] == 0)
            {
                [outMessage setState:noHlrReport];
                [report setReportState:noHlrSent];
            }
            else if ([ourName compare:@"myforwarder"] == 0)
            {
                [outMessage setState:notDelivered];
                [report setReportState:reportNotSent];
            }
        }
        
        if (inMessage)
        {
            [inMessage setDeliverState:deliverNoHlrReport];
            [report setDeliverReportState:deliverNoHlrSent];
        }
    }
    else
    {
        report.routerReference = transaction.routerReference;
        TestMessage *msg =  transaction.message;
        msg.messageState = report.reportType;
        transaction.report = report;
        [self eventDeliverReport:transaction];
        [self cleanupTransaction:transaction];
    }
    
    BOOL submitHlrReportOK = outMessage.mnc && outMessage.mcc && [[outMessage mnc] length] > 0 && [[outMessage mcc] length] > 0;
    BOOL deliverHlrReportOK = inMessage.mnc && inMessage.mcc && [[inMessage mnc] length] > 0 && [[inMessage mcc] length] > 0;
    
    /* we ignore delivery reports with unknown message id (which would give nil transaction)
     * delivery report from HLR (the route)*/
    if (transaction && [ourName compare:@"hlr"] == 0)
    {
        if (submitHlrReportOK && !message_rejected)
        {
            [outMessage setState:hlrReport];
            [report setReportState:hlrSent];
        }
        else if (deliverHlrReportOK && !message_rejected)
        {
            [inMessage setDeliverState:deliverHlrReport];
            [report setDeliverReportState:deliverHlrSent];
        }
        else if (transaction.transactionType == SUBMIT_SM)
        {
            [outMessage setState:noHlrReport];
            [report setReportState:noHlrSent];
        }
        else if (transaction.transactionType == DELIVER_SM)
        {
            [inMessage setDeliverState:deliverNoHlrReport];
            [report setDeliverReportState:deliverNoHlrSent];
        }
    }
    
    /* delivery report from forwardser)*/
    else if (transaction && [ourName compare:@"myforwarder"] == 0)
    {
        if (!message_rejected)
        {
            [outMessage setState:delivered];
            [report setReportState:reportSent];
        }
        else
        {
            [outMessage setState:notDelivered];
            [report setReportState:reportNotSent];
        }
    }
    
    if (outMessage)
        [outReports setObject:report forKey:report.connectionReference];
}

- (void) deliverReportSent:(id<SmscConnectionReportProtocol>)report forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = [self findPendingTransactionByRouterReference:report.routerReference];
    [self eventDeliverReportSent:transaction];
    [self cleanupTransaction:transaction];
    
    TestDeliveryReport *testReport = [outReports objectForKey:transaction.routerReference];
    [testReport setReportState:reportAcked];
}

- (void) deliverReportFailed:(id<SmscConnectionReportProtocol>)report withError:(SmscRouterError *)code forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = [self findPendingTransactionByRouterReference:report.routerReference];
    [self eventDeliverReportFailed:transaction withError:code];
    [self cleanupTransaction:transaction];
}

- (void) submitReport:(id<SmscConnectionReportProtocol>)report forObject:(id)sendingObject
{
    TestRouterTransaction *transaction = [self findPendingTransactionByRouterReference:report.routerReference];
    if(transaction)
    {
        [sendingObject submitReportFailed:report withError:SMSC_CONNECTION_ERR_MESSAGE_NOT_FOUND_IN_SMSC forObject:self];
    }
    else
    {
        [self eventSubmitReport:transaction];
        [self cleanupTransaction:transaction];
    }
}

- (void) submitReportSent:(id<SmscConnectionReportProtocol>)report  forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = [self findPendingTransactionByRouterReference:report.routerReference];
    [self eventSubmitReportSent:transaction];
    [self cleanupTransaction:transaction];
}

- (void) submitReportFailed:(id<SmscConnectionReportProtocol>)report withError:(SmscRouterError *)code forObject:(id)reportingObject
{
    TestRouterTransaction *transaction = [self findPendingTransactionByRouterReference:report.routerReference];
    [self eventSubmitReportFailed:transaction withError:code];
    [self cleanupTransaction:transaction];
}


/* router gets asked to create a new message object */
- (id<SmscConnectionMessageProtocol>)createMessage
{
    TestMessage *msg = [[TestMessage alloc]init];
    msg.routerReference = [SmscConnection uniqueMessageId];
    return msg;
}

- (id<SmscConnectionReportProtocol>)createReport
{
    TestDeliveryReport *report = [[TestDeliveryReport alloc]init];
    return report;
}

- (id<SmscConnectionReportProtocol>)	newReport
{
    id<SmscConnectionReportProtocol> report;
    
    report = [[TestDeliveryReport alloc] init];
       
    return report;
}

- (void) registerIncomingSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection
{
    @synchronized(incomingConnections)
    {
        if(smscConnection)
        {
            [incomingConnections removeObject:smscConnection];/*just in case its already there */
        }
        [incomingConnections addObject:smscConnection];
        [smscConnection setRouterName:[self routerName]];
        [smscConnection registerMessageRouter:self];
    }
}

- (void) unregisterIncomingSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection
{
    @synchronized(incomingConnections)
    {
        if(smscConnection)
        {
            [incomingConnections removeObject:smscConnection];
        }
        [smscConnection setRouterName:NULL];
        [smscConnection unregisterMessageRouter:self];
    }
}

- (void) registerOutgoingSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection withKey:(NSString *)key
{
    @synchronized(outgoingConnections)
    {
        if(key)
        {
            [outgoingConnections removeObjectForKey:key];
        }
        [outgoingConnections setObject:smscConnection forKey:key];
        [smscConnection setRouterName:[self routerName]];
        [smscConnection registerMessageRouter:self];
    }
}

- (void) unregisterOutgoingSmscConnection:(id<SmscConnectionProtocol>) smscConnection withKey:(NSString *)key
{
    @synchronized(outgoingConnections)
    {
        if(key)
        {
            [outgoingConnections removeObjectForKey:key];
        }
        [smscConnection setRouterName:NULL];
        [smscConnection unregisterMessageRouter:self];
    }
}

- (void) registerListeningSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection
{
    @synchronized(listeningConnections)
    {
        if(smscConnection)
        {
            [listeningConnections removeObject:smscConnection];
        }
        [listeningConnections addObject:smscConnection];
        [smscConnection setRouterName:[self routerName]];
        [smscConnection registerMessageRouter:self];
    }
}

- (void) unregisterListeningSmscConnection:(id<SmscConnectionProtocol>) smscConnection
{
    @synchronized(listeningConnections)
    {
        if(smscConnection)
        {
            [listeningConnections removeObject:smscConnection];
        }
        [smscConnection setRouterName:NULL];
        [smscConnection unregisterMessageRouter:self];
    }
}

- (void) registerSendingSmscConnection:(id<SmscConnectionProtocol, NSObject>) smscConnection
{
    @synchronized(sendingConnections)
    {
        if(smscConnection)
        {
            [sendingConnections removeObject:smscConnection];
        }
        [sendingConnections addObject:smscConnection];
    }
}

- (void) unregisterSendingSmscConnection:(id<SmscConnectionProtocol>) smscConnection
{
    @synchronized(sendingConnections)
    {
        [sendingConnections removeObject:smscConnection];
    }

}

- (id<SmscConnectionUserProtocol>) authenticateUser:(NSString *)username withPassword:(NSString *)password
{
    TestUser *user;
    
    user = [[TestUser alloc] init];
    
    return user;
}

- (BOOL) userExists:(NSString *)username
{
    return YES;
}

- (void)  registerMessageRouter:(id<SmscConnectionRouterProtocol>) router
{
}

- (void)  unregisterMessageRouter:(id<SmscConnectionRouterProtocol>) router
{
}

- (void) registerHlrConnection:(id<SmscConnectionProtocol>) smscConnection
{
    @synchronized(hlrConnections)
    {
        [hlrConnections removeObject:smscConnection];
        [hlrConnections addObject:smscConnection];
        [smscConnection setRouterName:[self routerName]];
        [smscConnection registerMessageRouter:self];
    }
}

- (void) unregisterHlrConnection:(id<SmscConnectionProtocol>) smscConnection
{
    @synchronized(hlrConnections)
    {
        [hlrConnections removeObject:smscConnection];
        [smscConnection setRouterName:NULL];
        [smscConnection unregisterMessageRouter:self];
    }
}

- (NSString *)htmlStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"<h3>Incoming:</h3><br>\n"];
    id<SmscConnectionProtocol> con;
    for(con in incomingConnections)
    {
        [s appendFormat:@"%@<br>\n",[con htmlStatus]];
    }
    
    [s appendFormat:@"<h3>Outgoing:</h3><br>\n"];
    for(con in outgoingConnections)
    {
        [s appendFormat:@"%@<br>\n",[con htmlStatus]];
    }
    
    [s appendFormat:@"<h3>HLR:</h3><br>\n"];
    for(con in hlrConnections)
    {
        [s appendFormat:@"%@<br>\n",[con htmlStatus]];
    }
    
    return s;
}

-(void)eventSubmitMessage:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventSubmitMessage" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventSubmitMessage_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventSubmitMessage_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventSubmitMessage_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventSubmitMessage_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventSubmitMessage_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventSubmitMessage_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventSubmitMessage_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventSubmitMessage: Unhandled state %d",transaction.state);
			break;
	}
}

- (void)HLRQueryForTransaction:(TestRouterTransaction *)transaction
{
    TestMessage *hlrMessage = [[TestMessage alloc]init];
    TestMessage *msg = transaction.originalMessage;
    hlrMessage.routerReference = msg.routerReference;
    hlrMessage.to = msg.to;
    hlrMessage.fromString = @"+000";
    hlrMessage.reportMask = UMDLR_MASK_FINAL;
    hlrMessage.pduContent = [NSData dataWithBytes:"HLR" length:3];
    hlrMessage.routerTransaction = transaction;
    [transaction.connectionForHlr submitMessage:hlrMessage forObject:self];
}

- (void)ProxyPassForTransaction:(TestRouterTransaction *)transaction
{
    TestMessage *proxyMessage = [[TestMessage alloc]init];
    TestMessage *msg = transaction.originalMessage;
    proxyMessage.routerReference = msg.routerReference;
    proxyMessage.to = msg.to;
    proxyMessage.from = msg.from;
    proxyMessage.reportMask = UMDLR_MASK_FINAL;
    proxyMessage.pduContent = msg.pduContent;
    proxyMessage.routerTransaction = transaction;
    [transaction.connectionForProxy proxyDeliverMessage:proxyMessage forObject:self];
}


-(void)statemachine_eventSubmitMessage_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateNew" forTransaction:transaction];
    [self HLRQueryForTransaction:transaction];
    transaction.state = stateSubmittedToHlr;
    [self addPendingTransaction:transaction];
}

-(void)statemachine_eventSubmitMessage_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessage_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessage_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessage_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessage_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessage_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessage_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessage_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessage_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessage_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessage_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessage_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessage_stateFinal" forTransaction:transaction];
}

-(void)eventDeliverMessage:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventDeliverMessage" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventDeliverMessage_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventDeliverMessage_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventDeliverMessage_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventDeliverMessage_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventDeliverMessage_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventDeliverMessage_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventDeliverMessage_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventDeliverMessage: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventDeliverMessage_stateNew:(TestRouterTransaction *)transaction
{
    [self actionLog:@"statemachine_eventDeliverMessage_stateNew" forTransaction:transaction];
    [self ProxyPassForTransaction:transaction];
    transaction.state = stateSubmittedToHlr;
    [self addPendingTransaction:transaction];
}

-(void)statemachine_eventDeliverMessage_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessage_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessage_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessage_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessage_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessage_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessage_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessage_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessage_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessage_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessage_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessage_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessage_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessage_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessage_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessage_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessage_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessage_stateFinal" forTransaction:transaction];
}

-(void)eventSubmitMessageSent:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventSubmitMessageSent" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventSubmitMessageSent_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventSubmitMessageSent_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventSubmitMessageSent_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventSubmitMessageSent_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventSubmitMessageSent_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventSubmitMessageSent_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventSubmitMessageSent_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventSubmitMessageSent: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventSubmitMessageSent_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageSent_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateSubmittedToHlr" forTransaction:transaction];
    [transaction.upperObject submitMessageSent:transaction.originalMessage forObject:self];
    transaction.state = stateAwaitingReportFromHlr;
}

-(void)statemachine_eventSubmitMessageSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageSent_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateSubmittedToForwarder" forTransaction:transaction];
    transaction.state = stateAwaitingReportFromForwarder;
}

-(void)statemachine_eventSubmitMessageSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageSent_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitMessageSent_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageSent_stateFinal" forTransaction:transaction];
}

-(void)eventSubmitMessageFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self eventLog:@"eventSubmitMessageFailed" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventSubmitMessageFailed_stateNew:transaction withError:err];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventSubmitMessageFailed_stateSubmittedToHlr:transaction withError:err];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventSubmitMessageFailed_stateAwaitingReportFromHlr:transaction withError:err];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventSubmitMessageFailed_stateSubmittedToForwarder:transaction withError:err];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventSubmitMessageFailed_stateAwaitingReportFromForwarder:transaction withError:err];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventSubmitMessageFailed_stateAwaitingReportAcknowlegmentFromUser:transaction withError:err];
			break;
		case stateFinal:
			[self statemachine_eventSubmitMessageFailed_stateFinal:transaction withError:err];
			break;
		default:
			NSAssert(NO,@"eventSubmitMessageFailed: Unhandled state %d err %d",transaction.state,err);
			break;
	}
}

-(void)statemachine_eventSubmitMessageFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageFailed_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateSubmittedToHlr" forTransaction:transaction];
    [transaction.upperObject submitMessageFailed:transaction.originalMessage withError:err forObject:self];
    transaction.state = stateAwaitingReportFromHlr;
}

-(void)statemachine_eventSubmitMessageFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageFailed_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventSubmitMessageFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitMessageFailed_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitMessageFailed_stateFinal" forTransaction:transaction];
}

-(void)eventDeliverMessageSent:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventDeliverMessageSent" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventDeliverMessageSent_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventDeliverMessageSent_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventDeliverMessageSent_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventDeliverMessageSent_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventDeliverMessageSent_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventDeliverMessageSent_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventDeliverMessageSent_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventDeliverMessageSent: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventDeliverMessageSent_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageSent_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverMessageSent_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageSent_stateFinal" forTransaction:transaction];
}

-(void)eventDeliverMessageFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self eventLog:@"eventDeliverMessageFailed" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventDeliverMessageFailed_stateNew:transaction withError:err];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventDeliverMessageFailed_stateSubmittedToHlr:transaction withError:err];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventDeliverMessageFailed_stateAwaitingReportFromHlr:transaction withError:err];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventDeliverMessageFailed_stateSubmittedToForwarder:transaction withError:err];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventDeliverMessageFailed_stateAwaitingReportFromForwarder:transaction withError:err];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventDeliverMessageFailed_stateAwaitingReportAcknowlegmentFromUser:transaction withError:err];
			break;
		case stateFinal:
			[self statemachine_eventDeliverMessageFailed_stateFinal:transaction withError:err];
			break;
		default:
			NSAssert(NO,@"eventDeliverMessageFailed: Unhandled state %d err %d",transaction.state,err);
			break;
	}
}

-(void)statemachine_eventDeliverMessageFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventDeliverMessageFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverMessageFailed_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverMessageFailed_stateFinal" forTransaction:transaction];
}

-(void)eventDeliverReport:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventDeliverReport" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventDeliverReport_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventDeliverReport_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventDeliverReport_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventDeliverReport_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventDeliverReport_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventDeliverReport_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventDeliverReport_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventDeliverReport: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventDeliverReport_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReport_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReport_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReport_stateSubmittedToHlr" forTransaction:transaction];
}

/* negative reports */
/* TODO: toUser: deliverReport(status=failed) */
- (void) sendFailedDeliveryReportWithTransaction:(TestRouterTransaction *)transaction withMessage:(TestMessage *)message andReport:(TestDeliveryReport *)report
{
    TestDeliveryReport *upReport = [self createReport];
    upReport.routerReference = message.routerReference;
    upReport.userReference = message.userReference;
    upReport.reportText = report.reportText;
    upReport.reportType = report.reportType;
    upReport.errorCode = report.errorCode;
    upReport.destination = message.from;
    upReport.source = message.to;
    [transaction.upperObject deliverReport:upReport forObject:self];
    transaction.state = stateAwaitingReportAcknowlegmentFromUser;
}

- (TestMessage *)parseReport:(TestDeliveryReport *)report toMessage:(TestMessage *)message
{
    if (!message)
        return nil;
    
    NSString *r = [report.reportText stringByReplacingOccurrencesOfString:@" date" withString:@"_date"];
    NSArray *parts = [r componentsSeparatedByString:@" "];
    for(NSString *line in parts)
    {
        NSString *tag = NULL;
        NSString *value = NULL;
        NSArray *items = [line componentsSeparatedByString:@":"];
        int i = 0;
        for(NSString *item in items)
        {
            if(i==0)
            {
                tag = item;
                i++;
            }
            else
            {
                if(value==NULL)
                {
                    value = item;
                }
                else
                {
                    value = [NSString stringWithFormat:@"%@%@",value,item];
                }
            }
        }
        if([tag isEqualToString:@"MNC"])
        {
            message.mnc = value;
        }
        else if([tag isEqualToString:@"MCC"])
        {
            message.mcc = value;
        }
        else if([tag isEqualToString:@"IMSI"])
        {
            message.imsi = value;
        }
        else if([tag isEqualToString:@"MSC"])
        {
            message.msc = [NSString stringWithFormat:@"+%@",value];
            message.smsc1 = @"+111";
            message.smsc2 = [global_appDelegate smsc2ForDestination:message.toString mcc:message.mcc mnc:message.mnc];
            message.smsc3 = [global_appDelegate smsc3ForDestination:message.toString mcc:message.mcc mnc:message.mnc];
            message.userflags = @"16"; /* USERFLAG_USE_SECONDARY_HLR */
        }
    }
    
    return message;
}

-(void)statemachine_eventDeliverReport_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateAwaitingReportFromHlr" forTransaction:transaction];
    [transaction.connectionForHlr deliverReportSent:transaction.report forObject:self];
    id<SmscConnectionReportProtocol> report = transaction.report;
    TestMessage * message = transaction.originalMessage;
    message = [self parseReport:report toMessage:message];
    
    switch(report.reportType)
    {
        case SMS_REPORT_SUBMITTED:
        case SMS_REPORT_ENROUTE:
        case SMS_REPORT_ACCEPTED:
            /* temporary reports */
            break;
        case SMS_REPORT_DELIVERED:
            /* if we get HLR data we deliver message to forwarder */
            if (message.mnc && message.mcc)
            {
                if (transaction.transactionType == SUBMIT_SM)
                    [transaction.connectionForForwarding submitMessage:transaction.originalMessage forObject:self];
                else if (transaction.transactionType == DELIVER_SM)
                    [transaction.upperObject deliverMessage:transaction.originalMessage forObject:self];
                transaction.state = stateSubmittedToForwarder;
            }
            /* negative report if we did not */
            else
            {
                [self sendFailedDeliveryReportWithTransaction:transaction withMessage:message andReport:report];
                transaction.state = stateAwaitingReportAcknowlegmentFromUser;
            }
            break;
        case SMS_REPORT_EXPIRED:
        case SMS_REPORT_DELETED:
        case SMS_REPORT_UNDELIVERABLE:
        case SMS_REPORT_REJECTED:
            [self sendFailedDeliveryReportWithTransaction:transaction withMessage:message andReport:report];
            break;
        case SMS_REPORT_UNSET:
        case SMS_REPORT_UNKNOWN:
        default:
            NSAssert(NO,@"dont know reportType value %d",report.reportType);
            break;
    }
}

-(void)statemachine_eventDeliverReport_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReport_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReport_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateAwaitingReportFromForwarder" forTransaction:transaction];
    [transaction.connectionForForwarding deliverReportSent:transaction.report forObject:self];
    TestDeliveryReport *report = transaction.report;
    switch(report.reportType)
    {
        case SMS_REPORT_SUBMITTED:
        case SMS_REPORT_ENROUTE:
        case SMS_REPORT_ACCEPTED:
            /* temporary reports */
        case SMS_REPORT_DELIVERED:
            /* positive report. For testing purposes, accept temporary reports */
            report.reportToMsg = transaction.originalMessage;
            report.routerReference = transaction.originalMessage.routerReference;
            transaction.state = stateAwaitingReportAcknowlegmentFromUser;
            break;
        case SMS_REPORT_EXPIRED:
        case SMS_REPORT_DELETED:
        case SMS_REPORT_UNDELIVERABLE:
        case SMS_REPORT_REJECTED:
            /* negative reports */
            report.routerReference = transaction.originalMessage.routerReference;
            [transaction.connectionForForwarding submitMessage:transaction.originalMessage forObject:self];
            [transaction.upperObject deliverReport:report forObject:self];
            transaction.state = stateAwaitingReportAcknowlegmentFromUser;
            break;
        case SMS_REPORT_UNSET:
        case SMS_REPORT_UNKNOWN:
        default:
            NSAssert(NO,@"dont know reportType value %d",(int)report.reportType);
            break;
    }
}

-(void)statemachine_eventDeliverReport_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReport_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReport_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReport_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReport_stateFinal" forTransaction:transaction];
}

-(void)eventDeliverReportSent:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventDeliverReportSent" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventDeliverReportSent_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventDeliverReportSent_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventDeliverReportSent_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventDeliverReportSent_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventDeliverReportSent_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventDeliverReportSent_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventDeliverReportSent_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventDeliverReportSent: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventDeliverReportSent_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportSent_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportSent_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportSent_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportSent_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
    transaction.state = stateFinal;
}

-(void)statemachine_eventDeliverReportSent_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventDeliverReportSent_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportSent_stateFinal" forTransaction:transaction];
}

-(void)eventDeliverReportFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self eventLog:@"eventDeliverReportFailed" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventDeliverReportFailed_stateNew:transaction withError:err];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventDeliverReportFailed_stateSubmittedToHlr:transaction withError:err];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventDeliverReportFailed_stateAwaitingReportFromHlr:transaction withError:err];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventDeliverReportFailed_stateSubmittedToForwarder:transaction withError:err];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventDeliverReportFailed_stateAwaitingReportFromForwarder:transaction withError:err];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventDeliverReportFailed_stateAwaitingReportAcknowlegmentFromUser:transaction withError:err];
			break;
		case stateFinal:
			[self statemachine_eventDeliverReportFailed_stateFinal:transaction withError:err];
			break;
		default:
			NSAssert(NO,@"eventDeliverReportFailed: Unhandled state %d err %d",transaction.state,err);
			break;
	}
}

-(void)statemachine_eventDeliverReportFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportFailed_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportFailed_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportFailed_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventDeliverReportFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
    transaction.state = stateFinal;
}

-(void)statemachine_eventDeliverReportFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventDeliverReportFailed_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventDeliverReportFailed_stateFinal" forTransaction:transaction];
}

-(void)eventSubmitReport:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventSubmitReport" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventSubmitReport_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventSubmitReport_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventSubmitReport_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventSubmitReport_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventSubmitReport_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventSubmitReport_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventSubmitReport_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventSubmitReport: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventSubmitReport_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReport_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReport_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReport_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReport_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReport_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReport_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReport_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReport_stateFinal" forTransaction:transaction];
}

-(void)eventSubmitReportSent:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventSubmitReportSent" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventSubmitReportSent_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventSubmitReportSent_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventSubmitReportSent_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventSubmitReportSent_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventSubmitReportSent_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventSubmitReportSent_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventSubmitReportSent_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventSubmitReportSent: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventSubmitReportSent_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportSent_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportSent_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportSent_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportSent_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportSent_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportSent_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventSubmitReportSent_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportSent_stateFinal" forTransaction:transaction];
}

-(void)eventSubmitReportFailed:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self eventLog:@"eventSubmitReportFailed" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventSubmitReportFailed_stateNew:transaction withError:err];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventSubmitReportFailed_stateSubmittedToHlr:transaction withError:err];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventSubmitReportFailed_stateAwaitingReportFromHlr:transaction withError:err];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventSubmitReportFailed_stateSubmittedToForwarder:transaction withError:err];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventSubmitReportFailed_stateAwaitingReportFromForwarder:transaction withError:err];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventSubmitReportFailed_stateAwaitingReportAcknowlegmentFromUser:transaction withError:err];
			break;
		case stateFinal:
			[self statemachine_eventSubmitReportFailed_stateFinal:transaction withError:err];
			break;
		default:
			NSAssert(NO,@"eventSubmitReportFailed: Unhandled state %d err %d",transaction.state,err);
			break;
	}
}

-(void)statemachine_eventSubmitReportFailed_stateNew:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportFailed_stateSubmittedToHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportFailed_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportFailed_stateSubmittedToForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportFailed_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportFailed_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventSubmitReportFailed_stateFinal:(TestRouterTransaction *)transaction withError:(SmscRouterError *)err
{
	[self actionLog:@"statemachine_eventSubmitReportFailed_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventSubmitReportFailed_stateFinal" forTransaction:transaction];
}

-(void)eventTransactionTimeout:(TestRouterTransaction *)transaction
{
	[self eventLog:@"eventTransactionTimeout" forTransaction:transaction];
	switch(transaction.state)
	{
		case stateNew:
			[self statemachine_eventTransactionTimeout_stateNew:transaction];
			break;
		case stateSubmittedToHlr:
			[self statemachine_eventTransactionTimeout_stateSubmittedToHlr:transaction];
			break;
		case stateAwaitingReportFromHlr:
			[self statemachine_eventTransactionTimeout_stateAwaitingReportFromHlr:transaction];
			break;
		case stateSubmittedToForwarder:
			[self statemachine_eventTransactionTimeout_stateSubmittedToForwarder:transaction];
			break;
		case stateAwaitingReportFromForwarder:
			[self statemachine_eventTransactionTimeout_stateAwaitingReportFromForwarder:transaction];
			break;
		case stateAwaitingReportAcknowlegmentFromUser:
			[self statemachine_eventTransactionTimeout_stateAwaitingReportAcknowlegmentFromUser:transaction];
			break;
		case stateFinal:
			[self statemachine_eventTransactionTimeout_stateFinal:transaction];
			break;
		default:
			NSAssert(NO,@"eventTransactionTimeout: Unhandled state %d",transaction.state);
			break;
	}
}

-(void)statemachine_eventTransactionTimeout_stateNew:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateNew" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateNew" forTransaction:transaction];
}

-(void)statemachine_eventTransactionTimeout_stateSubmittedToHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateSubmittedToHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateSubmittedToHlr" forTransaction:transaction];
}

-(void)statemachine_eventTransactionTimeout_stateAwaitingReportFromHlr:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateAwaitingReportFromHlr" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateAwaitingReportFromHlr" forTransaction:transaction];
}

-(void)statemachine_eventTransactionTimeout_stateSubmittedToForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateSubmittedToForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateSubmittedToForwarder" forTransaction:transaction];
}

-(void)statemachine_eventTransactionTimeout_stateAwaitingReportFromForwarder:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateAwaitingReportFromForwarder" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateAwaitingReportFromForwarder" forTransaction:transaction];
}

-(void)statemachine_eventTransactionTimeout_stateAwaitingReportAcknowlegmentFromUser:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateAwaitingReportAcknowlegmentFromUser" forTransaction:transaction];
}

-(void)statemachine_eventTransactionTimeout_stateFinal:(TestRouterTransaction *)transaction
{
	[self actionLog:@"statemachine_eventTransactionTimeout_stateFinal" forTransaction:transaction];
	[self actionUnimplemented:@"statemachine_eventTransactionTimeout_stateFinal" forTransaction:transaction];
}


- (void)cleanupTransaction:(TestRouterTransaction *)transaction
{
    if(transaction.state == stateFinal)
    {
        [messageCache markForPurging:transaction.message];
        [self eventLog:@"Destroying Transaction" forTransaction:transaction];
        [self removePendingTransaction:transaction];
    }
    else
    {
        [messageCache markForUpdating:transaction.message];
        [self eventLog:[NSString stringWithFormat:@"transaction is in %@",transaction.stateString] forTransaction:transaction];
    }
}

- (void)eventLog:(NSString *)event forTransaction:(TestRouterTransaction *)transaction
{
    [logFeed info:0 withText:[NSString stringWithFormat:@"Event Log: %@",event]];
}

- (void)actionUnimplemented:(NSString *)action forTransaction:(TestRouterTransaction *)transaction
{
    
}

- (void)actionLog:(NSString *)action forTransaction:(TestRouterTransaction *)transaction
{
    [logFeed info:0 withText:[NSString stringWithFormat:@"Action Log: %@",action]];
}

/* a new router transaction gets created */
/* we keep track of them in 3 separate lists by the corresponding reference keys */
- (void)addPendingTransaction:(TestRouterTransaction *)transaction
{
    if(transaction.routerReference!=NULL)
    {
        @synchronized(pendingTransactionsByRouterReference)
        {
            [pendingTransactionsByRouterReference setObject:transaction forKey:transaction.routerReference];
        }
    }
    if(transaction.userReference!=NULL)
    {
        @synchronized(pendingTransactionsByUserReference)
        {
            [pendingTransactionsByUserReference setObject:transaction forKey:transaction.userReference];
        }
    }
    if(transaction.connectionReference!=NULL)
    {
        @synchronized(pendingTransactionsByConnectionReference)
        {
            [pendingTransactionsByConnectionReference setObject:transaction forKey:transaction.connectionReference];
        }
    }
}


/* a  router transaction gets removed from all lists */
- (void)removePendingTransaction:(TestRouterTransaction *)transaction
{
    if(transaction.routerReference!=NULL)
    {
        @synchronized(pendingTransactionsByRouterReference)
        {
            [pendingTransactionsByRouterReference removeObjectForKey:transaction.routerReference];
        }
    }
    if(transaction.userReference!=NULL)
    {
        @synchronized(pendingTransactionsByUserReference)
        {
            [pendingTransactionsByUserReference removeObjectForKey:transaction.userReference];
        }
    }
    if(transaction.connectionReference!=NULL)
    {
        @synchronized(pendingTransactionsByConnectionReference)
        {
            [pendingTransactionsByConnectionReference removeObjectForKey:transaction.connectionReference];
        }
    }
}

/* find transaction by specific reference */
- (TestRouterTransaction *) findPendingTransactionByRouterReference:(NSString *)ref
{
    @synchronized(pendingTransactionsByRouterReference)
    {
        return pendingTransactionsByRouterReference objectForKey:ref];
    }
    
}

- (TestRouterTransaction *) findPendingTransactionByConnectionReference:(NSString *)ref
{
    @synchronized(pendingTransactionsByConnectionReference)
    {
        return pendingTransactionsByConnectionReference objectForKey:ref];
    }
    
}


- (void)updateConnectionReferenceInTransaction:(TestRouterTransaction *)transaction newReference:(NSString *)newConnectionReference
{
    @synchronized(pendingTransactionsByConnectionReference)
    {
        NSString *oldReference = transaction.connectionReference;
        if(oldReference)
            [pendingTransactionsByConnectionReference removeObjectForKey:oldReference];
        transaction.connectionReference = newConnectionReference;
        if(newConnectionReference)
            [pendingTransactionsByConnectionReference setObject:transaction forKey:transaction.connectionReference];
    }
}


@end
