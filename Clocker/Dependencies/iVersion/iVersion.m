//
//  iVersion.m
//
//  Version 1.11.4
//
//  Created by Nick Lockwood on 26/01/2011.
//  Copyright 2011 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/iVersion
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "iVersion.h"


#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"
#pragma clang diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
#pragma clang diagnostic ignored "-Wunused-macros"
#pragma clang diagnostic ignored "-Wconversion"
#pragma clang diagnostic ignored "-Wselector"
#pragma clang diagnostic ignored "-Wshadow"
#pragma clang diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


NSString *const iVersionErrorDomain = @"iVersionErrorDomain";

NSString *const iVersionInThisVersionTitleKey = @"iVersionInThisVersionTitle";
NSString *const iVersionUpdateAvailableTitleKey = @"iVersionUpdateAvailableTitle";
NSString *const iVersionVersionLabelFormatKey = @"iVersionVersionLabelFormat";
NSString *const iVersionOKButtonKey = @"iVersionOKButton";
NSString *const iVersionIgnoreButtonKey = @"iVersionIgnoreButton";
NSString *const iVersionRemindButtonKey = @"iVersionRemindButton";
NSString *const iVersionDownloadButtonKey = @"iVersionDownloadButton";

static NSString *const iVersionAppStoreIDKey = @"iVersionAppStoreID";
static NSString *const iVersionLastVersionKey = @"iVersionLastVersionChecked";
static NSString *const iVersionIgnoreVersionKey = @"iVersionIgnoreVersion";
static NSString *const iVersionLastCheckedKey = @"iVersionLastChecked";
static NSString *const iVersionLastRemindedKey = @"iVersionLastReminded";

static NSString *const iVersionMacAppStoreBundleID = @"com.apple.appstore";
static NSString *const iVersionAppLookupURLFormat = @"http://itunes.apple.com/%@/lookup";

static NSString *const iVersioniOSAppStoreURLFormat = @"itms-apps://itunes.apple.com/app/id%@";
static NSString *const iVersionMacAppStoreURLFormat = @"macappstore://itunes.apple.com/app/id%@";


#define SECONDS_IN_A_DAY 86400.0
#define MAC_APP_STORE_REFRESH_DELAY 5.0
#define REQUEST_TIMEOUT 60.0


@implementation NSString(iVersion)

- (NSComparisonResult)compareVersion:(NSString *)version
{
  return [self compare:version options:NSNumericSearch];
}

- (NSComparisonResult)compareVersionDescending:(NSString *)version
{
  return (NSComparisonResult)(0 - [self compareVersion:version]);
}

@end

static NSString *mostRecentVersionInDict(NSDictionary *dictionary)
{
  return [dictionary.allKeys sortedArrayUsingSelector:@selector(compareVersion:)].lastObject;
}

@interface iVersion ()

@property (nonatomic, copy) NSDictionary *remoteVersionsDict;
@property (nonatomic, strong) NSError *downloadError;
@property (nonatomic, copy) NSString *versionDetails;
@property (nonatomic, strong) id visibleLocalAlert;
@property (nonatomic, strong) id visibleRemoteAlert;
@property (nonatomic, assign) BOOL checkingForNewVersion;

@end


@implementation iVersion

+ (void)load
{
  [self performSelectorOnMainThread:@selector(sharedInstance) withObject:nil waitUntilDone:NO];
}

+ (iVersion *)sharedInstance
{
  static iVersion *sharedInstance = nil;
  if (sharedInstance == nil)
  {
    sharedInstance = [[iVersion alloc] init];
  }
  return sharedInstance;
}

