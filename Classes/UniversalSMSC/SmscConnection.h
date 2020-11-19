//
//  SmscConnection.h
//  UniversalSMS
//
//  Created by Andreas Fink on 12.01.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>
#import <ulib/ulib.h>
#import "UniversalSMSUtilities.h"

#import "SmscConnectionProtocol.h"
#import "SmscConnectionRouterProtocol.h"
#import "SmscConnectionMessagePassingProtocol.h"
@class SmscConnectionTransaction;

#define	SMSC_CONNECTION_DEFAULT_RECEIVE_POLL_TIMEOUT_MS		2000	/* poll timer for receive. in milliseconds */
#define	SMSC_CONNECTION_DEFAULT_TRANSMIT_TIMEOUT			100	/* in milliseconds */
#define	SMSC_CONNECTION_DEFAULT_KEEPALIVE					30
#define	SMSC_CONNECTION_DEFAULT_WINDOW_SIZE					10

#define	PREFS_TON				@"type-of-number"
#define	PREFS_NPI				@"numberplan-inicator"
#define	PREFS_NUMBER			@"number"

/* preference names of connections */
#define	PREFS_CON_NAME			@"name"
#define	PREFS_CON_PROTO			@"protocol"
#define	PREFS_CON_VERSION		@"version"
#define	PREFS_CON_LHOST			@"local-host"
#define	PREFS_CON_LPORT			@"local-port"
#define	PREFS_CON_RHOST			@"remote-host"
#define	PREFS_CON_RPORT			@"remote-port"
#define	PREFS_CON_RXTIMEOUT		@"receive-poll-timeout-miliseconds"
#define	PREFS_CON_TXTIMEOUT		@"transmit-ack-timeout-seconds"
#define	PREFS_CON_KEEPALIVE		@"keep-alive-seconds"
#define	PREFS_CON_WINDOW		@"window-size"
#define	PREFS_CON_SOCKTYPE		@"socket-type"
#define	PREFS_CON_ROUTER		@"router-name"
#define	PREFS_CON_SHORT_ID		@"short-id"
#define	PREFS_CON_LOGIN			@"login"
#define	PREFS_CON_PASSWORD		@"password"
#define	PREFS_CON_GSM_ERRCODE       @"gsm-error-code"
#define	PREFS_CON_SMPP_ERRCODE      @"smpp-error-code"
#define	PREFS_CON_DLR_ERRCODE       @"dlr-error-code"
#define	PREFS_CON_INTERNAL_ERRCODE  @"internal-error-code"
#define PREFS_CON_TCP_MSS       @"max-tcp-segment-size"

/* preference names of listeners */

#define	PREFS_LIS_NAME			@"name"
#define	PREFS_LIS_PROTO			@"protocol"
#define	PREFS_LIS_VERSION		@"version"
#define	PREFS_LIS_LHOST			@"local-host"
#define	PREFS_LIS_LPORT			@"local-port"
#define	PREFS_LIS_RXTIMEOUT		@"receive-poll-timeout-miliseconds"
#define	PREFS_LIS_TXTIMEOUT		@"transmit-ack-timeout-seconds"
#define	PREFS_LIS_KEEPALIVE		@"keep-alive-seconds"
#define	PREFS_LIS_WINDOW		@"window-size"
#define	PREFS_LIS_SOCKTYPE		@"socket-type"
#define	PREFS_LIS_ROUTER		@"router-name"
enum SmppAlphaCoding;

@interface SmscConnection : UMObject <SmscConnectionMessagePassingProtocol,SmscConnectionProtocol,SmscConnectionRouterUserProtocol>
{
	NSString			*name;
	NSString			*type;
	NSString			*version;
	NSString			*routerName;
	UMSocket			*uc;
#ifdef  USE_SMPP_PRIORITY_QUEUES
	PriorityQueue		*submitMessageQueue;
	PriorityQueue		*submitReportQueue;
	PriorityQueue		*deliverMessageQueue;
	PriorityQueue		*deliverReportQueue;
	PriorityQueue		*ackNackQueue;
#else
    UMQueueSingle             *submitMessageQueue;
    UMQueueSingle             *submitReportQueue;
    UMQueueSingle             *deliverMessageQueue;
    UMQueueSingle             *deliverReportQueue;
    UMQueueSingle             *ackNackQueue;
#endif
    
	UMSynchronizedDictionary *outgoingTransactions;
	UMSynchronizedDictionary *incomingTransactions;
    id<SmscConnectionRouterProtocol> __weak router;
	UMHost				*localHost;
	int					localPort;
	UMHost				*remoteHost;
	int					remotePort;
	UMSigAddr			*shortId;
	BOOL				endThisConnection;					/* Internal signal to shut down the inbound or outbound connection. It might autoreconnect on outbound */
    BOOL				endPermanently;					    /* Internal signal to shut down the connection permanently */
	NSDate				*lastActivity;				/* the last time something was sent over the main SMSC connection */
	UMSleeper			*rxSleeper;
	UMSleeper			*txSleeper;
    UMSleeper           *cxSleeper;
	int					receivePollTimeoutMs;		/* poll timer for receive. in miliseconds */
	int					transmitTimeout;			/* poll timer for transmit. in miliseconds */
	int					keepAlive;
	BOOL				isListener;
	BOOL				isInbound;
	int					windowSize;
	NSString			*login;
	NSString			*password;
    BOOL                autorestart;
    BOOL                stopped;
    BOOL                started;
    NSMutableDictionary *options;
    NSString            *lastStatus;
    int                 _max_tcp_segment_size;
    id<SmscConnectionUserProtocol>  user;
    UMThroughputCounter *inboundMessagesThroughput;
    UMThroughputCounter *outboundMessagesThroughput;
    UMThroughputCounter *inboundReportsThroughput;
    UMThroughputCounter *outboundReportsThroughput;
    
//    UMLogFeed           *packetLogFeed;
//    UMLogFeed           *comLogFeed;
}

