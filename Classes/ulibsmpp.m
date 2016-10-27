//
//  ulibsmpp.m
//  ulibsmpp
//
//  Created by Andreas Fink on 10/05/14.
//
//

#import "ulibsmpp.h"
#import "../version.h"

@implementation ulibsmpp

+ (NSString *) ulibsmpp_version
{
    return @VERSION;
}

+ (NSString *) ulibsmpp_build
{
    return @BUILD;
}

+ (NSString *) ulibsmpp_builddate
{
    return @BUILDDATE;
}

+ (NSString *) ulibsmpp_compiledate
{
    return @COMPILEDATE;
}

@end
