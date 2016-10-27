//
//  SmscConnectionNULL.m
//  ulibsmpp
//
//  Created by Andreas Fink on 14.11.14.
//
//

#import <ulib/ulib.h>
#import "SmscConnectionNULL.h"
#include <sys/signal.h>
#include <unistd.h> /* for usleep */
#import "NSMutableString+UniversalSMPP.h"
#import "NSString+UniversalSMPP.h"

@implementation SmscConnectionNULL

- (SmscConnectionNULL *)init
{
    if((self=[super init]))
    {
        [super setVersion: @"1.0"];
        [super setType: @"null"];
        self.lastActivity =[NSDate date];
    }
    return self;
}

- (NSString *)type
{
    return @"null";
}

- (NSString *) getType
{
    return @"null";
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
    dict[PREFS_CON_PROTO] = @"null";
    return dict;
}



- (NSDictionary *) getClientConfig
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] init];
    dict[PREFS_CON_NAME] = @"null";
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
    return @{ PREFS_CON_NAME : @"null" };
}

#pragma mark sendingPDUs

- (NSString *)connectedFrom
{
    return @"null";
}
    
- (NSString *)connectedTo
{
    return @"null";
}

- (void) outbound
{
    /* first, register self to sms router */
    @autoreleasepool
    {
        [self setIsInbound:NO];
        [router registerOutgoingSmscConnection:self];
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
    report = [router createReport];
    
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
    report.currentTransaction       = msg.routerTransaction;
    
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
                          synchronous:NO];
    report = [router createReport];
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

    [sendingObject submitReport:report forObject:self synchronous:NO];
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
