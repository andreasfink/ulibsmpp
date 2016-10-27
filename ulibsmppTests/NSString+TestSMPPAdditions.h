//
//  NSString+TestSMPPAdditions.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 21.09.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#define UUID_STR_LEN 36

typedef int (*range_func_t)(int);

@interface NSString (TestSMPPAdditions)

- (int) checkRange:(NSRange)range withFunction:(range_func_t)filter;

@end

@interface NSMutableString (TestSMPPAdditions)

- (int) checkRange:(NSRange)range withFunction:(range_func_t)filter;
- (long) integer16Value;

@end
