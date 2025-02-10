//
//  SmscStandardReport.m
//  ulibsmpp
//
//  Created by Andreas Fink on 14.11.14.
//
//

#import "SmscStandardReport.h"

@implementation SmscStandardReport

- (NSString *)responseCodeToString
{
    return [NSString stringWithFormat:@"%d",_responseCode];
}


@end

