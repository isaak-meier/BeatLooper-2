#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "BLPLogo" asset catalog image resource.
static NSString * const ACImageNameBLPLogo AC_SWIFT_PRIVATE = @"BLPLogo";

/// The "icons8-end-100" asset catalog image resource.
static NSString * const ACImageNameIcons8End100 AC_SWIFT_PRIVATE = @"icons8-end-100";

/// The "icons8-pause-button-100" asset catalog image resource.
static NSString * const ACImageNameIcons8PauseButton100 AC_SWIFT_PRIVATE = @"icons8-pause-button-100";

/// The "icons8-play-button-100" asset catalog image resource.
static NSString * const ACImageNameIcons8PlayButton100 AC_SWIFT_PRIVATE = @"icons8-play-button-100";

/// The "icons8-skip-to-start-100" asset catalog image resource.
static NSString * const ACImageNameIcons8SkipToStart100 AC_SWIFT_PRIVATE = @"icons8-skip-to-start-100";

/// The "rainbow-music-banner" asset catalog image resource.
static NSString * const ACImageNameRainbowMusicBanner AC_SWIFT_PRIVATE = @"rainbow-music-banner";

#undef AC_SWIFT_PRIVATE
