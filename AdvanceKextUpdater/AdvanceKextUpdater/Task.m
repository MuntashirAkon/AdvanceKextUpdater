//
//  Task.m
//
//  This is a modified version of the original Task.m of DPCIManager
//
//  Created by PHPdev32 on 10/13/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import "Task.h"
#import <sys/socket.h>
#import <ifaddrs.h>
#import <net/if_dl.h>
#import <net/if_types.h>
#import "JSONParser.h"

@implementation AScript

+(NSString *)tempFile:(NSString *)template{
    char *temp = (char *)[[NSTemporaryDirectory() stringByAppendingPathComponent:template] fileSystemRepresentation];
    close(mkstemps(temp, (int)template.pathExtension.length+1));
    unlink(temp);
    return [NSFileManager.defaultManager stringWithFileSystemRepresentation:temp length:strlen(temp)];
}

// Potentially vulnerable!!!
+(NSAppleEventDescriptor *)adminExec:(NSString *)command{
    NSDictionary *error;
    NSAppleEventDescriptor *evt = [[[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", command]] executeAndReturnError:&error];
    if(!evt)
        @throw [NSError errorWithDomain:APP_NAME code:232 userInfo:@{
             @"details": [error objectForKey:@"NSAppleScriptErrorBriefMessage"]
        }];
    return evt;
}
+(NSAppleEventDescriptor *)loadKext:(NSString *)kext{
    NSError *err;
    NSString *path = [AScript tempFile:@"DPCIXXXXX.kext"];
    if (![NSFileManager.defaultManager copyItemAtPath:kext toPath:path error:&err])
    if (ModalError(err)) return nil;
    [self recursivePermissions:path files:0644 directories:0755];
    return [self adminExec:[NSString stringWithFormat:@"/usr/sbin/chown -R 0:0 '%@';/sbin/kextload '%@';while :;do if kill -0 %d;then sleep 5;else /sbin/kextunload '%@';/bin/rm -rf '%@';break;fi;done &>/dev/null&", path, path, NSProcessInfo.processInfo.processIdentifier, path, path]];
}
+(void)recursivePermissions:(NSString *)path files:(short)files directories:(short)directories{
    BOOL isDir;
    NSFileManager *mgr = NSFileManager.defaultManager;
    NSDictionary *file = @{NSFilePosixPermissions:[NSNumber numberWithShort:files]};
    NSDictionary *directory = @{NSFilePosixPermissions:[NSNumber numberWithShort:directories]};
    if ([mgr fileExistsAtPath:path isDirectory:&isDir] && isDir)
        [mgr setAttributes:directory ofItemAtPath:path error:nil];
    else
        [mgr setAttributes:file ofItemAtPath:path error:nil];
    for(__strong NSString *item in [mgr enumeratorAtPath:path]) {
        item = [path stringByAppendingPathComponent:item];
        if ([mgr fileExistsAtPath:item isDirectory:&isDir] && isDir)
            [mgr setAttributes:directory ofItemAtPath:item error:nil];
        else
            [mgr setAttributes:file ofItemAtPath:item error:nil];
    }
}

@end

@implementation URLTask

@synthesize connection;
@synthesize hold;
@synthesize progress;
@synthesize successBlock;
@synthesize errorBlock;

+(NSURL *)getURL:(NSString *)url withQuery:(NSDictionary *)dict{
    NSMutableArray *temp = [NSMutableArray array];
    for (NSString *key in dict)
        [temp addObject:[NSString stringWithFormat:@"%@=%@", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[dict objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", url, [temp componentsJoinedByString:@"&"]]];
}
+(NSDictionary *)getMACs{
    struct ifaddrs *addrs;
    if (getifaddrs(&addrs)) return nil;
    NSMutableDictionary *macs = [NSMutableDictionary dictionary];
    struct ifaddrs *current = addrs;
    while (current) {
        struct sockaddr_dl *addr = (struct sockaddr_dl *)current->ifa_addr;
        if (current->ifa_addr->sa_family == AF_LINK && addr->sdl_type == IFT_ETHER) {
            [macs setObject:[NSString stringWithFormat:@"%02hhX:%02hhX:%02hhX:%02hhX:%02hhX:%02hhX", addr->sdl_data[addr->sdl_nlen], addr->sdl_data[addr->sdl_nlen+1], addr->sdl_data[addr->sdl_nlen+2], addr->sdl_data[addr->sdl_nlen+3], addr->sdl_data[addr->sdl_nlen+4], addr->sdl_data[addr->sdl_nlen+5]] forKey:[[NSString alloc] initWithBytes:addr->sdl_data length:addr->sdl_nlen encoding:NSASCIIStringEncoding]];
        }
        current = current->ifa_next;
    }
    freeifaddrs(addrs);
    return [macs copy];
}

+(bool)conditionalGet:(NSURL *)url toFile:(NSString *)file {
    return [self conditionalGet:url toFile:file supress:NO];
}

+(bool)conditionalGet:(NSURL *)url toFile:(NSString *)file supress:(BOOL) suppressErr {
    NSError *err;
    // Creat file if not exists
    if(![NSFileManager.defaultManager fileExistsAtPath:file])
        [NSFileManager.defaultManager createFileAtPath:file contents:nil attributes:nil];
    NSDate *filemtime = [[NSFileManager.defaultManager attributesOfItemAtPath:file error:&err] fileModificationDate];
    if (err != nil) return [self revert:file error:err suppress:suppressErr];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    NSHTTPURLResponse *response;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (err != nil) return [self revert:file error:err suppress:suppressErr];
    NSString *urlmstr = [response.allHeaderFields objectForKey:@"Last-Modified"];
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    NSDate *urlmtime = [df dateFromString:urlmstr];
    bool changed = ([filemtime compare:urlmtime] == NSOrderedAscending);
    if (changed){
        if (![[NSData dataWithContentsOfURL:url] writeToFile:file options:NSDataWritingAtomic error:&err]){
            if (err != nil) return [self revert:file error:err suppress:suppressErr];
        }
    }
    if (![NSFileManager.defaultManager setAttributes:@{NSFileModificationDate: urlmtime} ofItemAtPath:file error:&err]){
        if (err != nil) return [self revert:file error:err suppress:suppressErr];
    }
    return changed;
}

+(id)getJSON:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    if(data == nil) return nil;
    NSString *jsonString = [NSString.alloc initWithUTF8String:[data bytes]];
    if (jsonString == nil) return nil;
    return [JSONParser parse:jsonString];
}

+(bool)get:(NSURL *)url toFile:(NSString *)file {
    return [self conditionalGet:url toFile:file supress:NO];
}
    
+(bool)get:(NSURL *)url toFile:(NSString *)file supress:(BOOL) suppressErr {
    NSError *err;
    // Create file if not exists
    if(![NSFileManager.defaultManager fileExistsAtPath:file])
    [NSFileManager.defaultManager createFileAtPath:file contents:nil attributes:nil];
    if (![[NSData dataWithContentsOfURL:url] writeToFile:file options:NSDataWritingAtomic error:&err]){
        if (err != nil) return [self revert:file error:err suppress:suppressErr];
    }
    return true;
}

+ (bool) revert: (NSString *)file error: (NSError *) err suppress: (BOOL) suppressErr {
    if(!suppressErr) {
        ModalError(err);
    }
    [NSFileManager.defaultManager removeItemAtPath:file error:nil];
    return false;
}

+(URLTask *)asyncUpload:(NSURLRequest *)request withMode:(NSString *)mode onSuccess:(void(^)(NSData *data))successBlock onError:(void(^)(NSError *error))errorBlock{
    URLTask *temp = [URLTask new];
    temp.successBlock = successBlock;
    temp.errorBlock = errorBlock;
    temp.connection = [[NSURLConnection alloc] initWithRequest:request delegate:temp startImmediately:false];
    [temp.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:!mode?NSDefaultRunLoopMode:mode];
    [temp.connection start];
    return temp;
}
#pragma mark NSURLConnectionDataDelegate
-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
    self.progress = @(totalBytesWritten*100/totalBytesExpectedToWrite);
}

#pragma mark NSURLConnectionDelegate
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    if (!hold) hold = [NSMutableData data];
    [hold appendData:data];
}
-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    self.progress = nil;
    successBlock([NSData dataWithData:hold]);
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    self.progress = nil;
    errorBlock(error);
}

@end
