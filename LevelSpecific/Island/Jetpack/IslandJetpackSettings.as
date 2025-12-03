class UIslandJetpackSettings : UHazeComposableSettings
{
	// The class of the jetpack that gets spawned and attached
	UPROPERTY(Category = "Setup")
	TSubclassOf<AIslandJetpack> JetpackClass;

	UPROPERTY(Category = "Setup")
	USkeletalMesh MioMesh;

	UPROPERTY(Category = "Setup")
	USkeletalMesh ZoeMesh;

	// The name of the bone where the jetpack gets attached
	UPROPERTY(Category = "Setup")
	FName AttachmentBone = n"Spine2";

	/* Curve of how the velocity is applied over time
	Time axle : 0 -> 1 Duration of jet  
	Value axle : 0 -> 1 Fraction of max velocity (1 = VelocityMax) */
	UPROPERTY(Category = "Initial Boost")
	FRuntimeFloatCurve InitialBoostSpeedCurve;
	default InitialBoostSpeedCurve.AddDefaultKey(0.0, 0.0);
	default InitialBoostSpeedCurve.AddDefaultKey(0.5, 1.0);
	default InitialBoostSpeedCurve.AddDefaultKey(1.0, 0.0);

	// Velocity at 1 of the value axle in the velocity curve
	UPROPERTY(Category = "Initial Boost")
	float InitialBoostSpeedMax = 6000;

	UPROPERTY(Category = "Initial Boost")
	float HoldBoost = 4500.0;

	UPROPERTY(Category = "Initial Boost")
	float HoldDeceleration = 2.5;

	// Duration of the jet (Gets disabled after)
	UPROPERTY(Category = "Initial Boost")
	float InitialBoostDuration = 0.5;

	// How much faster you gain speed upwards if you are falling downwards during initial boost
	UPROPERTY(Category = "Initial Boost")
	float InitialBoostGoingDownMultiplier = 5.0;

	/* The vertical velocity will be clamped so it's size is not bigger than this value (up only, down is completely negated). Negative values means we wont clamp the vertical velocity when entering vertical phase walls */
	UPROPERTY(Category = "Phase Wall Boost")
	float ClampToMaxSizeVerticalVelocityWhenEnteringPhaseWall = 300.0;

	// Velocity at 1 of the value axle in the velocity curve
	UPROPERTY(Category = "Phase Wall Boost")
	float PhaseWallBoostSpeedMax = 18000;

	/* Curve of how the velocity is applied over time
	Time axle : 0 -> 1 Duration of jet  
	Value axle : 0 -> 1 Fraction of max velocity (1 = VelocityMax) */
	UPROPERTY(Category = "Phase Wall Boost")
	FRuntimeFloatCurve PhaseWallBoostSpeedCurve;
	default PhaseWallBoostSpeedCurve.AddDefaultKey(0.0, 1.0);
	default PhaseWallBoostSpeedCurve.AddDefaultKey(0.5, 0.5);
	default PhaseWallBoostSpeedCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(Category = "Phase Wall Boost")
	float PhaseWallBoostDuration = 0.2;

	// How much faster you gain speed upwards if you are falling downwards during phase wall boost
	UPROPERTY(Category = "Phase Wall Boost")
	float PhaseWallBoostGoingDownMultiplier = 5.0;

	// How much charge is lost per second while jetpacking
	UPROPERTY(Category = "Charge")
	float ChargeDepletionSpeed = 0.1;

	/** How much charge is lost per second while boosting */
	UPROPERTY(Category = "Charge")
	float BoostChargeDepletionSpeed = 0.2;

	/** How much charge is lost instantly when activating the jetpack */
	UPROPERTY(Category = "Charge")
	float BoostActivationDepletion = 0.1;

	UPROPERTY(Category = "Charge")
	float DashActivationDepletion = 0.085;

	/** How fast the charge gets replenished when landing */
	UPROPERTY(Category = "Charge")
	float ChargeLandReplenishSpeed = 2.0;

	UPROPERTY(Category = "Charge")
	float RespawnChargeDepletionDelay = 1.0;

	/** How much you go up when you are holding A after initial boost
	 * If you are holding sideways, you go less up :)
	 */
	UPROPERTY(Category = "Hold")
	float HoldVerticalBoost = 400.0;

	/** Constant vertical deceleration */
	UPROPERTY(Category = "Hold")
	float HoldVerticalDeceleration = 1.5;

	/** How much you go upwards if you have no stick input and hold A */
	UPROPERTY(Category = "Hold")
	float HoldVerticalSpeedMax = 550.0;

	/** How much faster you go upwards if you are going downwards
	 * To make you stop faster if you are falling fast and activate the thruster
	 */
	UPROPERTY(Category = "Hold")
	float HoldVerticalBoostGoingDownMultiplier = 5.0;

	UPROPERTY(Category = "Dash")
	TSubclassOf<UCameraShakeBase> DashShake;

	UPROPERTY(Category = "Dash")
	float DashDuration = 0.75;

	UPROPERTY(Category = "Dash")
	float DashAdditionalSpeedMax = 1500.0;

	UPROPERTY(Category = "Dash")
	float DashRedirectionSpeed = 2.5;

	UPROPERTY(Category = "Dash")
	FRuntimeFloatCurve DashSpeedCurve;
	default DashSpeedCurve.AddDefaultKey(0.0, 0.0);
	default DashSpeedCurve.AddDefaultKey(0.2, 1.0);
	default DashSpeedCurve.AddDefaultKey(1.0, 0.0);

	UPROPERTY(Category = "Dash")
	float DashMaxSpeed = 1750.0;

	UPROPERTY(Category = "Dash")
	float MinimumDashExitSpeed = 250.0;

	// How much acceleration horizontally you have with input
	UPROPERTY(Category = "Horizontal")
	float HorizontalVelocityAcceleration = 1150;

	// Makes it turn around faster
	UPROPERTY(Category = "Horizontal")
	float HorizontalVelocityNotGoingTowardsVelocityMultiplier = 1.5;

	// Constant deceleration, increase to make less floaty
	UPROPERTY(Category = "Horizontal")
	float HorizontalVelocityDeceleration = 1.5;

	// How fast you turn while jetpacking
	UPROPERTY(Category = "Rotation")
	float InterpRotationSpeed = 3.0;

	/** How fast you tilt towards the input */
	UPROPERTY(Category = "Rotation")
	float TiltTowardsInputSpeed = 1.0;

	/** How much you tilt as a maximum towards the input */
	UPROPERTY(Category = "Rotation")
	float TiltMax = 10.0;

	UPROPERTY(Category = "Phasable Platforms")
	float PhasablePlatformBoostImpulseSize = 2000.0;

	// Camera shake when the jetpack gets activated
	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> JetpackActivationShake;

	/** Applied at the start of the initial boost so it looks like player is going away from the camera slightly */
	UPROPERTY(Category = "Camera")
	FHazeCameraImpulse InitialBoostCameraImpulse;
	default InitialBoostCameraImpulse.WorldSpaceImpulse = FVector(0, 0, -500);
	default InitialBoostCameraImpulse.ExpirationForce = 10.0;

	UPROPERTY(Category = "FOV")
	float DashFOVAccelerationDuration = 0.3;

	UPROPERTY(Category = "FOV")
	float DashFOVDecelerationDuration = 0.5;

	UPROPERTY(Category = "FOV")
	float DashFOVIncreaseDuration = 0.4;

	UPROPERTY(Category = "FOV")
	float DashFOVIncreaseAmount = 5.0;

	UPROPERTY(Category = "FOV")
	float PhaseWallFOVAccelerationDuration = 0.3;

	UPROPERTY(Category = "FOV")
	float PhaseWallFOVDecelerationDuration = 0.5;

	UPROPERTY(Category = "FOV")
	float PhaseWallFOVIncreaseDuration = 0.4;

	UPROPERTY(Category = "FOV")
	float PhaseWallFOVIncreaseAmount = 5.0;

	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementAccelerationDuration = 2.0;

	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementCameraMaxAdditiveFOV = 25;

	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementCameraFOVAccDuration = 1.5;

	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementMinDuration = 0.75;

	/** How long the slowdown capability is active. */
	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementSlowdownTotalDuration = 0.75;

	/** How long it takes for the movement to reach desired slowdown speed. */
	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementSlowdownReachSpeedDuration = 0.35;

	/** How long it takes for the movement to reach desired slowdown speed. */
	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementSlowdownDesiredSpeed = -500;

	/** How long it takes for the camera to blend to 0 additive while slowing down. */
	UPROPERTY(Category = "Phasable Movement")
	float PhasableMovementSlowdownFOVBlendDuration = 0.75;
	
	UPROPERTY(Category = "Phasable Movement")
	TSubclassOf<UCameraShakeBase> PhasableMovementCameraShake;

	/** Rumble for initial burst */
	UPROPERTY(Category = "Haptic Feedback")
	UForceFeedbackEffect InitialBoostRumble;

	/** Multiplier for the continuous force rumble when holding
	 * Use big numbers, not sure why it's needed */
	UPROPERTY(Category = "Haptic Feedback")
	float HoldForceFeedbackMultiplier = 1.0;


	UPROPERTY(Category = "Jump Dash Charge")
	bool bReplenishAirDashAfterRunningOutOfFuel = false;

	UPROPERTY(Category = "Jump Dash Charge")
	bool bReplenishAirJumpAfterRunningOutOfFuel = false;

	// FUEL METER
	
	// The color of the meter when fully charged
	UPROPERTY(Category = "Fuel Meter")
	FLinearColor ChargedColor = FLinearColor::Teal;

	// The color of the meter when boosting
	UPROPERTY(Category = "Fuel Meter")
	FLinearColor BoostingColor = FLinearColor::Red;

	UPROPERTY(Category = "Fuel Meter")
	TSubclassOf<UIslandJetpackSidescrollerFuelWidget> SidescrollerFuelWidgetClass;

	// TUTORIAL
	UPROPERTY(Category = "Tutorial")
	FTutorialPrompt CancelPrompt;
	default CancelPrompt.Action = ActionNames::Cancel;
	default CancelPrompt.DisplayType = ETutorialPromptDisplay::Action;
	default CancelPrompt.Mode = ETutorialPromptMode::Default;
	default CancelPrompt.Text = NSLOCTEXT("Jetpack", "Cancel Tutorial Prompt", "Cancel");
	default CancelPrompt.MaximumDuration = -1.0;

	UPROPERTY(Category = "Tutorial")
	FVector CancelPromptOffset = FVector(0, 0, -250);

	UPROPERTY(Category = "Tutorial")
	FTutorialPrompt BoostPrompt;
	default BoostPrompt.Action = ActionNames::MovementJump;
	default BoostPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
	default BoostPrompt.Mode = ETutorialPromptMode::Default;
	default BoostPrompt.Text = NSLOCTEXT("Jetpack", "Boost Tutorial Prompt", "Boost");
	default BoostPrompt.MaximumDuration = -1.0;

	UPROPERTY(Category = "Tutorial")
	FVector BoostPromptOffset = FVector(0, 0, 100);
}