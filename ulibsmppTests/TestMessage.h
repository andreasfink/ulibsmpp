//
//  TestMessage.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 27.09.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "ulib/UniversalObject.h"
#import "SmscConnectionMessageProtocol.h"
#import "TestObject.h"

#define DB_STATUS_NEW_RECORD        0x01
#define DB_STATUS_NEEDS_UPDATING    0x02
#define DB_STATUS_CAN_BE_PURGED     0x04

/* states for submit sm */
typedef enum state_t
{
    notKnown,
    accepted,
    hlrResponse,
    noHlrResponse,
    hlrReport,
    noHlrReport,
    acked,
    notSent,
    delivered,
    notDelivered
} MessageState;

/* states for deliver sm */
typedef enum deliver_state_t
{
    deliverNotKnown,
    deliverAccepted,
    deliverHlrResponse,
    deliverNoHlrResponse,
    deliverAcked,
    deliverNotSent,
    deliverHlrReport,
    deliverNoHlrReport,
    deliverDelivered,
    deliverNotDelivered
} DeliverMessageState;

#if 0
static dbFieldDef db_message_fields[] =
{
    /* name                     default canBeNull Index             type                 fieldSize, dec, setter, getter, tag */
    { "RouterReference",        NULL,   NO,     DB_PRIMARY_INDEX,   DB_FIELD_TYPE_STRING,              64,   0,NULL,NULL,2},
    { "ConnectionReference",    NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              64,   0,NULL,NULL,3},
    { "UserReference",          NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              64,   0,NULL,NULL,1},
    { "UserMessageReference",   NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              4,   0,NULL,NULL,1},
    { "Type",                   NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,4},
    { "Method",                 NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,5},
    { "InboundMethod",          NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,6},
    { "Addr",                   NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,7},
    { "InboundType",            NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,8},
    { "InboundAddress",         NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,9},
    { "From",                   NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,10},
    { "To",                     NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,11},
    { "ReportTo",               NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,12},
    { "ReportMask",             NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,13},
    { "PduDcs",                 NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,14},
    { "PduCoding",              NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,15},
    { "PduPid",                 NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,16},
    { "PduUdhi",                NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,17},
    { "PduRp",                  NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,18},
    { "PduUdh",                 NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TEXT,                0,    0,NULL,NULL,19},
    { "PduContent",             NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TEXT,                0,    0,NULL,NULL,20},
    { "SubmitDate",             NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,21},
    { "SubmitAckTime",          NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,22},
    { "SubmitErrTime",          NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,23},
    { "AttemptedDate",          NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,24},
    { "Validity",               NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,25},
    { "Deferred",               NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,26},
    { "SubmitString",           NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_TIMESTAMP_AS_STRING, 0,    0,NULL,NULL,27},
    { "SubmitErrCode",          NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,28},
    { "NetworkErrorCode",       NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,29},
    { "MessageState",           NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,30},
    { "Priority",               NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,31},
    { "ReplaceIfPresentFlag",   NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,32},
    { "Msc",                    NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,33},
    { "Smsc1",                  NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,34},
    { "Smsc2",                  NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,35},
    { "Smsc3",                  NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,36},
    { "Opc1",                   NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              8,    0,NULL,NULL,37},
    { "Dpc1",                   NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              8,    0,NULL,NULL,38},
    { "Opc2",                   NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              8,    0,NULL,NULL,39},
    { "Dpc2",                   NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              8,    0,NULL,NULL,40},
    { "Userflags",              NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_INTEGER,             0,    0,NULL,NULL,41},
    { "Hlr",                    NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,42},
    { "Imsi",                   NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_STRING,              32,   0,NULL,NULL,43},
    { "Mnc",                    NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             3,    0,NULL,NULL,44},
    { "Mcc",                    NULL,   NO,     DB_INDEXED,         DB_FIELD_TYPE_INTEGER,             2,    0,NULL,NULL,45},
    { "ResponseUrl",            NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_TEXT,                0,  0,NULL,NULL,46},
    { "",                       NULL,   NO,     DB_NOT_INDEXED,     DB_FIELD_TYPE_END,                 0,    0,NULL,NULL,0},
};
#endif

@interface TestMessage : UMObject<SmscConnectionMessageProtocol>
{
    int dbStatusFlags;
    
