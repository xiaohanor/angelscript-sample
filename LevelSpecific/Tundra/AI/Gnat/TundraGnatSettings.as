class UTundraGnatSettings : UHazeComposableSettings
{
	// Move speed when climbing up giant walking log legs
	UPROPERTY(Category = "Entry")
	float ClimbMoveSpeed = 1200.0;

	UPROPERTY(Category = "Entry")
	float ClimbEntryPointCooldown = 4.0;

	UPROPERTY(Category = "Entry")
	float ClimbEntryMinSpacing = 600.0;

	UPROPERTY(Category = "Entry")
	float ClimbEntryMaxSpacing = 1200.0;

	// Move speed for when following a placed entry spline (currently used by ground gnats)
	UPROPERTY(Category = "Entry")
	float SplineClimbMoveSpeed = 500.0;

	UPROPERTY(Category = "Entry")
	bool ClimbEntryFrontOnly = false;

	// Move speed when climbing down from a beaver spear
	UPROPERTY(Category = "Entry")
	float BeaverSpearClimbMoveSpeed = 400.0;

	// Move speed when climbing down from a beaver spear
	UPROPERTY(Category = "Entry")
	float LeapEntryDuration = 1.5;

	UPROPERTY(Category = "Entry")
	float LeapEntryTargetLandingDistance = 800.0;


	// Move speed for engaging player on top of giant walking log
	UPROPERTY(Category = "Engage")
	float EngageMoveSpeed = 400.0;


	// Move speed for engaging ground gnats
	UPROPERTY(Category = "GroundEngage")
	float GroundEngageMoveSpeed = 300.0;


	// Move speed when patrolling
	UPROPERTY(Category = "Patrol")
	float PatrolMoveSpeed = 300.0;

	UPROPERTY(Category = "Patrol")
	float PatrolSwitchDestinationInterval = 5.0;

	UPROPERTY(Category = "Patrol")
	float PatrolStartPause = 3.0;

	UPROPERTY(Category = "Patrol")
	float PatrolTrackTargetRange = 5000.0;


	UPROPERTY(Category = "Annoy")
	float AnnoyRange = 300.0;

	UPROPERTY(Category = "Annoy")
	float AnnoyJumpSpeed = 400.0;

	UPROPERTY(Category = "Annoy")
	float AnnoyLatchOnRange = 200.0;

	UPROPERTY(Category = "Annoy")
	bool bOnlyAnnoyTree = false;

	UPROPERTY(Category = "Annoy")
	bool bDontAnnoyMonkey = true;

	UPROPERTY(Category = "Annoy")
	bool bAnnoyKillsHumansOtterFairy = true;

	UPROPERTY(Category = "Annoy")
	int AnnoyInnerCircleNumber = 8;

	UPROPERTY(Category = "ShakeOff")
	bool bShakeOffWithButtonMash = false;

	UPROPERTY(Category = "ShakeOff")
	float ShakeOffButtonMashDuration = 1.0;

	UPROPERTY(Category = "ShakeOff")
	EButtonMashDifficulty ShakeOffButtonMashDifficulty = EButtonMashDifficulty::Medium;

	UPROPERTY(Category = "ShakeOff")
	float ShakeOffForce = 2000.0;

	UPROPERTY(Category = "ShakeOff")
	float ShakeOffStunnedDuration = 3.0;


	UPROPERTY(Category = "Movement")
	float AtDestinationRange = 40.0;

	UPROPERTY(Category = "Movement")
	float Friction = 4.0;

	UPROPERTY(Category = "Movement")
	float TurnDuration = 2.0;

	UPROPERTY(Category = "Movement")
	float UpDirectionChangeDuration = 1.0;

	UPROPERTY(Category = "Movement")
	float Gravity = 982.0 * 3.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float ThrownMaxDuration = 5.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float ThrownDefaultRange = 2000.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float ThrownSpeed = 3000.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float ThrownHeight = 800.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float ThrownGravity = 982.0 * 3.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float GnapeHitGnapeRadius = 150.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float GnapeHitGnapeRedirection = 60.0;

	UPROPERTY(Category = "ThrownByMonkey")
	float GnapeHitGnapeHeightImpulse = 1500.0;

	UPROPERTY(Category = "ThrownByMonkey")
	bool GnapeThrownChainReaction = true;

	UPROPERTY(Category = "MonkeyGroundSlamReaction")
	float MonkeyGroundSlamMaxForce = 2000.0;

	UPROPERTY(Category = "MonkeyGroundSlamReaction")
	float MonkeyGroundSlamExtraHeight = 1500.0;

	UPROPERTY(Category = "AvoidMonkey")
	float AvoidMonkeyRange = 600.0;

	UPROPERTY(Category = "AvoidMonkey")
	float AvoidMonkeySpeed = 600.0;

	UPROPERTY(Category = "Flee")
	float FleeSpeed = 600.0;
}