//
//  TestObject.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 09.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <ulib/ulib.h>

@class UMConfig, UMLogFeed;

@interface TestObject : UMObject

- (void) addLogFromCfg:(UMConfig *)cfg fromGroup:(NSString *)group fromVariable:(NSString *)variable  withSection:(NSString *)section withSubsection:(NSString *)ss withName:(NSString *)n;

@end