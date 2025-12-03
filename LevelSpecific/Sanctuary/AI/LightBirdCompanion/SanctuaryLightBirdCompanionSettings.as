class USanctuaryLightBirdCompanionSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Companion")
	float AutoRecallRange = 7000.0;

	UPROPERTY(Category = "Companion")
	float CompanionResumeDuration = 10.0;

	
	UPROPERTY(Category = "LaunchStart")
	float LaunchStartMinDuration = 0.1;

	UPROPERTY(Category = "LaunchStart")
	FName LaunchStartSocket = n"LeftForeArm";

	UPROPERTY(Category = "LaunchStart")
	FVector LaunchStartOffset = FVector(0.0, 0.0, 0.0);

	UPROPERTY(Category = "LaunchStart")
	float LaunchStartSpeed = 8000.0;

	UPROPERTY(Category = "LaunchStart")
	float LaunchFromHeldUpFactor = 0.1;

	UPROPERTY(Category = "LaunchStart")
	float LaunchFromHeldMaxTangent = 600.0;
	
	UPROPERTY(Category = "LaunchStart")
	float LaunchStartHeldTurnDuration = 0.5;


	UPROPERTY(Category = "Launch")
	float LaunchTurnDuration = 0.2;

	// Max speed along launch curve
	UPROPERTY(Category = "Launch")
	float LaunchSpeed = 6000.0;

	// How randomly wide launch curve is
	UPROPERTY(Category = "Launch")
	float LaunchNoise = 0.05;

	// How fast we reach max speed
	UPROPERTY(Category = "Launch")
	float LaunchAccelerationDuration = 1.5;

	// How far we launch when there is no target
	UPROPERTY(Category = "Launch")
	float LaunchNoTargetRange = 1500;

	// When attached to a socket we rotate towards player to within this angle so that when will fly more or less straight back toward player when released.
	UPROPERTY(Category = "Launch")
	float LaunchAttachedYawThreshold = 20.0;

	UPROPERTY(Category = "Launch")
	float LaunchExitDuration = 0.1;

	UPROPERTY(Category = "Launch")
	FVector LaunchExitOffset = FVector(0.0, 80.0, 100.0);

	UPROPERTY(Category = "Launch")
	float LaunchExitAcceleration = 10000.0;

	UPROPERTY(Category = "Lantern")
	FName LanternSocket = n"LeftForeArm";

	UPROPERTY(Category = "Lantern")
	float LanternReturnSpeed = 4500.0;

	UPROPERTY(Category = "Lantern")
	float LanternReturnAccelerationDuration = 4.0;

	UPROPERTY(Category = "Lantern")
	float LanternIlluminateRange = 1000.0;

	UPROPERTY(Category = "Follow")
	FVector FollowOffsetMin = FVector(-50.0, -150.0, 150.0);

	UPROPERTY(Category = "Follow")
	FVector FollowOffsetMax = FVector(50.0, 20.0, 220.0);

	UPROPERTY(Category = "Follow")
	float FollowFlyAheadRangeMin = 1000.0;

	UPROPERTY(Category = "Follow")
	float FollowFlyAheadRangeMax = 4000.0;

	UPROPERTY(Category = "Follow")
	float FollowRepositionInterval = 2.0;

	UPROPERTY(Category = "Follow")
	float FollowFarSpeed = 6000.0;

	UPROPERTY(Category = "Follow")
	float FollowNearSpeed = 700.0;

	UPROPERTY(Category = "Follow")
	float FollowNearRange = 800.0;

	UPROPERTY(Category = "Movement")
	float FollowAtDestinationRange = 40.0;

	UPROPERTY(Category = "Movement")
	float FollowLookaAtLaunchObstacleDuration = 1.2;

	UPROPERTY(Category = "Follow")
	bool bFollowTightAllowed = true;

	UPROPERTY(Category = "Follow")
	float FollowTightSpeed = 6000.0;

	UPROPERTY(Category = "Follow")
	float FollowAtUserLag = 2.0;

	UPROPERTY(Category = "Follow")
	float FollowTightRange = 500.0;

	UPROPERTY(Category = "Follow")
	float FollowTightMovingDuration = 1.0;

	UPROPERTY(Category = "Follow")
	float FollowTightAfterLaunchDelay = 0.2;
	
	UPROPERTY(Category = "Follow")
	float FollowTightAccelerationDuration = 1.0;

	UPROPERTY(Category = "Follow")
	float TightFollowTurnDuration = 0.5;


	UPROPERTY(Category = "ObstructedReturn")
	float ObstructedDetectDuration = 0.3;

	UPROPERTY(Category = "ObstructedReturn")
	float UnobstructedDetectDuration = 0.1;

	UPROPERTY(Category = "ObstructedReturn")
	float ObstructedReturnMinDuration = 1.0;

	UPROPERTY(Category = "ObstructedReturn")
	float ObstructedNearRange = 2000.0;

	UPROPERTY(Category = "ObstructedReturn")
	float ObstructedReturnNearMaxSpeed = 2000.0;

	UPROPERTY(Category = "ObstructedReturn")
	bool bObstructedAllowNoLOSTeleport = true;

	UPROPERTY(Category = "ObstructedReturn")
	bool bObstructedAllowOutOfViewTeleport = true;

	UPROPERTY(Category = "ObstructedReturn")
	float ObstructedTeleportRange = 2000.0;

	UPROPERTY(Category = "Movement")
	float TurnDuration = 2.0;

	UPROPERTY(Category = "Movement")
	float AirFriction = 1.2;
	
	UPROPERTY(Category = "Movement")
	float FollowFarFriction = 5.0;
	
	UPROPERTY(Category = "Movement")
	float StopTurningDamping = 5.0;

	UPROPERTY(Category = "Movement")
	float MaxStrafeSpeed = 500.0;

	UPROPERTY(Category = "Movement")
	float MaxStrafeDistance = 500.0;

	// If true, targets we launch to can be illuminated even before companion has arrived at them and lantern illumination ignores range setting.
	UPROPERTY(Category = "Illumination")
	bool IlluminateImmediately = false;

	UPROPERTY(Category = "Intro")
	float IntroCompleteDistance = 500.0;

	// Max speed when investigating
	UPROPERTY(Category = "Investigate")
	float InvestigationSpeed = 1200.0;

	// How randomly wide invesigation curve is
	UPROPERTY(Category = "Investigate")
	float InvestigationNoise = 0.5;

	// How fast we reach max speed
	UPROPERTY(Category = "Investigate")
	float InvestigationAccelerationDuration = 5.0;

	UPROPERTY(Category = "Investigate")
	float InvestigationIlluminationRange = 1000.0;

	UPROPERTY(Category = "DiscSlideFollow")
	FVector DiscSlideFollowOffset = FVector(-100.0, -300.0, 100.0);

	UPROPERTY(Category = "CentipedeFollow")	
	FName CentipedeFollowSocket = n"RightAttach";

	UPROPERTY(Category = "CentipedeFollow")
	FVector CentipedeFollowOffset = FVector(-100.0, -200.0, 40.0);

	UPROPERTY(Category = "CentipedeFollow")
	float CentipedeFollowDuration = 2.0;
};

