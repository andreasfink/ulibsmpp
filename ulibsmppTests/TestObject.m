//
//  TestObject.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 09.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "TestObject.h" 


#import "ulib/UMLogHandler.h"
#import "ulib/UMLogFeed.h"
#import "ulib/UMConfig.h"
#import "TestLogFile.h"

@implementation TestObject

- (void) addLogFromCfg:(UMConfig *)cfg fromGroup:(NSString *)group fromVariable:(NSString *)variable  withSection:(NSString *)isection withSubsection:(NSString *)ss withName:(NSString *)n
{
    NSString *logFile;
    UMLogHandler *handler;
    TestLogFile *dst;
    
    NSDictionary *grp = [cfg getSingleGroup:group];
    if (!grp)
    {
        NSString *msg = [NSString stringWithFormat:@"configuration file must have group %@", group];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:msg userInfo:nil];
    }
    
    logFile = [grp objectForKey:@"log-file"];
    
    handler = [[UMLogHandler alloc] initWithConsole];
    dst = [[TestLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
    logFeed = [[UMLogFeed alloc] initWithHandler:handler section:isection subsection:ss];
    [handler addLogDestination:dst];
}

@end

