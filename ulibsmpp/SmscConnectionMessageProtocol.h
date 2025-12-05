
//
//  SmscConnectionMessageProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//
#if 0
#import <ulib/ulib.h>
#import <ummessage/ummessage.h>
#import <ulibsmpp/UniversalSMSUtilities.h>
#import <ulibsmpp/SmscConnectionUserProtocol.h>
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

<<<<<<< HEAD:ulibsmpp/SmscConnectionMessageProtocol.h
/* this is now in ummessage
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
 */
=======
>>>>>>> release-6.0:ulibsmpp6/SmscConnectionMessageProtocol.h

@class SRMessageState;

@protocol SmscConnectionMessageProtocol<NSObject>

- (void) setRouterReference:(NSString *)msgid;
- (NSString *)routerReference;

@property(readwrite)    id<SmscConnectionUserProtocol>user;

@property(readwrite)    UMDirtyString *instance;
@property(readwrite)    UMDirtyString *deliveryMethod;
@property(readwrite)    UMDirtyString *inboundMethod;
@property(readwrite)    UMDirtyString *inboundType;
@property(readwrite)    UMDirtyString *fromIp;
@property(readwrite)    UMDirtyString *routerReference;
@property(readwrite)    UMDirtyString *userReference;
@property(readwrite)    UMDirtyString *providerReference;
@property(readwrite)    UMDirtyData *userMessageReference;
@property(readwrite)    UMDirtyString *fromNumber;
@property(readwrite)    UMDirtyString *toNumber;
@property(readwrite)    UMDirtyString *deliveryReportNumber;
@property(readwrite)    UMDirtyInteger *deliveryReportMask;
@property(readwrite)    UMDirtyInteger *esmClass;
@property(readwrite)    UMDirtyInteger *messageClass;
@property(readwrite)    UMDirtyInteger *pduDcs;
@property(readwrite)    UMDirtyString *pduCoding;
@property(readwrite)    UMDirtyInteger *pduPid;
@property(readwrite)    UMDirtyInteger *pduReplyPathIndicator;
@property(readwrite)    UMDirtyInteger *pduUdhIndicator;
@property(readwrite)    UMDirtyData *pduUdh;
@property(readwrite)    UMDirtyData *pduContent;
@property(readwrite)    UMDirtyString *plaintextContent;
@property(readwrite)    UMDirtyDate *submitTimestamp;
@property(readwrite)    UMDirtyDate *submitAckTimestamp;
@property(readwrite)    UMDirtyDate *submitErrorTimestamp;
@property(readwrite)    UMDirtyDate *messageAttempted;
@property(readwrite)    UMDirtyDate *validity;
@property(readwrite)    UMDirtyDate *deferred;
@property(readwrite)    UMDirtyString *submitString;
@property(readwrite)    UMDirtyInteger *networkErrorCode;
@property(readwrite)    SmscMessageState messageStateCode;
@property(readwrite)    UMDirtyInteger *messagePriority;
@property(readwrite)    UMDirtyInteger *replaceIfPresentFlag;

- (void) setUser:(id<SmscConnectionUserProtocol>)user;
- (id<SmscConnectionUserProtocol>)user;

- (void) setUserMessageReference:(NSData *)ref;
- (NSData *)userMessageReference;

- (void) setProviderReference:(NSString *)msgid;
- (NSString *)providerReference;

//- (int)dbStatusFlags;
//- (void)setDbStatusFlags:(int)flags;
- (NSString *)type;
- (NSString *)method;
//- (NSString *)addr;
- (NSString *)inboundMethod;
- (void) setInboundMethod:(NSString *)method;
- (NSString *)inboundType;
- (void) setInboundType:(NSString *)type;
- (NSString *)inboundAddress;
- (void) setInboundAddress:(NSString *)addr;
- (void) setSource:(UMSigAddr *)from;
- (UMSigAddr *)source;
- (void) setDestination:(UMSigAddr *)to;
- (UMSigAddr *)destination;
- (void) setDeliveryReportAddress:(UMSigAddr *)reportTo;
- (UMSigAddr *)deliveryReportAddress;
- (void) setDeliveryReportMask:(UMReportMaskValue)mask;
- (UMReportMaskValue) deliveryReportMask;
- (void) setPduDcs:(NSInteger)dcs;
- (NSInteger) pduDcs;
- (void) setMessageClass:(NSInteger)messageClass;
- (NSInteger) messageClass;
- (void) setPduCoding:(NSInteger)coding;
- (NSInteger) pduCoding;
- (void) setPduPid:(NSInteger)pid;
- (NSInteger) pduPid;
- (void) setReplyPath:(NSInteger)rp;
- (NSInteger) replyPath;
- (void) setPduUdh:(NSData *)udh;
- (NSData *) pduUdh;
- (void) setUdhIndicator:(BOOL)b;
- (BOOL) udhIndicator;
- (void) setPduContent:(NSData *)content;
- (NSData *)pduContent;
- (NSDate *)messageAttempted;
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

- (int) messageStateCode;
- (void) setMessageStateCode:(int)state;

- (void) setUserTransaction:(id)transaction;
- (id) userTransaction;

- (void) setRouterTransaction:(id)transaction;
- (id) routerTransaction;
- (int) messagePriority;
- (void) setMessagePriority:(int)prio;
- (int) replaceIfPresentFlag;
- (void) setReplaceIfPresentFlag:(int)i;
- (id)originalSendingObject;
- (void)setOriginalSendingObject:(id)obj;
- (NSString *)instance;
- (void)setInstance:(NSString *)instance;
@optional
@property(readwrite)     UMDirtyString *smsc_srism_gt;
@property(readwrite)     UMDirtyString *smsc_srism_map;
@property(readwrite)     UMDirtyString *smsc_fsm_gt;
@property(readwrite)     UMDirtyString *smsc_fsm_map;
@property(readwrite)     UMDirtyString *opc_srism;
@property(readwrite)     UMDirtyString *dpc_srism;
@property(readwrite)     UMDirtyString *opc_fsm;
@property(readwrite)     UMDirtyString *dpc_fsm;
@property(readwrite)     UMDirtyInteger *userFlags;
@property(readwrite)     UMDirtyString *toMsc;
@property(readwrite)     UMDirtyString *fromMsc;
@property(readwrite)     UMDirtyString *toImsi;
@property(readwrite)     UMDirtyString *fromImsi;
@property(readwrite)     UMDirtyString *hlr;
@property(readwrite)     UMDirtyString *hlrOverride;
@property(readwrite)     UMDirtyString *mcc;
@property(readwrite)     UMDirtyString *mnc;

@property(readwrite)     NSMutableDictionary *tlvs;

- (BOOL)equals:(id<SmscConnectionMessageProtocol>)msg;

- (NSDictionary *)tlvs;
- (void)setTlvs:(NSDictionary *)tlvs;

@end
#endif

