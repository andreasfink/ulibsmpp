//
//  SmppMultiResult.h
//  ulibsmpp
//
//  Created by Andreas Fink on 28/03/14.
//
//

#import "ulib/ulib.h"
#import "SmppErrorCode.h"

@class UMSigAddr;

@interface SmppMultiResult : UMObject
{
	UMSigAddr				*dst;
	SmppErrorCode		    err;
}
@property(readwrite,strong)	UMSigAddr				*dst;
@property(readwrite,assign)	SmppErrorCode		err;

@end




