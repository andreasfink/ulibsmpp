//
//  SmscConnectionUserProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulibsmpp/UniversalSMSUtilities.h>

@protocol SmscConnectionUserProtocol<NSObject>

- (UMSigAddr *)shortId;
- (BOOL) hasCredits;
- (BOOL) withinSpeedlimit;
- (void) increase; /* counter for speed limit */
- (void) removeCredits:(NSInteger)count;
- (NSString *) username;
- (NSString *) password;
- (void) errorCounterIncrease;
- (NSString *)alphaCoding;

@optional
- (BOOL)tracing;
- (NSString *)tracePath;
@end
