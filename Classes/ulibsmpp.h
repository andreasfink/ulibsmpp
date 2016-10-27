//
//  ulibsmpp.h
//  ulibsmpp.h
//
//  Created by Andreas Fink on 01.03.09
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import "ulib/ulib.h"
#import "UniversalSMPP.h"
#import "UniversalEMIUCP.h"
#import "UniversalSMSC.h"
#import "UniversalSMPP.h"
#import "UniversalSMSUtilities.h"

@interface ulibsmpp : NSObject
{
    
}
+ (NSString *) ulibsmpp_version;
+ (NSString *) ulibsmpp_build;
+ (NSString *) ulibsmpp_builddate;
+ (NSString *) ulibsmpp_compiledate;
@end
