//
//  SmscConnectionUserProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "UniversalSMSUtilities.h"

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
