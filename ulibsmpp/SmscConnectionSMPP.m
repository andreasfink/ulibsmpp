//
//  SmscConnectionSMPP.m
//  UniversalSMSCConnectionSMPP
//
//  Created by Andreas Fink on 11.12.08.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/ulib.h>
#import "SmscConnectionSMPP.h"
#import "SmppPdu.h"
#import "NSMutableString+ulibsmpp.h"
#import "NSString+ulibsmpp.h"
#include <sys/signal.h>
#import "SmscConnectionUserProtocol.h"
#import <ulibsmpp/UMSmppError.h>
#import <ulibsms/ulibsms.h>
#import <ulibsmpp/NSData+ulibsmpp.h>

#define SMPP_RECONNECT_DELAY                 30
#define SMPP_WAIT_FOR_BIND_RESPONSE_DELAY    3000

#define MC_UNDEF                SMS_PARAM_UNDEFINED
#define MC_CLASS0                0
#define MC_CLASS1                1
#define MC_CLASS2                2
#define MC_CLASS3                3

#include <unistd.h> /* for usleep */

struct  SmppPduTableEntry	SmppPDUTable[] =
{
{ SMPP_PDU_SUBMIT_SM,				"SUBMIT_SM",				(SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX), (SMPP_SOURCE_ESME) },
{ SMPP_PDU_SUBMIT_SM_RESP,			"SUBMIT_SM_RESP",			(SMPP_STATE_OUT_BOUND_TX | SMPP_STATE_OUT_BOUND_TRX), (SMPP_SOURCE_SMSC) },
{ SMPP_PDU_DATA_SM,					"DATA_SM",					(SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_RX | SMPP_STATE_IN_BOUND_TRX),SMPP_SOURCE_BOTH },
{ SMPP_PDU_DATA_SM_RESP,			"DATA_SM_RESP",             (SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_RX | SMPP_STATE_IN_BOUND_TRX),SMPP_SOURCE_BOTH },
{ SMPP_PDU_DELIVER_SM,				"DELIVER_SM",				(SMPP_STATE_OUT_BOUND_RX | SMPP_STATE_OUT_BOUND_TRX), (SMPP_SOURCE_SMSC) },
{ SMPP_PDU_DELIVER_SM_RESP,			"DELIVER_SM_RESP",			(SMPP_STATE_IN_BOUND_RX | SMPP_STATE_IN_BOUND_TRX), (SMPP_SOURCE_ESME) },
{ SMPP_PDU_ENQUIRE_LINK,			"ENQUIRE_LINK",             SMPP_STATE_ANY, SMPP_SOURCE_BOTH }, /* should not be sent before AUTH completed but if we get it, we will better reply properly than with a generic nack */
{ SMPP_PDU_ENQUIRE_LINK_RESP,		"ENQUIRE_LINK_RESP",		SMPP_STATE_ANY, SMPP_SOURCE_BOTH },
{ SMPP_PDU_GENERIC_NACK,			"GENERIC_NACK",             SMPP_STATE_ANY,SMPP_SOURCE_BOTH },
{ SMPP_PDU_BIND_RECEIVER,			"BIND_RECEIVER",			(SMPP_STATE_IN_OPEN),(SMPP_SOURCE_ESME) },
{ SMPP_PDU_BIND_RECEIVER_RESP,		"BIND_RECEIVER_RESP",		(SMPP_STATE_OUT_OPEN),(SMPP_SOURCE_SMSC) },
{ SMPP_PDU_BIND_TRANSMITTER,		"BIND_TRANSMITTER",         (SMPP_STATE_IN_OPEN),(SMPP_SOURCE_ESME) },
{ SMPP_PDU_BIND_TRANSMITTER_RESP,	"BIND_TRANSMITTER_RESP",	(SMPP_STATE_OUT_OPEN),(SMPP_SOURCE_SMSC) },
{ SMPP_PDU_QUERY_SM,				"QUERY_SM",                 (SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX), (SMPP_SOURCE_ESME) },
{ SMPP_PDU_QUERY_SM_RESP,			"QUERY_SM_RESP",			(SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX), (SMPP_SOURCE_SMSC) },
{ SMPP_PDU_UNBIND,					"UNBIND",					(SMPP_STATE_IN_BOUND_TRX | SMPP_STATE_OUT_BOUND_TRX), (SMPP_SOURCE_SMSC | SMPP_SOURCE_ESME) },
{ SMPP_PDU_UNBIND_RESP,				"UNBIND_RESP",				(SMPP_STATE_IN_BOUND_TRX | SMPP_STATE_OUT_BOUND_TRX), (SMPP_SOURCE_SMSC | SMPP_SOURCE_ESME) },
{ SMPP_PDU_REPLACE_SM,				"REPLACE_SM",				(SMPP_STATE_IN_BOUND_TX),	(SMPP_SOURCE_ESME) },
{ SMPP_PDU_REPLACE_SM_RESP,			"REPLACE_SM_RESP",			(SMPP_STATE_IN_BOUND_TX), (SMPP_SOURCE_SMSC) },
{ SMPP_PDU_CANCEL_SM,				"CANCEL_SM",				(SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX),		 (SMPP_SOURCE_ESME) },
{ SMPP_PDU_CANCEL_SM_RESP,			"CANCEL_SM_RESP",			(SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX),		 (SMPP_SOURCE_SMSC) },
{ SMPP_PDU_BIND_TRANSCEIVER,		"BIND_TRANSCEIVER",         (SMPP_STATE_IN_OPEN),(SMPP_SOURCE_ESME) },
{ SMPP_PDU_BIND_TRANSCEIVER_RESP,	"BIND_TRANSCEIVER_RESP",	(SMPP_STATE_OUT_OPEN),(SMPP_SOURCE_SMSC) },
{ SMPP_PDU_OUTBIND,					"OUTBIND",					(SMPP_STATE_IN_OPEN),(SMPP_SOURCE_SMSC) },
{ SMPP_PDU_SUBMIT_SM_MULTI,			"SUBMIT_SM_MULTI",			(SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX), (SMPP_SOURCE_ESME) },
{ SMPP_PDU_SUBMIT_SM_MULTI_RESP,	"SUBMIT_SM_MULTI_RESP",     (SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_TRX), (SMPP_SOURCE_SMSC) },
{ SMPP_PDU_ALERT_NOTIFICATION,		"ALERT_NOTIFICATION",		(SMPP_STATE_IN_BOUND_RX | SMPP_STATE_IN_BOUND_TRX),(SMPP_SOURCE_SMSC) },
};

#define	EMPTYSTRINGFORNIL(a)	(a?a:@"")
#define	EMPTYIPFORNIL(a)        (a?a:@"0.0.0.0")

;


#import "NSMutableString+ulibsmpp.h"
#import "NSString+ulibsmpp.h"

@implementation SmscConnectionSMPP

#pragma mark -
#pragma mark SmscConnectionSMPP init/dealloc/synthesizer


- (SmscConnectionSMPP *)init
{
    self = [super init];
    if(self)
    {
        [super setVersion: @"3.4"];
        [super setType: @"smpp"];
        _txSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        _cxSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        _sendLock = [[UMMutex alloc] initWithName:@"smpp-send-lock"];
        _trnLock = [[UMMutex alloc] initWithName:@"smpp-trn-lock"];
        _smppMessageIdType = -1;
        _tlvDefs = [[NSDictionary alloc] init];
        self.lastActivity = [NSDate new];
    }
    return self;
}

- (NSString *)_type
{
    return @"smpp";
}

- (BOOL) isConnected
{
    if(_isInbound)
    {
        if ((_incomingStatus == SMPP_STATUS_INCOMING_CONNECTED)  || (_incomingStatus == SMPP_STATUS_INCOMING_ACTIVE))
        {
            return YES;
        }
        return NO;
    }
    
	if ((_outgoingStatus == SMPP_STATUS_OUTGOING_CONNECTED)  || (_outgoingStatus == SMPP_STATUS_OUTGOING_ACTIVE))
    {
        return YES;
    }
    return NO;
}

- (BOOL) isAuthenticated
{
    if(_isInbound)
    {
        if ((_incomingStatus == SMPP_STATUS_INCOMING_ACTIVE) && (_user != NULL))
        {
            return YES;
        }
    }
    else if (_outgoingStatus == SMPP_STATUS_OUTGOING_ACTIVE)
    {
        return YES;
    }
    return NO;
}

- (NSString *) getType
{
	return @"smpp";
}

#pragma mark handling config

- (int) setConfig: (NSDictionary *) dict
{
	return -1;
}

- (NSDictionary *) getConfig
{
	NSMutableDictionary *dict;
		
	dict = [NSMutableDictionary dictionaryWithDictionary: [super getConfig]];	
	dict[PREFS_CON_PROTO] = @"smpp";
	return dict;
}



- (NSDictionary *) getClientConfig
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] init];
    dict[PREFS_CON_NAME] = EMPTYSTRINGFORNIL(_name);
    dict[PREFS_CON_RHOST] = EMPTYSTRINGFORNIL([[_uc remoteHost]name]);
    dict[PREFS_CON_RPORT] = [NSNumber numberWithInt:[_uc requestedRemotePort]];
    dict[PREFS_CON_RECEIVE_PORT] = @((int)_receivePort);
    dict[PREFS_CON_TRANSMIT_PORT] = @((int)_transmitPort);
    dict[PREFS_CON_LOGIN] = EMPTYSTRINGFORNIL(_login);
	dict[PREFS_CON_PASSWORD] = EMPTYSTRINGFORNIL(_password);
    dict[PREFS_CON_SYSTEM_TYPE] = EMPTYSTRINGFORNIL(_systemType);
    dict[PREFS_CON_ROUTER] = EMPTYSTRINGFORNIL(_routerName);
    dict[PREFS_CON_ADDRESS_RANGE] = EMPTYSTRINGFORNIL(_addressRange);
    
    return dict;
}

+ (NSDictionary *) getDefaultConnectionConfig
{
	NSDictionary *smppConnectionDict;
	
	smppConnectionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						  @"default-smpp-connection",	PREFS_CON_NAME,
						  @"smpp",						PREFS_CON_PROTO,
						  @"localhost",					PREFS_CON_LHOST,
						  @SMSC_DEFAULT_SMPP_PORT,								PREFS_CON_LPORT,
						  @"somehost",						PREFS_CON_RHOST,
						  @0,													PREFS_CON_RPORT,
						  @SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS,		PREFS_CON_RXTIMEOUT,
						  @SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT,			PREFS_CON_TXTIMEOUT,
						  @SMSC_CONNECTION_DEFAULT_KEEPALIVE,					PREFS_CON_KEEPALIVE,
                          @SMSC_CONNECTION_DEFAULT_WINDOW_SIZE,                 PREFS_CON_WINDOW,
                          @(0),                                                 PREFS_CON_TCP_MSS,
						  @"tcp",																		PREFS_CON_SOCKTYPE,
						  @"default-router",																PREFS_CON_ROUTER,
						  @"someuser",																	PREFS_CON_LOGIN,
						  @"topsecret",																	PREFS_CON_PASSWORD,
						  [[NSDictionary alloc] initWithObjectsAndKeys:
						   @1,PREFS_TON,
						   @1,PREFS_NPI,
						   @"",PREFS_NUMBER, nil],														PREFS_CON_SHORT_ID,
						  nil];
	return smppConnectionDict;
}

+ (NSDictionary *) getDefaultListenerConfig
{
	NSDictionary *smppConnectionDict;
	
	smppConnectionDict = [[NSDictionary alloc] initWithObjectsAndKeys:
						  @"default-smpp-connection",	PREFS_CON_NAME,
						  @"smpp",						PREFS_CON_PROTO,
						  @"localhost",					PREFS_CON_LHOST,
						  @SMSC_DEFAULT_SMPP_PORT,								PREFS_CON_LPORT,
						  @"somehost",																	PREFS_CON_RHOST,
						  @0,													PREFS_CON_RPORT,
						  @SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS,		PREFS_CON_RXTIMEOUT,
						  @SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT,			PREFS_CON_TXTIMEOUT,
						  @SMSC_CONNECTION_DEFAULT_KEEPALIVE,					PREFS_CON_KEEPALIVE,
						  @SMSC_CONNECTION_DEFAULT_WINDOW_SIZE,					PREFS_CON_WINDOW,
                          @(0),                                                 PREFS_CON_TCP_MSS,
						  @"tcp",																		PREFS_CON_SOCKTYPE,
						  @"default-router",																PREFS_CON_ROUTER,
						  @"someuser",																	PREFS_CON_LOGIN,
						  @"topsecret",																	PREFS_CON_PASSWORD,
						  [[NSDictionary alloc] initWithObjectsAndKeys:
						   @1,PREFS_TON,
						   @1,PREFS_NPI,
						   @"",PREFS_NUMBER, nil],														PREFS_CON_SHORT_ID,
						  nil];
	return smppConnectionDict;
}

#pragma mark sendingPDUs

- (UMSocketError) sendPduWithNewSeq:(SmppPdu *)pdu
{
    ummutex_lock(_sendLock);
    _lastSeq++;
	_lastSeq %= 0x7FFFFFFF;
    if(_lastSeq == 0)
    {
        _lastSeq = 1;
    }
    pdu.seq =_lastSeq;
	int ret = [self _sendPdu:pdu];
    ummutex_unlock(_sendLock);
    return ret;
}

- (UMSocketError) sendPdu:(SmppPdu *)pdu
       withSequenceString:(NSString *)seqStr
{
    ummutex_lock(_sendLock);
	[pdu setSequenceString:seqStr];
    int ret = [self _sendPdu:pdu];
    ummutex_unlock(_sendLock);
    return ret;
}

- (UMSocketError) sendPdu:(SmppPdu *)pdu withSeq:(SmppPduSequence)seq
{
    ummutex_lock(_sendLock);
    pdu.seq = seq;
    int ret = [self _sendPdu:pdu];
    ummutex_unlock(_sendLock);
    return ret;
}

- (UMSocketError) sendPdu:(SmppPdu *)pdu asResponseTo:(SmppPdu *)pdu1
{
	return [self sendPdu:pdu withSeq:pdu1.seq];
}

- (UMSocketError) _sendPdu:(SmppPdu *)pdu
{
	NSUInteger      l;
	SmppPduType     t;
    UMSmppError 	e;
	NSUInteger      s;
	int             err;
	NSMutableData	*d;
	unsigned char header[16];
	l	= pdu.pdulen;
    [self logOutgoingPdu:pdu];

	t	= pdu.type;
    e	= pdu.err;
	s	= pdu.seq;

	header[0] = (l & 0xFF000000) >> 24;
	header[1] = (l & 0x00FF0000) >> 16;
	header[2] = (l & 0x0000FF00) >> 8;
	header[3] = (l & 0x000000FF) >> 0;

	header[4] = (t & 0xFF000000) >> 24;
	header[5] = (t & 0x00FF0000) >> 16;
	header[6] = (t & 0x0000FF00) >> 8;
	header[7] = (t & 0x000000FF) >> 0;
	
	header[8] = (e & 0xFF000000) >> 24;
	header[9] = (e & 0x00FF0000) >> 16;
	header[10] = (e & 0x0000FF00) >> 8;
	header[11] = (e & 0x000000FF) >> 0;
	
	header[12] = (s & 0xFF000000) >> 24;
	header[13] = (s & 0x00FF0000) >> 16;
	header[14] = (s & 0x0000FF00) >> 8;
	header[15] = (s & 0x000000FF) >> 0;

	d = [[NSMutableData alloc] initWithBytes:header length:16];
	[d appendData:pdu.payload];
     
	err = [_uc sendMutableData: d];
	if(err)
    {
        NSString *text = [NSString stringWithFormat:@"sendMutableData returned error (connection name %@)\r\n", _name];
		[self.logFeed majorError:err	withText:text];
    }
    if(err==0)
    {
        time(&_lastDataPacketSent);
    }
    return err;
}

- (int)activeOutbound
{
	return [self activePhase:1];
}

- (int)activeInbound
{
	return [self activePhase:0];
}

