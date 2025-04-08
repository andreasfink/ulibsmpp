//
//  UMSigAddr.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>
#import <ulibasn1/ulibasn1.h>

typedef	enum UMTonType
{
	UMTON_UNKNOWN 			= 0,
	UMTON_INTERNATIONAL	 	= 1,
	UMTON_NATIONAL 			= 2,
	UMTON_NETWORK_SPECIFIC	= 3,
	UMTON_SUBSCRIBER        = 4,
	UMTON_ALPHANUMERIC 		= 5,
	UMTON_ABBREVIATED       = 6,
	UMTON_RESERVED 			= 7,
    UMTON_POINTCODE         = 103,
    UMTON_EMPTY             = 104,
} UMTonType;

typedef enum UMNpiType
{
	UMNPI_UNKNOWN           = 0,
    UMNPI_ISDN_E164			= 1,
    UMNPI_GENERIC			= 2,
	UMNPI_DATA_X121			= 3,
	UMNPI_TELEX             = 4,
	UMNPI_NATIONAL			= 8,
	UMNPI_PRIVATE           = 9,
	UMNPI_ERMES             = 10,
	UMNPI_RESERVED 			= 15,
} UMNpiType;


typedef	enum UMNaiType
{
	UMNAI_UNKNOWN 		= 0,
	UMNAI_SUBSCRIBER 		= 1,
	UMNAI_RESERVED 		= 2,
	UMNAI_NATIONAL 		= 3,
	UMNAI_INTERNATIONAL 	= 4,
} UMNaiType;

@interface UMSigAddr : UMASN1Sequence
{
	UMTonType		_ton;
	UMNpiType		_npi;
    NSNumber        *_pointcode;
	NSString	    *_addr;
    NSString	    *_debugString;
}

@property (readwrite,assign)	UMTonType		ton;
@property (readwrite,assign)	UMNpiType		npi;
@property (readwrite,strong)    NSNumber        *pointcode;
@property (readwrite,strong)	NSString        *addr;
@property (readwrite,strong)	NSString        *debugString;

+ (UMSigAddr *) sigAddrFromString:(NSString *)digits;
- (UMSigAddr *) initWithString: (NSString *)digits;
- (UMSigAddr *) initWithInternationalString:(NSString *)digits;
- (UMSigAddr *) initWithAlpha: (NSString *)digits;
- (UMSigAddr *) initWithPackedAlpha: (NSData *)digits;
- (UMSigAddr *) initWithSigAddr: (UMSigAddr *)original;
- (NSString *)asString;
- (NSString *)asUrlEncodedString;
- (NSString *)asString:(int)formatType;	/* 0 = no prefix, 1 = with + for international, 2 = with 00 for international */
- (NSData *) asPackedAlpha;
- (UMSigAddr *) randomize; /* replaces X'es in the digits with random digits */
- (NSString *)description;
@end