- (NSString *)localizedStringForKey:(NSString *)key withDefault:(NSString *)defaultString
{
  static NSBundle *bundle = nil;
  if (bundle == nil)
  {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"iVersion" ofType:@"bundle"];
    if (self.useAllAvailableLanguages)
    {
      bundle = [NSBundle bundleWithPath:bundlePath];
      NSString *language = [NSLocale preferredLanguages].count? [NSLocale preferredLanguages][0]: @"en";
      if (![bundle.localizations containsObject:language])
      {
        language = [language componentsSeparatedByString:@"-"][0];
      }
      if ([bundle.localizations containsObject:language])
      {
        bundlePath = [bundle pathForResource:language ofType:@"lproj"];
      }
    }
    bundle = [NSBundle bundleWithPath:bundlePath] ?: [NSBundle mainBundle];
  }
  defaultString = [bundle localizedStringForKey:key value:defaultString table:nil];
  return [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
}

- (iVersion *)init
{
  if ((self = [super init]))
  {
    //get country
    self.appStoreCountry = [(NSLocale *)[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    if ([self.appStoreCountry isEqualToString:@"150"])
    {
      self.appStoreCountry = @"eu";
    }
    else if ([self.appStoreCountry stringByReplacingOccurrencesOfString:@"[A-Za-z]{2}" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, 2)].length)
    {
      self.appStoreCountry = @"us";
    }
    
    //application version (use short version preferentially)
    self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if ((self.applicationVersion).length == 0)
    {
      self.applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    }
    
    //bundle id
    self.applicationBundleID = [NSBundle mainBundle].bundleIdentifier;
    
    //default settings
    self.updatePriority = iVersionUpdatePriorityDefault;
    self.useAllAvailableLanguages = YES;
    self.onlyPromptIfMainWindowIsAvailable = YES;
    self.checkAtLaunch = YES;
    self.checkPeriod = 0.0f;
    self.remindPeriod = 1.0f;
    self.verboseLogging = YES;
    
#ifdef DEBUG
    
    //enable verbose logging in debug mode
    self.verboseLogging = YES;
    
#endif
    
    //app launched
    [self performSelectorOnMainThread:@selector(applicationLaunched) withObject:nil waitUntilDone:NO];
  }
  return self;
}

- (id<iVersionDelegate>)delegate
{
  if (_delegate == nil)
  {
    _delegate = (id<iVersionDelegate>)[NSApplication sharedApplication].delegate;
  }
  return _delegate;
}

- (NSString *)inThisVersionTitle
{
  return _inThisVersionTitle ?: [self localizedStringForKey:iVersionInThisVersionTitleKey withDefault:@"New in this version"];
}

- (NSString *)updateAvailableTitle
{
  return _updateAvailableTitle ?: [self localizedStringForKey:iVersionUpdateAvailableTitleKey withDefault:@"New version available"];
}

- (NSString *)versionLabelFormat
{
  return _versionLabelFormat ?: [self localizedStringForKey:iVersionVersionLabelFormatKey withDefault:@"Version %@"];
}

- (NSString *)okButtonLabel
{
  return _okButtonLabel ?: [self localizedStringForKey:iVersionOKButtonKey withDefault:@"OK"];
}

- (NSString *)ignoreButtonLabel
{
  return _ignoreButtonLabel ?: [self localizedStringForKey:iVersionIgnoreButtonKey withDefault:@"Ignore"];
}

- (NSString *)downloadButtonLabel
{
  return _downloadButtonLabel ?: [self localizedStringForKey:iVersionDownloadButtonKey withDefault:@"Download"];
}

- (NSString *)remindButtonLabel
{
  return _remindButtonLabel ?: [self localizedStringForKey:iVersionRemindButtonKey withDefault:@"Remind Me Later"];
}

- (NSURL *)updateURL
{
  if (_updateURL)
  {
    return _updateURL;
  }
  
  if (!self.appStoreID)
  {
    NSLog(@"iVersion error: No App Store ID was found for this application. If the application is not intended for App Store release then you must specify a custom updateURL.");
  }
  
  return [NSURL URLWithString:[NSString stringWithFormat:iVersionMacAppStoreURLFormat, @(self.appStoreID)]];
}

- (NSUInteger)appStoreID
{
  return [[[NSUserDefaults standardUserDefaults] objectForKey:iVersionAppStoreIDKey] unsignedIntegerValue];
}

- (void)setAppStoreID:(NSUInteger)appStoreID
{
  [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)appStoreID forKey:iVersionAppStoreIDKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastChecked
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:iVersionLastCheckedKey];
}