- (UMSocketError) sendAckNack:(SmscConnectionTransaction *) transaction
{
	SmppPdu *pdu2;
    UMSocketError err = 0;

	if(transaction.type == TT_SUBMIT_MESSAGE)
	{
        if(transaction.error.intValue == UM_ESME_ROK)
		{
            pdu2 = [SmppPdu OutgoingSubmitSmRespOK:transaction.message
                                            withId:transaction.message.routerReference.stringValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
		else 
		{
            pdu2 = [SmppPdu OutgoingSubmitSmRespErr:transaction.error.intValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
        if(err==0)
        {
            time(&_lastSubmitSmAckSent);
        }
    }

	else if(transaction.type == TT_DELIVER_MESSAGE)
	{
        if(transaction.error.intValue == UM_ESME_ROK)
		{
            pdu2 = [SmppPdu OutgoingDeliverSmRespOK:transaction.message withId:transaction.message.routerReference.stringValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
		else
		{
            pdu2 = [SmppPdu OutgoingDeliverSmRespErr:transaction.error.intValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
        if(err==0)
        {
            time(&_lastDeliverSmAckSent);
        }
	}

    else if(transaction.type == TT_DELIVER_REPORT)
	{
        /* we received a delivery report from a provider and have to ack it */
        if(transaction.error.intValue == UM_ESME_ROK)
		{
            UMMessageReport * report = [transaction report];
            pdu2 = [SmppPdu OutgoingDeliverSmReportRespOK:report
                                                   withId:report.providerReference];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
            NSLog(@"sendAckNack: outgoing OK deliver report response with connection reference: %@", report.providerReference);
		}
		else
		{
            pdu2 = [SmppPdu OutgoingDeliverSmRespErr:transaction.error.intValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
        if(err==0)
        {
            time(&_lastDeliverSmAckSent);
        }
	}
    
    else if(transaction.type == TT_SUBMIT_REPORT)
	{
        if(transaction.error.intValue == UM_ESME_ROK)
		{
			pdu2 = [SmppPdu OutgoingSubmitSmRespOK:transaction.message withId:transaction.message.routerReference.stringValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
		else
		{
			pdu2 = [SmppPdu OutgoingSubmitSmRespErr:transaction.error.intValue];
			err = [self sendPdu: pdu2 withSequenceString:transaction.sequenceNumber];
		}
        if(err==0)
        {
            time(&_lastSubmitSmAckSent);
        }
	}

	return err;
}

- (int) activePhase:(int)outbound
{
	id<SmscConnectionTransactionProtocol>		an;
	UMMessageObject           *msg;
	UMMessageReport     *report;
	SmppPdu *pdu;
	int i=0;
	UMSocketError err=0;

    /* first lets send out all pending ACK's or NACK's */
	do
	{
#ifdef USE_SMPP_PRIORITY_QUEUES
        an = [ackNackQueue getFromQueue];
#else
        an = [_ackNackQueue getFirst];
#endif
        if(an)
        {
            err = [self sendAckNack: an];
            [self transactionDone: an];
		}
	}
	while(an && (err==0));
    
	if(err!=0)
    {
        NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP activePhase] sendPduWithNewSeq returned error %d (general check), %@",err, outbound ? @"outbound" : @"inbound"];
        [self.logFeed majorError:0 inSubsection:@"active phase" withText:msg];
        goto error;
    }
    /* now lets look at pending outgoing messages and delivery report depending on the corresponding state */

    /* now lets send outgoing messages */
#ifdef USE_SMPP_PRIORITY_QUEUES
    msg = [submitMessageQueue getFromQueue];
#else
    msg = [_submitMessageQueue getFirst];
#endif
    if(msg)
    {
        pdu = [SmppPdu OutgoingSubmitSm:msg options:_options];
        [self.outboundMessagesThroughput increase];
        err = [self sendPduWithNewSeq:pdu];
        if(err==0)
        {
            SmscConnectionTransaction *transaction = [[SmscConnectionTransaction alloc]init];
            transaction.sequenceNumber = [pdu sequenceString];
            transaction.message = msg;
            transaction.type = TT_SUBMIT_MESSAGE;
            [self addOutgoingTransaction: transaction];
            i++;
        }
        else
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP activePhase] sendPduWithNewSeq returned error %d when submitting message, %@",err, (outbound ? @"outbound" : @"inbound")];
            [self.logFeed majorError:0 inSubsection:@"active phase" withText:msg];
            goto error;
        }
    }

#ifdef USE_SMPP_PRIORITY_QUEUES
    msg = [deliverMessageQueue getFromQueue];
#else
    msg = [_deliverMessageQueue getFirst];
#endif
    if(msg)
    {
        pdu = [SmppPdu OutgoingDeliverSm:msg];
        [self.outboundMessagesThroughput increase];

        err = [self sendPduWithNewSeq:pdu];
        if(err==0)
        {
            SmscConnectionTransaction *transaction = [[SmscConnectionTransaction alloc]init];
            transaction.sequenceNumber = [pdu sequenceString];
            transaction.message = msg;
            transaction.type = TT_DELIVER_MESSAGE;
            [self addOutgoingTransaction: transaction];
            i++;
        }
        else
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP activePhase] sendPduWithNewSeq returned error %d when delivering message %@",err, outbound ? @"outbound" : @"inbound"];
            [self.logFeed majorError:0 inSubsection:@"active phase" withText:msg];
            goto error;
        }
   }
#ifdef USE_SMPP_PRIORITY_QUEUES
    report = [submitReportQueue getFromQueue];
#else
    report = [_submitReportQueue getFirst];
#endif
    if(report)
    {
        msg = [report reportToMsg];
        pdu = [SmppPdu OutgoingSubmitSmReport: msg reportingEntity:SMPP_REPORTING_ENTITY_SMSC];
        [self.outboundReportsThroughput increase];

        err = [self sendPduWithNewSeq: pdu];
        if(err==0)
        {
            SmscConnectionTransaction *transaction = [[SmscConnectionTransaction alloc]init];
            transaction.sequenceNumber = [pdu sequenceString];
            transaction.message = msg;
            transaction.report = report;
            transaction.type = TT_SUBMIT_REPORT;
            [self addOutgoingTransaction: transaction];
            i++;
        }
        else
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP activePhase] sendPduWithNewSeq returned error %d when submitting report %@",err, outbound ? @"outbound" : @"inbound"];
            [self.logFeed majorError:0 inSubsection:@"active phase" withText:msg];
            goto error;
        }
    }
    
#ifdef USE_SMPP_PRIORITY_QUEUES
    report = [deliverReportQueue getFromQueue];
#else
    report = [_deliverReportQueue getFirst];
#endif

    if(report)
    {
        msg = [report reportToMsg];
        pdu = [SmppPdu OutgoingDeliverSmReport:msg
                               reportingEntity:SMPP_REPORTING_ENTITY_SMSC];
        [self.outboundReportsThroughput increase];

        err = [self sendPduWithNewSeq: pdu];
        if(err==0)
        {
            SmscConnectionTransaction *transaction = [[SmscConnectionTransaction alloc]init];
            transaction.sequenceNumber = [pdu sequenceString];
            transaction.message = msg;
            transaction.report = report;
            transaction.type = TT_DELIVER_REPORT;
            [self addOutgoingTransaction: transaction];
            i++;
        }
        else
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP activePhase] sendPduWithNewSeq returned error %d when delivering report %@",err, outbound ? @"outbound" : @"inbound"];
            [self.logFeed majorError:0 inSubsection:@"active phase" withText:msg];
            goto error;
        }
    }
    if((outbound) && (err==0))
    {
        [self checkForSendingKeepalive];
    }
    goto end;
error:
    if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
    {
        _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
    }
end:
    return i;
}

#pragma mark Thread handling
- (void)startListener
{
	_endThisConnection = NO;
    _endPermanently = NO;
    
    [self runSelectorInBackground:@selector(inboundListener)];

//	[self performSelectorInBackground:@selector(inboundListener) withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(inboundListener) toTarget:self withObject:nil];
}

- (void)stopListener
{
	_endThisConnection = YES;
    _endPermanently = YES;
}

- (void)startOutgoing
{
	_endThisConnection = NO;
    _endPermanently = NO;
    [self runSelectorInBackground:@selector(outgoingControlThread)];

//	[self performSelectorInBackground:@selector(outboundSender) withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(outgoingControlThread) toTarget:self withObject:nil];
}

- (void)stopOutgoing
{
    _endThisConnection = YES;
    _endPermanently = YES;
    [_cxSleeper wakeUp];
}

- (void)stopIncoming
{
    _endThisConnection = YES;
    _endPermanently = YES;
}

- (void) inboundListener
{
	UMSocket	*newUc;
	NSString	*newName;
	
	[self setIsListener:YES];
	[self setIsInbound:YES];

    ulib_set_thread_name(@"[SmscConnectionSMPP inboundListener]");

	UMSocketError	err;
	NSDate *retryTime = nil;
	NSDate *now = nil;
	NSTimeInterval bindDelay = 30;
	NSTimeInterval retryDelay = 10;
	_incomingStatus = SMPP_STATUS_INCOMING_OFF;
    if (_receivePollTimeoutMs <= 0)
    {
		_receivePollTimeoutMs = SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS; /* default to 20ms */
	}
    
    [self.logFeed info:0 withText:[NSString stringWithFormat:@"InboundListener for %@ on port %d\r\n",_name,_localPort]];
    [_router registerListeningSmscConnection:self];
	while (!_endThisConnection)
	{
		switch(_incomingStatus)
		{
			case SMPP_STATUS_INCOMING_OFF:
                _uc = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY name:@"smpp-listener"]; /* FIXME: really IPv4 only? */
				[_uc setLocalHost:_localHost];
				[_uc setLocalPort:_localPort];
                _uc.configuredMaxSegmentSize = _max_tcp_segment_size;
				_incomingStatus = SMPP_STATUS_INCOMING_HAS_SOCKET;
				break;
				
			case SMPP_STATUS_INCOMING_HAS_SOCKET:
				err = [_uc bind];
				if (![_uc isBound] )
				{
					[self.logFeed majorError:err withText:@"bind failed\r\n"];
					retryTime = [[NSDate alloc]initWithTimeIntervalSinceNow:bindDelay];
					_incomingStatus = SMPP_STATUS_INCOMING_BIND_RETRY_TIMER;
				}
				else
				{
                    TRACK_FILE_ADD_COMMENT_FOR_FDES([_uc sock],@"bound");
					_incomingStatus = SMPP_STATUS_INCOMING_BOUND;
					retryDelay = 10;
				}
				break;
				
			case SMPP_STATUS_INCOMING_BOUND:
                if(_advertizeName)
                {
                    _uc.advertizeName = _advertizeName;
                    _uc.advertizeDomain = @"";
                    _uc.advertizeType = @"_smpp._tcp";
                }
				err = [_uc listen];
				if (![_uc isListening] )
				{
					[self.logFeed majorError:err withText:@"listen failed\r\n"];
					retryTime = [[NSDate alloc]initWithTimeIntervalSinceNow:retryDelay];
					retryDelay = retryDelay * 2;
					if(retryDelay > 600)
						retryDelay = 600; /* try max every 10 minutes */
					_incomingStatus = SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER;
				}
				else
				{
                    TRACK_FILE_ADD_COMMENT_FOR_FDES([_uc sock],@"listening");
					_incomingStatus = SMPP_STATUS_INCOMING_LISTENING;
                    [self.logFeed debug:0 withText:@"Listening...\r\n"];
				}
				break;
			case SMPP_STATUS_INCOMING_LISTENING:
                err = [_uc dataIsAvailable:_receivePollTimeoutMs];
				if(err == UMSocketError_has_data)
				{
                    UMSocketError ret;
					newUc = [_uc accept:&ret];
					if(newUc)
					{
                        TRACK_FILE_ADD_COMMENT_FOR_FDES([_uc sock],@"accept");
                        BOOL doAccept = YES;
                        
                        if([_router respondsToSelector:@selector(isAddressWhitelisted:remotePort:localIpAddress:localPort:serviceType:user:)])
                        {
                            doAccept = [_router isAddressWhitelisted:newUc.connectedRemoteAddress
                                                          remotePort:@(newUc.connectedRemotePort)
                                                      localIpAddress:newUc.connectedLocalAddress
                                                           localPort:@(newUc.connectedLocalPort)
                                                         serviceType:@"smpp"
                                                                user:NULL];

                        }
                        if(doAccept)
                        {

                            newName = [NSString stringWithFormat:@"%@ (%p)",
                                       _name, newUc];
                            
                            SmscConnectionSMPP *e = [[SmscConnectionSMPP alloc] init];
                            [e setName: newName];
                            [e setUc: newUc];
                            [e setRouter: _router];
                            [e setLocalHost: [newUc localHost]];
                            [e setLocalPort: [newUc connectedLocalPort]];
                            [e setRemoteHost: [[UMHost alloc]initWithAddress:newUc.connectedRemoteAddress]];
                            [e setRemotePort: [newUc connectedRemotePort]];
                            [e setIncomingStatus: SMPP_STATUS_INCOMING_CONNECTED];
                            [e setInboundState: SMPP_STATE_IN_OPEN];
                            [e setIsListener: NO];
                            [e setIsInbound: YES];
                            [e setLastActivity:[NSDate date]];
                            [e setLogFeed:self.logFeed];
                            e.max_tcp_segment_size = _max_tcp_segment_size;
                            e.uc.configuredMaxSegmentSize = _max_tcp_segment_size;

                            [self.logFeed debug:0 withText:[NSString stringWithFormat:@"accepting connection for %@ for %@ at sock %d\r\n",_name,newUc,newUc.sock]];
                            [e runSelectorInBackground:@selector(inbound)];
//                            [NSThread detachNewThreadSelector:@selector(inbound) toTarget:e withObject:nil];
                        }
                        else
                        {
                            TRACK_FILE_ADD_COMMENT_FOR_FDES([_uc sock],@"failed whitelist");
                            [self.logFeed debug:0 withText:[NSString stringWithFormat:@"connection from %@ rejected (not in whitelist)\r\n",newUc.connectedRemoteAddress]];
                            [newUc close];
                            newUc=NULL;
                        }
					}
					else
                    {
						[_txSleeper sleep:100000]; /* check again in 100ms */
                    }
				}
				_incomingStatus = SMPP_STATUS_INCOMING_LISTENING;
				break;
			case SMPP_STATUS_INCOMING_BIND_RETRY_TIMER:
				now = [NSDate new];
                if(retryTime == NULL)
                {
                    retryTime = [NSDate dateWithTimeIntervalSinceNow:30];
                }
                if([now compare:retryTime] == NSOrderedDescending)
                {
                    retryTime = nil;
                    _incomingStatus = SMPP_STATUS_INCOMING_OFF;
                }
                else
                {
                    [_txSleeper sleep:100000]; /* check again in 100ms */
                }
				break;
				
			case SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER:
				now = [NSDate new];
				if([now compare:retryTime] == NSOrderedDescending)
				{
					retryTime = nil;
					_incomingStatus = SMPP_STATUS_INCOMING_OFF;
				}
				else
				{
					[_txSleeper sleep:100000]; /* check again in 100ms */
				}
				break;
			default:
				break;
		}
	}
    
    [self.logFeed info:0 withText:[NSString stringWithFormat:@"InboundListener for %@ on port %d shutting down\r\n",_name,_localPort]];
	[_router unregisterListeningSmscConnection:self];
	[self stopIncomingReceiverThread];
	[_uc close];
    [_terminatedDelegate terminatedCallback:self];
    _uc = nil;
    retryTime = nil;
}

- (NSString *)connectedFrom
{
    if(_isListener)
    {
        return [NSString stringWithFormat:@"listener on port %d",_uc.requestedLocalPort];
    }
    if(_uc==NULL)
    {
        return @"(not connected)";
        
    }
    
#define STRING_WITH_COMMA_FROM_ARRAY(a)  ((a) ? [(a) componentsJoinedByString:@","] : @"")

    return [NSString stringWithFormat:@"%@:%d", _uc.connectedRemoteAddress,_uc.connectedRemotePort];
    
}


- (NSString *)connectedTo
{
    if(_uc == NULL)
    {
        return @"no socket";
    }
    if(_uc.remoteHost == NULL)
    {
        return @"no host";
    }
    if([_uc.remoteHost.addresses count] == 0)
    {
        return @"no address";
    }
    
    return [NSString stringWithFormat:@"%@:%d",_uc.connectedRemoteAddress, _uc.requestedRemotePort];/* was  uc.remoteHost.addresses[0] */
}

- (void)startIncomingReceiverThread
{
    @autoreleasepool
    {
        int i;
        
        if(_runIncomingReceiverThread != SMPP_IRT_NOT_RUNNING)
        {
            [self.logFeed debug:0 withText:@"we try to start receiver thread while its already running ?!?"];
            [self stopIncomingReceiverThread];
        }
        
        _runIncomingReceiverThread = SMPP_IRT_STARTING;
        
        [self runSelectorInBackground:@selector(incomingReceiverThread)];
        //    [NSThread detachNewThreadSelector:@selector(incomingReceiverThread) toTarget:self withObject:nil];
        i = 0;
        while((_runIncomingReceiverThread != SMPP_IRT_RUNNING) && (i<100))
        {
            usleep(10000);
            i++;
        }
    }
}


- (void)stopIncomingReceiverThread
{
    @autoreleasepool
    {
        int i=0;
        
        if(_runIncomingReceiverThread == SMPP_IRT_NOT_RUNNING)
        {
            return;
        }_runIncomingReceiverThread = SMPP_IRT_TERMINATING;
        while((_runIncomingReceiverThread != SMPP_IRT_TERMINATED) && (i<100))
        {
            usleep(10000);
            i++;
        }
        _runIncomingReceiverThread = SMPP_IRT_NOT_RUNNING;
    }
}

- (void) incomingReceiverThread
{
    @autoreleasepool
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[SmscConnectionSMPP inboundReceiverThread] %@",_uc.description]);

        if(_runIncomingReceiverThread != SMPP_IRT_STARTING)
        {
            return;
        }
        _runIncomingReceiverThread = SMPP_IRT_RUNNING;
        
        if(_receivePollTimeoutMs <= 0)
        {
            _receivePollTimeoutMs = SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS; /* default to 500ms */
        }
        [self.logFeed info:0 withText:@"[SmscConnectionSMPP incomingReceiverThread]: inbound receiver thread is starting\r\n"];
        
        while ((!_endThisConnection) && (_runIncomingReceiverThread==SMPP_IRT_RUNNING))
        {
            @autoreleasepool
            {
                UMSocketError sErr = UMSocketError_no_data;
                sErr  = [_uc dataIsAvailable:_receivePollTimeoutMs];
                
                if((sErr == UMSocketError_has_data) || (sErr==UMSocketError_has_data_and_hup)) /* we received something */
                {
                    UMSocketError sErr2 = [_uc receiveToBufferWithBufferLimit: 10240];
                    if(sErr2 == UMSocketError_has_data)
                    {
                        [self checkForPackets]; /* process whatever is left */
                        continue;
                    }
                    if((sErr2== UMSocketError_no_data) || (sErr2==UMSocketError_connection_reset)) /* HUP */
                    {
                        NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP incomingReceiverThread]: EOF read"];
                        [self.logFeed info:0 inSubsection:@"outbound receiver" withText:msg];
                        _endThisConnection=YES;
                    }
                    else if(sErr2==UMSocketError_no_error)
                    {
                        [self checkForPackets];
                    }
                    else if(sErr2!=UMSocketError_try_again)
                    {
                        NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP incomingReceiverThread]:socket error %d (%@) when reading a packet\r\n", sErr2, [UMSocket getSocketErrorString:sErr2]];
                        [self.logFeed info:0 inSubsection:@"incoming receiver" withText:msg];
                        [self checkForPackets]; /* process whatever is left */
                        _endThisConnection=YES;
                        break;
                    }
                    if(sErr==UMSocketError_has_data_and_hup)
                    {
                        [self checkForPackets]; /* process whatever is left */
                        NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP incomingReceiverThread]: POLLHUP received"];
                        [self.logFeed info:0 inSubsection:@"outbound receiver" withText:msg];
                        _endThisConnection=YES;
                    }
                }
                else if((sErr != UMSocketError_try_again) && (sErr !=UMSocketError_no_error) && (sErr != UMSocketError_no_data))
                {
                    NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP incomingReceiverThread]: socket error %d (%@) when socket returns, will terminate thread\r\n", sErr, [UMSocket getSocketErrorString:sErr]];
                    [self.logFeed majorError:0 inSubsection:@"init" withText:msg];
                    _endThisConnection=YES;
                    break;
                }
            }
        }
        [self.logFeed info:0 withText:@"[SmscConnectionSMPP incomingReceiverThread]: inbound receiver thread is terminating\r\n"];
        _runIncomingReceiverThread = SMPP_IRT_TERMINATED;
    }
}

