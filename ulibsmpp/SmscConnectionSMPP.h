//
//  SmscConnectionSMPP.h
//  UniversalSMSCConnectionSMPP
//
//  Created by Andreas Fink on 11.12.08.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import <ulibsmpp/UniversalSMSC.h>
#import <ulibsmpp/SmppPdu.h>

#define	SMSC_DEFAULT_SMPP_PORT	5002
#define MIN_SMPP_PDU_LEN        (4*4)
/* old value was (1024). We need more because message_payload can be up to 64K octets*/
// not used anywhere
//#define MAX_SMPP_PDU_LEN        (7424)
/*Socket Errors are a separate class */
#define WRONG_SMPP_SIZE         -100
#define SMPP_VERSION            0x34

/* Preferences for SMPP clients */
#define	PREFS_CON_TRANSMIT_PORT			@"port"
#define	PREFS_CON_RECEIVE_PORT			@"receive-port"
#define	PREFS_CON_SYSTEM_TYPE			@"system-type"
#define	PREFS_CON_ADDRESS_RANGE			@"address-range"

@class SmscConnectionSMPP;

@protocol SmppTerminationCallback<NSObject>
- (void)terminatedCallback:(SmscConnectionSMPP *)con;
@end


typedef	enum SmppIncomingReceiverThreadStatus
{
		SMPP_IRT_NOT_RUNNING	= 0,
		SMPP_IRT_STARTING		= 1,
		SMPP_IRT_RUNNING		= 2,
		SMPP_IRT_TERMINATING	= 3,
		SMPP_IRT_TERMINATED     = 4,
} SmppIncomingReceiverThreadStatus;

typedef	enum SmppOutgoingReceiverThreadStatus
{
    SMPP_ORT_NOT_RUNNING	= 0,
    SMPP_ORT_STARTING		= 1,
    SMPP_ORT_RUNNING		= 2,
    SMPP_ORT_TERMINATING	= 3,
    SMPP_ORT_TERMINATED      = 4,
} SmppOutgoingReceiverThreadStatus;

typedef	enum	SmppAuth
{
	SMPP_AUTH_OK = 0,
	SMPP_AUTH_UNKNOWN_PDU_TYPE = -1,
	SMPP_AUTH_WRONG_SOURCE = -2,
	SMPP_AUTH_WRONG_STATE = -3
} SmppAuth;

typedef enum    SmppAlphaCoding
{
    SMPP_ALPHA_7BIT_GSM     = 0, /* default */
    SMPP_ALPHA_8BIT_GSM     = 1,
    SMPP_ALPHA_8BIT_ISO     = 2,
    SMPP_ALPHA_8BIT_UTF8    = 3,
} SmppAlphaCoding;

typedef struct SmppPduTableEntry
{
		SmppPduType		pduType;
		const char		*name;
		SmppState		allowedStates;
		SmppSource		allowedSources;
} SmppPduTableEntry;

typedef enum SMPPConnectionMode
{
    SMPP_CONNECTION_MODE_TX = 1,
    SMPP_CONNECTION_MODE_RX = 2,
    SMPP_CONNECTION_MODE_TRX = 3,
} SMPPConnectionMode;

@interface SmscConnectionSMPP : SmscConnection <SmscConnectionProtocol,SmscConnectionRouterUserProtocol>
{
	NSLock				*_sendLock;
	NSLock				*_trnLock;
	uint32_t			_lastSeq;
//	EmiUcpPendingTransaction slots[EMI2_MAX_TRN];
	SmppIncomingReceiverThreadStatus _runIncomingReceiverThread;
    SmppOutgoingReceiverThreadStatus _runOutgoingReceiverThread;
	SmppIncomingStatus	_incomingStatus;
    SmppOutgoingStatus  _outgoingStatus;
	SmppState			_inboundState;
    SmppState           _outboundState;
    NSString		    *_cid;
    NSString            *_altAddrCharset;
    NSString            *_altCharset;
    long                _receivePort;
    long                _transmitPort;
    SMPPConnectionMode  _transmissionMode;
    NSString            *_systemType;
    NSInteger		    _bindAddrTon;
	NSInteger		    _bindAddrNpi;
    NSString            *_addressRange;
    int                 _smppMessageIdType;
    time_t              _lastKeepAliveSent;
    time_t              _lastKeepAliveResponseReceived;
    time_t              _lastKeepAliveReceived;
    time_t              _lastDataPacketSent;
    time_t              _lastDataPacketReceived;
    
    time_t              _lastSubmitSmSent;
    time_t              _lastSubmitSmReceived;
    time_t              _lastSubmitSmAckSent;
    time_t              _lastSubmitSmAckReceived;