    UMStringWithHistory *dbUserReference;
    UMStringWithHistory *dbRouterReference;
    UMStringWithHistory *dbConnectionReference;
    UMDataWithHistory   *dbUserMessageReference;
    UMStringWithHistory *dbType;
    UMStringWithHistory *dbMethod;
    UMStringWithHistory *dbInboundMethod;
    UMStringWithHistory *dbAddr;
    UMStringWithHistory *dbInboundType;
    UMStringWithHistory *dbInboundAddress;
    
    UMStringWithHistory *dbFrom;
    UMStringWithHistory *dbTo;
    UMStringWithHistory *dbReportTo;
    
    UMIntegerWithHistory *dbReportMask;
    UMIntegerWithHistory *dbPduDcs;
    UMIntegerWithHistory *dbPduCoding;
    UMIntegerWithHistory *dbPduPid;
    UMIntegerWithHistory *dbPduUdhi;
    UMIntegerWithHistory *dbPduRp;
    
    UMDataWithHistory *dbPduUdh;
    UMDataWithHistory *dbPduContent;
    
    
    UMDateWithHistory *dbSubmitDate;
    UMDateWithHistory *dbSubmitAckTime;
    UMDateWithHistory *dbSubmitErrTime;
    UMDateWithHistory *dbAttemptedDate;
    
    UMDateWithHistory *dbValidity;
    UMDateWithHistory *dbDeferred;
    
    UMStringWithHistory *dbSubmitString;
    
    UMIntegerWithHistory *dbSubmitErrCode;
    UMIntegerWithHistory *dbNetworkErrorCode;
    
    UMIntegerWithHistory *dbMessageState;
    UMIntegerWithHistory *dbPriority;
    UMIntegerWithHistory *dbReplaceIfPresentFlag;
    
    UMStringWithHistory *dbMsc;
    UMStringWithHistory *dbSmsc1;
    UMStringWithHistory *dbSmsc2;
    UMStringWithHistory *dbSmsc3;
    UMStringWithHistory *dbOpc1;
    UMStringWithHistory *dbDpc1;
    UMStringWithHistory *dbOpc2;
    UMStringWithHistory *dbDpc2;
    UMStringWithHistory *dbUserflags;
    
    UMStringWithHistory *dbHlr;
    UMStringWithHistory *dbImsi;
    UMStringWithHistory *dbMnc;
    UMStringWithHistory *dbMcc;
    UMStringWithHistory *dbResponseUrl;
    
    /* non DB fields */
    id __weak userTransaction;
    id __weak routerTransaction;
    id __weak connectionTransaction;
    id __weak originalSendingObject;
    
    MessageState state;
    DeliverMessageState deliverState;
}

@property (readwrite,assign)    int dbStatusFlags;
@property (readwrite,retain)    UMStringWithHistory *dbRouterReference;
@property (readwrite,retain)    UMStringWithHistory *dbConnectionReference;
@property (readwrite,retain)    UMStringWithHistory *dbUserReference;
@property (readwrite,retain)    UMDataWithHistory   *dbUserMessageReference;
@property (readwrite,retain)    UMStringWithHistory *dbType;
@property (readwrite,retain)    UMStringWithHistory *dbMethod;
@property (readwrite,retain)    UMStringWithHistory *dbInboundMethod;
@property (readwrite,retain)    UMStringWithHistory *dbAddr;
@property (readwrite,retain)    UMStringWithHistory *dbInboundType;
@property (readwrite,retain)    UMStringWithHistory *dbInboundAddress;
@property (readwrite,retain)    UMStringWithHistory *dbFrom;
@property (readwrite,retain)    UMStringWithHistory *dbTo;
@property (readwrite,retain)    UMStringWithHistory *dbReportTo;

@property (readwrite,retain)    UMIntegerWithHistory *dbReportMask;
@property (readwrite,retain)    UMIntegerWithHistory *dbPduDcs;
@property (readwrite,retain)    UMIntegerWithHistory *dbPduCoding;
@property (readwrite,retain)    UMIntegerWithHistory *dbPduPid;
@property (readwrite,retain)    UMIntegerWithHistory *dbPduUdhi;
@property (readwrite,retain)    UMIntegerWithHistory *dbPduRp;