@property(readwrite,strong)		NSString			*name;
@property(readwrite,strong)		NSString			*type;
@property(readwrite,strong)		NSString			*version;
@property(readwrite,strong)		NSString			*routerName;
@property(readwrite,strong)		UMSocket			*uc;
@property(readwrite,strong)		id<SmscConnectionUserProtocol> user;
//@property(readwrite,strong)		PriorityQueue		*submitMessageQueue;
//@property(readwrite,strong)		PriorityQueue		*submitReportQueue;
//@property(readwrite,strong)		PriorityQueue		*deliverMessageQueue;
//@property(readwrite,strong)		PriorityQueue		*deliverReportQueue;
//@property(readwrite,strong)		PriorityQueue       *ackNackQueue;
@property(readwrite,weak)		id<SmscConnectionRouterProtocol>	router;
@property(readwrite,strong)		UMHost				*localHost;
@property(readwrite,assign)		int					localPort;
@property(readwrite,strong)		UMHost				*remoteHost;
@property(readwrite,assign)		int					remotePort;
@property(readwrite,assign)		int					receivePollTimeoutMs;
@property(readwrite,assign)		int					transmitTimeout;
@property(readwrite,assign)		int					keepAlive;
@property(readwrite,strong)		UMSigAddr			*shortId;
@property(readwrite,strong)		NSDate				*lastActivity;	/* the last time something was sent over the main SMSC connection */
@property(readwrite,assign)		BOOL				isListener;
@property(readwrite,assign)		BOOL				isInbound;
@property(readwrite,assign)		int					windowSize;
@property(readwrite,strong)		NSString			*login;
@property(readwrite,strong)		NSString			*password;
@property(readwrite,assign)     BOOL                autorestart;
@property(readwrite,assign)     BOOL                stopped;
@property(readwrite,assign)     BOOL                started;
@property(readonly,strong)      UMThroughputCounter *inboundMessagesThroughput;
@property(readonly,strong)      UMThroughputCounter *outboundMessagesThroughput;
@property(readonly,strong)      UMThroughputCounter *inboundReportsThroughput;
@property(readonly,strong)      UMThroughputCounter *outboundReportsThroughput;
@property(readwrite,strong)     NSString            *lastStatus;
@property(readwrite,assign)     int                 max_tcp_segment_size;

+ (NSString *)uniqueMessageId;
+ (NSString *)uniqueMessageIdWithPrefix:(NSString *)prefix;
- (void) registerMessageRouter:(id<SmscConnectionRouterProtocol>) router;
- (void) unregisterMessageRouter:(id<SmscConnectionRouterProtocol>) router;
- (BOOL) isConnected;
- (BOOL) isAuthenticated;
- (BOOL) isOutbound;
- (NSString *) getName;
- (NSString *) getType;
- (void) setRemoteHost: (UMHost *) host;
- (void) setRemotePort: (int) port;
- (void) setLocalHost:  (UMHost *) host;
- (void) setLocalPort:  (int) port;
- (void)startListener;
- (void)stopListener;
- (void)startOutgoing;
- (void)stopOutgoing;
- (void)stopIncoming;
- (int) setConfig: (NSDictionary *) dict;
- (NSDictionary *) getConfig;
+ (NSDictionary *) getDefaultConnectionConfig;
+ (NSDictionary *) getDefaultListenerConfig;
- (NSComparisonResult)caseInsensitiveCompare:(SmscConnection *)otherUser;

- (void) addIncomingTransaction:(SmscConnectionTransaction *)transaction;
- (void) addOutgoingTransaction:(SmscConnectionTransaction *)transaction;
- (void) removeIncomingTransaction:(SmscConnectionTransaction *)transaction;
- (void) removeOutgoingTransaction:(SmscConnectionTransaction *)transaction;

- (void) ackIncomingTransaction:(SmscConnectionTransaction *)transaction;
- (void) nackIncomingTransaction:(SmscConnectionTransaction *)transaction err:(SmscRouterError *)code;
- (void) timeoutOutgoingTransaction:(SmscConnectionTransaction *)transaction;
- (void) timeoutIncomingTransaction:(SmscConnectionTransaction *)transaction;
- (SmscConnectionTransaction *) findIncomingTransaction:(NSString *)trn;
- (SmscConnectionTransaction *) findOutgoingTransaction:(NSString *)trn;
- (SmscConnectionTransaction *) findIncomingTransactionByMessage:(id)msg;
- (SmscConnectionTransaction *) findOutgoingTransactionByMessage:(id)msg;
- (SmscConnectionTransaction *) findIncomingTransactionByReport:(id)rep;
- (SmscConnectionTransaction *) findOutgoingTransactionByReport:(id)rep;


- (void)transactionDone:(id<SmscConnectionTransactionProtocol>) t;
- (void) proxyDeliverMessage:(id<SmscConnectionMessageProtocol>)msg forObject:(id)sendingObject;
- (BOOL)hasOption:(NSString *)n;
- (void)setOption:(NSString *)n;
- (void)clearOption:(NSString *)n;
- (void)clearAllOptions;
- (NSString *)connectedFrom;
- (NSString *)connectedTo;

@end
