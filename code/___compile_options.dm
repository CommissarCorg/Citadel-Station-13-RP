///By using the testing("message") proc you can create debug-feedback for people with this
//#define TESTING
								//uncommented, but not visible in the release version)

/// uncomment to enable laggy as sin ZAS debugging systems coded in for when doing bugfixes or major systems overhaulling.
#define ZAS_DEBUG
	// if you touch anything #if'd behind a block for this you better make sure this works or I will bean you with a shoe.

///Enables the ability to cache datum vars and retrieve later for debugging which vars changed.
//#define DATUMVAR_DEBUGGING_MODE
// Comment this out if you are debugging problems that might be obscured by custom error handling in world/Error
#ifdef DEBUG
#define USE_CUSTOM_ERROR_HANDLER
#endif

#define DEBUG_SHUTTLES

#define TIMER_LOOP_DEBUGGING

#ifdef TESTING
#define DATUMVAR_DEBUGGING_MODE

///Used to find the sources of harddels, quite laggy, don't be surpised if it freezes your client for a good while
#ifdef REFERENCE_TRACKING

///Run a lookup on things hard deleting by default.
//#define GC_FAILURE_HARD_LOOKUP
#ifdef GC_FAILURE_HARD_LOOKUP
#define FIND_REF_NO_CHECK_TICK
#endif //ifdef GC_FAILURE_HARD_LOOKUP

#endif //ifdef REFERENCE_TRACKING

///Highlights atmos active turfs in green
//#define VISUALIZE_ACTIVE_TURFS
#endif //ifdef TESTING

///Enables unit tests via TEST_RUN_PARAMETER
//#define UNIT_TESTS
#ifndef PRELOAD_RSC				//set to:
///	0 to allow using external resources or on-demand behaviour;
#define PRELOAD_RSC	2
#endif							//	1 to use the default behaviour;
								//	2 for preloading absolutely everything;

#ifdef LOWMEMORYMODE
#define FORCE_MAP "_maps/runtimestation.json"
#endif

//Update this whenever you need to take advantage of more recent byond features
#define MIN_COMPILER_VERSION 513
#define MIN_COMPILER_BUILD 1514
#if DM_VERSION < MIN_COMPILER_VERSION || DM_BUILD < MIN_COMPILER_BUILD
//Don't forget to update this part
#error Your version of BYOND is too out-of-date to compile this project. Go to https://secure.byond.com/download and update.
#error You need version 513.1514 or higher
#endif

//Additional code for the above flags.
#ifdef TESTING
#warn compiling in TESTING mode. testing() debug messages will be visible.
#endif

#ifdef CIBUILDING
#define UNIT_TESTS
#endif

#ifdef CITESTING
#define TESTING
#endif

// A reasonable number of maximum overlays an object needs
// If you think you need more, rethink it
#define MAX_ATOM_OVERLAYS 100

/*
VORESTATION CRAP
*/

// ZAS Compile Options
/// Uncomment to turn on super detailed ZAS debugging that probably won't even compile.
//#define ZASDBG
/// Uncomment to turn on Multi-Z ZAS Support!
#define MULTIZAS
