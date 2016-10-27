//
//  NSMutableString+UniversalSMPP.m
//  ulibsmpp
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import "NSMutableString+UniversalSMPP.h"
#import "NSString+UniversalSMPP.h"

@implementation NSMutableString (UniversalSMPP)

- (int) checkRange:(NSRange)range withFunction:(range_func_t)filter
{
    long end = range.location + range.length;
    long pos;
    
    if (range.location >= [self length])
        return 1;
    if (end > [self length])
        end = [self length];
    
    pos = range.location;
    for ( ; pos < end; pos++)
    {
        if (!filter([self characterAtIndex:pos]))
            return 0;
    }
    
    return 1;
}

- (long) integer16Value
{
    long number;
    char *endptr;
    
    int eno = 0;
    number = strtol([self UTF8String], &endptr, 16);
    eno = errno;
    if (eno == ERANGE)
    {
        return -1;
    }
    return number;
}

- (void)stripBlanks
{
#ifdef LINUX
    /* TODO: we should have an alternative implementation */
#else
    CFStringTrimWhitespace ((CFMutableStringRef)self);
#endif
}

@end
