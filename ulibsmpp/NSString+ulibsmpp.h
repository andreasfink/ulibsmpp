//
//  NSString+ulibsmpp.h
//  ulibsmpp
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#define UUID_STR_LEN 36
#ifndef range_func_t
typedef int (*range_func_t2)(int);
#endif

@interface NSString(ulibsmpp)
- (int)smppCheckRange:(NSRange)range withFunction:(range_func_t2)filter;
- (long)smppInteger16Value;
- (BOOL)smppHasOnlyDecimalDigits;
-(BOOL)smppHasOnlyHexDigits;
- (NSString *)smppRandomize;
- (NSString *)smppHex;
+ (int)smppNibbleToInt:(char)c;
- (NSString *)smppUnhex;
- (NSData *)smppUnhexData;
- (NSMutableData *)smppGsm8;
- (NSMutableData *)smppGsm7WithNibbleLenPrefix;
- (NSMutableData *)smppGsm7: (int *)nibblelen;
- (NSMutableData *)smppGsm16;
- (NSString *)smppUrlencode;

@end
