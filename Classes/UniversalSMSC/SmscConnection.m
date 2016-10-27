//
//  SmscConnection.m
//  UniversalSMS
//
//  Created by Andreas Fink on 12.01.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "SmscConnection.h"
#import "SmscConnectionTransaction.h"
#include <uuid/uuid.h>
#import "SmscRouterError.h"

#define	EMPTYSTRINGFORNIL(a)	(a?a:@"")
#define	EMPTYIPFORNIL(a)        (a?a:@"0.0.0.0")

@implementation SmscConnection

@synthesize	name;
@synthesize	type;
@synthesize	version;
@synthesize	routerName;
@synthesize	uc;
@synthesize user;
@synthesize	router;
@synthesize	localHost;
@synthesize	localPort;
@synthesize	remoteHost;
@synthesize	remotePort;
@synthesize	shortId;
@synthesize	lastActivity;
@synthesize receivePollTimeoutMs;
@synthesize transmitTimeout;
@synthesize keepAlive;
@synthesize windowSize;
@synthesize isListener;
@synthesize isInbound;
//@synthesize	submitMessageQueue;
//@synthesize	submitReportQueue;
//@synthesize	deliverMessageQueue;
//@synthesize	deliverReportQueue;
//@synthesize	ackNackQueue;
@synthesize	login;
@synthesize	password;
@synthesize autorestart;
@synthesize stopped;
@synthesize started;
@synthesize inboundMessagesThroughput;
@synthesize outboundMessagesThroughput;
@synthesize inboundReportsThroughput;
@synthesize outboundReportsThroughput;
@synthesize lastStatus;
//@synthesize packetLogFeed;
//@synthesize comLogFeed;


- (SmscConnection *)init
{
    self = [super init];
	if(self)
    {
        outgoingTransactions    = [[UMSynchronizedDictionary alloc] init];
        incomingTransactions    = [[UMSynchronizedDictionary alloc] init];
#ifdef USE_SMPP_PRIORITY_QUEUES
        submitMessageQueue      = [[PriorityQueue alloc] init];
        submitReportQueue       = [[PriorityQueue alloc] init];
        deliverMessageQueue     = [[PriorityQueue alloc] init];
        deliverReportQueue      = [[PriorityQueue alloc] init];
        ackNackQueue            = [[PriorityQueue alloc] init];
#else
        submitMessageQueue      = [[UMQueue alloc] init];
        submitReportQueue       = [[UMQueue alloc] init];
        deliverMessageQueue     = [[UMQueue alloc] init];
        deliverReportQueue      = [[UMQueue alloc] init];
        ackNackQueue            = [[UMQueue alloc] init];
#endif
        inboundMessagesThroughput = [[UMThroughputCounter alloc]init];
        outboundMessagesThroughput = [[UMThroughputCounter alloc]init];
        inboundReportsThroughput = [[UMThroughputCounter alloc]init];
        outboundReportsThroughput = [[UMThroughputCounter alloc]init];
        receivePollTimeoutMs = SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS;
        transmitTimeout  =SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT;
        keepAlive = SMSC_CONNECTION_DEFAULT_KEEPALIVE;
        windowSize = SMSC_CONNECTION_DEFAULT_WINDOW_SIZE;
        stopped = NO;
        started = NO;
        autorestart = YES;
        endPermanently=NO;
        endThisConnection=NO;
        options = [[NSMutableDictionary alloc]init];
    }
	return self;
}


#pragma mark -
#pragma mark SMSRouter Interface Functions


- (NSComparisonResult)caseInsensitiveCompare:(SmscConnection *)other
{
    return [self.name caseInsensitiveCompare:other.name];
}

+ (NSString *)uniqueMessageId
{
    return [UMUUID UUID];
}

+ (NSString *)uniqueMessageIdWithPrefix:(NSString *)prefix
{
    return [NSString stringWithFormat:@"%@%@",prefix,[UMUUID UUID]];
}

/* submit Message: router->outbound TX connection */
- (void) submitMessage:(id<SmscConnectionMessageProtocol>)msg
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    if(![self isOutbound])
    {
        NSLog(@"Sending submitMessage on incoming connection!");
    }