- (void)setLastChecked:(NSDate *)date
{
  [[NSUserDefaults standardUserDefaults] setObject:date forKey:iVersionLastCheckedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDate *)lastReminded
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:iVersionLastRemindedKey];
}

- (void)setLastReminded:(NSDate *)date
{
  [[NSUserDefaults standardUserDefaults] setObject:date forKey:iVersionLastRemindedKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)ignoredVersion
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:iVersionIgnoreVersionKey];
}

- (void)setIgnoredVersion:(NSString *)version
{
  [[NSUserDefaults standardUserDefaults] setObject:version forKey:iVersionIgnoreVersionKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)viewedVersionDetails
{
  return [[[NSUserDefaults standardUserDefaults] objectForKey:iVersionLastVersionKey] isEqualToString:self.applicationVersion];
}

- (void)setViewedVersionDetails:(BOOL)viewed
{
  [[NSUserDefaults standardUserDefaults] setObject:(viewed? self.applicationVersion: nil) forKey:iVersionLastVersionKey];
}

- (NSString *)lastVersion
{
  return [[NSUserDefaults standardUserDefaults] objectForKey:iVersionLastVersionKey];
}

- (void)setLastVersion:(NSString *)version
{
  [[NSUserDefaults standardUserDefaults] setObject:version forKey:iVersionLastVersionKey];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSDictionary *)localVersionsDict
{
  static NSDictionary *versionsDict = nil;
  if (versionsDict == nil)
  {
    if (self.localVersionsPlistPath == nil)
    {
      versionsDict = [[NSDictionary alloc] init]; //empty dictionary
    }
    else
    {
      NSString *versionsFile = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:self.localVersionsPlistPath];
      versionsDict = [[NSDictionary alloc] initWithContentsOfFile:versionsFile];
      if (!versionsDict)
      {
        // Get the path to versions plist in localized directory
        NSArray *pathComponents = [self.localVersionsPlistPath componentsSeparatedByString:@"."];
        versionsFile = (pathComponents.count == 2) ? [[NSBundle mainBundle] pathForResource:pathComponents[0] ofType:pathComponents[1]] : nil;
        versionsDict = [[NSDictionary alloc] initWithContentsOfFile:versionsFile];
      }
    }
  }
  return versionsDict;
}

- (NSString *)versionDetails:(NSString *)version inDict:(NSDictionary *)dict
{
  id versionData = dict[version];
  if ([versionData isKindOfClass:[NSString class]])
  {
    return versionData;
  }
  else if ([versionData isKindOfClass:[NSArray class]])
  {
    return [versionData componentsJoinedByString:@"\n"];
  }
  return nil;
}

- (NSString *)versionDetailsSince:(NSString *)lastVersion inDict:(NSDictionary *)dict
{
  if (self.previewMode)
  {
    lastVersion = @"0";
  }
  BOOL newVersionFound = NO;
  NSMutableString *details = [NSMutableString string];
  NSArray *versions = [dict.allKeys sortedArrayUsingSelector:@selector(compareVersionDescending:)];
  for (NSString *version in versions)
  {
    if ([version compareVersion:lastVersion] == NSOrderedDescending)
    {
      newVersionFound = YES;
      if (self.groupNotesByVersion)
      {
        [details appendString:[self.versionLabelFormat stringByReplacingOccurrencesOfString:@"%@" withString:version]];
        [details appendString:@"\n\n"];
      }
      [details appendString:[self versionDetails:version inDict:dict] ?: @""];
      [details appendString:@"\n"];
      if (self.groupNotesByVersion)
      {
        [details appendString:@"\n"];
      }
    }
  }
  return newVersionFound? [details stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]: nil;
}

- (NSString *)versionDetails
{
  if (!_versionDetails)
  {
    if (self.viewedVersionDetails)
    {
      self.versionDetails = [self versionDetails:self.applicationVersion inDict:[self localVersionsDict]];
    }
    else
    {
      self.versionDetails = [self versionDetailsSince:self.lastVersion inDict:[self localVersionsDict]];
    }
  }
  return _versionDetails;
}

