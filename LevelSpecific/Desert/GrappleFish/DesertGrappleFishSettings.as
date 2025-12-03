namespace GrappleFishMovement
{
	const FHazeDevToggleCategory AutoPilotCategory = FHazeDevToggleCategory(n"GrappleFish AutoPilot");

	const FHazeDevToggleGroup MioAutoPilotGroup = FHazeDevToggleGroup(AutoPilotCategory, n"AutoPilotGroupMio");
	const FHazeDevToggleOption MioAutoPilotDisabled = FHazeDevToggleOption(MioAutoPilotGroup, n"Disabled");
	const FHazeDevToggleOption MioAutoPilotDead = FHazeDevToggleOption(MioAutoPilotGroup, n"Dead");
	const FHazeDevToggleOption MioAutoPilotAlive = FHazeDevToggleOption(MioAutoPilotGroup, n"Alive");

	const FHazeDevToggleGroup ZoeAutoPilotGroup = FHazeDevToggleGroup(AutoPilotCategory, n"AutoPilotGroupZoe");
	const FHazeDevToggleOption ZoeAutoPilotDisabled = FHazeDevToggleOption(ZoeAutoPilotGroup, n"Disabled");
	const FHazeDevToggleOption ZoeAutoPilotDead = FHazeDevToggleOption(ZoeAutoPilotGroup, n"Dead");
	const FHazeDevToggleOption ZoeAutoPilotAlive = FHazeDevToggleOption(ZoeAutoPilotGroup, n"Alive");

	const float MinRubberbandAdditiveMoveSpeed = -400;
	const float MaxRubberbandAdditiveMoveSpeed = 400;
	const float IdealMoveSpeed = 2800;
	const float MovementAccelerationDuration = 0.8;

	const float DivingIdealMoveSpeed = 4000;
	const float DivingStartedMoveSpeed = 500;
	const float DiveMovementAccelerationDuration = 0.5;

	const float IdealSharkDistance = 6000;

	const float MaxTurnSpeedDeg = 60;
	// How quickly the shark accelerates in Z to the height of landscape, lower values will make shark stick to ground but makes small bumps noticable
	const float LandscapeHeightAccelerationDuration = 0.1;
	// How long it takes to accelerate to maximum turnspeed
	const float TurnAccelerationDuration = 0.55;
	// How additional time it takes to accelerate to maximum turnspeed when changing direction
	const float TurnChangeDirectionAdditionalDuration = 0.3;
	// How long it takes to stop turning when not giving input
	const float TurnDecelerationDuration = 0.55;

	// Max speed the shark strafes horizontally relative to spline or splineoffset during autopilot
	const float AutoPilotStrafeMovementSpeed = 700;

	// How quickly the shark horizontal speed accelerates to max
	const float AutoPilotHorizontalAccelerationDuration = 0.5;
	const float ForceAutoPilotHorizontalAccelerationDuration = 0.1;

	const float LandscapeNormalAlignmentDuration = 0.5;

	const float EndJumpForwardMovementSpeed = 2500;
	const float EndJumpForwardAccelerationDuration = 0.5;
}

namespace GrappleFishAnimations
{
	const float DiveDuration = 1.0;
	const float BreachDuration = 0.9;
}

namespace GrappleFishCamera
{
	const float RidingCameraSettingsBlendInTime = 2.0;
	const float RidingCameraSettingsBlendOutTime = -1;

	// positive and negative roll clamp
	const float RidingCameraMaxRoll = 15.0;
	const bool bRidingCameraRollInSharkRollDirection = true;
	const float RidingCameraDismountUnrollInterpSpeed = 2;
}

namespace GrappleFishPOI
{
	const float POIForwardOffset = 2200.0;
	const float POISideOffset = 250.0;
	const float POISideInterpSpeed = 800.0;

	const FVector2D RidingPOIYawClamp = FVector2D(30, 30);
	const FVector2D RidingPOIPitchClamp = FVector2D(65, 0);

	// ClampSettings
	const float RidingPOIBlendInTime = 2.0;
	const float RidingPOIClampDuration = -1;
	const ECameraPointOfInterestAccelerationType RidingPOIBlendInAccelerationType = ECameraPointOfInterestAccelerationType::Fast;
	const float RidingPOIInputCounterForce = 4;
	const float RidingPOIInputTurnRateMultiplier = 0.3;
}

namespace GrappleFishVisuals
{
	// Animation turning blend cap, 1.0 will make the shark turn close to 90 degrees
	const float MaxBlendFrac = 0.35;
	// How quickly the shark reaches max blend
	const float TurnBlendInterpSpeed = 2.0;
	// Turn blend speed when stopping input
	const float NoInputTurnBlendInterpSpeed = 1.2;

	// How much the shark rolls towards input direction
	const float MaxRollAmount = 35;
	// How quickly the shark rolls
	const float RollInterpSpeed = 1.2;
	// How quickly the shark rolls back to 0
	const float NoInputRollnterpSpeed = 0.6;
}

namespace GrappleFishPlayer
{
	const float MinRespawnCooldown = 1.5;
	const float ExtendedRespawnAutoPilotDuration = 1.0;
	
	const float GrappleToPointAccelerationDuration = 0.06;
	const float GrappleToPointTopVelocity = 7400;
	const float LaunchUpwardsImpulse = 2300;
	const float LaunchForwardImpulseSpeedFraction = 0.75;
	
	const float EndJumpMovementImpulseMagnitude = 1000;
}