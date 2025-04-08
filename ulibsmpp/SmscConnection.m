//
//  SmscConnection.m
//  UniversalSMS
//
//  Created by Andreas Fink on 12.01.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "SmscConnection.h"
#import "SmscConnectionTransaction.h"
#include <uuid/uuid.h>
#import "SmscRouterError.h"

#define	EMPTYSTRINGFORNIL(a)	(a?a:@"")
#define	EMPTYIPFORNIL(a)        (a?a:@"0.0.0.0")

@implementation SmscConnection

- (SmscConnection *)init
{
    self = [super init];
	if(self)
    {
        _logLevel = UMLOG_MAJOR;
        _outgoingTransactions    = [[UMSynchronizedDictionary alloc] init];
        _incomingTransactions    = [[UMSynchronizedDictionary alloc] init];
#ifdef USE_SMPP_PRIORITY_QUEUES
        submitMessageQueue      = [[PriorityQueue alloc] init];
        submitReportQueue       = [[PriorityQueue alloc] init];
        deliverMessageQueue     = [[PriorityQueue alloc] init];
        deliverReportQueue      = [[PriorityQueue alloc] init];
        ackNackQueue            = [[PriorityQueue alloc] init];
#else
        _submitMessageQueue      = [[UMQueueSingle alloc] init];
        _submitReportQueue       = [[UMQueueSingle alloc] init];
        _deliverMessageQueue     = [[UMQueueSingle alloc] init];
        _deliverReportQueue      = [[UMQueueSingle alloc] init];
        _ackNackQueue            = [[UMQueueSingle alloc] init];
#endif
        _inboundMessagesThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _outboundMessagesThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _inboundReportsThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _outboundReportsThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _receivePollTimeoutMs = SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS;
        _transmitTimeout  =SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT;
        _keepAlive = SMSC_CONNECTION_DEFAULT_KEEPALIVE;
        _windowSize = SMSC_CONNECTION_DEFAULT_WINDOW_SIZE;
        _stopped = NO;
        _started = NO;
        _autorestart = YES;
        _endPermanently=NO;
        _endThisConnection=NO;
        _options = [[NSMutableDictionary alloc]init];
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
    [_submitMessageQueue  append:msg];
#endif
    [_txSleeper wakeUp];
}

/* deliverMessage: router->inbound RX connection */
- (void) deliverMessage:(id<SmscConnectionMessageProtocol>)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    if(![self isInbound])
    {
        NSLog(@"Sending deliverMessage on outbound connection %@!", _name);
    }
#ifdef USE_SMPP_PRIORITY_QUEUES
    [deliverMessageQueue   addToQueue:msg priority:[msg priority]];
#else
    [_deliverMessageQueue append:msg];
#endif
    [_txSleeper wakeUp];
}

/* deliver_sm to proxy for testing purposes*/
- (void) proxyDeliverMessage:(id<SmscConnectionMessageProtocol>)msg forObject:(id)sendingObject
{
#ifdef USE_SMPP_PRIORITY_QUEUES
    [deliverMessageQueue   addToQueue:msg priority:[msg priority]];
#else
    [_deliverMessageQueue append:msg];
#endif
    [_txSleeper wakeUp];
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
    [_submitReportQueue append:report];
#endif
    [_txSleeper wakeUp];
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
    [_deliverReportQueue append:report];
#endif
    [_txSleeper wakeUp];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
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
        [_ackNackQueue append:transaction];
#endif
    }
}

#pragma mark Router Registration

- (void) registerMessageRouter:(id<SmscConnectionRouterProtocol>) r
{
	if ( r != _router)
	{
		_router = r;
	}
}

- (void) unregisterMessageRouter:(id<SmscConnectionRouterProtocol>) r
{
	if ( r == _router)
	{
        r = NULL;
	}
}

#pragma mark Various Acessors

- (BOOL) isOutbound
{
    return !_isInbound;
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
	return [NSString stringWithString:_name];
}

- (NSString *) getType
{
	return [NSString stringWithString:_type];
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
	dict[PREFS_CON_NAME] = EMPTYSTRINGFORNIL(_name);
	dict[PREFS_CON_PROTO] = EMPTYSTRINGFORNIL(_type);
	dict[PREFS_CON_VERSION] = EMPTYSTRINGFORNIL(_version);
	dict[PREFS_CON_LHOST] = EMPTYSTRINGFORNIL([[_uc localHost]name]);
	dict[PREFS_CON_LPORT] = [NSNumber numberWithInt:[_uc requestedLocalPort]];
	dict[PREFS_CON_RHOST] = EMPTYSTRINGFORNIL([[_uc remoteHost]name]);
	dict[PREFS_CON_RPORT] = [NSNumber numberWithInt:[_uc requestedRemotePort]];
	dict[PREFS_CON_RXTIMEOUT] = @(_receivePollTimeoutMs);
	dict[PREFS_CON_TXTIMEOUT] = @(_transmitTimeout);
	dict[PREFS_CON_KEEPALIVE] = @(_keepAlive);
	dict[PREFS_CON_WINDOW] = @(_windowSize);
	dict[PREFS_CON_SHORT_ID] = EMPTYSTRINGFORNIL([_shortId asString]);
	dict[PREFS_CON_SOCKTYPE] = EMPTYSTRINGFORNIL([UMSocket socketTypeDescription:[_uc type]]);
	dict[PREFS_CON_ROUTER] = EMPTYSTRINGFORNIL(_routerName);
	dict[PREFS_CON_LOGIN] = EMPTYSTRINGFORNIL(_login);
	dict[PREFS_CON_PASSWORD] = EMPTYSTRINGFORNIL(_password);
    dict[PREFS_CON_TCP_MSS] = @(_max_tcp_segment_size);

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
    dict[PREFS_CON_TCP_MSS] = @(0);
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
    dict[PREFS_CON_TCP_MSS] = @(0);
	return dict;
}