- (void)downloadedVersionsData
{
  //only show when main window is available
  if (self.onlyPromptIfMainWindowIsAvailable && ![NSApplication sharedApplication].mainWindow)
  {
    [self performSelector:@selector(downloadedVersionsData) withObject:nil afterDelay:0.5];
    return;
  }
  
  if (self.checkingForNewVersion)
  {
    //no longer checking
    self.checkingForNewVersion = NO;
    
    //check if data downloaded
    if (!self.remoteVersionsDict)
    {
      //log the error
      if (self.downloadError)
      {
        NSLog(@"iVersion update check failed because: %@", (self.downloadError).localizedDescription);
      }
      else
      {
        NSLog(@"iVersion update check failed because an unknown error occured");
      }
      
      if ([self.delegate respondsToSelector:@selector(iVersionVersionCheckDidFailWithError:)])
      {
        [self.delegate iVersionVersionCheckDidFailWithError:self.downloadError];
      }
      
      //deprecated code path
      else if ([self.delegate respondsToSelector:@selector(iVersionVersionCheckFailed:)])
      {
        NSLog(@"iVersionVersionCheckFailed: delegate method is deprecated, use iVersionVersionCheckDidFailWithError: instead");
        [self.delegate performSelector:@selector(iVersionVersionCheckFailed:) withObject:self.downloadError];
      }
      return;
    }
    
    //get version details
    NSString *details = [self versionDetailsSince:self.applicationVersion inDict:self.remoteVersionsDict];
    NSString *mostRecentVersion = mostRecentVersionInDict(self.remoteVersionsDict);
    if (details)
    {
      //inform delegate of new version
      if ([self.delegate respondsToSelector:@selector(iVersionDidDetectNewVersion:details:)])
      {
        [self.delegate iVersionDidDetectNewVersion:mostRecentVersion details:details];
      }
      
      //deprecated code path
      else if ([self.delegate respondsToSelector:@selector(iVersionDetectedNewVersion:details:)])
      {
        NSLog(@"iVersionDetectedNewVersion:details: delegate method is deprecated, use iVersionDidDetectNewVersion:details: instead");
        [self.delegate performSelector:@selector(iVersionDetectedNewVersion:details:) withObject:mostRecentVersion withObject:details];
      }
      
      //check if ignored
      BOOL showDetails = ![self.ignoredVersion isEqualToString:mostRecentVersion] || self.previewMode;
      if (showDetails)
      {
        if ([self.delegate respondsToSelector:@selector(iVersionShouldDisplayNewVersion:details:)])
        {
          showDetails = [self.delegate iVersionShouldDisplayNewVersion:mostRecentVersion details:details];
          if (!showDetails && self.verboseLogging)
          {
            NSLog(@"iVersion did not display the new version because the iVersionShouldDisplayNewVersion:details: delegate method returned NO");
          }
        }
      }
      else if (self.verboseLogging)
      {
        NSLog(@"iVersion did not display the new version because it was marked as ignored");
      }
      
      //show details
      if (showDetails && !self.visibleRemoteAlert)
      {
        NSString *title = self.updateAvailableTitle;
        if (!self.groupNotesByVersion)
        {
          title = [title stringByAppendingFormat:@" (%@)", mostRecentVersion];
        }
        
        self.visibleRemoteAlert = [self showAlertWithTitle:title
                                                   details:details
                                             defaultButton:self.downloadButtonLabel
                                              ignoreButton:[self showIgnoreButton]? self.ignoreButtonLabel: nil
                                              remindButton:[self showRemindButton]? self.remindButtonLabel: nil];
      }
    }
    else if ([self.delegate respondsToSelector:@selector(iVersionDidNotDetectNewVersion)])
    {
      [self.delegate iVersionDidNotDetectNewVersion];
    }
  }
}