#ifdef USE_SMPP_PRIORITY_QUEUES
    [submitMessageQueue  addToQueue:msg priority:[msg priority]];
#else
    [submitMessageQueue  append:msg];
#endif
    [txSleeper wakeUp];
}

/* deliverMessage: router->inbound RX connection */
- (void) deliverMessage:(id<SmscConnectionMessageProtocol>)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    if(![self isInbound])
    {
        NSLog(@"Sending deliverMessage on outbound connection %@!", name);
    }
#ifdef USE_SMPP_PRIORITY_QUEUES
    [deliverMessageQueue   addToQueue:msg priority:[msg priority]];
#else
    [deliverMessageQueue append:msg];
#endif
    [txSleeper wakeUp];
}

/* deliver_sm to proxy for testing purposes*/
- (void) proxyDeliverMessage:(id<SmscConnectionMessageProtocol>)msg forObject:(id)sendingObject
{
#ifdef USE_SMPP_PRIORITY_QUEUES
    [deliverMessageQueue   addToQueue:msg priority:[msg priority]];
#else
    [deliverMessageQueue append:msg];
#endif
    [txSleeper wakeUp];
}


/* submitReport: router->outbound TX connection */
- (void) submitReport:(id<SmscConnectionReportProtocol>)report
            forObject:(id)sendingObject
          synchronous:(BOOL)sync
{
/*    if([self isOutbound])
    {
        NSLog(@"Sending submitReport on inbound connection!");
    }
*/
#ifdef USE_SMPP_PRIORITY_QUEUES
    [submitReportQueue  addToQueue:report priority:[report priority]];
#else
    [submitReportQueue append:report];
#endif
    [txSleeper wakeUp];
}

/* deliverReport: router->inbound RX connection */
- (void) deliverReport:(id<SmscConnectionReportProtocol>)report
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
 /*   if([self isInbound])
    {
        NSLog(@"Sending deliverReport on outbound connection!");
    }
*/
#ifdef USE_SMPP_PRIORITY_QUEUES
    [deliverReportQueue addToQueue:report priority:[report priority]];
#else
    [deliverReportQueue append:report];
#endif
    [txSleeper wakeUp];
}

/* submitMessageSent: router->inbound TX connection */
- (void) submitMessageSent:(id<SmscConnectionMessageProtocol>)msg
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
    /* router is telling us that a submit message we sent to him has been accepted */
    SmscConnectionTransaction *transaction = [self findIncomingTransactionByMessage:msg];
    if(transaction)
    {
        [transaction.status setInternalErrorCode:SMSError_none];
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:msg.priority];
#else
        [ackNackQueue append:transaction];
#endif
    }
}


/* submitMessageFailed: router->inbound TX connection */
- (void) submitMessageFailed:(id<SmscConnectionMessageProtocol>)msg
                   withError:(SmscRouterError *)code
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    /* router is telling us that a submit message we sent to him has failed */
    /* TODO: we should send out submitSMResponse matching that transaction */

    SmscConnectionTransaction *transaction = [self findIncomingTransactionByMessage:msg];
    if(transaction)
    {
        transaction.status = code;
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:msg.priority];
#else
        [ackNackQueue append:transaction];
#endif
    }
}

- (void) submitReportSent:(id<SmscConnectionReportProtocol>)rep
                forObject:(id)reportingObject
              synchronous:(BOOL)sync
{
    /* router is telling us that a submit report we sent to him has been accepted */
    SmscConnectionTransaction * transaction = [self findIncomingTransactionByReport:rep];
    if(transaction)
    {
        [transaction.status setInternalErrorCode:SMSError_none];
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
        [ackNackQueue append:transaction];
#endif

    }
}

- (void) submitReportFailed:(id<SmscConnectionReportProtocol>)rep
                  withError:(SmscRouterError *)code
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    /* router is telling us that a submit report we sent to him has failed */
    SmscConnectionTransaction * transaction = [self findIncomingTransactionByReport:rep];
    if(transaction)
    {
        transaction.status = code;
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
        [ackNackQueue append:transaction];
#endif
    }
}

