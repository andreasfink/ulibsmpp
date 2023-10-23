//
//  NSString+UniversalSMPP.h
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

@interface NSString(UniversalSMPP)
- (int) checkRange:(NSRange)range withFunction:(range_func_t2)filter;
- (long) integer16Value;
- (BOOL)hasOnlyDecimalDigits;
- (BOOL)hasOnlyHexDigits;
@end
