//
//  Task.h
//
//  Created by PHPdev32 on 10/13/12.
//  Modified by Muntashir Al-Islam
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//
#import <Foundation/Foundation.h>
@interface AScript : NSObject

+(NSString *)tempFile:(NSString *)template;
+(NSAppleEventDescriptor *)adminExec:(NSString *)command;
+(NSAppleEventDescriptor *)loadKext:(NSString *)path;

@end

@interface URLTask : NSObject <NSURLConnectionDelegate
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_7
, NSURLConnectionDataDelegate
#endif
>

@property NSURLConnection *connection;
@property NSMutableData *hold;
@property NSNumber *progress;
@property (copy, nonatomic) void (^successBlock)(NSData *data);
@property (copy, nonatomic) void (^errorBlock)(NSError *error);

+(bool)conditionalGet:(NSURL *)url toFile:(NSString *)file;
+(bool)conditionalGet:(NSURL *)url toFile:(NSString *)file supress:(BOOL) suppressErr;
+(id)getJSON:(NSURL *)url;
+(bool)get:(NSURL *)url toFile:(NSString *)file;
+(bool)get:(NSURL *)url toFile:(NSString *)file supress:(BOOL) suppressErr;
+(NSDictionary *)getMACs;
+(NSURL *)getURL:(NSString *)url withQuery:(NSDictionary *)dict;
+(URLTask *)asyncUpload:(NSURLRequest *)request withMode:(NSString *)mode onSuccess:(void(^)(NSData *data))successBlock onError:(void(^)(NSError *error))errorBlock;

@end
