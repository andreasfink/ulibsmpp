//
//  SmscConnectionFAIL.h
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC implementation which always return a failed delivery report

#import <ulibsmpp/SmscConnection.h>
#import <ulibsmpp/SmscConnectionMessagePassingProtocol.h>
#import <ulibsmpp/UMSmppError.h>


@interface SmscConnectionFAIL : SmscConnection
{
    UMSmppError errorToReturn;
}

@property(readwrite,assign)     UMSmppError errorToReturn;

@end
