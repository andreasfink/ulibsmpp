//
//  ulibsmpp.h
//  ulibsmpp.h
//
//  Created by Andreas Fink on 01.03.09
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import <ulib/ulib.h>
#import <ulibsmpp/UniversalSMSC.h>
#import <ulibsmpp/UniversalSMPP.h>
#import <ulibsmpp/UniversalEMIUCP.h>
#import <ulibsmpp/UniversalSMSUtilities.h>

@interface ulibsmpp : NSObject
{
    
}
+ (NSString *) ulibsmpp_version;
+ (NSString *) ulibsmpp_build;
+ (NSString *) ulibsmpp_builddate;
+ (NSString *) ulibsmpp_compiledate;
@end
