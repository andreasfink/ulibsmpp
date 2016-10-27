//
//  NSMutableString+SmscConnection.h
//  ulibsmpp
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>
#ifndef range_func_t
typedef int (*range_func_t)(int);
#endif

@interface NSMutableString(UniversalSMPP)
- (int) checkRange:(NSRange)range withFunction:(range_func_t)filter;
- (void)stripBlanks;
- (long) integer16Value;

@end
