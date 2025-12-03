class UPlayerWallScrambleSettings : UHazeComposableSettings
{
	// Height you can gain, subtracted from the distance to the floor beneath you
	UPROPERTY()
	float FloorHeightGain = 365.0;

	UPROPERTY()
	float NoFloorHeightGain = 225.0;

	// How fast you scramble up the wall
	UPROPERTY()
	float ScrambleSpeed = 650.0;

	// If there is no wall at this height, the scramble will be cancelled. Acts like a 'grab height'
	UPROPERTY()
	float TopHeight = 160.0;

	// if there is no wall at this height, then scramble will be cancelled. Traces around the height of foot placement along the wall for scramble
	UPROPERTY()
	float BottomHeight = 30;

	// If there is no wall at this height we initiate exit
	UPROPERTY()
	float PredictionHeight = 60;

	UPROPERTY()
	float JumpVerticalImpulse = 535.0;

	UPROPERTY()
	float JumpHorizontalImpulse = 750.0;

	// The acceptance angle (yaw) of the player
	const float AcceptanceAngle = 65.0;

	UPROPERTY()
	float ExitHorizontalInterpSpeed = 1200.0;
	
	const float ExitDuration = 1.5;
	
	const float ExitTurnDuration = 0.5;

	// How long the player can't move for
	const float ExitNoInputDuration = 0.25;

	// How long it takes for the input to get to 100% strength (from activation)
	const float ExitNoInputBlendTime = 0.75;

	// How long within the Exit can you activate the jump
	const float JumpExitAcceptanceTime = 0.5;

	// How long the player has no input for
	const float JumpNoInputTime = 0.4;

	// How long it takes for the input to blend into full strength
	const float JumpInputBlendinTime = 0.8;

	const float JumpHorizontalDrag = 1.2;

	const float JumpGravityBlendInTime = 0.4;
}