//
//  SmscStandardReport.m
//  ulibsmpp
//
//  Created by Andreas Fink on 14.11.14.
//
//

#import "SmscStandardReport.h"

@implementation SmscStandardReport

@synthesize userReference;
@synthesize routerReference;
@synthesize providerReference;
@synthesize destination;
@synthesize source;
@synthesize reportText;
@synthesize reportType;
@synthesize error;

@synthesize priority;
@synthesize originalSendingObject;
@synthesize imsi;
@synthesize msc;
@synthesize mcc;
@synthesize mnc;
@synthesize responseCode;
@synthesize reportToMsg;
@synthesize reportTypeAsString;
@synthesize currentTransaction;

- (NSString *)responseCodeToString
{
    return [NSString stringWithFormat:@"%d",responseCode];
}
@end