#pragma mark receivingPDUs and parsing
- (void) checkForPackets
{
    @autoreleasepool
    {
        
        unsigned char header[16];
        SmppPdu *pdu;
        int l;
        
        if(_debugLastLocation != NULL)
        {
            int a= 1;
            int b= 0;
            int c;
#pragma unused(c)
            c = a/b;
            //kill(getpid(), SIGTRAP);
        }
        else
        {
            pthread_t ptid = pthread_self();
            
            NSString *threadName = ulib_get_thread_name(ptid);
            _debugLastLocation =[NSString stringWithFormat:@"Thread %ld (%@)",(long)ptid,threadName];
        }
        
        do
        {
            memset(header,0xF0,sizeof(header));
            if([[_uc receiveBuffer] length] < 16)
            {
                break;
            }
            
            @synchronized(_uc.receiveBuffer)
            {
                [[_uc receiveBuffer] getBytes: header length:16];
            }
            if(   (header[0] == 'G')
               && (header[1] == 'E')
               && (header[2] == 'T')
               && (header[3] == ' ')
               && (header[4] == '/'))
            {
                [_uc sendString:@"HTTP/1.0 400 Bad Request\r\n"];
                [_uc sendString:@"Server: ulibsmpp\r\n"];
                [_uc sendString:@"Mime-Version: 1.0\r\n"];
                [_uc sendString:@"Content-Type: text/html\r\n"];
                [_uc sendString:@"Connection: close\r\n"];
                [_uc sendString:@"\r\n"];
                [_uc sendString:@"<html>\r\n"];
                [_uc sendString:@"<head>\r\n"];
                [_uc sendString:@"    <title>Wrong Port</title>\r\n"];
                [_uc sendString:@"    <meta charset=\"UTF-8\">"];
                [_uc sendString:@"</head>\r\n"];
                [_uc sendString:@"<body>\r\n"];
                [_uc sendString:@"  <h2>Wrong Port</h2>\r\n"];
                [_uc sendString:@"  <p>This port is supposed to be used for SMPP not for HTTP!</p>\r\n"];
                [_uc sendString:@"</body>\r\n"];
                [_uc sendString:@"</html>\r\n"];
                _endThisConnection=YES;
                break;
            }
            
            l	= ((header[0] << 24) | (header[1] << 16) | (header[2] << 8) | (header[3]));
            if([[_uc receiveBuffer] length] < l)
            {
                long len = [[_uc receiveBuffer] length];
                NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP checkForPackets]: received packet with erroneous length (claimed %d, was %ld)\r\n", l, len];
                [self.logFeed minorError:0 inSubsection:@"smpp" withText:msg];
                break;
           }
            
            pdu = [[SmppPdu alloc] initFromData:[_uc receiveBuffer]];
            if(pdu)
            {
                time(&_lastDataPacketReceived);
                [self logIncomingPdu:pdu];
                [self handleIncomingPdu:pdu];
                pdu = NULL;
            }
            
            //[uc deleteFromReceiveBuffer:l];
            //  Remove packet from the receive buffer
            [_uc. receiveBuffer replaceBytesInRange:NSMakeRange(0,l) withBytes:"" length:0];
        }
        while(1);
        _debugLastLastLocation = _debugLastLocation;
        _debugLastLocation = NULL;
    }
}


- (SmppAuth)	checkAuthorisation: (SmppPdu *)pdu
{
	SmppSource			source;
	if([self isInbound])
    {
		source = SMPP_SOURCE_ESME;
    }
	else
    {
		source =SMPP_SOURCE_SMSC;
    }
	int i;
	for (i=0;i< sizeof(SmppPDUTable) / sizeof(SmppPduTableEntry);i++)
	{
		if( SmppPDUTable[i].pduType == pdu.type)
		{
			if(0 == (SmppPDUTable[i].allowedSources & source))
            {
				return SMPP_AUTH_WRONG_SOURCE; /* wrong source */
            }
			if(0 == (SmppPDUTable[i].allowedStates & _inboundState))
            {
                if(0 == (SmppPDUTable[i].allowedStates & _outboundState))
                {
				    return SMPP_AUTH_WRONG_STATE; /* wrong state */
                }
            }
			return SMPP_AUTH_OK;
		}
	}
	return SMPP_AUTH_UNKNOWN_PDU_TYPE;
}

#pragma mark -
#pragma mark Incoming PDU parsing

- (void)	handleIncomingPdu:(SmppPdu *)pdu
{
    @autoreleasepool
    {
        SmppAuth a;
        SmppPdu *pdu2;
        
        a = [self checkAuthorisation:pdu];
        switch(a)
        {
            case SMPP_AUTH_UNKNOWN_PDU_TYPE:
                pdu2	= [SmppPdu OutgoingGenericNack: UM_ESME_RINVCMDID];
                [self sendPdu: pdu2 asResponseTo:pdu];
                _endThisConnection = YES;
                _endPermanently = YES;
                break;
                
            case SMPP_AUTH_WRONG_SOURCE:
                pdu2	= [SmppPdu OutgoingGenericNack: UM_ESME_RINVBNDSTS];
                [self sendPdu: pdu2 asResponseTo:pdu];
                _endThisConnection = YES;
                _endPermanently = YES;
                break;
                
            case SMPP_AUTH_WRONG_STATE:
                pdu2	= [SmppPdu OutgoingGenericNack: UM_ESME_RINVBNDSTS];
                [self sendPdu: pdu2 asResponseTo:pdu];
                _endThisConnection = YES;
                _endPermanently = YES;
                break;
                
            case SMPP_AUTH_OK:
                switch( (int)pdu.type)
            {
                case SMPP_PDU_SUBMIT_SM:
                    time(&_lastSubmitSmReceived);
                    [self handleIncomingSubmitSm: pdu];
                    self.lastActivity =[NSDate new];
                    break;
                case SMPP_PDU_SUBMIT_SM_RESP:
                    time(&_lastSubmitSmAckReceived);
                    [self handleIncomingSubmitSmResp: pdu];
                    break;
                case SMPP_PDU_DATA_SM:
                    [self handleIncomingDataSm: pdu];
                    break;
                case SMPP_PDU_DATA_SM_RESP:
                    [self handleIncomingDataSmResp: pdu];
                    break;
                case SMPP_PDU_DELIVER_SM:
                    time(&_lastDeliverSmReceived);
                    [self handleIncomingDeliverSm: pdu];
                    self.lastActivity =[NSDate new];
                    break;
                case SMPP_PDU_DELIVER_SM_RESP:
                    time(&_lastDeliverSmAckReceived);
                    [self handleIncomingDeliverSmResp: pdu];
                    break;
                case SMPP_PDU_ENQUIRE_LINK:
                    [self handleIncomingEnquireLink: pdu];
                    break;
                case SMPP_PDU_ENQUIRE_LINK_RESP:
                    [self handleIncomingEnquireLinkResp: pdu];
                    break;
                case SMPP_PDU_GENERIC_NACK:
                    [self handleIncomingGenericNack: pdu];
                    break;
                case SMPP_PDU_BIND_RECEIVER:
                    [self handleIncomingBindReceiver: pdu];
                    break;
                case SMPP_PDU_BIND_RECEIVER_RESP:
                    [self handleIncomingBindReceiverResp: pdu];
                    break;
                case SMPP_PDU_BIND_TRANSMITTER:
                    [self handleIncomingBindTransmitter: pdu];
                    break;
                case SMPP_PDU_BIND_TRANSMITTER_RESP:
                    [self handleIncomingBindTransmitterResp: pdu];
                    break;
                case SMPP_PDU_QUERY_SM:
                    [self handleIncomingQuerySm: pdu];
                    break;
                case SMPP_PDU_QUERY_SM_RESP:
                    [self handleIncomingQuerySmResp: pdu];
                    break;
                case SMPP_PDU_UNBIND:
                    [self handleIncomingUnbind: pdu];
                    break;
                case SMPP_PDU_UNBIND_RESP:
                    [self handleIncomingUnbindResp: pdu];
                    break;
                case SMPP_PDU_REPLACE_SM:
                    [self handleIncomingReplaceSm: pdu];
                    break;
                case SMPP_PDU_REPLACE_SM_RESP:
                    [self handleIncomingReplaceSmResp: pdu];
                    break;
                case SMPP_PDU_CANCEL_SM:
                    [self handleIncomingCancelSm: pdu];
                    break;
                case SMPP_PDU_CANCEL_SM_RESP:
                    [self handleIncomingCancelSmResp: pdu];
                    break;
                case SMPP_PDU_BIND_TRANSCEIVER:
                    [self handleIncomingBindTransceiver: pdu];
                    break;
                case SMPP_PDU_BIND_TRANSCEIVER_RESP:
                    [self handleIncomingBindTransceiverResp: pdu];
                    break;
                case SMPP_PDU_OUTBIND:
                    [self handleIncomingOutbind: pdu];
                    break;
                case SMPP_PDU_SUBMIT_SM_MULTI:
                    [self handleIncomingSubmitSmMulti: pdu];
                    break;
                case SMPP_PDU_SUBMIT_SM_MULTI_RESP:
                    [self handleIncomingSubmitSmMultiResp: pdu];
                    break;
                case SMPP_PDU_ALERT_NOTIFICATION:
                    [self handleIncomingAlertNotification: pdu];
                    break;
            }
                break;
        }
    }
}