- (BOOL)shouldCheckForNewVersion
{
  //debug mode?
  if (!self.previewMode)
  {
    //check if within the reminder period
    if (self.lastReminded != nil)
    {
      //reminder takes priority over check period
      if ([[NSDate date] timeIntervalSinceDate:self.lastReminded] < self.remindPeriod * SECONDS_IN_A_DAY)
      {
        if (self.verboseLogging)
        {
          NSLog(@"iVersion did not check for a new version because the user last asked to be reminded less than %g days ago", self.remindPeriod);
        }
        return NO;
      }
    }
    
    //check if within the check period
    else if (self.lastChecked != nil && [[NSDate date] timeIntervalSinceDate:self.lastChecked] < self.checkPeriod * SECONDS_IN_A_DAY)
    {
      if (self.verboseLogging)
      {
        NSLog(@"iVersion did not check for a new version because the last check was less than %g days ago", self.checkPeriod);
      }
      return NO;
    }
  }
  else if (self.verboseLogging)
  {
    NSLog(@"iVersion debug mode is enabled - make sure you disable this for release");
  }
  
  //confirm with delegate
  if ([self.delegate respondsToSelector:@selector(iVersionShouldCheckForNewVersion)])
  {
    BOOL shouldCheck = [self.delegate iVersionShouldCheckForNewVersion];
    if (!shouldCheck && self.verboseLogging)
    {
      NSLog(@"iVersion did not check for a new version because the iVersionShouldCheckForNewVersion delegate method returned NO");
    }
    return shouldCheck;
  }
  
  //perform the check
  return YES;
}

- (void)setAppStoreIDOnMainThread:(NSString *)appStoreIDString
{
  self.appStoreID = appStoreIDString.longLongValue;
}

