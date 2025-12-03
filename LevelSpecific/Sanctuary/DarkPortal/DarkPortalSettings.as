namespace DarkPortal
{
	namespace Tags
	{
		const FName DarkPortal = n"DarkPortal";

		const FName DarkPortalAim = n"DarkPortalAim";
		const FName DarkPortalStrafe = n"DarkPortalStrafe";
		const FName DarkPortalFire = n"DarkPortalFire";
		const FName DarkPortalRecall = n"DarkPortalRecall";

		const FName DarkPortalLaunch = n"DarkPortalLaunch";
		const FName DarkPortalSettle = n"DarkPortalSettle";
		const FName DarkPortalGrab = n"DarkPortalGrab";
		const FName DarkPortalArmEffect = n"DarkPortalArmEffect";
		const FName DarkPortalExplosion = n"DarkPortalExplosion";
		const FName DarkPortalPull = n"DarkPortalPull";
		const FName DarkPortalPlacementValidation = n"DarkPortalPlacementValidation";

		const FName DarkPortalActiveDuringIntro = n"DarkPortalActiveDuringIntro";
		const FName DarkPortalTargetActiveOnBloodGate = n"DarkPortalTargetActiveOnBloodGate";

		const FName DarkPortalInvestigate = n"DarkPortalInvestigate"; 
	}

	namespace Aim
	{
		// Range of the player's aim when tracing for attachable surface.
		const float Range = 6000.0;	//Changed from 4200 -> 6000 for the boat ride
	}

	namespace Absorb
	{
		const FName AttachSocket = n"Backpack";
	}

	namespace Launch
	{
		const float Acceleration = 25000.0;
		const float MaximumSpeed = 9000.0;
		const float Drag = 0.0;
	}

	namespace Recall
	{	
		const float Acceleration = 25000.0;
		const float MaximumSpeed = 25000.0;
		const float Drag = 0.0;
	}

	namespace Grab
	{
		// Maximum angle in degrees at which we can grab targets.
		const float MaxAngle = 80.0;

		// Default range of the portal's grabbing functionality; between portal & target.
		const float Range = 1000.0;

		// Extra range of the portal's grabbing functionality when first spawned; between portal & target.
		const float SpawnExtendedRange = 500.0;

		// How many simultaneous grabs we can have.
		const int MaxGrabs = 20;

		// Default force applied to pulled targets.
		const float DefaultPullForce = 3000.0;

		// Radius of impulse added to physics objects when the portal pushes it's targets away.
		const float PushRadius = 3000.0;

		// Default impulse applied when a target is pushed away.
		const float DefaultPushImpulse = 0.0;

		// Exponent used to calculate push fall-off.
		const float PushExponent = 1.0;

		// Forward offset from portal location, origin for traces and pulling.
		const float OriginOffset = 50.0;

		const float ForceAlphaRadius = 200.0;
	}

	namespace Explosion
	{
		// How close the light bird needs to be to the portal in order to make it explode.
		const float LightBirdDistance = 100.0;
		const float ExplosionRadius = 500.0;
		const float ExplosionDelay = 0.5;
	}

	namespace Timings
	{
		// should the arms automatically come out if you put out a portal?
		const bool StartExtended = false;

		// Delay before the arms spawn.
		const float SpawnDelay = 0.0;
		// Time spent moving from hidden to fully extended.
		const float SpawnDuration = 0.0;
		// Adds individual randomness to arms appearing.
		const float SpawnMaxRoll = 0.5;

		// Time spent moving from idle to grabbing.
		const float GrabDuration = 0.5;
		// Adds individual randomness to arms grabbing.
		const float GrabMaxRoll = 0.5;
	}

	namespace Arms
	{
		// Maximum radius arms can be offset around portal center.
		const float OffsetRadius = 90.0;

		const FHazeRange ContractedLength = FHazeRange(150.f, 250.f);
		const FHazeRange ExtendedLength = FHazeRange(300.f, 500.f);

		// Tilts the end of the arm with falloff from portal center offset.
		const float MaxTilt = 100.0;

		// Weight between uniform and random values.
		const float UniformWeight = 0.2;
	}
}