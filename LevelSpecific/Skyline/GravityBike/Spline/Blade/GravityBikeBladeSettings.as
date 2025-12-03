namespace GravityBikeBlade
{
	const FName ChangeGravityInput = ActionNames::SecondaryLevelAbility;
	const float LandingAngleThreshold = 30;

	const float ThrowingDuration = 0.2;

	// Throw
	const float ThrowFOVAdditive = -20;
	const float ThrowSpeed = 10000;
	const float ThrowTargetLineLength = 10000;
	const FName HipSocket = n"GravityBladeBikeSocket";
	const FName HandSocket = n"RightAttach";
	const float MinThrowDuration = 0.05;
	const float MaxThrowDuration = 0.2;
	const float AlphaExponent = 2;
	const float BladeRotationInterpSpeed = 5;

	// Change Gravity
	const float MinTimeToLanding = 0.2;

	// Grapple
	const float MinGrappleDuration = 0.4;
	const float MaxGrappleDuration = 0.5;
	const float GrappleFOVAdditive = 20;
	const float GrappleFOVBlendOutTime = 0.2;
	const float GrappleSpeed = 5000;
	const float GrappleTerminalVelocity = 20000;
	const float GrappleAcceleration = 10000;
	//const float PivotLagMax = 1000;
	//const float PivotLagAccelerationDuration = 2;
	
	AHazePlayerCharacter GetPlayer()
	{
		return Game::Mio;
	}
}