//
//  SigAddr.h
//  UniversalSMSUtilitites
//
//  Created by Andreas Fink on 27.02.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

typedef	enum TonType
{
	TON_UNKNOWN 			= 0,
	TON_INTERNATIONAL	 	= 1,
	TON_NATIONAL 			= 2,
	TON_NETWORK_SPECIFIC	= 3,
	TON_SUBSCRIBER 			= 4,
	TON_ALPHANUMERIC 		= 5,
	TON_ABBREVIATED			= 6,
	TON_RESERVED 			= 7,
    TON_POINTCODE           = 103,
    TON_EMPTY               = 104,
} TonType;

typedef enum NpiType
{
	NPI_UNKNOWN				= 0,
	NPI_ISDN_E164			= 1,
	NPI_DATA_X121			= 3,	 	
	NPI_TELEX 				= 4,
	NPI_NATIONAL			= 8,
	NPI_PRIVATE				= 9,
	NPI_ERMES 				= 10,
	NPI_RESERVED 			= 15,
} NpiType;


typedef	enum NaiType
{
	NAI_UNKNOWN 		= 0,
	NAI_SUBSCRIBER 		= 1,
	NAI_RESERVED 		= 2,
	NAI_NATIONAL 		= 3,
	NAI_INTERNATIONAL 	= 4,
} NaiType;

@interface SigAddr : NSObject
{
	TonType		ton;
	NpiType		npi;
    int         pointcode;
	NSString	*addr;
    NSString    *debugString;
}

@property (readwrite,assign)	TonType		ton;
@property (readwrite,assign)	NpiType		npi;
@property (readwrite,retain)	NSString	*addr;
@property (readwrite,retain)	NSString	*debugString;


+ (SigAddr *) sigAddrFromString:(NSString *)digits;
- (SigAddr *) initWithString: (NSString *)digits;
- (SigAddr *) initWithInternationalString:(NSString *)digits;
- (SigAddr *) initWithAlpha: (NSString *)digits;
- (SigAddr *) initWithPackedAlpha: (NSData *)digits;
- (SigAddr *) initWithSigAddr: (SigAddr *)original;
- (NSString *)asString;
- (NSString *)asUrlEncodedString;
- (NSString *)asString:(int)formatType;	/* 0 = no prefix, 1 = with + for international, 2 = with 00 for international */
- (NSData *) asPackedAlpha;
- (SigAddr *) randomize; /* replaces X'es in the digits with random digits */
- (NSString *)description;
@end
