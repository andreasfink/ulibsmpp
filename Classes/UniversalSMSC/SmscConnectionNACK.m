//
//  SmscConnectionNACK.m
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC which always return Failed

#import "SmscConnectionNACK.h"
#import <ulib/ulib.h>
#include <sys/signal.h>
#include <unistd.h> /* for usleep */
#import "NSMutableString+UniversalSMPP.h"
#import "NSString+UniversalSMPP.h"

@implementation SmscConnectionNACK


- (SmscConnectionNACK *)init
{
    self=[super init];
    if(self)
    {
        [super setVersion: @"1.0"];
        [super setType: @"nack"];
        self.lastActivity =[NSDate date];
    }
    return self;
}

- (NSString *)type
{
    return @"nack";
}

- (NSString *) getType
{
    return @"nack";
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
    dict[PREFS_CON_PROTO] = @"nack";
    return dict;
}



- (NSDictionary *) getClientConfig
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] init];
    dict[PREFS_CON_NAME] = @"nack";
    return dict;
}

+ (NSDictionary *) getDefaultConnectionConfig
{
    NSDictionary *smppConnectionDict;
    
    smppConnectionDict = @{ PREFS_CON_NAME : @"nack" };
    return smppConnectionDict;
}

+ (NSDictionary *) getDefaultListenerConfig
{
    return @{ PREFS_CON_NAME : @"nack" };
}

#pragma mark sendingPDUs

- (NSString *)connectedFrom
{
    return @"nack";
}

- (NSString *)connectedTo
{
    return @"nack";
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
    SmscRouterError *err = [router createError];
    if(err==NULL)
    {
        err = [[SmscRouterError alloc]init];
    }
    [err setSmppErrorCode:ESME_RUNKNOWNERR];
    [sendingObject submitMessageFailed:msg
                             withError:err
                             forObject:self
                           synchronous:NO];
}

- (void) submitReport:(id<SmscConnectionReportProtocol>)report
            forObject:(id)sendingObject
          synchronous:(BOOL)sync
{
    SmscRouterError *err = [router createError];
    if(err==NULL)
    {
        err = [[SmscRouterError alloc]init];
    }
    [err setSmppErrorCode:ESME_RUNKNOWNERR];
    [sendingObject submitReportFailed:report
                            withError:err
                            forObject:self
                          synchronous:NO];
}

- (void) submitReportSent:(id<SmscConnectionReportProtocol>)report
                forObject:(id)reportingObject
              synchronous:(BOOL)sync
{
}

- (void) submitReportFailed:(id<SmscConnectionReportProtocol>)report
                  withError:(SmscRouterError *)code
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    
}

/* deliverMessage: router->inbound RX connection */
- (void) deliverMessage:(id<SmscConnectionMessageProtocol>)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    SmscRouterError *err = [router createError];
    if(err==NULL)
    {
        err = [[SmscRouterError alloc]init];
    }
    [err setSmppErrorCode:ESME_RUNKNOWNERR];

    [sendingObject deliverMessageFailed:msg
                              withError:err
                              forObject:self
                            synchronous:NO];
}

- (void) deliverReport:(id<SmscConnectionReportProtocol>)report
             forObject:(id)sendingObject
{
    SmscRouterError *err = [router createError];
    if(err==NULL)
    {
        err = [[SmscRouterError alloc]init];
    }
    [err setSmppErrorCode:ESME_RUNKNOWNERR];

    [sendingObject deliverReportFailed:report
                             withError:err
                             forObject:self
                           synchronous:NO];
}

- (void) deliverReportSent:(id<SmscConnectionReportProtocol>)report
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
}

- (void) deliverReportFailed:(id<SmscConnectionReportProtocol>)report
                   withError:(SmscRouterError *)code
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    
}


@end