- (void) handleIncomingSubmitSm: (SmppPdu *)pdu
{
    UMTonType ton;
    UMNpiType npi;
    NSString *addr = nil;
//	NSString *serviceType = nil;
    UMSigAddr *from = nil;
    UMSigAddr *to = nil;
    NSData *data = nil;
    NSData *udh = nil;
    int udhLen;
    int dataLen;
    SmscConnectionTransaction *transaction;
 //   NSString *username;
//    int err;

    UMMessageObject * msg = [_router createMessage];
    @try
    {
        msg.submissionMethod = UMDIRTY_STRING(@"smpp");
        msg.submissionType   = UMDIRTY_STRING(@"submit");
        msg.fromIp        = UMDIRTY_STRING([_uc connectedRemoteAddress]);
        msg.user = _user;
        msg.userName = UMDIRTY_STRING(_user.username);
        [pdu resetCursor];

        /*serviceType = */
        [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:255];
        ton  = (UMTonType)[pdu grabInt8];
        npi  = (UMNpiType)[pdu grabInt8];
        addr = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:40];
        if(ton == UMTON_ALPHANUMERIC)
        {
            from = [[UMSigAddr alloc] initWithAlpha:addr];
            [from setNpi: npi];
        }
        else
        {
            from = [[UMSigAddr alloc] init];
            [from setTon: ton];
            [from setNpi: npi];
            [from setAddr: addr];
            if(![addr smppHasOnlyDecimalDigits])
            {
                @throw([NSException exceptionWithName:@"ESME_RINVSRCADR"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"invalid_source_address (address does not only contain digits)",
                    @"func": @(__func__),
                    @"obj":self,
                    @"code":@(UM_ESME_RINVSRCADR)
                }
                       ]);
                
            }
        }
        msg.fromNumber = UMDIRTY_STRING([from asString:1]);
        ton  = (UMTonType)[pdu grabInt8];
        npi  = (UMNpiType)[pdu grabInt8];
        addr = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:31];
        if(ton == UMTON_ALPHANUMERIC)
        {
            to = [[UMSigAddr alloc] initWithAlpha:addr];
            [to setNpi: npi];
        }
        else
        {
            to = [[UMSigAddr alloc] init];
            [to setTon: ton];
            [to setNpi: npi];
            [to setAddr: addr];
            if(![addr smppHasOnlyDecimalDigits])
            {
                @throw([NSException exceptionWithName:@"ESME_RINVDSTADR"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"invalid_destination_addres (address does not only contain digits)",
                    @"func": @(__func__),
                    @"obj":self,
                    @"code":@(UM_ESME_RINVDSTADR)
                }
                       ]);
            }
        }
        msg.toNumber = UMDIRTY_STRING([to asString:1]);
        NSInteger esmClass = [pdu grabInt8];
        /* TODO: do something with ESM class */

        if((esmClass & 0x03) == 0)
        {
            esmClass |= SMPP_PDU_ESM_CLASS_SUBMIT_STORE_AND_FORWARD_MODE;
        }
        if((esmClass & 0x03) != SMPP_PDU_ESM_CLASS_SUBMIT_STORE_AND_FORWARD_MODE)
        {
            @throw([NSException exceptionWithName:@"ESME_RINVESMCLASS"
                                           reason:NULL
                                         userInfo:@{
                @"sysmsg" : @"error_wrong_esm_clas should be 0x03 for store & forward",
                @"func": @(__func__),
                @"obj":self,
                @"code":@(UM_ESME_RINVESMCLASS)
            }
                   ]);
        }
        if(esmClass & SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR)
        {
            msg.udhIndicator=YES;
        }
        else
        {
            msg.udhIndicator=NO;
        }
        if(esmClass & SMPP_PDU_ESM_CLASS_SUBMIT_RPI)
        {
            msg.replyPathIndicator = YES;
        }
        else
        {
            msg.replyPathIndicator = NO;
        }
        msg.pduPid =  UMDIRTY_INTEGER([pdu grabInt8]);
        msg.messagePriority = UMDIRTY_INTEGER([pdu grabInt8]);

        NSString *defferredDeliveryString   = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding maxLength:255];
        NSDate *defferredDelivery           = [SmppPdu smppTimestampFromString:defferredDeliveryString];
        msg.deferred = UMDIRTY_DATE(defferredDelivery);

        NSString *validityPeriodString      = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding maxLength:255];
        NSDate *validityPeriod              = [SmppPdu smppTimestampFromString:validityPeriodString];
        msg.validity = UMDIRTY_DATE(validityPeriod);
        UMRequestMaskValue dlrMask = (UMRequestMaskValue)[pdu grabInt8];
        UMReportMaskValue requestMask = 0;
        if(dlrMask & REQUEST_MASK_SUCCESS_OR_FAIL)
        {
            requestMask |= ( UMDLR_MASK_SUCCESS  | UMDLR_MASK_FAIL);
        }
        if (dlrMask & REQUEST_MASK_FAIL)
        {
            requestMask |= UMDLR_MASK_FAIL;
        }
        if (dlrMask & REQUEST_MASK_INTERMEDIATE)
        {
            requestMask |= (UMDLR_MASK_BUFFERED | UMDLR_MASK_SUBMIT);
        }
        msg.deliveryReportMask      = [[UMDirtyInteger alloc]initWithInteger:requestMask];
        msg.replaceIfPresentFlag    = [[UMDirtyInteger alloc]initWithInteger:([pdu grabInt8] ? 1 : 0)];
        int dcs = (int)[pdu grabInt8];
        switch(dcs)
        {
            case 0: /* default */
            case 1: /* IA5 CCITT T.50 */
                msg.pduCoding=[[UMDirtyString alloc]initWithString:@"gsm"];
                break;
            case 2: /* Octet unspecified (8-bit binary) */
            case 4: /* Octet unspecified (8-bit binary) */
                msg.pduCoding=UMDIRTY_STRING(@"binary");
                break;
            case 3: /* Latin 1 ISO-8859-1 */
                msg.pduCoding=UMDIRTY_STRING(@"latin-1");
                break;
            case 5: /* JIS (X 0208-1990) */
                msg.pduCoding=UMDIRTY_STRING(@"jis");
                break;
            case 6: /* Cyrillic (ISO-8859-5) */
                msg.pduCoding=UMDIRTY_STRING(@"cyrillic");
                break;
            case 7: /* Latin/Hebrew (ISO-8859-8)  */
                msg.pduCoding=UMDIRTY_STRING(@"latin-8");
                break;
            case 8: /* UCS2 */
                msg.pduCoding=UMDIRTY_STRING(@"ucs2");
                break;
            case 9: /* UCS2 */
                msg.pduCoding=UMDIRTY_STRING(@"ucs2");
                break;
            case 0x0A: /* Music Codes */
                msg.pduCoding=UMDIRTY_STRING(@"music");
                break;
            case 0x0D:
                msg.pduCoding = UMDIRTY_STRING(@"extended-kanji");
                break;
            case 0x0E:
                msg.pduCoding = UMDIRTY_STRING(@"ks-c-5601");
                break;
            default:
            {
                int upperFlags = dcs & 0xF0;
                if((upperFlags == 0xC0)  || (upperFlags == 0xD0))
                {
                    msg.pduCoding = UMDIRTY_STRING(@"gsm-mwi");
                }
                else if(upperFlags == 0xF0)
                {
                    msg.pduCoding = UMDIRTY_STRING(@"gsm-message-class-control");
                }
                else
                {
                    msg.pduCoding = UMDIRTY_STRING(@"reserved");
                }
            }
        }
        msg.pduDcs= UMDIRTY_INTEGER(dcs);
    //	int i;
        
    /*	i = */[pdu grabInt8];
    //	[msg setDefaultMessageId: i];
        int length = (int)[pdu grabInt8];
            
        if(msg.udhIndicator)
        {
            if(length< 1)
            {
                @throw([NSException exceptionWithName:@"ESME_RINVPARLEN"
                                               reason:NULL
                                             userInfo:@{
                                                        @"sysmsg" : @"invalid length",
                                                        @"func": @(__func__),
                                                        @"obj":self,
                                                        @"code":@(UM_ESME_RINVPARLEN)
                                                        }
                        ]);

            }
            udhLen = (int)[pdu grabInt8];

            dataLen = length - udhLen - 1 ;
            if((udhLen <= 0) || (dataLen < 0))
            {
                @throw([NSException exceptionWithName:@"ESME_RINVPARLEN"
                                               reason:NULL
                                             userInfo:@{
                                                        @"sysmsg" : @"invalid length",
                                                        @"func": @(__func__),
                                                        @"obj":self,
                                                        @"code":@(UM_ESME_RINVPARLEN)
                                                        }
                        ]);
            }
            pdu.cursor = pdu.cursor - 1;
            udh = [[NSData alloc] initWithBytes: &((unsigned char *)[pdu.payload bytes])[pdu.cursor] length:udhLen+1];
            [pdu setCursor: pdu.cursor + udhLen + 1];

            data = [[NSData alloc] initWithBytes: &((unsigned char *)[pdu.payload bytes])[pdu.cursor] length:dataLen];
            [pdu setCursor: pdu.cursor + dataLen + 1];
        }
        else
        {
    //		udhLen = 0;
            dataLen = length;
            udh = nil;
            data = [[NSData alloc] initWithBytes: &((unsigned char *)[pdu.payload bytes])[pdu.cursor] length:dataLen];
            [pdu setCursor: pdu.cursor + dataLen + 1];
        }
        msg.pduUdh = UMDIRTY_DATA(udh);
        msg.pduContent = UMDIRTY_DATA(data);
        [msg expandUdh];
        msg.plaintextContent = UMDIRTY_STRING([data smppStringFromGsm8]);
        [pdu grabTlvsWithDefinitions:_tlvDefs];
        msg.tlvsText = UMDIRTY_STRING([pdu.tlvs jsonString]);
        switch(pdu.dest_addr_subunit)
        {
            case 0x00: /* Unknown (default) */
                break;
            case 0x01: /* MS Display */
                msg.messageClass= UMDIRTY_INTEGER(MC_CLASS0); /* 3GPP TS 23.038 Class 0 = flash SMS */
                break;
            case 0x02: /* Mobile Equipment */
                msg.messageClass=UMDIRTY_INTEGER(MC_CLASS1); /* 3GPP TS 23.038 Default meaning: ME-specific. */
                break;
            case 0x03: /* Smart Card 1 (expected to be SIM if a SIM exists in the MS) */
                msg.messageClass= UMDIRTY_INTEGER(MC_CLASS2); /* 3GPP TS 23.038 (U)SIM specific message */
                break;
            case 0x04: /* External Unit 1 */
                msg.messageClass= UMDIRTY_INTEGER(MC_CLASS3); /* default meaning: TE specific (see 3GPP TS 27.005 [8]) */
                break;
            default: /*  5 to 255 = reserved */
                @throw([NSException exceptionWithName:@"ESME_ROPTPARNOTALLWD"
                                               reason:NULL
                                             userInfo:@{
                                                        @"sysmsg" : @"ESME_ROPTPARNOTALLWD",
                                                        @"func": @(__func__),
                                                        @"err": @(UM_ESME_ROPTPARNOTALLWD)
                                                        }]);

                break;
        }


        if([_user hasCredits] == NO)
        {
            @throw([NSException exceptionWithName:@"ESME_RMSGQFUL"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"ESME_RMSGQFUL(out of credit)",
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"code":@(UM_ESME_RMSGQFUL)
                                                    }
                    ]);
        }
        if([_user withinSpeedlimit] == NO)
        {
            @throw([NSException exceptionWithName:@"ESME_RTHROTTLED"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"ESME_RTHROTTLED(throttling because of speed limit reached)",
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"code":@(UM_ESME_RTHROTTLED)
                                                    }
                    ]);
        }
        [_user increase];
        [self.inboundMessagesThroughput increase];
        msg.user = _user;
        msg.userName = UMDIRTY_STRING(_user.username);
        msg.userReference = UMDIRTY_STRING([pdu sequenceString]);
        transaction = [[SmscConnectionTransaction alloc] init];
        [transaction setLowerObject:self];
        transaction.sequenceNumber = [pdu sequenceString];
        transaction.message= msg;
        [transaction setType: TT_SUBMIT_MESSAGE];
        [transaction setIncoming:YES];
        [self addIncomingTransaction:transaction];
         msg.userTransaction = transaction;
        
        transaction = NULL;

        if(_router)
        {
            [_router submitMessage: msg
                        forObject:self
                      synchronous:NO];
            _lastStatus = [NSString stringWithFormat:@"submitSm"];
        }
        else
        {
            @throw([NSException exceptionWithName:@"ESME_RTHROTTLED"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"ESME_RTHROTTLED(throttling because of speed limit reached)",
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"code":@(UM_ESME_RTHROTTLED)
                                                    }
                    ]);
        }
    }
    @catch(NSException *err)
    {
        _lastStatus =  err.userInfo[@"sysmsg"];
        int errorCode = [err.userInfo[@"code"] intValue];
        SmppPdu *pdu2	= [SmppPdu OutgoingSubmitSmRespErr:(UMSmppError)errorCode];
        [self sendPdu: pdu2 asResponseTo:pdu];
    }
}

- (void) handleIncomingSubmitSmResp: (SmppPdu *)pdu
{
    UMSmppError stCode = pdu.err;
    NSString *remoteMessageId = [pdu grabStringWithEncoding:NSASCIIStringEncoding maxLength:65];
  
    if(_usesHexMessageIdInSubmitSmResp)
    {
        long long llid;
        sscanf(remoteMessageId.UTF8String,"%llx",&llid);
        remoteMessageId = [NSString stringWithFormat:@"%lld",llid ];
    }
    
    SmscConnectionTransaction *transaction = [self findOutgoingTransaction:[pdu sequenceString]];
    UMMessageObject *msg = transaction.message;
    if(msg)
    {
        msg.networkErrorCode = UMDIRTY_INTEGER(stCode);
        msg.providerReference = UMDIRTY_STRING(remoteMessageId);
        if (stCode == UM_ESME_ROK)
        {
            [_router submitMessageSent:msg
                            forObject:self
                          synchronous:NO];
            _lastStatus = @"OK";
        }
        else
        {
            [_router submitMessageFailed:msg
                                   error:@(stCode)
                               forObject:self
                             synchronous:NO];
            _lastStatus = [NSString stringWithFormat:@"%@ (0x%08lx)",UMSmppErrorAsString(stCode), (unsigned long )stCode ];

        }
    }
    if(transaction)
    {
        @synchronized(_outgoingTransactions)
        {
            [_outgoingTransactions removeObjectForKey:transaction.sequenceNumber];
        }
    }
}

- (void) handleIncomingDataSm: (SmppPdu *)pdu
{
}

- (void) handleIncomingDataSmResp: (SmppPdu *)pdu
{
}

- (void) handleIncomingDeliverSm: (SmppPdu *)pdu
{
    BOOL deliveryReport = NO;
    SmscConnectionTransaction *transaction = NULL;
    int esmClass;
    UMMessageReport * report=NULL;
    UMMessageObject * msg=NULL;
    
    [pdu unpackDeliverSmUsingTlvDefinition:_tlvDefs];
    
    esmClass = (int)pdu.esm_class;
    msg.esmClass = UMDIRTY_INTEGER(esmClass);
    deliveryReport = esmClass == SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK ||
                     esmClass == SMPP_PDU_ESM_CLASS_DELIVER_SME_DELIVER_ACK ||
                     esmClass == SMPP_PDU_ESM_CLASS_DELIVER_SME_MANULAL_ACK ||
                     esmClass == SMPP_PDU_ESM_CLASS_DELIVER_INTERM_DEL_NOTIFICATION;
    
    transaction = [[SmscConnectionTransaction alloc] init];
    transaction.sequenceNumber =[pdu sequenceString];
    if (deliveryReport)
    {
        report = [self deliverPduToReport:pdu];
        [transaction setReport:report];
        [transaction setType: TT_DELIVER_REPORT];
    }
    else
    {
        msg = [self deliverPduToMsg:pdu];
        transaction.message = msg;
        [transaction setType: TT_DELIVER_MESSAGE];
    }
    [transaction setIncoming:YES];
    [self  addIncomingTransaction:transaction];
    
    [self.inboundReportsThroughput increase];

    if (deliveryReport)
    {
        if((report) && (_router))
        {
            [_router deliverReport:report
                        forObject:self
                      synchronous:NO];
        }
        else
        {
            SmppPdu *pdu2	= [SmppPdu OutgoingDeliverSmRespErr: UM_ESME_RSYSERR];
            [self sendPdu: pdu2 asResponseTo:pdu];
        }
    }
    else
    {
        if((msg)  && (_router))
        {
            [_router deliverMessage:msg
                         forObject:self
                       synchronous:NO];
        }
        else
        {
            SmppPdu *pdu2	= [SmppPdu OutgoingDeliverSmRespErr: UM_ESME_RSYSERR];
            [self sendPdu: pdu2 asResponseTo:pdu];
        }
    }
}

- (void) handleIncomingDeliverSmResp: (SmppPdu *)pdu
{
    UMMessageReport *report;
    UMMessageObject       *message;
    
    UMSmppError stCode = pdu.err;
//    NSString *remoteMessageId = [pdu grabStringWithEncoding:NSASCIIStringEncoding maxLength:65];
    SmscConnectionTransaction *transaction = [self findOutgoingTransaction:[pdu sequenceString]];

//    NSString *sentMessageId = transaction.message.routerReference;
    message = transaction.message;
    report = [transaction report];
    if(report)
    {
        /* this is an ack to a delivery report we sent upstream */
        //[report setNetworkErrorCode:stCode];
        //[report setRemoteMessageId:remoteMessageId];
        if (stCode == UM_ESME_ROK)
        {
            [_router deliverReportSent:report
                            forObject:self
                          synchronous:NO];
        }
        else
        {
            [_router deliverReportFailed:report
                                   error:@(UM_ESME_RDELIVERYFAILURE)
                              forObject:self
                            synchronous:NO];

        }
    }
    else if(message)
    {
        /* this is an ack on a sms-mo we sent upstream */
        message.networkErrorCode=UMDIRTY_INTEGER(stCode);
        // As we sent a deliver sm upstream, remoteMessageId should be our own router id we send before
        // so definitively not the same as the provider's message ID we used before.
        //message.connectionReference = remoteMessageId;/* FIXME setRemoteMessageId should be what? */
        if (stCode == UM_ESME_ROK)
        {
            [_router deliverMessageSent:message
                             forObject:self
                           synchronous:NO];
        }
        else
        {
            [_router deliverMessageFailed:message
                                    error:@(UM_ESME_RDELIVERYFAILURE)
                               forObject:self
                             synchronous:NO];
        }
    }
    [self removeOutgoingTransaction:transaction];
}

- (void) handleIncomingEnquireLink: (SmppPdu *)pdu
{
	SmppPdu *pdu2;
	pdu2	= [SmppPdu OutgoingEnquireLinkResp];
	[self sendPdu: pdu2 asResponseTo:pdu];
}

- (void) handleIncomingEnquireLinkResp: (SmppPdu *)pdu
{
    time(&_lastKeepAliveReceived);
    _outstandingKeepalives--;
}

- (void) handleIncomingGenericNack: (SmppPdu *)pdu
{
}


- (void) handleIncomingBind: (SmppPdu *)pdu rx:(BOOL)rx tx:(BOOL)tx
{
	SmppPdu		*pdu2 = nil;
	//int err = 0;
	NSString	*usr;
	NSString	*pwd;
	NSString	*systemType;
	int			bindTon;
	int			bindNpi;
	NSString	*bindAddr;
	int			interfaceVersion;
	
	[pdu resetCursor];
	usr = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:16];
	pwd = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:9];
	systemType = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:9];
	interfaceVersion = (int) [pdu grabInt8];
	bindTon  = (int) [pdu grabInt8];
	bindNpi  = (int) [pdu grabInt8];
	bindAddr = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:31];
    _user = NULL;
	if([_router userExists:usr]==NO)
	{
        _lastStatus = [NSString stringWithFormat:@"User '%@' does not exist",usr];
        pdu2	= [SmppPdu OutgoingBindRespError: UM_ESME_RINVSYSID rx:rx tx:tx status:@"User does not exist"];
		[self sendPdu: pdu2 asResponseTo:pdu];
        _endThisConnection = YES;
        _endPermanently = YES;
	}
    else
    {

        NSString *bindType;
        if(rx && tx)
        {
            bindType=@"TRX";
        }
        else if(rx)
        {
            bindType=@"RX";
        }
        else if(tx)
        {
            bindType=@"TX";
        }
        else
        {
            bindType=@"NULL";
        }
        _user = [_router authenticateUser:usr
                             withPassword:pwd
                                ipAddress:_uc.connectedRemoteAddress
                               systemType:systemType
                         interfaceVersion:@(interfaceVersion)
                                 bindType:bindType
                                  bindTon:@(bindTon)
                                  bindNpi:@(bindNpi)
                              bindAddress:bindAddr];

        if(!_user)
        {
            _lastStatus = [NSString stringWithFormat:@"User '%@' has wrong password",usr];
            pdu2	= [SmppPdu OutgoingBindRespError: UM_ESME_RINVPASWD rx:rx tx:tx status:@"Password mismatch"];
            [self sendPdu: pdu2 asResponseTo:pdu];
            _endThisConnection = YES;
            _endPermanently = YES;
        }
        else
        {
            /* switching logging to tracefile */

            if([_user respondsToSelector:@selector(tracing)] && [_user respondsToSelector:@selector(tracePath)])
            {
                BOOL tracing = _user.tracing;
                NSString *tracefile = [_user tracePath];
                if(tracing && (tracefile.length > 0))
                {
                    UMLogHandler *userLogHandler = [[UMLogHandler alloc]init];
                    UMLogFile *logFile = [[UMLogFile alloc]initWithFileName:tracefile];
                    logFile.level = UMLOG_DEBUG;
                    [userLogHandler addLogDestination:logFile];
                    self.logFeed = [[UMLogFeed alloc]initWithHandler:userLogHandler section:@"incoming"];
                    [self.logFeed debug:0 withText:@"startTracing"];
                }
            }
            
            if ([_user hasCredits])
            {
                BOOL doAccept=YES;
                if([_router respondsToSelector:@selector(isAddressWhitelisted:remotePort:localIpAddress:localPort:serviceType:user:)])
                {
                    doAccept = [_router isAddressWhitelisted:_uc.connectedRemoteAddress
                                                  remotePort:@(_uc.connectedRemotePort)
                                              localIpAddress:_uc.connectedLocalAddress
                                                   localPort:@(_uc.connectedLocalPort)
                                                 serviceType:@"smpp"
                                                        user:_user.username];
                }
                if(doAccept)
                {
                    if(tx && rx)
                    {
                        _lastStatus = [NSString stringWithFormat:@"User '%@' successfully bound transceiver",usr];
                    }
                    else if(tx && !rx)
                    {
                        _lastStatus = [NSString stringWithFormat:@"User '%@' successfully bound transmitter",usr];
                    }
                    else if(!tx && rx)
                    {
                        _lastStatus = [NSString stringWithFormat:@"User '%@' successfully bound receiver",usr];
                    }
                    pdu2	= [SmppPdu OutgoingBindRespOK:@"UniversalSMS" supportedVersion:0x34  rx:rx tx:tx];
                    [self sendPdu: pdu2 asResponseTo:pdu];

                    if((rx==YES) && (tx==NO))
                    {
                        _inboundState = SMPP_STATE_IN_BOUND_RX;
                    }
                    else if((rx==NO) && (tx==YES))
                    {
                        _inboundState = SMPP_STATE_IN_BOUND_TX;
                    }
                    else  if((rx==YES) && (tx==YES))
                    {
                        _inboundState = SMPP_STATE_IN_BOUND_TRX;
                    }
                    _incomingStatus = SMPP_STATUS_INCOMING_ACTIVE;
                    self.login = usr;
                    self.password = pwd;
                    if( [_user respondsToSelector:@selector(alphaCoding)])
                    {
                        [self setAlphaEncodingString:[_user alphaCoding]];
                    }
                }
                else
                {
                    _lastStatus = [NSString stringWithFormat:@"User '%@' is not in whitelis for '%@'",usr,_uc.connectedRemoteAddress];
                    pdu2	= [SmppPdu OutgoingBindRespError:UM_ESME_RBINDFAIL rx:rx tx:tx status:@"IP not in whitelist"];
                    [self sendPdu: pdu2 asResponseTo:pdu];
                    _endThisConnection = YES;
                    _endPermanently = YES;
                }
            }
            else
            {
                _lastStatus = [NSString stringWithFormat:@"User '%@' is out of credit (bind failed)",usr];
                pdu2	= [SmppPdu OutgoingBindRespError:UM_ESME_RBINDFAIL rx:rx tx:tx status:@"out of credit"];
                [self sendPdu: pdu2 asResponseTo:pdu];
                _endThisConnection = YES;
                _endPermanently = YES;
            }
        }
    }
    [_readyForServiceDelegate readyForMessages:(_outgoingStatus==SMPP_STATUS_OUTGOING_ACTIVE ? YES : NO) connection:self];
}