- (void)checkForNewVersionInBackground
{
  @synchronized (self)
  {
    @autoreleasepool
    {
      __block BOOL newerVersionAvailable = NO;
      __block BOOL osVersionSupported = NO;
      __block NSString *latestVersion = nil;
      __block NSDictionary *versions = nil;
      
      //first check iTunes
      NSString *iTunesServiceURL = [NSString stringWithFormat:iVersionAppLookupURLFormat, self.appStoreCountry];
      if (self.appStoreID)
      {
        iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?id=%@", @(self.appStoreID)];
      }
      else
      {
        iTunesServiceURL = [iTunesServiceURL stringByAppendingFormat:@"?bundleId=%@", self.applicationBundleID];
      }
      
      if (self.verboseLogging)
      {
        NSLog(@"iVersion is checking %@ for a new app version...", iTunesServiceURL);
      }
      
      __block NSError *jsonError = nil;
      NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:iTunesServiceURL]
                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                           timeoutInterval:REQUEST_TIMEOUT];
      
      __weak typeof(self) weakSelf = self;
      
      NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
      
      NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        
        __strong typeof(self) strongSelf = weakSelf;
        
        if (!strongSelf) {
          return;
        }
        
        if (error != nil || data == nil) {
          return;
        }
        
        NSDictionary *json =  [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (!jsonError) {
          //check bundle ID matches
          NSArray *resultsArray = json[@"results"];
          
          if (![resultsArray isKindOfClass:[NSArray class]]) {
            return;
          }
          
          NSDictionary *firstResult = [resultsArray firstObject];
          
          if (!firstResult) {
            return;
          }
          
          NSString *bundleID = firstResult[@"bundleId"];
          
          if (![bundleID isKindOfClass:[NSString class]]) {
            return;
          }
          
          if (bundleID) {
            if ([bundleID isEqualToString:strongSelf.applicationBundleID])
            {
              //get supported OS version
              NSString *minimumSupportedOSVersion = firstResult[@"minimumOsVersion"];
              
              if (!minimumSupportedOSVersion || ![minimumSupportedOSVersion isKindOfClass:[NSString class]]) {
                return;
              }
              
              NSOperatingSystemVersion version = [NSProcessInfo processInfo].operatingSystemVersion;
              NSString *systemVersion = [NSString stringWithFormat:@"%zd.%zd.%zd", version.majorVersion, version.minorVersion, version.patchVersion];
              
              osVersionSupported = ([systemVersion compare:minimumSupportedOSVersion options:NSNumericSearch] != NSOrderedAscending);
              if (!osVersionSupported)
              {
                error = [NSError errorWithDomain:iVersionErrorDomain
                                            code:iVersionErrorOSVersionNotSupported
                                        userInfo:@{NSLocalizedDescriptionKey: @"Current OS version is not supported."}];
              }
              
              //get version details
              NSString *releaseNotes = firstResult[@"releaseNotes"];
              latestVersion = firstResult[@"version"];
              if (latestVersion && osVersionSupported)
              {
                versions = @{latestVersion: releaseNotes ?: @""};
              }
              
              //get app id
              if (!strongSelf.appStoreID)
              {
                NSString *appStoreIDString = firstResult[@"trackId"];
                [strongSelf performSelectorOnMainThread:@selector(setAppStoreIDOnMainThread:)
                                             withObject:appStoreIDString
                                          waitUntilDone:YES];
                
                if (strongSelf.verboseLogging)
                {
                  NSLog(@"iVersion found the app on iTunes. The App Store ID is %@", appStoreIDString);
                }
              }
              
              //check for new version
              newerVersionAvailable = ([latestVersion compareVersion:strongSelf.applicationVersion] == NSOrderedDescending);
              if (strongSelf.verboseLogging)
              {
                if (newerVersionAvailable)
                {
                  NSLog(@"iVersion found a new version (%@) of the app on iTunes. Current version is %@", latestVersion, strongSelf.applicationVersion);
                }
                else
                {
                  NSLog(@"iVersion did not find a new version of the app on iTunes. Current version is %@, latest version is %@", strongSelf.applicationVersion, latestVersion);
                }
              }
            }
            else
            {
              if (strongSelf.verboseLogging)
              {
                NSLog(@"iVersion found that the application bundle ID (%@) does not match the bundle ID of the app found on iTunes (%@) with the specified App Store ID (%@)", strongSelf.applicationBundleID, bundleID, @(strongSelf.appStoreID));
              }
              
              error = [NSError errorWithDomain:iVersionErrorDomain
                                          code:iVersionErrorBundleIdDoesNotMatchAppStore
                                      userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Application bundle ID does not match expected value of %@", bundleID]}];
            }
          } else if (strongSelf.appStoreID || !strongSelf.remoteVersionsPlistURL)
          {
            if (strongSelf.verboseLogging)
            {
              NSLog(@"iVersion could not find this application on iTunes. If your app is not intended for App Store release then you must specify a remoteVersionsPlistURL. If this is the first release of your application then it's not a problem that it cannot be found on the store yet");
            }
            
            error = [NSError errorWithDomain:iVersionErrorDomain
                                        code:iVersionErrorApplicationNotFoundOnAppStore
                                    userInfo:@{NSLocalizedDescriptionKey: @"The application could not be found on the App Store."}];
          }
          else if (!strongSelf.appStoreID && strongSelf.verboseLogging)
          {
            NSLog(@"iVersion could not find your app on iTunes. If your app is not yet on the store or is not intended for App Store release then don't worry about this");
          }
          
          
        } else {
          //http error
          NSString *message = [NSString stringWithFormat:@"The server returned a %@ error", @([httpResponse statusCode])];
          error = [NSError errorWithDomain:@"HTTPResponseErrorDomain"
                                      code:[httpResponse statusCode]
                                  userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        
        [strongSelf performSelectorOnMainThread:@selector(setDownloadError:) withObject:error waitUntilDone:YES];
        [strongSelf performSelectorOnMainThread:@selector(setRemoteVersionsDict:) withObject:versions waitUntilDone:YES];
        [strongSelf performSelectorOnMainThread:@selector(setLastChecked:) withObject:[NSDate date] waitUntilDone:YES];
        [strongSelf performSelectorOnMainThread:@selector(downloadedVersionsData) withObject:nil waitUntilDone:YES];
        
      }];
      
      [dataTask resume];
    }
  }
}

