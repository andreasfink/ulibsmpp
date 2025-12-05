//
//  NSMutableString+ulibsmpp.h
//  ulibsmpp
//
//  Created by Andreas Fink on 23.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/framework.h>
#ifndef range_func_t
typedef int (*range_func_t)(int);
#endif

@interface NSMutableString(ulibsmpp)
<<<<<<< HEAD:ulibsmpp6/NSMutableString+ulibsmpp.h
- (int)smppCheckRange:(NSRange)range withFunction:(range_func_t)filter;
- (void)smppStripBlanks;
- (long)smppInteger16Value;
=======
<<<<<<<< HEAD:ulibsmpp6/NSMutableString+UniversalSMPP.h
- (int)smppCheckRange:(NSRange)range withFunction:(range_func_t)filter;
- (void)smppStripBlanks;
- (long)smppInteger16Value;
========
- (int) checkRange:(NSRange)range withFunction:(range_func_t)filter;
- (void)stripBlanks;
- (long) integer16Value;
>>>>>>>> release-6.0:ulibsmpp/NSMutableString+ulibsmpp.h
>>>>>>> release-6.0:ulibsmpp/NSMutableString+ulibsmpp.h

@end
