
namespace BabyDragonZipline
{
	// How far away from the zipline we can enter it (this is only the default value, can be overriden in ABabyDragonZiplinePoint)
	const float ZiplineEnterRange = 100.0;
	// How far away a dot is visible (this is only the default value, can be overriden in ABabyDragonZiplinePoint)
	const float VisibleRange = 1200.0;
	// How long to wait before actually starting the move towards the zipline
	const float AnticipationDelay = 0.0;
	// Speed at which we jump to the zipline
	const float EnterSpeed = 1300.0;
	// Acceleration duration at which we achieve the enter speed
	const float EnterAccelerationDuration = 0.3;
	// Offset from the zipline the player should be at
	const FVector PlayerZiplineOffset(0.0, 0.0, -190.0);
	// Maximum angle for our camera to be facing from the zipline's direction to be able to enter a zipline (degrees)
	const float EnterMaximumAllowedAngleFromForward = 180.0;

	// Initial speed we move on the zipline after entering
	const float ZiplineInitialSpeed = 800.0;
	// Maximum speed we reach while ziplining
	const float ZiplineMaxSpeed = 1400.0;
	// How long it takes to accelerate up to maximum speed while ziplining
	const float ZiplineAccelerationDuration = 1.0;
};