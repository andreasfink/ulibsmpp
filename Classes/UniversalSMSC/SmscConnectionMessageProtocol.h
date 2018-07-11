
//
//  SmscConnectionMessageProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "ulib/ulib.h"
#import "UniversalSMSUtilities.h"
#import "SmscConnectionUserProtocol.h"
/* this is the protocol a ShortMessage object must support as a minimum so a SMSC driver can fill a message it gets from the router */

#define	SMS_PARAM_UNDEFINED		-1

#define DC_UNDEF				SMS_PARAM_UNDEFINED
#define DC_7BIT					0
#define DC_8BIT					1
#define DC_UCS2					2

#define COMPRESS_UNDEF			SMS_PARAM_UNDEFINED
#define COMPRESS_OFF			0
#define COMPRESS_ON				1

#define RPI_UNDEF				SMS_PARAM_UNDEFINED
#define RPI_OFF					0
#define RPI_ON					1

#define SMS_7BIT_MAX_LEN		160
#define SMS_8BIT_MAX_LEN		140
#define SMS_UCS2_MAX_LEN		70

#define MC_UNDEF				SMS_PARAM_UNDEFINED
#define MC_CLASS0				0
#define MC_CLASS1				1
#define MC_CLASS2				2
#define MC_CLASS3				3

#define MWI_UNDEF				SMS_PARAM_UNDEFINED
#define MWI_VOICE_ON			0
#define MWI_FAX_ON				1
#define MWI_EMAIL_ON			2
#define MWI_OTHER_ON			3
#define MWI_VOICE_OFF			4
#define MWI_FAX_OFF				5
#define MWI_EMAIL_OFF			6
#define MWI_OTHER_OFF			7

#define	REPORT_NONE		0
#define	REPORT_SUCCESS	1
#define	REPORT_FAILURE	2
#define	REPORT_BUFFERED	4

#define	MESSAGE_STATE_ENROUTE		1
#define	MESSAGE_STATE_DELIVERED		2
#define	MESSAGE_STATE_EXPIRED	    3
#define	MESSAGE_STATE_DELETED		4
#define	MESSAGE_STATE_UNDELIVERABLE 5
#define	MESSAGE_STATE_ACCEPTED		6
#define	MESSAGE_STATE_UNKNOWN		7
#define	MESSAGE_STATE_REJECTED		8

typedef enum UMReportMaskValue
{
    UMDLR_MASK_REPORT_SUBMITTED = 1,
    UMDLR_MASK_REPORT_ENROUTE = 2,
    UMDLR_MASK_REPORT_DELIVERED = 4,
    UMDLR_MASK_REPORT_EXPIRED = 8,
    UMDLR_MASK_REPORT_DELETED = 16,
    UMDLR_MASK_REPORT_UNDELIVERABLE = 32,
    UMDLR_MASK_REPORT_ACCEPTED = 64,
    UMDLR_MASK_REPORT_UNKNOWN = 128,
    UMDLR_MASK_REPORT_REJECTED = 256,

    UMDLR_MASK_SUCCESS  = (UMDLR_MASK_REPORT_DELIVERED),
    UMDLR_MASK_FAIL     = (UMDLR_MASK_REPORT_EXPIRED | UMDLR_MASK_REPORT_DELETED | UMDLR_MASK_REPORT_UNDELIVERABLE | UMDLR_MASK_REPORT_REJECTED),
    UMDLR_MASK_BUFFERED = (UMDLR_MASK_REPORT_ENROUTE),
    UMDLR_MASK_SUBMIT   = (UMDLR_MASK_REPORT_SUBMITTED),
    UMDLR_MASK_FINAL    = (UMDLR_MASK_SUCCESS | UMDLR_MASK_FAIL),
} UMReportMaskValue;

typedef enum UMRequestMaskValue
{
    REQUEST_MASK_SUCCESS_OR_FAIL = 1,
    REQUEST_MASK_FAIL            = 2,
    REQUEST_MASK_INTERMEDIATE    = 16,
} UMRequestMaskValue;

@class SRMessageState;

@protocol SmscConnectionMessageProtocol<NSObject>

- (void) setRouterReference:(NSString *)msgid;
- (NSString *)routerReference;

- (void) setUserReference:(NSString *)msgid;
- (NSString *)userReference;

