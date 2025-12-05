//
//  SmppMultiResult.h
//  ulibsmpp
//
//  Created by Andreas Fink on 28/03/14.
//
//

#import <ulib/ulib.h>
#import <ulibsmpp/UMSmppError.h>

@class UMSigAddr;

@interface SmppMultiResult : UMObject
{
	UMSigAddr				*dst;
    UMSmppError		    err;
}
@property(readwrite,strong)	UMSigAddr				*dst;
@property(readwrite,assign)	UMSmppError		err;

@end




