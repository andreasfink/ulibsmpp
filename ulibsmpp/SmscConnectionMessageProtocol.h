
//
//  SmscConnectionMessageProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//
#if 0
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


@class SRMessageState;

@protocol SmscConnectionMessageProtocol<NSObject>

@property(readwrite)    id userTransaction;
@property(readwrite)    id routerTransaction;
@property(readwrite)    id providerTransaction;
@property(readwrite)    id originalSendingObject;

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


@end
#endif