- (void) setUser:(id<SmscConnectionUserProtocol>)user;
- (id<SmscConnectionUserProtocol>)user;

- (void) setUserMessageReference:(NSData *)ref;
- (NSData *)userMessageReference;

- (void) setProviderReference:(NSString *)msgid;
- (NSString *)providerReference;

- (int)dbStatusFlags;
- (void)setDbStatusFlags:(int)flags;
- (NSString *)type;
- (NSString *)method;
- (NSString *)addr;
- (NSString *)inboundMethod;
- (void) setInboundMethod:(NSString *)method;
- (NSString *)inboundType;
- (void) setInboundType:(NSString *)type;
- (NSString *)inboundAddress;
- (void) setInboundAddress:(NSString *)addr;
- (void) setFrom:(UMSigAddr *)from;
- (UMSigAddr *)from;
- (void) setTo:(UMSigAddr *)to;
- (UMSigAddr *)to;
- (void) setReportTo:(UMSigAddr *)reportTo;
- (UMSigAddr *)reportTo;
- (void) setReportMask:(UMReportMaskValue)mask;
- (UMReportMaskValue) reportMask;
- (void) setPduDcs:(NSInteger)dcs;
- (NSInteger) pduDcs;
- (void) setMessageClass:(NSInteger)messageClass;
- (NSInteger) messageClass;
- (void) setPduCoding:(NSInteger)coding;
- (NSInteger) pduCoding;
- (void) setPduPid:(NSInteger)pid;
- (NSInteger) pduPid;
- (void) setPduRp:(NSInteger)rp;
- (NSInteger) pduRp;
- (void) setPduUdh:(NSData *)udh;
- (NSData *) pduUdh;
- (void) setPduUdhi:(NSInteger)i;
- (NSInteger) pduUdhi;
- (void) setPduContent:(NSData *)content;
- (NSData *)pduContent;
- (NSData *)pduContentIncludingUdh;
- (NSDate *)attemptedDate;
- (NSDate *)submitDate;
- (NSDate *)submitAckTime;
- (void) setSubmitAckTime:(NSDate *)d;
- (void) setValidity:(NSDate *)d;
- (NSDate *)validity;
- (void) setDeferred:(NSDate *)d;
- (NSDate *)deferred;
- (void) setSubmitString: (NSString *)s;
- (NSString *)submitString;
- (NSDate *)submitErrTime;
- (void) setSubmitErrTime:(NSDate *)d;
- (NSInteger)submitErrCode;
- (void) setSubmitErrCode:(NSInteger)err;
- (int) networkErrorCode;
- (void)setNetworkErrorCode:(int)c;
- (int) messageState;
- (void) setMessageState:(int)state;

- (void) setUserTransaction:(id)transaction;
- (id) userTransaction;

- (void) setRouterTransaction:(id)transaction;
- (id) routerTransaction;
- (int) priority;
- (void) setPriority:(int)prio;
- (int) replaceIfPresentFlag;
- (void) setReplaceIfPresentFlag:(int)i;
- (id)originalSendingObject;
- (void)setOriginalSendingObject:(id)obj;
- (NSString *)instance;
- (void)setInstance:(NSString *)instance;
@optional
- (NSString *)smsc1;
- (void)setSmsc1:(NSString *)smsc1;
- (NSString *)smsc2;
- (void)setSmsc2:(NSString *)smsc2;
- (NSString *)smsc3;
- (void)setSmsc3:(NSString *)smsc3;
- (NSString *)opc1;
- (NSString *)opc2;
- (NSString *)dpc1;
- (NSString *)dpc2;
- (NSString *)userflags;
- (void)setUserflags:(NSString *)flags;
- (NSString *)msc;
- (void)setMsc:(NSString *)msc;
- (NSString *)hlr;
- (NSString *)mcc;
- (void)setMcc:(NSString *)mcc;
- (NSString *)mnc;
- (void)setMnc:(NSString *)mnc;
- (NSString *)imsi;
- (void)setImsi:(NSString *)imsi;
- (NSString *)toString;
- (void)setToString:(NSString *)t;
- (UMStringWithHistory *)dbUser;
- (void)setString:(NSString *)newValue;

- (BOOL)equals:(id<SmscConnectionMessageProtocol>)msg;

- (NSDictionary *)tlvs;
- (void)setTlvs:(NSDictionary *)tlvs;

@end
