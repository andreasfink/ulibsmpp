//
//  TestUser.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 27.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestUser.h"

@implementation TestUser

@synthesize shortId;
@synthesize username;
@synthesize password;

- (BOOL) hasCredits
{
    return YES;
}

- (BOOL) withinSpeedlimit
{
    return YES;
}

- (void) removeCredits:(NSInteger)count
{
    
}
- (void) errorCounterIncrease
{
    
}

- (void)increase
{
    
}

- (NSString *)alphaCoding
{
    return nil;
}

-(void)addGlobalUser:(TestUser *)user
{
    if(globalUserList==NULL)
    {
        globalUserList = [[NSMutableDictionary alloc]init];
    }
    [globalUserList setObject:user forKey:user.username];
}


@end