- (void) deliverMessageSent:(id<SmscConnectionMessageProtocol>)msg
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    /* router is telling us that a deliverMessage we sent to him has been accepted */
    SmscConnectionTransaction * transaction = [self findOutgoingTransactionByMessage:msg];
    if(transaction)
    {
        [transaction.status setInternalErrorCode:SMSError_none];
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:msg.priority];
#else
        [ackNackQueue append:transaction];
#endif
    }
}

- (void) deliverMessageFailed:(id<SmscConnectionMessageProtocol>)msg
                    withError:(SmscRouterError *)code
                    forObject:(id)reportingObject
                  synchronous:(BOOL)sync
{
    /* router is telling us that a deliverMessage we sent to him has failed */
    SmscConnectionTransaction * transaction = [self findOutgoingTransactionByMessage:msg];
    if(transaction)
    {
        transaction.status = code;
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:msg.priority];
#else
        [ackNackQueue append:transaction];
#endif

    }
}

/* we get a deliverReport inbound and acknowledge it outbount */
- (void) deliverReportSent:(id<SmscConnectionReportProtocol>)rep
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
    /* router is telling us that a deliverReport we sent to him has been accepted */
    SmscConnectionTransaction * transaction = [self findIncomingTransactionByReport:rep];
    if(transaction)
    {
        [transaction.status setInternalErrorCode:SMSError_none];
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
        [ackNackQueue append:transaction];
#endif
    }
}

- (void) deliverReportFailed:(id<SmscConnectionReportProtocol>)rep
                   withError:(SmscRouterError *)code
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    /* router is telling us that a deliverReport we sent to him has failed */
    SmscConnectionTransaction * transaction = [self findOutgoingTransactionByReport:rep];
    if(transaction)
    {
        transaction.status = code;
#ifdef USE_SMPP_PRIORITY_QUEUES
        [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
        [ackNackQueue append:transaction];
#endif
    }
}

#pragma mark Router Registration

- (void) registerMessageRouter:(id<SmscConnectionRouterProtocol>) r
{
	if ( r != router)
	{
		router = r;
	}
}

- (void) unregisterMessageRouter:(id<SmscConnectionRouterProtocol>) r
{
	if ( r == router)
	{
        r = NULL;
	}
}

#pragma mark Various Acessors

- (BOOL) isOutbound
{
    return !isInbound;
}

- (BOOL)  isConnected
{
	return NO;
	/* should be overrided */
}

- (BOOL)  isAuthenticated
{
	return NO;
	/* should be overrided */
}

- (NSString *) getName
{
	return [NSString stringWithString:name];
}

- (NSString *) getType
{
	return [NSString stringWithString:type];
}

#pragma mark Thread Handling

- (void)startListener
{
	NSLog(@"startListener should be implemented by the subclass");
}

- (void) stopListener
{
	NSLog(@"startListener should be implemented by the subclass");
}

- (void) startOutgoing;
{
	NSLog(@"startOutgoing should be implemented by the subclass");
}

- (void) stopOutgoing
{
	NSLog(@"stopOutgoing should be implemented by the subclass");
}

- (void) stopIncoming
{
	NSLog(@"stopIncoming should be implemented by the subclass");
}

#pragma mark config
- (int) setConfig: (NSDictionary *) dict
{
	NSLog(@"setConfig should be implemented by the subclass");
	return -1;
}

- (NSDictionary *) getConfig
{
	NSMutableDictionary *dict;
	
	dict = [[NSMutableDictionary alloc] init];
	dict[PREFS_CON_NAME] = EMPTYSTRINGFORNIL(name);
	dict[PREFS_CON_PROTO] = EMPTYSTRINGFORNIL(type);
	dict[PREFS_CON_VERSION] = EMPTYSTRINGFORNIL(version);
	dict[PREFS_CON_LHOST] = EMPTYSTRINGFORNIL([[uc localHost]name]);
	dict[PREFS_CON_LPORT] = [NSNumber numberWithInt:[uc requestedLocalPort]];
	dict[PREFS_CON_RHOST] = EMPTYSTRINGFORNIL([[uc remoteHost]name]);
	dict[PREFS_CON_RPORT] = [NSNumber numberWithInt:[uc requestedRemotePort]];
	dict[PREFS_CON_RXTIMEOUT] = @(receivePollTimeoutMs);
	dict[PREFS_CON_TXTIMEOUT] = @(transmitTimeout);
	dict[PREFS_CON_KEEPALIVE] = @(keepAlive);
	dict[PREFS_CON_WINDOW] = @(windowSize);
	dict[PREFS_CON_SHORT_ID] = EMPTYSTRINGFORNIL([shortId asString]);
	dict[PREFS_CON_SOCKTYPE] = EMPTYSTRINGFORNIL([UMSocket socketTypeDescription:[uc type]]);
	dict[PREFS_CON_ROUTER] = EMPTYSTRINGFORNIL(routerName);
	dict[PREFS_CON_LOGIN] = EMPTYSTRINGFORNIL(login);
	dict[PREFS_CON_PASSWORD] = EMPTYSTRINGFORNIL(password);
	return dict;
}

