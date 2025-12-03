namespace GravityWhip
{
	namespace Common
	{
		const FName AttachSocket = n"RightAttach";
		const bool bShowCrosshair = true;
		const bool bApplyAimingSensitivity = false;

		const FName IdleAttachSocket = n"GravityWhipSocket";
		const FTransform IdleAttachTransform = FTransform(FRotator(0, 0, 0), FVector(0, 0, 0));
		// const FName IdleAttachSocket = n"Hips";
		// const FTransform IdleAttachTransform = FTransform(FRotator(60, 10, 90), FVector(-12, 15,5));
	}
	
	namespace Hit
	{
		// How long hitting something with the whip takes
		const float HitDuration = 0.30;

		// Base pusback when hitting something with the whip
		const float HitBasePushback = 1000.0;
	}

	namespace Grab
	{
		// Whether multi-grabbing is always enabled, otherwise the secondary input is used.
		const bool bAlwaysMultiGrab = true;

		// Range of the aiming trace, which determines which surface we're aiming towards.
		const float AimTraceRange = 4000.0;

		// Distance to angle ratio weighing when selecting targets.
		const float DistanceWeight = 0.5;

		// Maximum angle in degrees at which we reach peak throwing power.
		const float MaxThrowAngle = 40.0;

		// How many targets we can grab at most when multi-targeting.
		const int MaxNumGrabs = 6;

		// Angle in degrees at which we clamp the camera while throwing.
		const float CameraClampAngle = 20.0;

		// Constant force applied to objects towards hover location while grabbed.
		const float GrabForce = 7500.0;

		// Impulse force applied to objects towards tension direction when thrown.
		const float ThrowImpulse = 5000.0;

		// Offset from player location where slingable objects hover, relative to aim direction.
		const FVector SlingOriginOffset = FVector(-50.0, 200.0, 200.0);

		// Offset from player location where slingable objects hover while aiming is 2D constrained, relative to aim direction.
		const FVector SlingOriginOffset2D = FVector(-100.0, 0.0, 300.0);

		// Time before the grab becomes active and the corresponding response event is triggered.
		const float GrabDelay = 0.25;

		// Time after release until we can try to grab again
		const float ReleaseDuration = 0.1;

		// Time after release until the strafe goes away
		const float StrafeDuration = 0.3;

		// How long until after starting a whip grab can we buffer the next whip grab / hit
		const float CanBufferHitsAfterDuration = 0.1;

		// If the whip target is more than this many degrees away from our current facing, snap the player rotation immediately
		const float SnapRotationAngleThreshold = 15.0;
		
		// Time sling is force held when just tapping.
		const float ForceSlingDuration = 0.9;

		// Delay after releasing the button before the sling throws
		const float SlingThrowDelay = 0.15;

		// How fast the object initially moves towards the whip position
		const float SlingPickupAccelerationDuration = 1.0;

		// How tightly the object sticks to the whip position during hold
		const float SlingHoldAccelerationDuration = 1.0;

		// How tightly the object sticks to the whip position during throw
		const float SlingThrowAccelerationDuration = 0.1;

		// Legacy behaviour, excludes multi-grab by blueprint class instead of categories and grab mode, kept so we can go through and set-up categories without whip breaking.
		const bool bLegacyTargetExclusion = true;

		// Distance the whip should extend to when grabbing without a valid target.
		const float AirGrabDistance = 1000.0;

		// Duration of the air grab.
		const float AirGrabDuration = 0.2;
	
		const FName TargetableCategory = n"GravityWhip";

		const FName SlingTargetableCategory = n"GravityWhipSling";
	}
}