- (void)checkForNewVersion
{
  if (!self.checkingForNewVersion)
  {
    self.checkingForNewVersion = YES;
    [self performSelectorInBackground:@selector(checkForNewVersionInBackground)
                           withObject:nil];
  }
}

- (void)checkIfNewVersion
{
  //only show when main window is available
  if (self.onlyPromptIfMainWindowIsAvailable && ![NSApplication sharedApplication].mainWindow)
  {
    [self performSelector:@selector(checkIfNewVersion) withObject:nil afterDelay:0.5];
    return;
  }
  
  if (self.lastVersion != nil || self.showOnFirstLaunch || self.previewMode)
  {
    if ([self.applicationVersion compareVersion:self.lastVersion] == NSOrderedDescending || self.previewMode)
    {
      //clear reminder
      self.lastReminded = nil;
      
      //get version details
      BOOL showDetails = !!self.versionDetails;
      if (showDetails && [self.delegate respondsToSelector:@selector(iVersionShouldDisplayCurrentVersionDetails:)])
      {
        showDetails = [self.delegate iVersionShouldDisplayCurrentVersionDetails:self.versionDetails];
      }
      
      //show details
      if (showDetails && !self.visibleLocalAlert && !self.visibleRemoteAlert)
      {
        self.visibleLocalAlert = [self showAlertWithTitle:self.inThisVersionTitle
                                                  details:self.versionDetails
                                            defaultButton:self.okButtonLabel
                                             ignoreButton:nil
                                             remindButton:nil];
      }
    }
  }
  else
  {
    //record this as last viewed release
    self.viewedVersionDetails = YES;
  }
}

- (BOOL)showIgnoreButton
{
  return (self.ignoreButtonLabel).length && self.updatePriority < iVersionUpdatePriorityMedium;
}

- (BOOL)showRemindButton
{
  return (self.remindButtonLabel).length && self.updatePriority < iVersionUpdatePriorityHigh;
}

- (id)showAlertWithTitle:(NSString *)title
                 details:(NSString *)details
           defaultButton:(NSString *)defaultButton
            ignoreButton:(NSString *)ignoreButton
            remindButton:(NSString *)remindButton
{
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = title;
  alert.informativeText = self.inThisVersionTitle;
  [alert addButtonWithTitle:defaultButton];
  
  NSScrollView *scrollview = [[NSScrollView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 380.0, 15.0)];
  NSSize contentSize = scrollview.contentSize;
  scrollview.borderType = NSBezelBorder;
  scrollview.hasVerticalScroller = YES;
  scrollview.hasHorizontalScroller = NO;
  scrollview.autoresizingMask = (NSAutoresizingMaskOptions)(NSViewWidthSizable|NSViewHeightSizable);
  
  NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, contentSize.width, contentSize.height)];
  textView.minSize = NSMakeSize(0.0, contentSize.height);
  textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
  textView.verticallyResizable = YES;
  textView.horizontallyResizable = NO;
  textView.editable = NO;
  textView.autoresizingMask = NSViewWidthSizable;
  textView.textContainer.containerSize = NSMakeSize(contentSize.width, FLT_MAX);
  textView.textContainer.widthTracksTextView = YES;
  textView.string = details;
  scrollview.documentView = textView;
  [textView sizeToFit];
  
  CGFloat height = MIN(200.0, [[scrollview documentView] frame].size.height) + 3.0;
  scrollview.frame = NSMakeRect(0.0, 0.0, scrollview.frame.size.width, height);
  alert.accessoryView = scrollview;
  
  if (ignoreButton)
  {
    [alert addButtonWithTitle:ignoreButton];
  }
  
  if (remindButton)
  {
    [alert addButtonWithTitle:remindButton];
    
    
    NSModalResponse modalResponse = [alert runModal];
    if (modalResponse == NSAlertFirstButtonReturn)
    {
      //right most button
      [self didDismissAlert:alert withButtonAtIndex:0];
    }
    else if (modalResponse == NSAlertSecondButtonReturn)
    {
      [self didDismissAlert:alert withButtonAtIndex:1];
    }
    else
    {
      [self didDismissAlert:alert withButtonAtIndex:2];
    }
  }
    
    
    return alert;
  }
  
