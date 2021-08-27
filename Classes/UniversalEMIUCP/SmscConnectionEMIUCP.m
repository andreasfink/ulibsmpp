//
//  SmscConnectionEMIUCP.m
//  ulibsmpp
//
//  Created by Andreas Fink on 17/11/14.
//
//

#import <ulib/ulib.h>
#import "SmscConnectionEMIUCP.h"
#include <sys/signal.h>
#include <unistd.h> /* for usleep */
#import "NSMutableString+UniversalSMPP.h"
#import "NSString+UniversalSMPP.h"

@implementation SmscConnectionEMIUCP


- (SmscConnectionEMIUCP *)init
{
    self=[super init];
    if(self)
    {
        [super setVersion: @"1.0"];
        [super setType: @"emiucp"];
        self.lastActivity =[NSDate new];
    }
    return self;
}

- (NSString *)_type
{
    return @"emiucp";
}

- (NSString *) getType
{
    return @"emiucp";
}

- (BOOL) isConnected
{
    return YES;
}

- (BOOL) isAuthenticated
{
    return YES;
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
    dict[PREFS_CON_PROTO] = @"emiucp";
    return dict;
}



- (NSDictionary *) getClientConfig
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] init];
    dict[PREFS_CON_NAME] = @"emiucp";
    return dict;
}

+ (NSDictionary *) getDefaultConnectionConfig
{
    NSDictionary *smppConnectionDict;
    
    smppConnectionDict = @{ PREFS_CON_NAME : @"null" };
    return smppConnectionDict;
}

+ (NSDictionary *) getDefaultListenerConfig
{
    return @{ PREFS_CON_NAME : @"emiucp" };
}

#pragma mark sendingPDUs

- (NSString *)connectedFrom
{
    return @"emiucp";
}

- (NSString *)connectedTo
{
    return @"emiucp";
}

- (void) outbound
{
    /* first, register self to sms router */
    @autoreleasepool
    {
        ulib_set_thread_name([NSString stringWithFormat:@"[SmscConnectionSMPP outbound] %@",_uc.description]);
        self.isInbound=NO;
        [_router registerOutgoingSmscConnection:self];
    }
}

/* submit Message: router->outbound TX connection */
- (void) submitMessage:(id<SmscConnectionMessageProtocol>)msg
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    id<SmscConnectionReportProtocol> report = NULL;
    
    [sendingObject submitMessageSent:msg
                           forObject:self
                         synchronous:!sync];
    
    sleep(1); /* TODO: well NULL is only good for debugging anyway */
    report = [_router createReport];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:DELIVRD err:0",
                            msg.routerReference,
                            msg.submitDate ?    [formatter stringFromDate:msg.submitDate]:[formatter stringFromDate:[NSDate date]],
                            msg.attemptedDate ? [formatter stringFromDate:msg.attemptedDate]:[formatter stringFromDate:[NSDate date]]];
    report.reportType               = SMS_REPORT_DELIVERED;
    report.error                    = NULL;
    report.routerReference          = msg.routerReference;
    report.providerReference        = msg.providerReference;
    report.userReference            = msg.userReference;
    report.originalSendingObject    = msg.originalSendingObject;
    report.reportText               = reportText;
    report.source                   = msg.to;
    report.destination              = msg.from;
    [sendingObject deliverReport:report
                       forObject:self
                     synchronous:NO];
}

- (void) submitReport:(id<SmscConnectionReportProtocol>)report
            forObject:(id)sendingObject
          synchronous:(BOOL)sync
{
    [sendingObject submitReportSent:report
                          forObject:self
                        synchronous:!sync];
}

- (void) submitReportSent:(id<SmscConnectionReportProtocol>)report
                forObject:(id)reportingObject
              synchronous:(BOOL)sync
{
}

- (void) submitReportFailed:(id<SmscConnectionReportProtocol>)report
                  withError:(SmscRouterError *)err
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    
}

/* deliverMessage: router->inbound RX connection */
- (void) deliverMessage:(id<SmscConnectionMessageProtocol>)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    id<SmscConnectionReportProtocol> report = NULL;
    
    [sendingObject deliverMessageSent:msg
                            forObject:self
                          synchronous:!sync];
    report = [_router createReport];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:DELIVRD err:0",
                            msg.routerReference,
                            msg.submitDate ?    [formatter stringFromDate:msg.submitDate]:[formatter stringFromDate:[NSDate date]],
                            msg.attemptedDate ? [formatter stringFromDate:msg.attemptedDate]:[formatter stringFromDate:[NSDate date]]];
    report.reportType               = SMS_REPORT_DELIVERED;
    report.error                    = NULL;
    report.routerReference          = msg.routerReference;
    report.providerReference      = msg.providerReference;
    report.userReference            = msg.userReference;
    report.originalSendingObject    = msg.originalSendingObject;
    report.reportText               = reportText;
    report.source                   = msg.to;
    report.destination              = msg.from;
    [sendingObject submitReport:report
                      forObject:self
                    synchronous:NO];
}

- (void) deliverReport:(id<SmscConnectionReportProtocol>)report
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    [sendingObject deliverReportSent:report
                           forObject:self
                         synchronous:!sync];
}

- (void) deliverReportSent:(id<SmscConnectionReportProtocol>)report
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
}

- (void) deliverReportFailed:(id<SmscConnectionReportProtocol>)report
                   withError:(SmscRouterError *)err
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    
}


@end