    time_t              _lastDeliverSmSent;
    time_t              _lastDeliverSmReceived;
    time_t              _lastDeliverSmAckSent;
    time_t              _lastDeliverSmAckReceived;

    NSString            *_debugLastLocation;
    NSString            *_debugLastLastLocation;
    NSDictionary        *_tlvDefs;
    NSString            *_advertizeName;
    NSDate              *_bindExpires;
    BOOL                _usesHexMessageIdInSubmitSmResp;
    BOOL                _usesHexMessageIdInDlrText;
    BOOL                _registered;
    
    SmppAlphaCoding     _alphanumericOriginatorCoding;
    int                 _outstandingKeepalives;
    __weak id<SmppTerminationCallback>   _terminatedDelegate; /* we call this with [obj terminatedCallback:self] */
	/*
     @property(readwrite,retain)     UMLogFeed *packetLogFeed;
     @property(readwrite,retain)     UMLogFeed *comLogFeed;

	NSMutableArray	*outMessageQueue;
	NSMutableArray	*outReportQueue;

	NSInteger		passiveConnection;

	NSString		*smppSystemType;
	NSString		*smppUsername;
	NSString		*smppPassword;
	NSString		*smppAddressRange;
	NSString		*smppMyNumber;
	NSString		*smppServiceType;
	NSInteger		enquireLinkInterval;
	NSInteger		maxPendingSubmits;
	NSInteger		ton;
	NSInteger		npi;
	NSInteger		seq;
//	NSLock			*lock;
	NSLock			*sendLock;
	SmppState		state;
	SmppStatus		status;
	SmppSource		source;
	NSInteger 		priority;      
	NSInteger		throttlingErrTime;
	NSInteger		smppMsgIdType;  // msg id in C string, hex or decimal 
	NSInteger		autodetectAddr;
	NSInteger 		connectionTimeout;
    NSString		    *altCharset;
	NSInteger 		waitAck;
	NSInteger		waitAckAction;
	NSInteger		totalSentMessages;
	NSInteger		totalReceivedMessages;
	NSInteger		totalSentReports;
	NSInteger		totalReceivedReports;
	NSInteger		limitSend;
	NSInteger		limitReceive;
	NSInteger		smppPduTx;
	NSInteger		smppPduRx;
	NSInteger		mustQuit;
	NSDate			*lastConnection;
	NSDate			*lastMessageSent;
	NSDate			*lastMessageReceived;
	NSMutableArray	*acksWaiting;
	*/
}

@property (readwrite,weak)      id              terminatedDelegate;

@property (readwrite,assign) 	SmppIncomingStatus		incomingStatus;
@property (readwrite,assign) 	SmppOutgoingStatus		outgoingStatus;
@property (readwrite,assign)    SmppState	    inboundState;
@property (readwrite,assign)    SmppState       outboundState;
@property (readwrite,strong) 	NSString		*cid;
@property (readwrite,strong) 	NSString		*altAddrCharset;
@property (readwrite,strong) 	NSString		*altCharset;
@property (readwrite,assign) 	long            transmitPort;
@property (readwrite,assign) 	long            receivePort;
@property (readwrite,strong) 	NSString		*addressRange;
@property (readwrite,assign) 	SMPPConnectionMode transmissionMode;
@property (readwrite,strong) 	NSString		*systemType;
@property (readwrite,strong)    NSDictionary    *tlvDefs;
@property (readwrite,strong)    NSString        *advertizeName;
@property (readwrite,assign)    SmppAlphaCoding alphanumericOriginatorCoding;
@property (readwrite,assign)    BOOL            usesHexMessageIdInSubmitSmResp;
@property (readwrite,assign)    BOOL            usesHexMessageIdInDlrText;
@property (readwrite,assign)   NSInteger        bindAddrTon;
@property (readwrite,assign)   NSInteger        bindAddrNpi;

- (SmscConnectionSMPP *)init;


/* main functions */
- (NSString *)connectedFrom;
- (NSString *)connectedTo;
- (int)activeOutbound;
- (int)activeInbound;
- (int)activePhase:(int)outbound;
- (void)startListener;
- (void)stopListener;
- (void)startOutgoing;
- (void)stopOutgoing;
- (void)stopIncoming;

- (void) stopIncomingReceiverThread;
- (void) startIncomingReceiverThread;
- (void) stopOutgoingReceiverThread;
- (void) startOutgoingReceiverThread;
- (void) outgoingReceiverThread;
- (void) incomingReceiverThread;
- (void) checkForPackets;