- (void)didDismissAlert:(id)alertView withButtonAtIndex:(NSInteger)buttonIndex
  {
    //get button indices
    NSInteger downloadButtonIndex = 0;
    NSInteger ignoreButtonIndex = [self showIgnoreButton]? 1: 0;
    NSInteger remindButtonIndex = [self showRemindButton]? ignoreButtonIndex + 1: 0;
    
    //latest version
    NSString *latestVersion = mostRecentVersionInDict(self.remoteVersionsDict);
    
    if (alertView == self.visibleLocalAlert)
    {
      //record that details have been viewed
      self.viewedVersionDetails = YES;
      
      //release alert
      self.visibleLocalAlert = nil;
      return;
    }
    
    if (buttonIndex == downloadButtonIndex)
    {
      //clear reminder
      self.lastReminded = nil;
      
      //log event
      if ([self.delegate respondsToSelector:@selector(iVersionUserDidAttemptToDownloadUpdate:)])
      {
        [self.delegate iVersionUserDidAttemptToDownloadUpdate:latestVersion];
      }
      
      if (![self.delegate respondsToSelector:@selector(iVersionShouldOpenAppStore)] ||
          [self.delegate iVersionShouldOpenAppStore])
      {
        //go to download page
        [self openAppPageInAppStore];
      }
    }
    else if (buttonIndex == ignoreButtonIndex)
    {
      //ignore this version
      self.ignoredVersion = latestVersion;
      self.lastReminded = nil;
      
      //log event
      if ([self.delegate respondsToSelector:@selector(iVersionUserDidIgnoreUpdate:)])
      {
        [self.delegate iVersionUserDidIgnoreUpdate:latestVersion];
      }
    }
    else if (buttonIndex == remindButtonIndex)
    {
      //remind later
      self.lastReminded = [NSDate date];
      
      //log event
      if ([self.delegate respondsToSelector:@selector(iVersionUserDidRequestReminderForUpdate:)])
      {
        [self.delegate iVersionUserDidRequestReminderForUpdate:latestVersion];
      }
    }
    
    //release alert
    self.visibleRemoteAlert = nil;
  }
  
  - (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(__unused void *)contextInfo
  {
    [self didDismissAlert:alert withButtonAtIndex:returnCode - NSAlertFirstButtonReturn];
  }
  
  - (void)openAppPageWhenAppStoreLaunched
  {
    //check if app store is running
    for (NSRunningApplication *app in [NSWorkspace sharedWorkspace].runningApplications)
    {
      if ([app.bundleIdentifier isEqualToString:iVersionMacAppStoreBundleID])
      {
        //open app page
        [[NSWorkspace sharedWorkspace] performSelector:@selector(openURL:) withObject:self.updateURL afterDelay:MAC_APP_STORE_REFRESH_DELAY];
        return;
      }
    }
    
    //try again
    [self performSelector:@selector(openAppPageWhenAppStoreLaunched) withObject:nil afterDelay:0.0];
  }
  
  - (BOOL)openAppPageInAppStore
  {
    if (!_updateURL && !self.appStoreID)
    {
      if (self.verboseLogging)
      {
        NSLog(@"iVersion was unable to open the App Store because the app store ID is not set.");
      }
      return NO;
    }
    
    if (self.verboseLogging)
    {
      NSLog(@"iVersion will open the App Store using the following URL: %@", self.updateURL);
    }
    
    [[NSWorkspace sharedWorkspace] openURL:self.updateURL];
    if (!_updateURL) [self openAppPageWhenAppStoreLaunched];
    return YES;
  }
  
  - (void)applicationLaunched
  {
    if (self.checkAtLaunch)
    {
      [self checkIfNewVersion];
      if ([self shouldCheckForNewVersion]) [self checkForNewVersion];
    }
    else if (self.verboseLogging)
    {
      NSLog(@"iVersion will not check for updates because the checkAtLaunch option is disabled");
    }
  }
  
  @end
