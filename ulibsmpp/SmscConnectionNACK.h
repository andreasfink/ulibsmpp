//
//  SmscConnectionNACK.h
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC which always return NACK on submit or deliver

#import <ulibsmpp/SmscConnection.h>
#import <ulibsmpp/SmscConnectionMessagePassingProtocol.h>

@interface SmscConnectionNACK : SmscConnection

@end