+ (NSDictionary *) getDefaultListenerConfig
{
	NSMutableDictionary *dict;
	
	dict = [[NSMutableDictionary alloc] init];
	dict[PREFS_CON_NAME] = @"";
	dict[PREFS_CON_PROTO] = @"";
	dict[PREFS_CON_VERSION] = @"";
	dict[PREFS_CON_LHOST] = @"localhost";
	dict[PREFS_CON_LPORT] = @0;
	dict[PREFS_CON_RHOST] = @"";
	dict[PREFS_CON_RPORT] = @0;
	dict[PREFS_CON_RXTIMEOUT] = @SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS;
	dict[PREFS_CON_TXTIMEOUT] = @SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT;
	dict[PREFS_CON_KEEPALIVE] = @SMSC_CONNECTION_DEFAULT_KEEPALIVE;
	dict[PREFS_CON_WINDOW] = @SMSC_CONNECTION_DEFAULT_WINDOW_SIZE;
	dict[PREFS_CON_SHORT_ID] = @"";
	dict[PREFS_CON_SOCKTYPE] = @"tcp";
	dict[PREFS_CON_ROUTER] = @"default-router";
	dict[PREFS_CON_LOGIN] = @"";
	dict[PREFS_CON_PASSWORD] = @"";
	return dict;
}

+ (NSDictionary *) getDefaultConnectionConfig
{
	NSMutableDictionary *dict;
	
	dict = [[NSMutableDictionary alloc] init];
	dict[PREFS_CON_NAME] = @"";
	dict[PREFS_CON_PROTO] = @"";
	dict[PREFS_CON_VERSION] = @"";
	dict[PREFS_CON_LHOST] = @"localhost";
	dict[PREFS_CON_LPORT] = @0;
	dict[PREFS_CON_RHOST] = @"";
	dict[PREFS_CON_RPORT] = @0;
	dict[PREFS_CON_RXTIMEOUT] = @SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS;
	dict[PREFS_CON_TXTIMEOUT] = @SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT;
	dict[PREFS_CON_KEEPALIVE] = @SMSC_CONNECTION_DEFAULT_KEEPALIVE;
	dict[PREFS_CON_WINDOW] = @SMSC_CONNECTION_DEFAULT_WINDOW_SIZE;
	dict[PREFS_CON_SHORT_ID] = @"";
	dict[PREFS_CON_SOCKTYPE] = @"tcp";
	dict[PREFS_CON_ROUTER] = @"default-router";
	dict[PREFS_CON_LOGIN] = @"";
	dict[PREFS_CON_PASSWORD] = @"";
	return dict;
}

/*	Those functions will be called from another thread. it only updates the status and returns.
	The main connection thread should read them and send out ack/nack accordingly */
#pragma mark -
#pragma mark Transactions

- (id) findIncomingTransaction:(NSString *)trn
{
    SmscConnectionTransaction *transaction = incomingTransactions[trn];
    return transaction;
}

- (id) findOutgoingTransaction:(NSString *)trn
{
    SmscConnectionTransaction *transaction = outgoingTransactions[trn];
    return transaction;
}

- (id) findIncomingTransactionByMessage:(id<SmscConnectionMessageProtocol>)msg
{
    return [msg userTransaction];

    /* 
     SmscConnectionTransaction *transaction = NULL;
    NSString *key;
    NSArray *allKeys;
    
    @synchronized(incomingTransactions)
    {
        allKeys = [incomingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = incomingTransactions[key];
            if([transaction._message isEqual:msg])
            {
                return transaction;
            }
        }
    }
    return NULL;
    */
}

