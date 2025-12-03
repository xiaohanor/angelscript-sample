class USanctuaryDarkPortalCompanionSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Companion")
	float CompanionMinSettleDuration = 3.0;

	UPROPERTY(Category = "Companion")
	float AutoRecallRange = 6500.0;

	UPROPERTY(Category = "Follow")
	FVector FollowOffsetMin = FVector(20.0, 20.0, 90.0);

	UPROPERTY(Category = "Follow")
	FVector FollowOffsetMax = FVector(-20.0, 60.0, 130.0);

	UPROPERTY(Category = "Follow")	
	float FollowPredictionTime = 0.3;	

	UPROPERTY(Category = "Follow")	
	float FollowRepositionInterval = 2.0;

	UPROPERTY(Category = "Follow")
	float FollowSpeed = 3500.0;

	UPROPERTY(Category = "Follow")
	float FollowRange = 1500.0;

	UPROPERTY(Category = "Follow")
	float FollowMinRange = 200.0;

	UPROPERTY(Category = "Follow")
	float FollowPlayerSpeedThreshold = 150.0;

	UPROPERTY(Category = "Follow")
	float FollowMinDuration = 1.0;

	UPROPERTY(Category = "Follow")
	float FollowCooldown = 0.5;

	UPROPERTY(Category = "Follow")
	float FollowFarSpeed = 6000.0;

	UPROPERTY(Category = "Follow")
	float FollowNearSpeed = 700.0;

	UPROPERTY(Category = "Follow")
	float FollowNearRange = 800.0;

	UPROPERTY(Category = "Follow")
	float FollowAtDestinationRange = 40.0;

	UPROPERTY(Category = "Follow")
	bool bFollowTightAllowed = true;

	UPROPERTY(Category = "Follow")
	float FollowAtUserLag = 2.0;

	UPROPERTY(Category = "Follow")
	float FollowTightRange = 500.0;

	UPROPERTY(Category = "Follow")
	float FollowTightSpeed = 6000.0;

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



	UPROPERTY(Category = "WatsonTeleport")
	float WatsonTeleportStuckDuration = 3.0;

	UPROPERTY(Category = "WatsonTeleport")
	float WatsonTeleportStuckDistance = 6000.0;

	UPROPERTY(Category = "WatsonTeleport")
	float WatsonTeleportCooldown = 3.0;


	UPROPERTY(Category = "Intro")
	float IntroCompleteDistance = 500.0;


	UPROPERTY(Category = "PlayerRepulsion")
	float PlayerRepulsionRange = 80.0;

	UPROPERTY(Category = "PlayerRepulsion")
	float PlayerRepulsionForce = 1000.0;


	UPROPERTY(Category = "Movement")
	float TurnDuration = 3.0;

	UPROPERTY(Category = "Movement")
	float AirFriction = 1.2;

	UPROPERTY(Category = "Movement")
	float FollowFarFriction = 3.2;

	UPROPERTY(Category = "Movement")
	float StopTurningDamping = 5.0;

	UPROPERTY(Category = "Movement")
	float MaxStrafeSpeed = 500.0;

	UPROPERTY(Category = "Movement")
	float MaxStrafeDistance = 500.0;


	UPROPERTY(Category = "Aimed")
	float AimedReturnDuration = 2.0;

	UPROPERTY(Category = "Aimed")
	FName AimedSocket = n"RightAttach";

	UPROPERTY(Category = "Aimed")
	float AimedMidHeightMax = 500.0;

	UPROPERTY(Category = "Aimed")
	float AimedTangentSize = 400.0;


	UPROPERTY(Category = "LaunchStart")
	float LaunchStartMinDuration = 0.1;

	UPROPERTY(Category = "LaunchStart")	
	FName LaunchStartSocket = n"RightAttach";

	UPROPERTY(Category = "LaunchStart")
	FVector LaunchStartOffset = FVector(60.0, 20.0, 0.0);

	UPROPERTY(Category = "LaunchStart")
	float LaunchStartSpeed = 8000.0;

	UPROPERTY(Category = "LaunchStart")
	float LaunchStartAtUserFollowDuration = 1.0;

	UPROPERTY(Category = "LaunchStart")
	float LaunchStartYawClamp = 60.0;

	UPROPERTY(Category = "LaunchStart")
	float LaunchStartPitchClamp = 0.0;

	UPROPERTY(Category = "LaunchStart")
	float LaunchFromHeldUpFactor = 0.6;

	UPROPERTY(Category = "LaunchStart")
	float LaunchFromHeldMaxTangent = 100.0;
	
	UPROPERTY(Category = "LaunchStart")
	float LaunchStartHeldTurnDuration = 1.0;


	UPROPERTY(Category = "Launch")
	float LaunchTurnDuration = 0.01;

	// Max speed along launch curve
	UPROPERTY(Category = "Launch")
	float LaunchSpeed = 5000.0;

	// How randomly wide launch curve is
	UPROPERTY(Category = "Launch")
	float LaunchNoise = 0.05;

	UPROPERTY(Category = "Launch")
	float LaunchNoTargetRange = 1500;

	// How fast we reach max speed
	UPROPERTY(Category = "Launch")
	float LaunchAccelerationDuration = 1.0;

	// Only reposition portal if we try to launch this far from current location
	UPROPERTY(Category = "Launch")
	float LaunchRepositionMinDistance = 100.0;

	// Deprecated
	UPROPERTY(Category = "Launch")
	float LaunchMidHeightMax = 500.0;

	// Deprecated
	UPROPERTY(Category = "Launch")
	float LaunchTargetTangentFactor = 0.3;


	UPROPERTY(Category = "AtPortal")
	float AtPortalYawThreshold = 5.0;


	UPROPERTY(Category = "PortalExit")
	float PortalExitDuration = 0.1;

	UPROPERTY(Category = "PortalExit")
	FVector PortalExitOffset = FVector(200.0, 40.0, 40.0);

	UPROPERTY(Category = "PortalExit")
	float PortalExitAcceleration = 10000.0;


	UPROPERTY(Category = "Follow")
	FVector RoamOffsetMin = FVector(-200.0, -200.0, 60.0);

	UPROPERTY(Category = "Follow")
	FVector RoamOffsetMax = FVector(500.0, 200.0, 150.0);

	UPROPERTY(Category = "Follow")
	float RoamSpeed = 200.0;

	UPROPERTY(Category = "Follow")	
	float RoamRepositionInterval = 5.0;

	UPROPERTY(Category = "Follow")	
	float RoamStrafeInterval = 10.0;

	UPROPERTY(Category = "Follow")	
	float RoamStrafeRange = 250.0;

	UPROPERTY(Category = "Follow")	
	float RoamRepositionPause = 0.7;


	// Max speed when investigating
	UPROPERTY(Category = "Investigate")
	float InvestigationSpeed = 1200.0;

	// How randomly wide invesigation curve is
	UPROPERTY(Category = "Investigate")
	float InvestigationNoise = 0.5;

	// How fast we reach max speed
	UPROPERTY(Category = "Investigate")
	float InvestigationAccelerationDuration = 5.0;

	UPROPERTY(Category = "MeshRotation")
	float MeshRotationApplyDuration = 1.0; 

	UPROPERTY(Category = "MeshRotation")
	float MeshRotationClearDuration = 2.0; 

	UPROPERTY(Category = "DiscSlideFollow")
	FVector DiscSlideFollowOffset = FVector(-100.0, 300.0, 100.0);

	UPROPERTY(Category = "CentipedeFollow")	
	FName CentipedeFollowSocket = n"RightAttach";

	UPROPERTY(Category = "CentipedeFollow")
	FVector CentipedeFollowOffset = FVector(-100.0, 200.0, 40.0);

	UPROPERTY(Category = "CentipedeFollow")
	float CentipedeFollowDuration = 2.0;
};

