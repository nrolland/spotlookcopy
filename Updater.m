#import "Updater.h"

static Updater *sharedInstance = nil;

@implementation Updater

+ (Updater *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[Updater alloc] init];
    }
    return sharedInstance;
}

- (BOOL) version:(NSArray *)a isBiggerThan:(NSArray *)b {
    unsigned aa = [[a objectAtIndex:0] intValue];
    unsigned ab = [[a objectAtIndex:1] intValue];
    unsigned cc = [a count] > 2 ? [[a objectAtIndex:2] intValue] : 0;

    unsigned ba = [[b objectAtIndex:0] intValue];
    unsigned bb = [[b objectAtIndex:1] intValue];
    unsigned bc = [b count] > 2 ? [[b objectAtIndex:2] intValue] : 0;

    return ((aa > ba) || (aa == ba && ab > bb) || (aa == ba && ab == bb && cc > bc));
}

- (BOOL) shortVersion:(NSString *)sa isBiggerThan:(NSString *)sb {
	NSArray *a = [sa componentsSeparatedByString:@"."];
	NSArray *b = [sb componentsSeparatedByString:@"."];
	return [self version:a isBiggerThan:b];
}

- (void) threadCheckUpdateDisplayPanel:(BOOL)displayPanel bypassDefault:(BOOL)bypassDefault {

	NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // set defaults, redundant with addDefaults.plist
    if([[defaults dictionaryRepresentation] valueForKey:@"versionCheckRunAtStartup"] == nil) {
        [defaults setBool:YES forKey:@"versionCheckRunAtStartup"];
    }

    if(!bypassDefault && [defaults boolForKey:@"versionCheckRunAtStartup"] == NO) {
        [subPool release];
        return;
    }

    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersionString = [infoDictionary valueForKey:@"CFBundleShortVersionString"];
    NSArray *currentVersion = [currentVersionString componentsSeparatedByString:@"."];

	NSString *urlString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"UpdaterURL"];
	if(!urlString) {
		NSLog(@"Can't update, no UpdaterURL in Info.plist");
		[subPool release];
		return;
	}

    NSURL *versionCheckURL = [NSURL URLWithString:urlString];
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfURL:versionCheckURL];
    if(d == nil ||
      [d valueForKey:@"LatestVersion"] == nil ||
      [d valueForKey:@"PageURL"] == nil ||
      [d valueForKey:@"DownloadURL"] == nil) {
        [subPool release];
        return;
    }

    NSString *latestVersionString = [d valueForKey:@"LatestVersion"];
    NSArray *latestVersion = [latestVersionString componentsSeparatedByString:@"."];
    NSURL *pageURL = [NSURL URLWithString:[d valueForKey:@"PageURL"]];
    NSURL *downloadURL = [NSURL URLWithString:[d valueForKey:@"DownloadURL"]];
	
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleName"];

    if([self version:latestVersion isBiggerThan:currentVersion] == NO) {
        if(displayPanel) {
            NSRunInformationalAlertPanel(NSLocalizedString(@"You are up to date!", nil),
                                         [NSString stringWithFormat:NSLocalizedString(@"%@ %@ is the latest version available.", nil), appName, latestVersionString],
                                         NSLocalizedString(@"OK", nil),
                                         @"",
                                         @"");
        }
        [subPool release];
        return;
    }
    
    int alertReturn = NSRunAlertPanel([NSString stringWithFormat: NSLocalizedString(@"%@ version %@ is available!", nil), appName, latestVersionString],
                                      [NSString stringWithFormat: NSLocalizedString(@"What do you want to do?", nil), latestVersionString],
                                      NSLocalizedString(@"Download now", nil),
                                      NSLocalizedString(@"Ignore and Continue", nil),
                                      [NSString stringWithFormat:NSLocalizedString(@"Go to %@ website", nil), appName]);
                                      
    switch (alertReturn) {
        case NSAlertDefaultReturn:
            [[NSWorkspace sharedWorkspace] openURL:downloadURL];
            break;
        case NSAlertOtherReturn:
            [[NSWorkspace sharedWorkspace] openURL:pageURL];
            break;
        default:
            break;
    }
    
    [subPool release];
}

- (void) threadCheckUpdateSilentIfUptodate {
	[self threadCheckUpdateDisplayPanel:NO bypassDefault:NO];
}

- (void) threadCheckUpdateBypassPrefsDisplayAlertIfUptodate {
	[self threadCheckUpdateDisplayPanel:YES bypassDefault:YES];
}

- (void) threadCheckUpdateDisplayAlertIfUptodate {
	[self threadCheckUpdateDisplayPanel:YES bypassDefault:NO];
}

- (IBAction) checkUpdateDisplayAlertIfUptodate:(id)sender {
    [NSThread detachNewThreadSelector:@selector(threadCheckUpdateDisplayAlertIfUptodate)
                             toTarget:self
                           withObject:nil];
}

- (IBAction) checkUpdateBypassPrefsDisplayAlertIfUptodate:(id)sender {
    [NSThread detachNewThreadSelector:@selector(threadCheckUpdateBypassPrefsDisplayAlertIfUptodate)
                             toTarget:self
                           withObject:nil];
}

- (IBAction) checkUpdateSilentIfUpToDate:(id)sender {
    [NSThread detachNewThreadSelector:@selector(threadCheckUpdateSilentIfUptodate)
                             toTarget:self
                           withObject:nil];
}

@end