/*	Those functions will be called from another thread. it only updates the status and returns.
	The main connection thread should read them and send out ack/nack accordingly */
#pragma mark -
#pragma mark Transactions

- (id) findIncomingTransaction:(NSString *)trn
{
    SmscConnectionTransaction *transaction = _incomingTransactions[trn];
    return transaction;
}

- (id) findOutgoingTransaction:(NSString *)trn
{
    SmscConnectionTransaction *transaction = _outgoingTransactions[trn];
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
    
    @synchronized(_outgoingTransactions)
    {
        allKeys = [_outgoingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = _outgoingTransactions[key];
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
    
    @synchronized(_incomingTransactions)
    {
        allKeys = [_incomingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = _incomingTransactions[key];
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
    

    @synchronized(_outgoingTransactions)
    {
        allKeys = [_outgoingTransactions allKeys];
        for(key in allKeys)
        {
            transaction = _outgoingTransactions[key];
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
    @synchronized(_outgoingTransactions)
    {
        _outgoingTransactions[transaction.sequenceNumber] = transaction;
    }
}

- (void) addIncomingTransaction:(SmscConnectionTransaction * )transaction
{
	[transaction setIncoming:1];
    _incomingTransactions[transaction.sequenceNumber] = transaction;
}

- (void) removeIncomingTransaction:(SmscConnectionTransaction *)transaction
{
    id key = transaction.sequenceNumber;
    if(key)
    {
        [_incomingTransactions removeObjectForKey:key];
    }
}

- (void) removeOutgoingTransaction:(SmscConnectionTransaction *)transaction
{
    id key = transaction.sequenceNumber;
    if(key)
    {
        @synchronized(_outgoingTransactions)
        {
            [_outgoingTransactions removeObjectForKey:key];
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
    [_ackNackQueue append:transaction];
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
    [_ackNackQueue append:transaction];
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
    [_ackNackQueue append:transaction];
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
    [_ackNackQueue append:transaction];
#endif
}

- (void) timeoutIncomingTransaction:(id)transaction
{
    SmscRouterError *err = [_router createError];
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
    SmscRouterError *err = [_router createError];
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

    NSArray *allKeys = [_incomingTransactions allKeys];
	for(transactionKey in allKeys)
	{
        transaction = [self findIncomingTransaction:transactionKey];
		if ([transaction isExpired])
		{
			[self timeoutIncomingTransaction:transaction];
		}
	}

    allKeys = [_outgoingTransactions allKeys];
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
    return _routerName;
}

- (NSString *)htmlStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"Connection: %@<br>",_name];
    [s appendFormat:@"Type: %@<br>",_type];
    [s appendFormat:@"Version: %@<br>",_version];
    [s appendFormat:@"RouterName: %@<br>",_routerName];
    [s appendFormat:@"socket: %@<br>",_uc];
    [s appendFormat:@"submitMessageQueue: %d entries<br>",(int)[_submitMessageQueue count]];
    [s appendFormat:@"submitReportQueue: %d entries<br>",(int)[_submitReportQueue count]];
    [s appendFormat:@"deliverMessageQueue: %d entries<br>",(int)[_deliverMessageQueue count]];
    [s appendFormat:@"deliverReportQueue: %d entries<br>",(int)[_deliverReportQueue count]];
    [s appendFormat:@"ackNackQueue: %d entries<br>",(int)[_ackNackQueue count]];
    [s appendFormat:@"outgoingTransactions: %d entries<br>",(int)[_outgoingTransactions count]];
    [s appendFormat:@"incomingTransactions: %d entries<br>",(int)[_incomingTransactions count]];
    [s appendFormat:@"shortId: %@<br>",[_shortId asString]];
    [s appendFormat:@"endThisConnection: %d<br>",_endThisConnection];
    [s appendFormat:@"endPermanently: %d<br>",_endPermanently];
    [s appendFormat:@"lastActivity: %@<br>",_lastActivity];
    [s appendFormat:@"login: %@<br>",_login];
    [s appendFormat:@"isListener: %@<br>",_isListener ? @"YES" : @"NO"];
    [s appendFormat:@"isInbound: %@<br>",_isInbound ? @"YES" : @"NO"];
    [s appendFormat:@"activeSegmentSize: %d<br>",_uc.activeMaxSegmentSize ];
    return s;
}


- (BOOL)hasOption:(NSString *)n
{
    id result = _options[n];
    if(result)
    {
        return YES;
    }
    return NO;
}

- (void)setOption:(NSString *)n
{
    _options[n] = n;
}

- (void)clearOption:(NSString *)n
{
    [_options removeObjectForKey:n];
}

- (void)clearAllOptions
{
    _options=[[NSMutableDictionary alloc]init];
}

- (NSString *)connectedFrom
{
    return @"";
}

- (NSString *)connectedTo
{
    return @"";
}


- (int)max_tcp_segment_size
{
    return _max_tcp_segment_size;
}

- (void) setMax_tcp_segment_size:(int)max
{
    _max_tcp_segment_size = max;
    _uc.configuredMaxSegmentSize = max;
}
@end
