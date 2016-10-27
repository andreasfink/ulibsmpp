//
//  TestDeliveryReport.m
//  smsrouter
//
//  Created by Aarno Syvänen on 01.02.13.
//  Copyright (c) 2013 Andreas Fink. All rights reserved.
//

#import "TestDeliveryReport.h"

@implementation TestDeliveryReport

@synthesize userReference;
@synthesize routerReference;
@synthesize connectionReference;
@synthesize originalSendingObject;

@synthesize destination;
@synthesize source;
@synthesize reportText;
@synthesize reportType;
@synthesize errorCode;
@synthesize priority;
@synthesize connection;
@synthesize provider;
@synthesize imsi;
@synthesize msc;
@synthesize responseCode;
@synthesize hlrGt;
@synthesize mnc;
@synthesize mcc;
@synthesize reportState;
@synthesize tlvs;
@synthesize usedAt;
@synthesize hlrReport;
@synthesize reportFormat;


@synthesize deliverReportState;
@synthesize deliveryAcked;
@synthesize deliverer;
@synthesize pduContent;

- (TestDeliveryReport *)initWithReport:(id <SmscConnectionReportProtocol>)report
{
    if ((self = [super init]))
    {
        self.userReference = report.userReference;
        self.routerReference = report.routerReference;
        self.connectionReference = report.providerReference;
    
        self.destination = report.destination;
        self.source = report.source;
        self.reportText = report.reportText;
        self.reportType = report.reportType;
        self.error = (SmscConnectionErrorCode)report.error;
        self.priority = report.priority;
    }
    return self;
}

- (BOOL)equals:(TestDeliveryReport*)msg
{
    if (!destination)
        return FALSE;
    if (![msg destination])
        return FALSE;
    if ([[destination asString] compare:[[msg destination] asString]] != 0)
        return FALSE;
    if (!source && [msg source])
        return FALSE;
    if (source && ![msg source])
        return FALSE;
    if ([[source asString] compare:[[msg source] asString]] != 0)
        return FALSE;
    if (!reportText)
        return FALSE;
    if (![msg reportText])
        return FALSE;
    if ([reportText compare:[msg reportText]] != 0)
        return FALSE;
    if (reportType != [msg reportType])
        return FALSE;
    if (errorCode != [msg errorCode])
        return FALSE;
    if (priority != [msg priority])
        return FALSE;
    
    return TRUE;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"Test delivery dump starts"];
    [desc appendFormat:@"%@",[super description]];
    [desc appendFormat:@"report state is %@\n",[self reportStateToString]];
    [desc appendFormat:@"delivery report state was %@", [self deliverReportStateToString]];
    [desc appendString:@"Test delivery dump ends"];
    
    return desc;
}

- (NSString *)deliverReportStateToString
{
    switch (deliverReportState)
    {
        case deliverReportNotKnown:
            return @"deliver report not known";
        case deliverHlrSent:
            return @"deliver hlr sent";
        case deliverNoHlrSent:
            return @"deliver hlr not sent";
        case deliverHlrAcked:
            return @"deliver hlr acked";
        case deliverHlrNotAcked:
            return @"deliver hlr not acked";
        case deliverReportSent:
            return @"deliver report sent";
        case deliverReportNotSent:
            return @"deliver report not sent";
        case deliverReportAcked:
            return @"deliver report acked";
        case deliverReportNotAcked:
            return @"deliver report not acked";
    }
    
    return @"deliver report not known";
}

- (NSString *)reportStateToString
{
    switch (reportState)
    {
        case reportNotKnown:
            return @"report not known";
        case hlrSent:
            return @"hlr sent";
        case noHlrSent:
            return @"hlr not sent";
        case hlrAcked:
            return @"hlr acked";
        case hlrNotAcked:
            return @"hlr not acked";
        case reportSent:
            return @"report sent";
        case reportNotSent:
            return @"report not sent";
        case reportAcked:
            return @"report acked";
        case reportNotAcked:
            return @"report not acked";
    }
    
    return @"report not known";
}

@end