- (id) findOutgoingTransactionByMessage:(id<SmscConnectionMessageProtocol>)msg
{
    SmscConnectionTransaction * transaction = NULL;
    NSString *key;
    NSArray *allKeys;
    
    @synchronized(outgoingTransactions)
    {
        allKeys = [outgoingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = outgoingTransactions[key];
            if([transaction._message isEqual:msg])
            {
                return transaction;
            }
        }
    }
    return NULL;;
}

- (id) findIncomingTransactionByReport:(id)rep
{
    SmscConnectionTransaction *transaction = NULL;
    NSString *key;
    NSArray *allKeys;
    
    @synchronized(incomingTransactions)
    {
        allKeys = [incomingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = incomingTransactions[key];
            if([[transaction report]isEqual:rep])
            {
                break;
            }
            else
            {
                transaction = NULL;
            }
        }
    }
    return transaction;
}

- (id) findOutgoingTransactionByReport:(id)rep
{
    SmscConnectionTransaction *transaction = NULL;
    NSString *key;
    NSArray *allKeys;
    

    @synchronized(outgoingTransactions)
    {
        allKeys = [outgoingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = outgoingTransactions[key];
            if(transaction)
            {
                if([[transaction report] isEqual:rep])
                {
                    break;
                }
                else if ([[transaction sequenceNumber] isEqual:[rep userReference]])
                {
                    break;
                }
                else
                {
                    transaction = NULL;
                }
            }
        }
    }
    return transaction;
}


- (void) addOutgoingTransaction:(SmscConnectionTransaction *)transaction
{
	[transaction setIncoming:0];
    @synchronized(outgoingTransactions)
    {
        outgoingTransactions[transaction.sequenceNumber] = transaction;
    }
}

- (void) addIncomingTransaction:(SmscConnectionTransaction * )transaction
{
	[transaction setIncoming:1];
    incomingTransactions[transaction.sequenceNumber] = transaction;
}

- (void) removeIncomingTransaction:(SmscConnectionTransaction *)transaction
{
    id key = transaction.sequenceNumber;
    if(key)
    {
        [incomingTransactions removeObjectForKey:key];
    }
}

- (void) removeOutgoingTransaction:(SmscConnectionTransaction *)transaction
{
    id key = transaction.sequenceNumber;
    if(key)
    {
        @synchronized(outgoingTransactions)
        {
            [outgoingTransactions removeObjectForKey:key];
        }
    }
}

/* where do we call this from ? */
- (void) ackIncomingTransaction:(SmscConnectionTransaction *)transaction
{
    SmscConnectionTransaction *t = transaction;
	[self removeIncomingTransaction:t];
    [t.status setInternalErrorCode:SMSError_none];
#ifdef USE_SMPP_PRIORITY_QUEUES
    [ackNackQueue addToQueue: transaction];
// why dont we know the priority here?
// like:  [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
    [ackNackQueue append:transaction];
#endif
}

/* called on timeout of incoming transaction (no answer by router */
- (void) nackIncomingTransaction:(SmscConnectionTransaction *)transaction err:(SmscRouterError *)code
{
	[self removeIncomingTransaction:transaction];
	[transaction setStatus:code];
#ifdef USE_SMPP_PRIORITY_QUEUES
    [ackNackQueue addToQueue: transaction];
    // why dont we know the priority here?
    // like:  [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
    [ackNackQueue append:transaction];
#endif
}

- (void) ackOutgoingTransaction:(SmscConnectionTransaction *)transaction
{
	[self removeOutgoingTransaction:transaction];
    [transaction.status setInternalErrorCode:SMSError_none];
#ifdef USE_SMPP_PRIORITY_QUEUES
    [ackNackQueue addToQueue: transaction];
    // why dont we know the priority here?
    // like:  [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
    [ackNackQueue append:transaction];
#endif

}

