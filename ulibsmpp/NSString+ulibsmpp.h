//
//  NSString+smppFunctions.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/ulib.h>

#define UUID_STR_LEN 36
#ifndef range_func_t
typedef int (*range_func_t2)(int);
#endif


@interface NSString (ulibsmpp)

+ (int) smppNibbleToInt:(char)c;
- (NSString *) smppUrlencode;
- (NSData *) smppUnhexData;
- (NSMutableData *) smppGsm16;
- (NSMutableData *) smppGsm8;
- (NSMutableData *) smppGsm7:(int *)nibblelen;
- (NSMutableData *) smppGsm7WithNibbleLenPrefix;
- (NSString *) smppRandomize;

- (int)smppCheckRange:(NSRange)range withFunction:(range_func_t2)filter;
- (long)smppInteger16Value;
- (BOOL)smppHasOnlyDecimalDigits;
-(BOOL)smppHasOnlyHexDigits;

@end