- (void) handleIncomingBindReceiver: (SmppPdu *)pdu
{
	[self handleIncomingBind:pdu rx:YES tx:NO];
}


- (void) handleIncomingBindReceiverResp: (SmppPdu *)pdu
{
    NSString *systemId;
    UMSmppError err;
    
    [pdu resetCursor];
    _bindExpires = NULL;

    systemId = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:16];
    
    err = pdu.err;
    if ((err != UM_ESME_ROK) && (err != UM_ESME_RALYBND))
    {
        NSString *msg = [NSString stringWithFormat:@"SmscConnectionSMPP:handleIncomingBindReceiverResp: [%@]: SMSC rejected login to transmit, code 0x%08lx (%@) with <%@>.\r\n", _name, (unsigned long )err, UMSmppErrorAsString(err), systemId];
        [self.logFeed majorError:0 withText:msg];
        if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
        {
            _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
        }

        _lastStatus = [NSString stringWithFormat:@"%@ (0x%08lx) for user <%@>",UMSmppErrorAsString(err), (unsigned long )err, _name ];
    }
    else
    {
       _outboundState = SMPP_STATE_OUT_BOUND_RX;
       _outgoingStatus = SMPP_STATUS_OUTGOING_ACTIVE;
       _lastStatus = @"bind success RX";
    }
    [_readyForServiceDelegate readyForMessages:(_outgoingStatus==SMPP_STATUS_OUTGOING_ACTIVE ? YES : NO) connection:self];
}

- (void) handleIncomingBindTransmitter: (SmppPdu *)pdu
{
	[self handleIncomingBind:pdu rx:NO tx:YES];
}

- (void) handleIncomingBindTransmitterResp: (SmppPdu *)pdu
{
    NSString *systemId;
    UMSmppError err;
    
    [pdu resetCursor];
    
    _bindExpires = NULL;
    systemId = [pdu grabStringWithEncoding:NSUTF8StringEncoding maxLength:16];
    
    err = pdu.err;
    if ((err != UM_ESME_ROK) && (err != UM_ESME_RALYBND))
    {
        NSString *msg = [NSString stringWithFormat:@"SmscConnectionSMPP:handleIncomingBindTransmitterResp: [%@]: SMSC rejected login to transmit, code 0x%08lx (%@) with <%@>.\r\n", _name, (unsigned long )err, UMSmppErrorAsString(err), systemId];
        [self.logFeed majorError:0 withText:msg];
        if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
        {
            _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
        }
        _lastStatus = [NSString stringWithFormat:@"%@ (0x%08lx) for user <%@>",UMSmppErrorAsString(err), (unsigned long )err, _name ];

    }
    else
    {
        _outboundState = SMPP_STATE_OUT_BOUND_TX;
        _outgoingStatus = SMPP_STATUS_OUTGOING_ACTIVE;
        _lastStatus = @"bind success TX";
    }
    [_readyForServiceDelegate readyForMessages:(_outgoingStatus==SMPP_STATUS_OUTGOING_ACTIVE ? YES : NO) connection:self];
}

- (void) handleIncomingQuerySm: (SmppPdu *)pdu
{
    SmppPdu *pdu2 = NULL;
    
    NSString *messageId = [pdu grabStringWithEncoding:NSUTF8StringEncoding maxLength:65];
    [pdu grabStringWithEncoding:NSISOLatin1StringEncoding    maxLength:255];
    UMTonType ton       = (UMTonType)[pdu grabInt8];
    UMNpiType npi       = (UMNpiType)[pdu grabInt8];
    NSString *addr      = [pdu grabStringWithEncoding:NSISOLatin1StringEncoding maxLength:21];
    
    if([_router respondsToSelector:@selector(queryMessage:withNumber:)])
    {
        UMMessageObject *msg = [_router queryMessage:messageId withNumber:addr];
        pdu2 = [SmppPdu OutgoingQueryRespOK:msg withId:messageId];
    }
    if([_router respondsToSelector:@selector(queryMessage:)])
    {
        UMMessageObject * msg = [_router queryMessage:messageId];
        pdu2 = [SmppPdu OutgoingQueryRespOK:msg withId:messageId];
    }
    else
    {
        pdu2 = [SmppPdu OutgoingGenericNack:UM_ESME_RQUERYFAIL];
    }
    [self sendPdu: pdu2 asResponseTo:pdu];
}

- (void) handleIncomingQuerySmResp: (SmppPdu *)pdu
{
}

- (void) handleIncomingUnbind: (SmppPdu *)pdu
{
  	SmppPdu *pdu2 = [SmppPdu OutgoingUnbindRespOK];
    [self sendPdu: pdu2 asResponseTo:pdu];
    NSString *text;
    
    [_readyForServiceDelegate readyForMessages:NO connection:self];
    [_uc close];
    _uc = NULL;
    _endThisConnection = YES;
    [_terminatedDelegate terminatedCallback:self];

    if(_autorestart==NO)
    {
        text = [NSString stringWithFormat:@"[SmscConnectionSMPP handleIncomingUnbind]: closing %@ due to incoming Unbind\r\n", _name];
        [self.logFeed info:0 withText:text];
        _endThisConnection = YES;
        _endPermanently = YES;

    }
    else
    {
        text = [NSString stringWithFormat:@"[SmscConnectionSMPP handleIncomingUnbind]: restarting %@ due incoming unbind\r\n", _name];
        [self.logFeed info:0 withText:text];
        _endThisConnection = YES;
        _endPermanently = NO;
    }
        
    _outboundState = SMPP_STATE_CLOSED;
    _outgoingStatus = SMPP_STATUS_OUTGOING_OFF;
    _runOutgoingReceiverThread = SMPP_ORT_TERMINATING;
}

- (void) handleIncomingUnbindResp: (SmppPdu *)pdu
{
    NSString *text = [NSString stringWithFormat:@"[SmscConnectionSMPP handleIncomingUnbindResp]: incoming Unbind response %@\r\n", _name];
    [self.logFeed info:0 withText:text];
    [_readyForServiceDelegate readyForMessages:NO connection:self];
    [_uc close];
    [_terminatedDelegate terminatedCallback:self];

    _outboundState = SMPP_STATE_CLOSED;
    _outgoingStatus = SMPP_STATUS_OUTGOING_OFF;
    _runOutgoingReceiverThread = SMPP_ORT_TERMINATING;
    _endThisConnection=YES;
    if(_autorestart==NO)
    {
        _endPermanently = NO;
    }
}

- (void) handleIncomingReplaceSm: (SmppPdu *)pdu
{
}

- (void) handleIncomingReplaceSmResp: (SmppPdu *)pdu
{
}

- (void) handleIncomingCancelSm: (SmppPdu *)pdu
{
}

- (void) handleIncomingCancelSmResp: (SmppPdu *)pdu
{
}

- (void) handleIncomingBindTransceiver: (SmppPdu *)pdu
{
	[self handleIncomingBind:pdu rx:YES tx:YES];
}

- (void) handleIncomingBindTransceiverResp: (SmppPdu *)pdu
{
    NSString *systemId;
    UMSmppError err;
    
    [pdu resetCursor];
    _bindExpires = NULL;

    systemId = [pdu grabStringWithEncoding:NSUTF8StringEncoding maxLength:16];
    
    err = pdu.err;
    if ((err != UM_ESME_ROK) && (err != UM_ESME_RALYBND))
    {
        NSString *msg = [NSString stringWithFormat:@"SmscConnectionSMPP:handleIncomingBindTransceiverResp: [%@]: SMSC rejected login (systemId: <%@>) to transmit, code 0x%08lx (%@).\r\n", _name, systemId,(unsigned long )err, UMSmppErrorAsString(err)];
        [self.logFeed majorError:0 withText:msg];
        if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
        {
            _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
        }
        _lastStatus = [NSString stringWithFormat:@"%@ (0x%08lx) for user <%@>",UMSmppErrorAsString(err), (unsigned long )err, _name ];

    }
    else
    {
        _outboundState = SMPP_STATE_OUT_BOUND_TRX;
        _outgoingStatus = SMPP_STATUS_OUTGOING_ACTIVE;
        _lastStatus = @"bind success TRX";
    }
}

- (void) handleIncomingOutbind: (SmppPdu *)pdu
{
}

- (void) handleIncomingSubmitSmMulti: (SmppPdu *)pdu
{
}

- (void) handleIncomingSubmitSmMultiResp: (SmppPdu *)pdu
{
}

- (void) handleIncomingAlertNotification: (SmppPdu *)pdu
{
}


- (UMMessageReport *)deliverPduToReport:(SmppPdu *)pdu
{
    UMMessageReport         *report=NULL;
    NSString                *receiptedId=NULL;
    //NSString *submitDateString =NULL;
    //NSString *doneDateString =NULL;
    NSData                  *messagePayload;
    NSData                  *shortMessage;
    UMMessageStatusCode messageState = UMMESSAGE_STATUS_UNDEFINED;
    NSData                  *networkErrorCode;
    int                     errInt;
    NSString                *tmp;
    NSString                *r;


    report = [_router createReport];
    errInt = UM_ESME_RUNKNOWNERR;


    NSDictionary *tlvs = pdu.tlvs;
    /* check for SMPP v.3.4. and message_payload */
    messagePayload = tlvs[@"message payload"];
    shortMessage = pdu.short_message;
    if ([[self version] integerValue] > 0x33 && !shortMessage)
    {
        r = [[NSString alloc] initWithData:messagePayload encoding:NSASCIIStringEncoding];
    }
    else
    {
        r = [[NSString alloc] initWithData:shortMessage encoding:NSASCIIStringEncoding];
    }

    /* first we parse the text, if there's more specific TLVs they will override it */
    r = [r stringByReplacingOccurrencesOfString:@" date" withString:@"_date"];
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
        if([tag isEqualToString:@"id"])
        {
            receiptedId = value;
            if(_usesHexMessageIdInDlrText)
            {
                long long llid;
                sscanf(receiptedId.UTF8String,"%llx",&llid);
                receiptedId = [NSString stringWithFormat:@"%lld",llid ];
            }

        }
        else if([tag isEqualToString:@"sub"])
        {
            ; /* nothing to do with that */
        }
        else if([tag isEqualToString:@"dlvrd"])
        {
            ; /* nothing to do with that */
        }
        else if([tag isEqualToString:@"submit_date"])
        {
            //submitDateString = value;
        }
        else if([tag isEqualToString:@"done_date"])
        {
            //doneDateString = value;
        }
        else if([tag isEqualToString:@"stat"])
        {
            if ([value isEqualToString:@"ENROUTE"])
            {
                messageState = UMMESSAGE_STATUS_ENROUTE;
            }
            else if (([value isEqualToString:@"DELIVRD"]) || ([value isEqualToString:@"DELIVERED"]))
            {
                messageState = UMMESSAGE_STATUS_DELIVERED;
            }
            else if ([value isEqualToString:@"EXPIRED"])
            {
                messageState = UMMESSAGE_STATUS_EXPIRED;
            }
            else if ([value isEqualToString:@"DELETED"])
            {
                messageState = UMMESSAGE_STATUS_DELETED;
            }
            else if (([value isEqualToString:@"UNDELIV"]) || ([value isEqualToString:@"UNDELIVERABLE"]))
            {
                messageState = UMMESSAGE_STATUS_UNDELIVERABLE;
            }
            else if (([value isEqualToString:@"ACCEPTD"]) || ([value isEqualToString:@"ACCEPTED"]))
            {
                messageState = UMMESSAGE_STATUS_ACCEPTED;
            }
            else if ( ([value isEqualToString:@"REJECTD"])
                        || ([value isEqualToString:@"REJECTED"])
                        || ([value isEqualToString:@"REJECT"]))
            {
                messageState = UMMESSAGE_STATUS_REJECTED;
            }
            else
            {
                messageState = UMMESSAGE_STATUS_UNDEFINED;
                [self.logFeed minorError:0 withText:[NSString stringWithFormat:@"Unknown message state %@",value]];
            }
        }
        else if([tag isEqualToString:@"err"])
        {
            errInt = [value intValue];
        }
    }
    NSString *s = tlvs[@"receipted message id"];
    if (s && [[self version] doubleValue] > 3.3)
    {
        receiptedId = s;
    }
    
    s = tlvs[@"message state"];
    if(s)
    {
        if (([s isEqualToString:@"1"]) || ([s isEqualToString:@"1"]))
        {
            messageState = UMMESSAGE_STATUS_ENROUTE;
        }
        else if (([s isEqualToString:@"DELIVRD"]) || ([s isEqualToString:@"DELIVERED"]) || ([s isEqualToString:@"2"]))
        {
            messageState = UMMESSAGE_STATUS_DELIVERED;
        }
        else if ([s isEqualToString:@"EXPIRED"] || ([s isEqualToString:@"3"]))
        {
            messageState = UMMESSAGE_STATUS_EXPIRED;
        }
        else if ([s isEqualToString:@"DELETED"]|| ([s isEqualToString:@"4"]))
        {
            messageState = UMMESSAGE_STATUS_DELETED;
        }
        else if (([s isEqualToString:@"UNDELIV"]) || ([s isEqualToString:@"UNDELIVERABLE"]) || ([s isEqualToString:@"5"]))
        {
            messageState = UMMESSAGE_STATUS_UNDELIVERABLE;
        }
        else if (([s isEqualToString:@"ACCEPTD"]) || ([s isEqualToString:@"ACCEPTED"])|| ([s isEqualToString:@"6"]))
        {
            messageState = UMMESSAGE_STATUS_ACCEPTED;
        }
        else if (([s isEqualToString:@"REJECTD"]) || ([s isEqualToString:@"REJECTED"])|| ([s isEqualToString:@"8"]))
        {
            messageState = UMMESSAGE_STATUS_REJECTED;
        }
        else
        {
            messageState = UMMESSAGE_STATUS_UNDEFINED;
        }
    }

    networkErrorCode = tlvs[@"network error code"];
    if (networkErrorCode)
    {
        errInt = [SmscConnectionSMPP errorFromNetworkErrorCode:networkErrorCode];
    }
    
    if (receiptedId && messageState != -1)
    {
        unsigned long long value;
        /*
         * Obey which SMPP msg_id type this SMSC is using, where we
         * have the following semantics for the variable smpp_msg_id:
         *
         * bit 1: type for submit_sm_resp, bit 2: type for deliver_sm
         *
         * if bit is set value is hex otherwise dec
         *
         * 0x00 deliver_sm dec, submit_sm_resp dec
         * 0x01 deliver_sm dec, submit_sm_resp hex
         * 0x02 deliver_sm hex, submit_sm_resp dec
         * 0x03 deliver_sm hex, submit_sm_resp hex
         *
         * Default behaviour is SMPP spec compliant, which means
         * msg_ids should be C strings and hence non modified.
         */
        if (_smppMessageIdType == -1)
        {
            /* the default, C string */
            tmp = receiptedId;
        }
        else
        {
            if ((_smppMessageIdType  & 0x02) ||
                (![receiptedId smppCheckRange:NSMakeRange(0, [receiptedId length]) withFunction:isdigit]))
            {
                value = [receiptedId smppInteger16Value];
                tmp = [NSMutableString stringWithFormat:@"%llu", value];
            }
            else
            {
                value = [receiptedId integerValue];
                tmp = [NSMutableString stringWithFormat:@"%llu", value];
            }
        }
    }
    else
    {
        tmp = receiptedId;
    }
    
    [report setProviderReference:tmp];
    [report setReportText:r];
    [report setReportType:messageState];

    if((errInt==0) && (messageState != UMMESSAGE_STATUS_DELIVERED))
    {
        report.error = @(UM_ESME_VENDOR_SPECIFIC_NO_ERROR_CODE_PROVIDED);
    }
    else
    {
        report.error = @(errInt);
    }

    UMSigAddr *from;
    if([pdu source_addr_ton] == UMTON_ALPHANUMERIC)
	{
		from = [[UMSigAddr alloc] initWithAlpha:[pdu source_addr]];
		[from setNpi:(UMNpiType)[pdu source_addr_npi]];
	}
	else
	{
		from = [[UMSigAddr alloc] init];
		[from setTon:(UMTonType)[pdu source_addr_ton]];
		[from setNpi:(UMNpiType)[pdu source_addr_npi]];
		[from setAddr:[pdu source_addr]];
	}
    report.fromNumber=from.stringValue;
    UMSigAddr *to;
    if([pdu dest_addr_ton] == UMTON_ALPHANUMERIC)
	{
		to = [[UMSigAddr alloc] initWithAlpha:[pdu dest_addr]];
		[to setNpi:(UMNpiType)[pdu dest_addr_npi]];
	}
	else
	{
		to = [[UMSigAddr alloc] init];
		[to setTon:(UMTonType)[pdu dest_addr_ton]];
		[to setNpi:(UMNpiType)[pdu dest_addr_npi]];
		[to setAddr:[pdu dest_addr]];
	}
    report.toNumber = to.stringValue;
    report.tlvsText = [tlvs jsonString];
    return report;
}

