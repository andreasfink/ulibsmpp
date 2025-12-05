//
//  SmscConnectionNACK.m
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC which always return Failed

#import <ulib/ulib.h>
#include <sys/signal.h>
#include <unistd.h> /* for usleep */
#import <ulibsmpp/SmscConnectionNACK.h>
<<<<<<< HEAD:ulibsmpp/SmscConnectionNACK.m
#import <ulibsmpp/NSMutableString+ulibsmpp.h>
#import <ulibsmpp/NSString+ulibsmpp.h>
=======
#import <ulibsmpp/NSMutableString+UniversalSMPP.h>
#import <ulibsmpp/NSString+UniversalSMPP.h>
#import <ulibsmpp/UMSmppError.h>
>>>>>>> release-6.0:ulibsmpp6/SmscConnectionNACK.m

@implementation SmscConnectionNACK


- (SmscConnectionNACK *)init
{
    self=[super init];
    if(self)
    {
        [super setVersion: @"1.0"];
        [super setType: @"nack"];
        self.lastActivity =[NSDate new];
    }
    return self;
}

- (NSString *)_type
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
        [_router registerOutgoingSmscConnection:self];
    }
}

/* submit Message: router->outbound TX connection */
- (void) submitMessage:(UMMessageObject *)msg
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    [sendingObject submitMessageFailed:msg
                                 error:@(UM_ESME_RUNKNOWNERR)
                             forObject:self
                           synchronous:NO];
}

- (void) submitReport:(UMMessageReport *)report
            forObject:(id)sendingObject
          synchronous:(BOOL)sync
{
    [sendingObject submitReportFailed:report
                                error:@(UM_ESME_RUNKNOWNERR)
                            forObject:self
                          synchronous:NO];
}

- (void) submitReportSent:(UMMessageReport *)report
                forObject:(id)reportingObject
              synchronous:(BOOL)sync
{
}

- (void) submitReportFailed:(UMMessageReport *)report
                      error:(NSNumber *)error
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    
}

/* deliverMessage: router->inbound RX connection */
- (void) deliverMessage:(UMMessageObject *)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    [sendingObject deliverMessageFailed:msg
                                  error:@(UM_ESME_RUNKNOWNERR)
                              forObject:self
                            synchronous:NO];
}

- (void) deliverReport:(UMMessageReport *)report
             forObject:(id)sendingObject
{
    [sendingObject deliverReportFailed:report
                                 error:@(UM_ESME_RUNKNOWNERR)
                             forObject:self
                           synchronous:NO];
}

- (void) deliverReportSent:(UMMessageReport *)report
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
}

- (void) deliverReportFailed:(UMMessageReport *)report
                       error:(NSNumber *)error
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    
}


@end