/* */
- (UMSocketError)	_sendPdu:(SmppPdu *)pdu; /* dont use directly. use sendPduWithNewSeq or sendPdu:asResponseTo:*/
- (UMSocketError)	sendPduWithNewSeq:(SmppPdu *)pdu;
- (UMSocketError) sendPdu:(SmppPdu *)pdu asResponseTo:(SmppPdu *)pdu1;
- (UMSocketError) sendPdu:(SmppPdu *)pdu withSeq:(SmppPduSequence)seq;
- (UMSocketError) sendAckNack:(SmscConnectionTransaction *)	transaction;

- (void) handleIncomingPdu:(SmppPdu *)pdu;

- (void) handleIncomingSubmitSm: (SmppPdu *)pdu;
- (void) handleIncomingSubmitSmResp: (SmppPdu *)pdu;
- (void) handleIncomingDataSm: (SmppPdu *)pdu;
- (void) handleIncomingDataSmResp: (SmppPdu *)pdu;
- (void) handleIncomingDeliverSm: (SmppPdu *)pdu;
- (void) handleIncomingDeliverSmResp: (SmppPdu *)pdu;
- (void) handleIncomingEnquireLink: (SmppPdu *)pdu;
- (void) handleIncomingEnquireLinkResp: (SmppPdu *)pdu;
- (void) handleIncomingGenericNack: (SmppPdu *)pdu;
- (void) handleIncomingBind: (SmppPdu *)pdu rx:(BOOL)rx tx:(BOOL)tx;
- (void) handleIncomingBindReceiver: (SmppPdu *)pdu;
- (void) handleIncomingBindReceiverResp: (SmppPdu *)pdu;
- (void) handleIncomingBindTransmitter: (SmppPdu *)pdu;
- (void) handleIncomingBindTransmitterResp: (SmppPdu *)pdu;
- (void) handleIncomingQuerySm: (SmppPdu *)pdu;
- (void) handleIncomingQuerySmResp: (SmppPdu *)pdu;
- (void) handleIncomingUnbind: (SmppPdu *)pdu;
- (void) handleIncomingUnbindResp: (SmppPdu *)pdu;
- (void) handleIncomingReplaceSm: (SmppPdu *)pdu;
- (void) handleIncomingReplaceSmResp: (SmppPdu *)pdu;
- (void) handleIncomingCancelSm: (SmppPdu *)pdu;
- (void) handleIncomingCancelSmResp: (SmppPdu *)pdu;
- (void) handleIncomingBindTransceiver: (SmppPdu *)pdu;
- (void) handleIncomingBindTransceiverResp: (SmppPdu *)pdu;
- (void) handleIncomingOutbind: (SmppPdu *)pdu;
- (void) handleIncomingSubmitSmMulti: (SmppPdu *)pdu;
- (void) handleIncomingSubmitSmMultiResp: (SmppPdu *)pdu;
- (void) handleIncomingAlertNotification: (SmppPdu *)pdu;

- (void) checkForSendingKeepalive;


- (id<SmscConnectionReportProtocol>)deliverPduToReport:(SmppPdu *)pdu;
- (id<SmscConnectionMessageProtocol>)deliverPduToMsg:(SmppPdu *)pdu;

- (int) setConfig: (NSDictionary *) dict;
- (NSDictionary *) getConfig;
+ (NSDictionary *) getDefaultConnectionConfig;
+ (NSDictionary *) getDefaultListenerConfig;
- (NSDictionary *) getClientConfig;

+ (NSString *)outgoingStatusToString:(SmppOutgoingStatus)status;
+ (NSString *)incomingStatusToString:(SmppIncomingStatus)status;

/* logging */
-(void) logIncomingPdu:(SmppPdu *)pdu;
-(void) logOutgoingPdu:(SmppPdu *)pdu;

/* helper functions */
+ (NSString *)smppErrorToString:(SmppErrorCode) err;

//+ (NSString *)smppErrorToString:(SmppErrorCode) err;
//+ (int) errorFromNetworkErrorCode:(NSData *)networkErrorCode;

//+ (SmscConnectionErrorCode) smppErrToGlobal:(SmppErrorCode)err;
//+ (SmppErrorCode) globalToSmppErr:(SmscConnectionErrorCode)err;

- (NSString *)stringStatus;


//+ (SmscConnectionErrorCode)old_networkErrorToGlobal:(int)e;
//+ (int)old_globalToNetworkError:(SmscConnectionErrorCode)e;

- (void)setAlphaEncodingString:(NSString *)alphaCoding;
@end

