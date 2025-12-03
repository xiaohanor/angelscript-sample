class UTundraPlayerTreeGuardianSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Tint")
	FLinearColor MorphPlayerTint = FLinearColor(0.730461, 0.450786, 0.187821);

	UPROPERTY(Category = "Tint")
	FLinearColor MorphShapeTint = FLinearColor(0.283849, 0.5, 0.274499);

	/* This friction will be applied when the tree guardian is grounded to slow down it's horizontal velocity */
	UPROPERTY(Category="Movement")
	float HorizontalGroundFriction = 5;

	/* This friction will be applied when the tree guardian is airborne to slow down it's horizontal velocity */
	UPROPERTY(Category="Movement")
	float HorizontalAirFriction = 5;

	/* How fast the rotation will respond to the tree guardian's velocity */
	UPROPERTY(Category="Movement")
	float TreeGuardianRotationInterpSpeed = 5;

	UPROPERTY(Category="Movement")
	float GravityAmount = 4000.0;

	UPROPERTY(Category="Movement")
	float TerminalVelocity = 2500.0;

	UPROPERTY(Category="Movement")
	float GravityBlendTime = 0.5;

	UPROPERTY(Category = "Movement|Floor Motion")
    float MinimumInput = 0.4;

	UPROPERTY(Category = "Movement|Floor Motion")
    float MinimumSpeed = 250.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float MaximumSpeed = 800.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float Acceleration = 1500.0;

	UPROPERTY(Category = "Movement|Floor Motion")
    float Deceleration = 1777.7;

	UPROPERTY(Category = "Movement|Floor Motion")
    float TurnMultiplier = 2.0;

	UPROPERTY(Category = "Movement|Floor Motion")
	float TurnAroundDuration = 0.5;

	UPROPERTY(Category = "Movement|Floor Motion")
	float TurnAroundRotationDuration = 0.00001;

	UPROPERTY(Category="Life Giving")
	float DelayBeforeEnablingLifeGiving = 1.0;

	UPROPERTY(Category="Life Giving")
	float ForceFeedbackMinSinValue = 0.1;

	UPROPERTY(Category="Life Giving")
	float ForceFeedbackSinWaveDuration = 1.0;

	UPROPERTY(Category="Life Giving")
	float ForceFeedbackMaxStrength = 0.3;

	/* How fast the stick size will interp to the actual stick size (this value will be multiplied with force feedback max strength to determine current force feedback strength) */
	UPROPERTY(Category="Life Giving")
	float ForceFeedbackInterpSpeed = 2.0;

	/* If moving stick less than this size, will not apply force feedback */
	UPROPERTY(Category="Life Giving")
	float ForceFeedbackStickDeadzone = 0.0;

	UPROPERTY(Category = "Ranged Interactions")
	bool bAllowRangedInteractionAimingWhileAirborne = false;

	/* How fast the roots grow from tree guardian's hands when interacting with a grapple point */
	UPROPERTY(Category = "Ranged Interactions|Grapple")
	float GrappleRootsGrowSpeed = 8000.0;

	UPROPERTY(Category = "Ranged Interactions|Grapple")
	float GrappleEnterSpeed = 3500.0;

	/* The relative offset from the actual grapple point where the tree guardian will be located. */
	UPROPERTY(Category = "Ranged Interactions|Grapple")
	FVector GrappleRelativeOffset = FVector(200.0, 0.0, -300.0);

	/** When the player is this far away from the destination point, the player will start to rotate to be attached to the wall, will also set bool for animation to start preparing for attach */
	UPROPERTY(Category = "Ranged Interactions|Grapple")
	float DistanceFromGrapplePointToStartPreparingToAttach = 300.0;

	UPROPERTY(Category = "Ranged Interactions|Grapple")
	float SpeedEffectAmount = 2.0;

	/* How fast the roots grow from tree guardian's hands when interacting with a ranged life give */
	UPROPERTY(Category = "Ranged Interactions|Life Giving")
	float RangedLifeGivingRootsGrowSpeed = 400000.0;

	UPROPERTY(Category = "Ranged Interactions|Shoot")
	float MaxAngleToShootTargetableFromPlayerForward = 70.0;
}