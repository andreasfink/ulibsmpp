//
//  NSData+ulibsmpp.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//


#import <Foundation/Foundation.h>
#import <ulibsmpp/NSString+ulibsmpp.h>

@interface NSData (ulibsmpp)


- (NSString *)smppHexString;
- (NSString *)smppGsmHexString;
+ (NSData *)smppUnhexFromString:(NSString *)str;
- (NSData *)smppUnhex;
- (NSData *)smppHex;
-(NSString *)smppStringFromGsm8;
-(NSString *)smppStringFromGsm7withNibbleLengthPrefix;
-(NSString *)smppStringFromGsm7:(int)nibblelen;
- (NSMutableData *)smppGsm7to8:(int)nibblelen;
- (NSMutableData *)smppGsm8to7: (int *)nibblelen;
- (NSMutableData *)smppGsm8to7withNibbleLengthPrefix;

@end