- (UMMessageObject *)deliverPduToMsg:(SmppPdu *)pdu
{
    UMMessageObject * msg;
    UMSigAddr *from, *to;
    NSString *addr;
    int ton, npi;
    int udhLen;
	int dataLen;
    NSData *data = nil;
	NSData *udh = nil;
    SmppPdu *pdu2;
    
    msg = [_router createMessage];
    msg.submissionMethod   = UMDIRTY_STRING(@"smpp");
    msg.submissionType     = UMDIRTY_STRING(@"deliver");
	msg.fromIp          = UMDIRTY_STRING([_uc connectedRemoteAddress]);
    
	ton  = (int)[pdu source_addr_ton];
	npi  = (int)[pdu source_addr_npi];
	addr = [pdu source_addr];
	if(ton == UMTON_ALPHANUMERIC)
	{
		from = [[UMSigAddr alloc] initWithAlpha:addr];
		[from setNpi: npi];
	}
	else
	{
		from = [[UMSigAddr alloc] init];
		[from setTon: ton];
		[from setNpi: npi];
		[from setAddr: addr];
	}
    msg.fromNumber = UMDIRTY_STRING(from.stringValue);
    
	ton  = (int)[pdu dest_addr_ton];
	npi  = (int)[pdu dest_addr_npi];
	addr = [pdu dest_addr];
	if(ton == UMTON_ALPHANUMERIC)
	{
		to = [[UMSigAddr alloc] initWithAlpha:addr];
		[to setNpi: npi];
	}
	else
	{
		to = [[UMSigAddr alloc] init];
		[to setTon: ton];
		[to setNpi: npi];
		[to setAddr: addr];
	}
    msg.toNumber = UMDIRTY_STRING(to.stringValue);

    int esmClass = (int)[pdu esm_class];
    if(esmClass & SMPP_PDU_ESM_CLASS_DELIVER_UDH_INDICATOR)
    {
        msg.udhIndicator = YES;
    }
    if(esmClass & SMPP_PDU_ESM_CLASS_DELIVER_RPI)
    {
        msg.replyPathIndicator = YES;
    }
    msg.pduPid = UMDIRTY_INTEGER(pdu.protocol_id);
	msg.messagePriority = UMDIRTY_INTEGER(pdu.priority_flag);
    
    msg.replaceIfPresentFlag = UMDIRTY_INTEGER(pdu.replace_if_present_flag ? 1 : 0);
    msg.pduDcs = UMDIRTY_INTEGER(pdu.data_coding);
    
    int length = (int)[pdu sm_length];
    NSData *sm = [pdu short_message];
    if(msg.udhIndicator)
	{
		if(length< 1)
        {
            goto length_error;
        }
        unsigned const char *d;
        d = [sm bytes];
		udhLen = d[0];
        
		dataLen = length - udhLen - 1;
		if((udhLen <= 0) || (dataLen < 0))
			goto length_error;
    
		udh = [sm subdataWithRange:NSMakeRange(0, udhLen + 1)];
		data = [sm subdataWithRange:NSMakeRange(udhLen + 1, dataLen - udhLen - 1)];
	}
	else
	{
        // udhLen = 0;
		dataLen = length;
		udh = nil;
		data = [NSData dataWithData:sm];
		[pdu setCursor: pdu.cursor + dataLen + 1];
	}
    
	msg.pduUdh = UMDIRTY_DATA(udh);
	msg.pduContent = UMDIRTY_DATA(data);
    return msg;
    
length_error:
	pdu2 = [SmppPdu OutgoingSubmitSmRespErr: UM_ESME_RINVPARLEN];
	[self sendPdu: pdu2 asResponseTo:pdu];
    return nil;
}

/* process a incoming connection */
- (void) inbound
{
	/* first, register self to sms router */
	[self setIsInbound:YES];
    
    ulib_set_thread_name([NSString stringWithFormat:@"[SmscConnectionSMPP inbound] %@",_uc.description]);
    TRACK_FILE_ADD_COMMENT_FOR_FDES([_uc sock],@"inbound");

	[_router registerIncomingSmscConnection:self];
	
	[self startIncomingReceiverThread];
    [self.logFeed info:0 inSubsection:@"init" withText:@"[SmscConnectionSMPP inbound] starting\r\n"];
    
    _bindExpires = [[NSDate alloc]initWithTimeIntervalSinceNow:130]; /* we want to see authentication being passed within 30 seconds */

	while ((!_endThisConnection) && ((_incomingStatus ==SMPP_STATUS_INCOMING_CONNECTED) || (_incomingStatus ==  SMPP_STATUS_INCOMING_ACTIVE)))
	{
		switch(_incomingStatus)
		{
			case SMPP_STATUS_INCOMING_CONNECTED:
				/* no login has occured yet so we wont send any messages out on this link yet */
                
                if(_bindExpires != NULL)
                {
                    if([_bindExpires  timeIntervalSinceNow] < 0)
                    {
                        _bindExpires = NULL;
                        _lastStatus = @"timeout waiting for bind";
                        SmppPdu *pdu = [SmppPdu OutgoingGenericNack:UM_ESME_RBINDFAIL];
                        [_readyForServiceDelegate readyForMessages:NO connection:self];
                        [self sendPduWithNewSeq:pdu];
                        _incomingStatus = SMPP_STATUS_INCOMING_MAJOR_FAILURE;
                        sleep(1); /* we wait one second before the connection closes */
                    }
                }
                [_txSleeper sleep:200000]; /* check again in 200 ms */
				break;
				
			case SMPP_STATUS_INCOMING_ACTIVE:
                _bindExpires=NULL;
				/* login has occured so we can send mo messages and delivery reports out on this link */
				if( [self activeInbound] < 1)
                {
					[_txSleeper sleep:200000]; /* check again in 2000 ms */
                }
				break;
			default:
				break;
				
		}
	}
    [_readyForServiceDelegate readyForMessages:NO connection:self];
    [self stopIncomingReceiverThread];
    [_router unregisterIncomingSmscConnection:self];
	[_uc close];
    [_terminatedDelegate terminatedCallback:self];

	_uc = nil;
    NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP inbound] terminated (endThisConnection %d)\r\n", _endThisConnection];
    [self.logFeed info:0 inSubsection:@"shutdown" withText:msg];
}

- (void) outgoingControlThread
{
    NSDate *retryTime = nil;
	NSDate *now = nil;
	NSTimeInterval connectDelay = SMPP_RECONNECT_DELAY;
    
    NSTimeInterval waitForBindResponse = SMPP_WAIT_FOR_BIND_RESPONSE_DELAY;

	_outgoingStatus = SMPP_STATUS_OUTGOING_OFF;
    int ret;
    
    [self setIsListener:NO];
	[self setIsInbound:NO];
    
    ulib_set_thread_name([NSString stringWithFormat:@"[SmsConnectionSMPP outboundSender] %@",_uc.description]);

    [self.logFeed info:0 inSubsection:@"outbound sender" withText:@"[SmscConnectionSMPP outboundSender]: thread starting\r\n"];
	
    retryTime = [[NSDate alloc]initWithTimeIntervalSinceNow:connectDelay];

    SmppOutgoingStatus oldstatus = SMPP_STATUS_OUTGOING_OFF;
    
    [_router registerSendingSmscConnection:self];
    _registered = YES;

    BOOL needSleep=NO;

    while (!_endPermanently)
	{
        if(needSleep==YES)
        {
            /*to avoid busyloops */
            [_txSleeper sleep:100000]; /* check again in 100ms */
        }
        needSleep=YES;
        if(oldstatus != _outgoingStatus)
        {
            NSString *oldstatusString = [SmscConnectionSMPP outgoingStatusToString:oldstatus];
            NSString *newstatusString = [SmscConnectionSMPP outgoingStatusToString:_outgoingStatus];
            NSString *message = [NSString stringWithFormat:@"Status change: %@ -> %@", oldstatusString, newstatusString];
            [self.logFeed info:0 inSubsection:@"control" withText:message];
        }
        oldstatus = _outgoingStatus;

        switch (_outgoingStatus)
		{
            case SMPP_STATUS_OUTGOING_OFF:
                if (_stopped && !_started)
                {
                    if (!retryTime)
                    {
					    retryTime = [[NSDate alloc]initWithTimeIntervalSinceNow:connectDelay];
                    }
                    NSString *msg = [NSString stringWithFormat:@"restarting connection after %5.2f seconds\r\n",fabs([retryTime timeIntervalSinceNow])];
                    [self.logFeed majorError:0 withText:msg];
					_outgoingStatus = SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER;
                    needSleep=YES;
                }
                else
                {
                    if (_transmissionMode == SMPP_CONNECTION_MODE_TX)
                    {
                        ret = [self openTransmitter];
                    }
                    else if (_transmissionMode == SMPP_CONNECTION_MODE_TRX)
                    {
                        ret = [self openTransceiver];
                    }
                    else
                    {
                        ret = [self openReceiver];
                    }
                
                    if (ret == -1)
                    {
                        [self.logFeed majorError:0 withText:@"connect failed\r\n"];
                        if (!retryTime)
                        {
					        retryTime = [[NSDate alloc]initWithTimeIntervalSinceNow:connectDelay];
                        }
					    _outgoingStatus = SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER;
                        needSleep=YES;
                    }
                    else
                    {
                        _stopped = NO;
                        _started = NO;
                        _outgoingStatus = SMPP_STATUS_OUTGOING_CONNECTING;
                        needSleep=YES;
                    }
                }
                break;
                
            case SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER:
				now = [NSDate new];
				if([now compare:retryTime] == NSOrderedDescending)
				{
					retryTime = nil;
                    _started = YES;
					_outgoingStatus = SMPP_STATUS_OUTGOING_OFF;
				}
				else
				{
					[_txSleeper sleep:100000]; /* check again in 100ms */
                    needSleep=NO;
				}
				break;
                
            case SMPP_STATUS_OUTGOING_CONNECTING:
                retryTime = nil;
                _outboundState = SMPP_STATE_OUT_OPEN;
                _bindExpires = [[NSDate alloc]initWithTimeIntervalSinceNow:waitForBindResponse];
                //[self performSelectorInBackground:@selector(outgoingSenderThread) withObject:nil];
                /*****/
                [self runSelectorInBackground:@selector(outgoingSenderThread)];
//                [NSThread detachNewThreadSelector:@selector(outgoingSenderThread) toTarget:self withObject:nil];
                _outgoingStatus = SMPP_STATUS_OUTGOING_CONNECTED;
                needSleep=YES;
                break;
                
            case SMPP_STATUS_OUTGOING_CONNECTED:
                [_cxSleeper sleep:100000];
                needSleep=NO;
                if(_bindExpires != NULL)
                {
                    if([_bindExpires  timeIntervalSinceNow] < 0)
                    {
                        _bindExpires = NULL;
                        _lastStatus = @"timeout waiting for bind response";
                        if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
                        {
                            _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
                        }
                    }
                }
                break;

            case SMPP_STATUS_OUTGOING_MAJOR_FAILURE:
            {
                NSString *text = [NSString stringWithFormat:@"[SmscConnectionSMPP outboundSender]: closing %@ due outgoing major failure\r\n", _name];
                [self.logFeed majorError:0 withText:text];
                [_readyForServiceDelegate readyForMessages:NO connection:self];
                [_uc close];
                [_terminatedDelegate terminatedCallback:self];
                _uc = NULL;

                if(_autorestart==NO)
                {
                    _outgoingStatus = SMPP_STATUS_OUTGOING_OFF;
                    _outboundState = SMPP_STATE_CLOSED;
                    _endThisConnection = YES;
                    _endPermanently = YES;
                    /* we will exit the loop */
                }
                else
                {
                    retryTime = [[NSDate alloc]initWithTimeIntervalSinceNow:connectDelay];
                    _outgoingStatus = SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER;
                    _outboundState = SMPP_STATE_CLOSED;
                    
                    NSString *text = [NSString stringWithFormat:@"[SmscConnectionSMPP outboundSender]: restarting %@ due autorestart\r\n", _name];
                    [self.logFeed majorError:0 withText:text];
                    _endThisConnection = YES;
                    _endPermanently = NO;
                    _outgoingStatus = SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER;
                    _outboundState = SMPP_STATE_CLOSED;
                }
                needSleep=YES;
                break;
            }
                
            case SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER:
   				now = [NSDate new];
				if([now compare:retryTime] == NSOrderedDescending)
				{
					retryTime = nil;
                    _started = YES;
					_outgoingStatus = SMPP_STATUS_OUTGOING_OFF;
                    _endThisConnection = NO;
				}
				else
				{
					[_txSleeper sleep:100000]; /* check again in 100ms */
                    needSleep=NO;
				}
				break;

            default:
                [_cxSleeper sleep:100000]; /* our work done, we wait for end signal */
                needSleep=NO;
                break;
        }
    }

    NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP outgoingControlThread]: terminating this connection permanently\r\n"];
    [self.logFeed info:0 inSubsection:@"outgoingControlThread" withText:msg];
    retryTime = nil;
    [_readyForServiceDelegate readyForMessages:NO connection:self];
    if(_uc)
    {
        [_uc close];
        [_terminatedDelegate terminatedCallback:self];
        _uc = nil;
    }
    if(_registered)
    {
        [_router unregisterSendingSmscConnection:self];
        _registered = NO;
    }
}

- (int)openTransmitter
{
    @autoreleasepool
    {
        SmppPdu *bind;
        int ret;
        UMSocketError sErr;
        
        if (!_login || !_password)
        {
            return -1;
        }
        _uc = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY name:@"smpp-open-transmitter"];
        if (!_uc)
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP openTransmitter] [%@]: Couldn't connect to server (no socket, status %d).\r\n", _name, _outgoingStatus];
            [self.logFeed majorError:0 withText:msg];
            return -1;
        }
        _uc.configuredMaxSegmentSize = _max_tcp_segment_size;

        _outgoingStatus = SMPP_STATUS_OUTGOING_HAS_SOCKET;
        
        [_uc setRemoteHost:_remoteHost];
        [_uc setRequestedRemotePort:_transmitPort];
        sErr = [_uc connect];
        if (sErr != UMSocketError_no_error)
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPPopenTransmitter] (%@) Couldn't connect to server <%@:%ld> (error %d, status %d)\n", _name, _remoteHost, _transmitPort, sErr, _outgoingStatus];
            [self.logFeed majorError:0 withText:msg];
            [_uc close];
            [_terminatedDelegate terminatedCallback:self];
            _uc = nil;
            return -1;
        }
        
        bind = [SmppPdu OutgoingBindTransmitter:_login
                                       password:_password
                                     systemType:_systemType
                                        version:SMPP_VERSION
                                            ton:_bindAddrTon
                                            npi:_bindAddrNpi
                                          range:_addressRange];
        ret = [self sendPduWithNewSeq:bind];
        _lastStatus = @"BindTransmitter sent";
        if (ret < 0)
        {
            NSString *msg = [NSString stringWithFormat:@"SMPP[%@]: Couldn't send bind_transmitter to server\n", _name];
            [self.logFeed majorError:0 withText:msg];
            [_uc close];
            [_terminatedDelegate terminatedCallback:self];
            _uc = nil;
            return -1;
        }
        return 0;
    }
}