@property (readwrite,retain)    UMDataWithHistory *dbPduUdh;
@property (readwrite,retain)    UMDataWithHistory *dbPduContent;


@property (readwrite,retain)    UMDateWithHistory *dbSubmitDate;
@property (readwrite,retain)    UMDateWithHistory *dbSubmitAckTime;
@property (readwrite,retain)    UMDateWithHistory *dbSubmitErrTime;
@property (readwrite,retain)    UMDateWithHistory *dbAttemptedDate;

@property (readwrite,retain)    UMDateWithHistory *dbValidity;
@property (readwrite,retain)    UMDateWithHistory *dbDeferred;

@property (readwrite,retain)    UMStringWithHistory *dbSubmitString;

@property (readwrite,retain)    UMIntegerWithHistory *dbSubmitErrCode;
@property (readwrite,retain)    UMIntegerWithHistory *dbNetworkErrorCode;

@property (readwrite,retain)    UMIntegerWithHistory *dbMessageState;
@property (readwrite,retain)    UMIntegerWithHistory *dbPriority;
@property (readwrite,retain)    UMIntegerWithHistory *dbReplaceIfPresentFlag;

@property (readwrite,retain)    UMStringWithHistory *dbMsc;
@property (readwrite,retain)    UMStringWithHistory *dbSmsc1;
@property (readwrite,retain)    UMStringWithHistory *dbSmsc2;
@property (readwrite,retain)    UMStringWithHistory *dbSmsc3;
@property (readwrite,retain)    UMStringWithHistory *dbOpc1;
@property (readwrite,retain)    UMStringWithHistory *dbDpc1;
@property (readwrite,retain)    UMStringWithHistory *dbOpc2;
@property (readwrite,retain)    UMStringWithHistory *dbDpc2;
@property (readwrite,retain)    UMStringWithHistory *dbUserflags;

@property (readwrite,retain)    UMStringWithHistory *dbHlr;
@property (readwrite,retain)    UMStringWithHistory *dbImsi;
@property (readwrite,retain)    UMStringWithHistory *dbMnc;
@property (readwrite,retain)    UMStringWithHistory *dbMcc;
@property (readwrite,retain)    UMStringWithHistory *dbResponseUrl;

@property (readwrite,retain)    NSString *msc;
@property (readwrite,retain)    NSString *smsc1;
@property (readwrite,retain)    NSString *smsc2;
@property (readwrite,retain)    NSString *smsc3;
@property (readwrite,retain)    NSString *opc1;
@property (readwrite,retain)    NSString *dpc1;
@property (readwrite,retain)    NSString *opc2;
@property (readwrite,retain)    NSString *dpc2;
@property (readwrite,retain)    NSString *userflags;
@property (readwrite,retain)    NSString *hlr;
@property (readwrite,retain)    NSString *imsi;
@property (readwrite,retain)    NSString *mnc;
@property (readwrite,retain)    NSString *mcc;
@property (readwrite,retain)    NSString *responseUrl;

@property (readwrite,weak)      id userTransaction;
@property (readwrite,weak)      id routerTransaction;
@property (readwrite,weak)      id connectionTransaction;
@property (readwrite,weak)      id originalSendingObject;

@property (readwrite,assign)    MessageState state;
@property (readwrite,assign)    DeliverMessageState deliverState;

- (NSData *)pduContentIncludingUdh;
- (BOOL)equals:(id<SmscConnectionMessageProtocol>)msg;
- (NSString *)fromString;
- (void)setFromString:(NSString *)f;
- (NSString *)toString;
- (void)setToString:(NSString *)t;
- (NSString *)textUTF8String;
- (void)setTextUTF8String:(NSString *)s;
//+ (dbFieldDef *)tableDefinition;
- (NSArray *)arrayForInsert;
- (NSArray *)arraysForUpdate; /* returns an array with 3 entries. 0=array of field names, 1=array of values, 2=array of old values, 3=key field name, 4=key new value, 5=key old value */
- (void)clearDirtyFlags;
- (void)loadFromRow:(NSArray *)row;
- (void)setReplaceIfPresentFlag:(int)integer;
- (NSString *)messageStateToString;
- (NSString *)deliverMessageStateToString;

@end
