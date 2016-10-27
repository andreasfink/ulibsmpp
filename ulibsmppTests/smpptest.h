//
//  smpptest.h
//  smpptest
//
//  Created by Aarno Syvänen on 25.09.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <SenTestingKit/SenTestingKit.h>

typedef enum report_state_t
{
    reportNotKnown = 0,
    hlrSent        = 1,
    noHlrSent      = 2,
    hlrAcked       = 3,
    hlrNotAcked    = 4,
    reportSent     = 5,
    reportNotSent  = 6,
    reportAcked    = 7,
    reportNotAcked = 8
} ReportState;

typedef enum deliver_report_state_t
{
    deliverReportNotKnown,
    deliverHlrSent,
    deliverNoHlrSent,
    deliverHlrAcked,
    deliverHlrNotAcked,
    deliverReportSent,
    deliverReportNotSent,
    deliverReportAcked,
    deliverReportNotAcked
} DeliverReportState;

typedef enum HLRResponseCode
{
    UNKNOWN = -1,
    OK,
    QUEUED,
    UNKNOWN_SUBSCRIBER,
    ABSENT_SUBSCRIBER_SM,
    CALL_BARRED,
    TELESERVICE_NOT_PROVISIONED,
    FACILITY_NOT_SUPPORTED,
    TIMEOUT,
    SYSTEM_FAILURE,
    HLR_ABORT,
    HLR_QUEUED,
    HLR_LOCAL_CANCEL
} HLRResponseCode;

typedef enum {
    FORMAT_NOT_KNOWN = -1,
    FORMAT_TEXT,
    FORMAT_JSON
} ReportFormat;

@class TestMessage;

@interface smpptest : SenTestCase

+ (void)configSubmitTest:(TestMessage **)t;
+ (void)configDeliverTest:(TestMessage **)t;
+ (BOOL)outconnectionClosed;
+ (BOOL)inconnectionClosed;

@end