- (int)openTransceiver
{
    @autoreleasepool
    {
        SmppPdu *bind;
        int ret;
        UMSocketError sErr;
        
        if (!_login || !_password)
        {
            return -1;
        }
        _uc = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY name:@"smpp-open-transceiver"];
        [_uc setRemoteHost:_remoteHost];
        if(_transmitPort == 0)
        {
            _transmitPort = _remotePort;
        }
        [_uc setRequestedRemotePort:_transmitPort];
        _uc.configuredMaxSegmentSize = _max_tcp_segment_size;
        sErr = [_uc connect];
        if (sErr != UMSocketError_no_error)
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP openTransceiver] (%@) Couldn't connect to server <%@:%ld>, error %d, status %d.\n", _name, _remoteHost, _transmitPort, sErr, _outgoingStatus];
            [self.logFeed majorError:0 withText:msg];
            [_uc close];
            [_terminatedDelegate terminatedCallback:self];
            _uc = nil;
            return -1;
        }
        
        
        if (!_addressRange)
        {
            _addressRange = @"";
        }
        
        bind = [SmppPdu OutgoingBindTransceiver:_login
                                       password:_password
                                     systemType:_systemType
                                        version:SMPP_VERSION
                                            ton:_bindAddrTon
                                            npi:_bindAddrNpi
                                          range:_addressRange];
        ret = [self sendPduWithNewSeq:bind];
        _lastStatus = @"BindTransceiver sent";
        if (ret < 0)
        {
            NSString *msg = [NSString stringWithFormat:@"SMPP[%@]: Couldn't send bind_transceiver to server.\n", _name];
            [self.logFeed majorError:0 withText:msg];
            [_uc close];
            [_terminatedDelegate terminatedCallback:self];
            _uc = nil;
            return -1;
        }
        return 0;
    }
}

- (int)openReceiver
{
    @autoreleasepool
    {
        SmppPdu *bind;
        int ret;
        UMSocketError sErr;
        
        if (!_login || !_password)
            return -1;
        
        _uc = [[UMSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY name:@"open-receiver"];
        [_uc setRemoteHost:_remoteHost];
        [_uc setRequestedRemotePort:_receivePort];
        _uc.configuredMaxSegmentSize = _max_tcp_segment_size;
        sErr = [_uc connect];
        if (sErr != UMSocketError_no_error)
        {
            NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP openReceiver] (%@) Couldn't connect to server <%@:%ld> (error %d, status %d)\n", _name, _remoteHost, _transmitPort, sErr, _outgoingStatus];
            [self.logFeed majorError:0 withText:msg];
            [_uc close];
            [_terminatedDelegate terminatedCallback:self];
            _uc = nil;
            return -1;
        }
        
        
        if (!_addressRange)
        {
            _addressRange = @"";
        }
        bind = [SmppPdu OutgoingBindReceiver:_login
                                    password:_password
                                  systemType:_systemType
                                     version:SMPP_VERSION
                                         ton:_bindAddrTon
                                         npi:_bindAddrNpi
                                       range:_addressRange];
        ret = [self sendPduWithNewSeq:bind];
        _lastStatus = @"BindReceiver sent";
        if (ret < 0)
        {
            NSString *msg = [NSString stringWithFormat:@"SMPP[%@]: Couldn't send bind_transceiver to server\n", _name];
            [self.logFeed majorError:0 withText:msg];
            [_uc close];
            [_terminatedDelegate terminatedCallback:self];
            _uc = nil;
            return -1;
        }
        
        return 0;
    }
}

- (void) outgoingSenderThread
{
    /* first, register self to sms router */
    @autoreleasepool
    {
		[self setIsInbound:NO];
		[_router registerOutgoingSmscConnection:self];
		[self startOutgoingReceiverThread];
		while (  (!_endPermanently) &&
                 (!_endThisConnection) &&
               (_outgoingStatus ==  SMPP_STATUS_OUTGOING_CONNECTING ||
                _outgoingStatus ==  SMPP_STATUS_OUTGOING_CONNECTED ||
                _outgoingStatus ==  SMPP_STATUS_OUTGOING_ACTIVE))
		{
            @autoreleasepool
            {
                switch(_outgoingStatus)
                {
                    case SMPP_STATUS_OUTGOING_OFF:
                    case SMPP_STATUS_OUTGOING_CONNECTING:
                    case SMPP_STATUS_OUTGOING_CONNECTED:
                        /* no login has occured yet so we wont send any messages out on this link yet */
                        [_txSleeper sleep:200000]; /* 200ms */
                        break;
                        
                    case SMPP_STATUS_OUTGOING_ACTIVE:
                        /* login has occured so we can send mt messages and delivery reports out on this link */
                        if( [self activeOutbound] < 1)
                        {
                            [_txSleeper sleep:200000]; /* check again in 200ms */
                        }
                        break;
                    default:
                        break;
                        
                }
            }
		}
        _endThisConnection=YES;
        /* should this not be done in the control thread ?*/
		[self stopOutgoingReceiverThread];
        [_uc close];
        [_terminatedDelegate terminatedCallback:self];
        _uc = nil;
        [_router unregisterOutgoingSmscConnection:self];
    }
}

- (void)startOutgoingReceiverThread
{
    @autoreleasepool
    {
        int i=0;

        if(_runOutgoingReceiverThread != SMPP_ORT_NOT_RUNNING)
        {
            NSLog(@"[SmscConnectionSMPP startOutgoingReceiverThread]:wrong status %u for runOutgoingReceiverThread at the beginning", _runIncomingReceiverThread);
        }
        _runOutgoingReceiverThread = SMPP_ORT_STARTING;
        _endPermanently = NO;
        [self runSelectorInBackground:@selector(outgoingReceiverThread)];

    //    [NSThread detachNewThreadSelector:@selector(outgoingReceiverThread) toTarget:self withObject:nil];
        while ((_runOutgoingReceiverThread != SMPP_ORT_RUNNING) && (i<100))
        {
            usleep(10000);
            i++;
        }
        if(_runOutgoingReceiverThread != SMPP_ORT_RUNNING)
        {
            NSLog(@"[SmscConnectionSMPP startOutgoingReceiverThread]:wrong status %u for runOutgoingReceiverThread the end (after %d attemps)", _runIncomingReceiverThread, i);
        }
    }
}

- (void)stopOutgoingReceiverThread
{
    @autoreleasepool
    {
        int i=0;
     
        if (_runOutgoingReceiverThread != SMPP_ORT_TERMINATED)
            _runOutgoingReceiverThread = SMPP_ORT_TERMINATING;
        
        while((_runOutgoingReceiverThread != SMPP_ORT_TERMINATED)  && (i<100))
        {
            usleep(10000);
            i++;
        }
        if(_runOutgoingReceiverThread != SMPP_ORT_TERMINATED)
        {
            NSLog(@"[SmscConnectionSMPP stopOutgoingReceiverThread]: wrong status for stopOutgoingReceiverThread");
        }
        _runOutgoingReceiverThread = SMPP_ORT_NOT_RUNNING;
    }
}

- (void) outgoingReceiverThread
{
    @autoreleasepool
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[SmscConnectionSMPP outgoingReceiverThread] %@",_uc.description]);
        
        if(_runOutgoingReceiverThread != SMPP_ORT_STARTING)
        {
            NSLog(@"wrong status %u for runOutgoingReceiverThread", _runIncomingReceiverThread);
        }
        
        NSString *msg = [NSString stringWithFormat:@"SmscConnectionSMPP outgoingReceiverThread]: outbound receiver thread %@ is starting\r\n", _name];
        [self.logFeed info:0 withText:msg];
        
        _runOutgoingReceiverThread = SMPP_ORT_RUNNING;
        
        if(_receivePollTimeoutMs <= 0)
        {
            _receivePollTimeoutMs = SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS; /* default to 200ms */
        }
        
        while ((!_endPermanently) && (!_endThisConnection) && (_runOutgoingReceiverThread==SMPP_ORT_RUNNING))
        {
            @autoreleasepool
            {
                
                UMSocketError err = UMSocketError_no_data;
                
                if (_runOutgoingReceiverThread!=SMPP_ORT_RUNNING)
                {
                    _endThisConnection = YES;
                    continue;
                }
                err  = [_uc dataIsAvailable:_receivePollTimeoutMs];
                if((err ==UMSocketError_has_data) || (err==UMSocketError_has_data_and_hup)) /* we received something */
                {
                    UMSocketError err = [_uc receiveToBufferWithBufferLimit: 10240];
                    if(err==UMSocketError_no_error)
                    {
                        [self checkForPackets];
                    }
                    else if (err==UMSocketError_has_data)
                    {
                        [self checkForPackets];
                    }
                    else if(err==UMSocketError_has_data_and_hup)
                    {
                        NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP outgoingReceiverThread]: POLLHUP received"];
                        [self.logFeed info:0 inSubsection:@"outbound receiver" withText:msg];
                        _endThisConnection = YES;
                    }
                    else
                    {
                        NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP outgoingReceiverThread]: socket error %d when reading from socket\r\n", err];
                        [self.logFeed info:0 inSubsection:@"outbound receiver" withText:msg];
                        _endThisConnection = YES;
                    }
                }
                else if(err == UMSocketError_try_again)
                {
                    usleep(10000);
                }
                else if (err == UMSocketError_no_error)
                {
                    usleep(10000);
                }
                else if (err == UMSocketError_no_data)
                {
                    usleep(10000);
                }
                else
                {
                    NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP outgoingReceiverThread]: socket error %d when socket returned\r\n", err];
                    [self.logFeed majorError:0 inSubsection:@"init" withText:msg];
                    _endThisConnection = YES;
                    break;
                }
            }
        }
        
        NSString *txt = [NSString stringWithFormat:@"[SmscConnectionSMPP outgoingReceiverThread]: outbound receiver thread ending(end %d, run status %d, \r\n", _endPermanently, _runOutgoingReceiverThread];
        [self.logFeed info:0 withText:txt];
        
        _runOutgoingReceiverThread = SMPP_ORT_TERMINATING;
        if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
        {
            _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
        }
        
        /*  if (autorestart==YES)
         {
         NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP outgoingReceiverThread]: outbound receiver thread (end %d, run status %d): restart requested\r\n", endPermanently, runOutgoingReceiverThread];
         [self.logFeed info:0 withText:msg];
         stopped = YES;
         started = NO;
         }
         */
        _runOutgoingReceiverThread = SMPP_ORT_TERMINATED;
    }
}

-(void) checkForSendingKeepalive
{
    int err;
    
    if(_lastKeepAliveSent==0)
    {
        if(_keepAlive > 0)
        {
            time(&_lastKeepAliveSent);
        }
    }
    else
    {
        time_t now;
        time(&now);
        if((now - _lastKeepAliveSent) > _keepAlive)
        {
            SmppPdu *pdu = [SmppPdu OutgoingEnquireLink];
            err = [self sendPduWithNewSeq:pdu];
            if (err == 0)
            {
                _lastKeepAliveSent = now;
                _outstandingKeepalives++;
            }
            else
            {
                NSString *msg = [NSString stringWithFormat:@"[SmscConnectionSMPP checkForSendingKeepAlive] sendPduWithNewSeq returned error %d when submitting keep alive",err];
                [self.logFeed majorError:0 inSubsection:@"active phase" withText:msg];
                if(_outgoingStatus != SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER)
                {
                    _outgoingStatus =  SMPP_STATUS_OUTGOING_MAJOR_FAILURE;
                }
            }
        }
    }
}

#pragma mark Loging functions

-(void) logIncomingPdu:(SmppPdu *)pdu
{
    @autoreleasepool
    {
        NSString *typeString = [SmppPdu pduTypeToString:pdu.type];
        NSString *errString = UMSmppErrorAsString(pdu.err);
        NSMutableString *desc = [[NSMutableString alloc]init];
        [desc appendFormat:@"IncomingPdu:\n\tconnection:     0x%08lX (%ld)\n", (unsigned long)pdu.pdulen,(unsigned long)pdu.pdulen];
        [desc appendFormat:@"\tlen:     0x%08lX (%ld)\n", (unsigned long)pdu.pdulen,(unsigned long)pdu.pdulen];
        [desc appendFormat:@"\ttype:    0x%08lX %@\n", (unsigned long)pdu.type, typeString];
        [desc appendFormat:@"\terror:   0x%08lX %@\n", (unsigned long)pdu.err, errString];
        [desc appendFormat:@"\tseq:     0x%08lX (%ld)\n", (unsigned long)pdu.seq,(unsigned long)pdu.seq];
        [desc appendFormat:@"\tpayload: %@\n", pdu.payload];
        [self.logFeed info:0 withText:desc];
    }
}

-(void) logOutgoingPdu:(SmppPdu *)pdu
{
    @autoreleasepool
    {
        NSMutableString *desc = [[NSMutableString alloc]init];
        [desc appendFormat:@"OutgoingPdu:\n\tlen:     0x%08lX (%ld)\n", (unsigned long)pdu.pdulen,(unsigned long)pdu.pdulen];
        [desc appendFormat:@"\ttype:    0x%08lX %@\n", (unsigned long)pdu.type,[SmppPdu pduTypeToString:pdu.type]];
        [desc appendFormat:@"\terror:   0x%08lX %@\n", (unsigned long)pdu.err, UMSmppErrorAsString(pdu.err)];
        [desc appendFormat:@"\tseq:     0x%08lX (%ld)\n", (unsigned long)pdu.seq,(unsigned long)pdu.seq];
        [desc appendFormat:@"\tpayload: %@\n", pdu.payload];
        [self.logFeed info:0 withText:desc];
    /* temporary */
    //    NSLog(@"%@",desc);
    }
}



#pragma mark helper functions

+ (NSString *)incomingStatusToString:(SmppIncomingStatus)status
{
    switch(status)
    {
        case SMPP_STATUS_INCOMING_OFF:
            return @"incoming off";
            
        case SMPP_STATUS_INCOMING_HAS_SOCKET:
            return @"socket assigned";
        case SMPP_STATUS_INCOMING_BOUND:
            return @"bound";
        case SMPP_STATUS_INCOMING_LISTENING:
            return @"listening";
        case SMPP_STATUS_INCOMING_CONNECTED:
            return @"connected inbound";
        case SMPP_STATUS_INCOMING_ACTIVE:
            return @"active";
        case SMPP_STATUS_INCOMING_CONNECT_RETRY_TIMER:
            return @"connect retry timer";
        case SMPP_STATUS_INCOMING_BIND_RETRY_TIMER:
            return @"bind retry timer";
        case SMPP_STATUS_INCOMING_LOGIN_WAIT_TIMER:
            return @"login wait timer";
        case SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER:
            return @"listen wait timer";
        case SMPP_STATUS_INCOMING_MAJOR_FAILURE:
            return @"major failure";
        case SMPP_STATUS_LISTENER_MAJOR_FAILURE_RESTART_TIMER:
            return @"major failure restart timer";
        default:
            return @"incoming status unknown";
    }
}


+ (NSString *)outgoingStatusToString:(SmppOutgoingStatus)status
{
    switch(status)
    {
        case SMPP_STATUS_OUTGOING_OFF:
            return @"off";
        case SMPP_STATUS_OUTGOING_HAS_SOCKET:
            return @"has-socket";
        case SMPP_STATUS_OUTGOING_MAJOR_FAILURE:
            return @"major-failure";
        case SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER:
            return @"major-failure-retry-timer";
        case SMPP_STATUS_OUTGOING_CONNECTING:
            return @"connecting";
        case SMPP_STATUS_OUTGOING_CONNECTED:
            return @"connected"; /* but not authenticated yet	*/
        case SMPP_STATUS_OUTGOING_ACTIVE:
            return @"active";  /* correctly logged in			*/
        case SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER :
            return @"connect-retry-timer";
        default:
            return @"unknown";
    }
}


+ (int) errorFromNetworkErrorCode:(NSData *)networkErrorCode
{
    /* see section 4.8.4.42 network_error_code in http://www.smsforum.net/smppv50.pdf.zip for correct encoding */
    
    unsigned char *nec;
    int ourType;
    int err;
    
    if(!networkErrorCode)
    {
        return 0;
    }
    if([networkErrorCode length] !=3 )
    {
        return 0;
    }
    nec = (unsigned char *)[networkErrorCode bytes];
    ourType = nec[0];
    err = (nec[1]<<8) | nec[2];
    
    if((ourType >= '0') && (ourType <= '9'))
    {
        /* this is a bogous SMSC sending back network_error_code as 3 digit string instead as in the delivery report. */
        sscanf((const char *)nec,"%03d",&err);
        return err;
    }
    return err;
}