- (void) nackOutgoingTransaction:(SmscConnectionTransaction *)transaction err:(SmscRouterError *)code
{
	[self removeOutgoingTransaction:transaction];
	[transaction setStatus:code];
#ifdef USE_SMPP_PRIORITY_QUEUES
    [ackNackQueue addToQueue: transaction];
    // why dont we know the priority here?
    // like:  [ackNackQueue addToQueue:transaction priority:rep.priority];
#else
    [ackNackQueue append:transaction];
#endif
}

- (void) timeoutIncomingTransaction:(id)transaction
{
    SmscRouterError *err = [router createError];
    if(err==NULL)
    {
        err = [[SmscRouterError alloc]init];
    }
    [err setSmppErrorCode:ESME_RUNKNOWNERR];
    [err setInternalErrorCode:SMSError_Timeout];
    [self nackIncomingTransaction:transaction err:err];
}

- (void) timeoutOutgoingTransaction:(id)transaction
{
    SmscRouterError *err = [router createError];
    if(err==NULL)
    {
        err = [[SmscRouterError alloc]init];
    }
    [err setInternalErrorCode:SMSError_Timeout];

    [self nackOutgoingTransaction:transaction err: err];
}

- (void) checkForTimedOutTransactions
{
	SmscConnectionTransaction *transaction;
    NSString *transactionKey;

    NSArray *allKeys = [incomingTransactions allKeys];
	for(transactionKey in allKeys)
	{
        transaction = [self findIncomingTransaction:transactionKey];
		if ([transaction isExpired])
		{
			[self timeoutIncomingTransaction:transaction];
		}
	}

    allKeys = [outgoingTransactions allKeys];
	for(transactionKey in allKeys)
	{
        transaction = [self findOutgoingTransaction:transactionKey];
		if ([transaction isExpired])
		{
			[self timeoutOutgoingTransaction:transaction];
		}
	}
}

- (void) transactionDone:(id) t
{
    [self removeIncomingTransaction:t];
}

-(void)setConnectionName:(NSString *)connectionName
{
    
}

-(NSString *)connectionName
{
    return routerName;
}

- (NSString *)htmlStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"Connection: %@<br>",name];
    [s appendFormat:@"Type: %@<br>",type];
    [s appendFormat:@"Version: %@<br>",version];
    [s appendFormat:@"RouterName: %@<br>",routerName];
    [s appendFormat:@"socket: %@<br>",uc];
    [s appendFormat:@"submitMessageQueue: %d entries<br>",(int)[submitMessageQueue count]];
    [s appendFormat:@"submitReportQueue: %d entries<br>",(int)[submitReportQueue count]];
    [s appendFormat:@"deliverMessageQueue: %d entries<br>",(int)[deliverMessageQueue count]];
    [s appendFormat:@"deliverReportQueue: %d entries<br>",(int)[deliverReportQueue count]];
    [s appendFormat:@"ackNackQueue: %d entries<br>",(int)[ackNackQueue count]];
    [s appendFormat:@"outgoingTransactions: %d entries<br>",(int)[outgoingTransactions count]];
    [s appendFormat:@"incomingTransactions: %d entries<br>",(int)[incomingTransactions count]];
    [s appendFormat:@"shortId: %@<br>",[shortId asString]];
    [s appendFormat:@"endThisConnection: %d<br>",endThisConnection];
    [s appendFormat:@"endPermanently: %d<br>",endPermanently];
    [s appendFormat:@"lastActivity: %@<br>",lastActivity];
    [s appendFormat:@"login: %@<br>",login];
    [s appendFormat:@"isListener: %@<br>",isListener ? @"YES" : @"NO"];
    [s appendFormat:@"isInbound: %@<br>",isInbound ? @"YES" : @"NO"];
    return s;
}


- (BOOL)hasOption:(NSString *)n
{
    id result = options[n];
    if(result)
    {
        return YES;
    }
    return NO;
}

- (void)setOption:(NSString *)n
{
    options[n] = n;
}

- (void)clearOption:(NSString *)n
{
    [options removeObjectForKey:n];
}

- (void)clearAllOptions
{
    options=[[NSMutableDictionary alloc]init];
}

- (NSString *)connectedFrom
{
    return @"";
}

- (NSString *)connectedTo
{
    return @"";
}

@end
