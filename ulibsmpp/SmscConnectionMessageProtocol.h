
//
//  SmscConnectionMessageProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/ulib.h>
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

typedef enum SmscMessageState
{
    MESSAGE_STATE_NEW           = 0,
    MESSAGE_STATE_ENROUTE       = 1,
    MESSAGE_STATE_DELIVERED     = 2,
    MESSAGE_STATE_EXPIRED       = 3,
    MESSAGE_STATE_DELETED		= 4,
	MESSAGE_STATE_UNDELIVERABLE = 5,
	MESSAGE_STATE_ACCEPTED		= 6,
	MESSAGE_STATE_REJECTED		= 7,
    MESSAGE_STATE_UNKNOWN       = 8,
} SmscMessageState;

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

@property(readwrite)    id userTransaction;
@property(readwrite)    id routerTransaction;
@property(readwrite)    id providerTransaction;
@property(readwrite)    id originalSendingObject;

@property(readwrite)    NSString *instance;
@property(readwrite)    NSString *deliveryMethod;
@property(readwrite)    NSString *inboundMethod;
@property(readwrite)    NSString *inboundType;
@property(readwrite)    NSString *fromIp;
@property(readwrite)    NSString *routerReference;
@property(readwrite)    NSString *userReference;
@property(readwrite)    NSString *providerReference;
@property(readwrite)    NSData *userMessageReference;
@property(readwrite)    id<SmscConnectionUserProtocol>user;
@property(readwrite)    NSString *fromNumber;
@property(readwrite)    NSString *toNumber;
@property(readwrite)    NSString *deliveryReportNumber;
@property(readwrite)    NSNumber *deliveryReportMask;
@property(readwrite)    NSNumber *esmClass;
@property(readwrite)    NSNumber *messageClass;
@property(readwrite)    NSNumber *pduDcs;
@property(readwrite)    NSString *pduCoding;
@property(readwrite)    NSNumber *pduPid;
@property(readwrite)    NSNumber *pduReplyPathIndicator;
@property(readwrite)    NSNumber *pduUdhIndicator;
@property(readwrite)    NSData *pduUdh;
@property(readwrite)    NSData *pduContent;
@property(readwrite)    NSString *plaintextContent;
@property(readwrite)    NSDate *submitTimestamp;
@property(readwrite)    NSDate *submitAckTimestamp;
@property(readwrite)    NSDate *submitErrorTimestamp;
@property(readwrite)    NSDate *messageAttemptedTimestamp;
@property(readwrite)    NSDate *validity;
@property(readwrite)    NSDate *deferred;
@property(readwrite)    NSString *submitString;
@property(readwrite)    NSNumber *networkErrorCode;
@property(readwrite)    SmscMessageState messageStateCode;
@property(readwrite)    NSNumber *messagePriority;
@property(readwrite)    NSNumber *replaceIfPresentFlag;

@optional
@property(readwrite)     NSString *smsc_srism_gt;
@property(readwrite)     NSString *smsc_srism_map;
@property(readwrite)     NSString *smsc_fsm_gt;
@property(readwrite)     NSString *smsc_fsm_map;
@property(readwrite)     NSString *opc_srism;
@property(readwrite)     NSString *dpc_srism;
@property(readwrite)     NSString *opc_fsm;
@property(readwrite)     NSString *dpc_fsm;
@property(readwrite)     NSNumber *userFlags;
@property(readwrite)     NSString *toMsc;
@property(readwrite)     NSString *fromMsc;
@property(readwrite)     NSString *toImsi;
@property(readwrite)     NSString *fromImsi;
@property(readwrite)     NSString *hlr;
@property(readwrite)     NSString *hlrOverride;
@property(readwrite)     NSString *mcc;
@property(readwrite)     NSString *mnc;
@property(readwrite)     NSMutableDictionary *tlvs;


@end
