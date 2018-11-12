//
//  TestUser.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 27.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "SmscConnectionUserProtocol.h"
#import "TestObject.h"
#import "TestCounter.h"

@interface TestUser : UMObject<SmscConnectionUserProtocol>
{
    UMSigAddr *shortId;
    NSInteger credits;
    NSInteger limit;
    NSString *username;
    NSString *password;
    TestCounter *errorCounter;
    NSMutableDictionary *globalUserList;
}

@property(readwrite,retain) UMSigAddr *shortId;
@property(readwrite,retain) NSString *username;
@property(readwrite,retain) NSString *password;

- (void)addGlobalUser:(TestUser *)user;
- (BOOL) hasCredits;
- (BOOL) withinSpeedlimit;
- (void) removeCredits:(NSInteger)count;
- (void) errorCounterIncrease;

@end