- (NSString *)stringStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];
    @autoreleasepool
    {
        [s appendFormat:@"Connection: %@\r\n",_name];
        [s appendFormat:@"Type: %@\r\n",_type];
        [s appendFormat:@"Version: %@\r\n",_version];
        [s appendFormat:@"RouterName: %@\r\n",_routerName];
        [s appendFormat:@"socket: %@\r\n",_uc];
        
        [s appendFormat:@"submitMessageQueue: %d entries\r\n",(int)[_submitMessageQueue count]];
        
        [s appendFormat:@"submitReportQueue: %d entries\r\n",(int)[_submitReportQueue count]];
        
        [s appendFormat:@"deliverMessageQueue: %d entries\r\n",(int)[_deliverMessageQueue count]];
        [s appendFormat:@"deliverReportQueue: %d entries\r\n",(int)[_deliverReportQueue count]];
        [s appendFormat:@"ackNackQueue: %d entries\r\n",(int)[_ackNackQueue count]];
        [s appendFormat:@"outgoingTransactions: %d entries\r\n",(int)[_outgoingTransactions count]];
        [s appendFormat:@"incomingTransactions: %d entries\r\n",(int)[_incomingTransactions count]];
        [s appendFormat:@"shortId: %@\r\n",[_shortId asString]];
        [s appendFormat:@"endThisConnection: %d",_endThisConnection];
        [s appendFormat:@"endPermanently: %d\r\n",_endPermanently];
        [s appendFormat:@"lastActivity: %@\r\n",_lastActivity];
        [s appendFormat:@"login: %@\r\n",_login];
        [s appendFormat:@"isListener: %@\r\n",_isListener ? @"YES" : @"NO"];
        [s appendFormat:@"isInbound: %@\r\n",_isInbound ? @"YES" : @"NO"];
        [s appendFormat:@"lastSeq: %d\r\n",_lastSeq];
        [s appendFormat:@"user: %@\r\n",_user.username];
        [s appendFormat:@"runIncomingReceiverThread: %d ",_runIncomingReceiverThread];
        switch(_runIncomingReceiverThread)
        {
            case SMPP_IRT_NOT_RUNNING:
                [s appendFormat:@"SMPP_IRT_NOT_RUNNING"];
                break;
            case SMPP_IRT_STARTING:
                [s appendFormat:@"SMPP_IRT_STARTING"];
                break;
            case SMPP_IRT_RUNNING:
                [s appendFormat:@"SMPP_IRT_RUNNING"];
                break;
            case SMPP_IRT_TERMINATING:
                [s appendFormat:@"SMPP_IRT_TERMINATING"];
                break;
            case SMPP_IRT_TERMINATED:
                [s appendFormat:@"SMPP_IRT_TERMINATED"];
                break;

        }
        [s appendFormat:@"\r\n"];

        
        [s appendFormat:@"runOutgoingReceiverThread: %d ",_runOutgoingReceiverThread];
        switch(_runOutgoingReceiverThread)
        {
            case SMPP_ORT_NOT_RUNNING:
                [s appendFormat:@"SMPP_ORT_NOT_RUNNING"];
                break;
            case SMPP_ORT_STARTING:
                [s appendFormat:@"SMPP_ORT_STARTING"];
                break;
            case SMPP_ORT_RUNNING:
                [s appendFormat:@"SMPP_ORT_RUNNING"];
                break;
            case SMPP_ORT_TERMINATING:
                [s appendFormat:@"SMPP_ORT_TERMINATING"];
                break;
            case SMPP_ORT_TERMINATED:
                [s appendFormat:@"SMPP_ORT_TERMINATED"];
                break;
        }
        [s appendFormat:@"\r\n"];

        
        [s appendFormat:@"incomingStatus: %d ",_incomingStatus];
        switch(_incomingStatus)
        {
            case SMPP_STATUS_INCOMING_OFF:
                [s appendFormat:@"SMPP_STATUS_INCOMING_OFF"];
                break;
            case SMPP_STATUS_INCOMING_HAS_SOCKET:
                [s appendFormat:@"SMPP_STATUS_INCOMING_HAS_SOCKET"];
                break;
            case SMPP_STATUS_INCOMING_BOUND:
                [s appendFormat:@"SMPP_STATUS_INCOMING_BOUND"];
                break;
            case SMPP_STATUS_INCOMING_LISTENING:
                [s appendFormat:@"SMPP_STATUS_INCOMING_LISTENING"];
                break;
            case SMPP_STATUS_INCOMING_CONNECTED:
                [s appendFormat:@"SMPP_STATUS_INCOMING_CONNECTED"];
                break;
            case SMPP_STATUS_INCOMING_ACTIVE:
                [s appendFormat:@"SMPP_STATUS_INCOMING_ACTIVE"];
                break;
            case SMPP_STATUS_INCOMING_CONNECT_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_CONNECT_RETRY_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_BIND_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_BIND_RETRY_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_LOGIN_WAIT_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_LOGIN_WAIT_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_MAJOR_FAILURE:
                [s appendFormat:@"SMPP_STATUS_INCOMING_MAJOR_FAILURE"];
                break;
            case SMPP_STATUS_LISTENER_MAJOR_FAILURE_RESTART_TIMER:
                [s appendFormat:@"SMPP_STATUS_LISTENER_MAJOR_FAILURE_RESTART_TIMER"];
                break;
        }
        [s appendFormat:@"\r\n"];

        [s appendFormat:@"outgoingStatus: %d ",_outgoingStatus];
        switch(_outgoingStatus)
        {
            case SMPP_STATUS_OUTGOING_OFF:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_OFF"];
                break;
            case SMPP_STATUS_OUTGOING_HAS_SOCKET:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_HAS_SOCKET"];
                break;
            case SMPP_STATUS_OUTGOING_MAJOR_FAILURE:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_MAJOR_FAILURE"];
                break;
            case SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER"];
                break;
            case SMPP_STATUS_OUTGOING_CONNECTING:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_CONNECTING"];
                break;
            case SMPP_STATUS_OUTGOING_CONNECTED:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_CONNECTED"];
                break;
            case SMPP_STATUS_OUTGOING_ACTIVE:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_ACTIVE"];
                break;
            case SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER"];
                break;
        }
        [s appendFormat:@"\r\n"];

        [s appendFormat:@"inboundState: %d ",_inboundState];
        switch(_inboundState)
        {
            case SMPP_STATE_CLOSED:
                [s appendFormat:@"SMPP_STATE_CLOSED"];
                break;
            case SMPP_STATE_IN_OPEN:
                [s appendFormat:@"SMPP_STATE_IN_OPEN"];
                break;
            case SMPP_STATE_IN_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TX"];
                break;
            case SMPP_STATE_IN_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_RX"];
                break;
            case SMPP_STATE_IN_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_OPEN:
                [s appendFormat:@"SMPP_STATE_OUT_OPEN"];
                break;
            case SMPP_STATE_OUT_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TX"];
                break;
            case SMPP_STATE_OUT_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_RX"];
                break;
            case SMPP_STATE_ANY_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_ANY_BOUND_TRX"];
                break;
            case SMPP_STATE_ANY:
                [s appendFormat:@"SMPP_STATE_ANY"];
                break;
        }
        [s appendFormat:@"\r\n"];

        [s appendFormat:@"outboundState: %d ",_outboundState];
        switch(_outboundState)
        {
            case SMPP_STATE_CLOSED:
                [s appendFormat:@"SMPP_STATE_CLOSED"];
                break;
            case SMPP_STATE_IN_OPEN:
                [s appendFormat:@"SMPP_STATE_IN_OPEN"];
                break;
            case SMPP_STATE_IN_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TX"];
                break;
            case SMPP_STATE_IN_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_RX"];
                break;
            case SMPP_STATE_IN_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_OPEN:
                [s appendFormat:@"SMPP_STATE_OUT_OPEN"];
                break;
            case SMPP_STATE_OUT_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TX"];
                break;
            case SMPP_STATE_OUT_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_RX"];
                break;
            case SMPP_STATE_ANY_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_ANY_BOUND_TRX"];
                break;
            case SMPP_STATE_ANY:
                [s appendFormat:@"SMPP_STATE_ANY"];
                break;
        }
        [s appendFormat:@"\r\n"];

        [s appendFormat:@"cid: %@\r\n",_cid];
        [s appendFormat:@"receivePort: %ld\r\n",_receivePort];
        [s appendFormat:@"transmitPort: %ld\r\n",_transmitPort];
        [s appendFormat:@"transmissionMode: %d ",_transmissionMode];
        switch(_transmissionMode)
        {
            case SMPP_CONNECTION_MODE_TX:
                [s appendFormat:@"SMPP_CONNECTION_MODE_TX"];
                break;
            case SMPP_CONNECTION_MODE_RX:
                [s appendFormat:@"SMPP_CONNECTION_MODE_RX"];
                break;
            case SMPP_CONNECTION_MODE_TRX:
                [s appendFormat:@"SMPP_CONNECTION_MODE_TRX"];
                break;

        }
        [s appendFormat:@"\r\n"];
    }
    return s;
}

- (NSString *)htmlStatus
{
    NSMutableString *s = [[NSMutableString alloc]init];
    @autoreleasepool
    {
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
        [s appendFormat:@"lastSeq: %d<br>",_lastSeq];
        [s appendFormat:@"user: %@<br>",_user.username];
        [s appendFormat:@"runIncomingReceiverThread: %d ",_runIncomingReceiverThread];
        switch(_runIncomingReceiverThread)
        {
            case SMPP_IRT_NOT_RUNNING:
                [s appendFormat:@"SMPP_IRT_NOT_RUNNING"];
                break;
            case SMPP_IRT_STARTING:
                [s appendFormat:@"SMPP_IRT_STARTING"];
                break;
            case SMPP_IRT_RUNNING:
                [s appendFormat:@"SMPP_IRT_RUNNING"];
                break;
            case SMPP_IRT_TERMINATING:
                [s appendFormat:@"SMPP_IRT_TERMINATING"];
                break;
            case SMPP_IRT_TERMINATED:
                [s appendFormat:@"SMPP_IRT_TERMINATED"];
                break;
                
        }
        [s appendFormat:@"<br>"];
        
        
        [s appendFormat:@"runOutgoingReceiverThread: %d ",_runOutgoingReceiverThread];
        switch(_runOutgoingReceiverThread)
        {
            case SMPP_ORT_NOT_RUNNING:
                [s appendFormat:@"SMPP_ORT_NOT_RUNNING"];
                break;
            case SMPP_ORT_STARTING:
                [s appendFormat:@"SMPP_ORT_STARTING"];
                break;
            case SMPP_ORT_RUNNING:
                [s appendFormat:@"SMPP_ORT_RUNNING"];
                break;
            case SMPP_ORT_TERMINATING:
                [s appendFormat:@"SMPP_ORT_TERMINATING"];
                break;
            case SMPP_ORT_TERMINATED:
                [s appendFormat:@"SMPP_ORT_TERMINATED"];
                break;
        }
        [s appendFormat:@"<br>"];
        
        
        [s appendFormat:@"incomingStatus: %d ",_incomingStatus];
        switch(_incomingStatus)
        {
            case SMPP_STATUS_INCOMING_OFF:
                [s appendFormat:@"SMPP_STATUS_INCOMING_OFF"];
                break;
            case SMPP_STATUS_INCOMING_HAS_SOCKET:
                [s appendFormat:@"SMPP_STATUS_INCOMING_HAS_SOCKET"];
                break;
            case SMPP_STATUS_INCOMING_BOUND:
                [s appendFormat:@"SMPP_STATUS_INCOMING_BOUND"];
                break;
            case SMPP_STATUS_INCOMING_LISTENING:
                [s appendFormat:@"SMPP_STATUS_INCOMING_LISTENING"];
                break;
            case SMPP_STATUS_INCOMING_CONNECTED:
                [s appendFormat:@"SMPP_STATUS_INCOMING_CONNECTED"];
                break;
            case SMPP_STATUS_INCOMING_ACTIVE:
                [s appendFormat:@"SMPP_STATUS_INCOMING_ACTIVE"];
                break;
            case SMPP_STATUS_INCOMING_CONNECT_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_CONNECT_RETRY_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_BIND_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_BIND_RETRY_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_LOGIN_WAIT_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_LOGIN_WAIT_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER:
                [s appendFormat:@"SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER"];
                break;
            case SMPP_STATUS_INCOMING_MAJOR_FAILURE:
                [s appendFormat:@"SMPP_STATUS_INCOMING_MAJOR_FAILURE"];
                break;
            case SMPP_STATUS_LISTENER_MAJOR_FAILURE_RESTART_TIMER:
                [s appendFormat:@"SMPP_STATUS_LISTENER_MAJOR_FAILURE_RESTART_TIMER"];
                break;
        }
        [s appendFormat:@"<br>"];
        
        [s appendFormat:@"outgoingStatus: %d ",_outgoingStatus];
        switch(_outgoingStatus)
        {
            case SMPP_STATUS_OUTGOING_OFF:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_OFF"];
                break;
            case SMPP_STATUS_OUTGOING_HAS_SOCKET:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_HAS_SOCKET"];
                break;
            case SMPP_STATUS_OUTGOING_MAJOR_FAILURE:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_MAJOR_FAILURE"];
                break;
            case SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER"];
                break;
            case SMPP_STATUS_OUTGOING_CONNECTING:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_CONNECTING"];
                break;
            case SMPP_STATUS_OUTGOING_CONNECTED:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_CONNECTED"];
                break;
            case SMPP_STATUS_OUTGOING_ACTIVE:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_ACTIVE"];
                break;
            case SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER:
                [s appendFormat:@"SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER"];
                break;
        }
        [s appendFormat:@"<br>"];
        
        [s appendFormat:@"inboundState: %d ",_inboundState];
        switch(_inboundState)
        {
            case SMPP_STATE_CLOSED:
                [s appendFormat:@"SMPP_STATE_CLOSED"];
                break;
            case SMPP_STATE_IN_OPEN:
                [s appendFormat:@"SMPP_STATE_IN_OPEN"];
                break;
            case SMPP_STATE_IN_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TX"];
                break;
            case SMPP_STATE_IN_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_RX"];
                break;
            case SMPP_STATE_IN_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_OPEN:
                [s appendFormat:@"SMPP_STATE_OUT_OPEN"];
                break;
            case SMPP_STATE_OUT_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TX"];
                break;
            case SMPP_STATE_OUT_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_RX"];
                break;
            case SMPP_STATE_ANY_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_ANY_BOUND_TRX"];
                break;
            case SMPP_STATE_ANY:
                [s appendFormat:@"SMPP_STATE_ANY"];
                break;
        }
        [s appendFormat:@"<br>"];
        
        [s appendFormat:@"outboundState: %d ",_outboundState];
        switch(_outboundState)
        {
            case SMPP_STATE_CLOSED:
                [s appendFormat:@"SMPP_STATE_CLOSED"];
                break;
            case SMPP_STATE_IN_OPEN:
                [s appendFormat:@"SMPP_STATE_IN_OPEN"];
                break;
            case SMPP_STATE_IN_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TX"];
                break;
            case SMPP_STATE_IN_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_RX"];
                break;
            case SMPP_STATE_IN_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_IN_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_OPEN:
                [s appendFormat:@"SMPP_STATE_OUT_OPEN"];
                break;
            case SMPP_STATE_OUT_BOUND_TX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TX"];
                break;
            case SMPP_STATE_OUT_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_TRX"];
                break;
            case SMPP_STATE_OUT_BOUND_RX:
                [s appendFormat:@"SMPP_STATE_OUT_BOUND_RX"];
                break;
            case SMPP_STATE_ANY_BOUND_TRX:
                [s appendFormat:@"SMPP_STATE_ANY_BOUND_TRX"];
                break;
            case SMPP_STATE_ANY:
                [s appendFormat:@"SMPP_STATE_ANY"];
                break;
        }
        [s appendFormat:@"<br>"];
        
        [s appendFormat:@"cid: %@<br>",_cid];
        [s appendFormat:@"receivePort: %ld<br>",_receivePort];
        [s appendFormat:@"transmitPort: %ld<br>",_transmitPort];
        [s appendFormat:@"transmissionMode: %d ",_transmissionMode];
        switch(_transmissionMode)
        {
            case SMPP_CONNECTION_MODE_TX:
                [s appendFormat:@"SMPP_CONNECTION_MODE_TX"];
                break;
            case SMPP_CONNECTION_MODE_RX:
                [s appendFormat:@"SMPP_CONNECTION_MODE_RX"];
                break;
            case SMPP_CONNECTION_MODE_TRX:
                [s appendFormat:@"SMPP_CONNECTION_MODE_TRX"];
                break;
                
        }
        [s appendFormat:@"<br>"];
    }
    return s;
}


- (void)setAlphaEncodingString:(NSString *)alphaCoding
{
    if([alphaCoding isEqualToString:@"8bit-gsm"])
    {
        self.alphanumericOriginatorCoding = SMPP_ALPHA_8BIT_GSM;
    }
    else if([alphaCoding isEqualToString:@"8bit-iso"])
    {
        self.alphanumericOriginatorCoding = SMPP_ALPHA_8BIT_ISO;
    }
    else if([alphaCoding isEqualToString:@"8bit-utf8"])
    {
        self.alphanumericOriginatorCoding = SMPP_ALPHA_8BIT_UTF8;
    }
    else
    {
        self.alphanumericOriginatorCoding = SMPP_ALPHA_7BIT_GSM;
    }
}

@end

