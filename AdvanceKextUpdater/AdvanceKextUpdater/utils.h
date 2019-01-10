//
//  utils.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/7/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef utils_h
#define utils_h

/// @function _fprintf
/// @abstract
/// Print to any <code>FILE</code> stream
/// @param stream
/// The file stream, can be any <code>FILE</code> stream or stdin/stdout/stderr
/// @param format
/// The string to be printed
void _fprintf(FILE *stream, NSString *format, ...);

/// @function _printf
/// @abstract
/// Print to stdout
/// @param format The string to be printed
void _printf(NSString *format, ...);

/// @function tty
/// @abstract
/// Run and get the output of a command
/// @param cmd
/// The command
/// @param output
/// Output in either NSString or NSArray or nil.
/// The variable must be initialize in order to use it.
/// @return
/// Exit code or (-1) on error
int tty(NSString *cmd, _Nullable id *output);

/// @function hasInternetConnection
/// @abstract
/// Check whether the user has active internet connection
/// @see https://stackoverflow.com/a/18750343/4147849
/// @return YES if user has an active internet connection, NO otherwise
BOOL hasInternetConnection(void);

/// @function isRootUser
/// @abstract
/// Whether the current user is the root user
/// @return
/// YES if root user, NO otherwise
BOOL isRootUser(void);

/// @function getMainUser
/// @abstract
/// Get the currently logged in user
/// @return
/// Username of the current user
NSString *getMainUser(void);

/// @function unzip
/// @abstract
/// Unzip a zip file to the target directory
/// @param zipFile
/// The path to the zip file
/// @param targetFolder
/// The target directory
/// @return
/// <code>YES</code> on success and <code>NO</code> on failure
BOOL unzip(NSString * zipFile, NSString * targetFolder);

/// @function find
/// @abstract
/// Find the location(s) of a kext
/// @discussion
/// Currently this function only searches at kSLE and kLE
/// @todo
/// - Add support for Clover, et all.
///
/// - Should've been an NSArray
///
/// - Add a cache mechanism/make multithreaded since `kextfind` takes a lot of time
/// @param kextName
/// Name of the kext: .kext extension is optional
/// @return
/// The location of the kext along with the kext name with extension, or <code>nil</code> on failure
NSString * _Nullable find(NSString * kextName);

/// @function isDarkMode
/// @abstract
/// Whether the system is running in Dark Mode
/// @return
/// YES if in Dark Mode, NO otherwise
BOOL isDarkMode(void);

@interface NSString (VersionNumbers)
/// @abstract
/// Shorten the version number, ie. remove unnecessary 0's
/// as they create problem when comparing with other version
/// @return
/// Shortened version
- (NSString *) shortenedVersionNumberString;
@end

@interface NSArray (MatchFromStringToRegex)
/// @abstract
/// Matches the given string using the array of RegEx string
/// @param string
/// The string to be matched
/// @return
/// YES if matches, NO otherwise
- (BOOL) usingArrayMemberAsRegexMatchString: (NSString *) string;
@end

#endif /* utils_h */
