class UJetskiMovementSettings : UHazeComposableSettings
{
	// Movement

	UPROPERTY(Category = "Speed")
    float MaxSpeed = 3500;

	UPROPERTY(Category = "Speed")
    float MaxSpeedWhileTurning = 3500;

	UPROPERTY(Category = "Speed")
    float Acceleration = 3000;
	
	UPROPERTY(Category = "Speed")
    float Deceleration = 2000;

	// How fast do we want to lose horizontal velocity towards the sides of the jetski? (not forward)
	UPROPERTY(Category = "Speed")
	float SideSpeedDeceleration = 4;

	UPROPERTY(Category = "Movement")
    float GravityScale = 5;


	// Air

	UPROPERTY(Category = "Air")
	float AirDiveGravityMultiplier = 2.0;


	// Water

	UPROPERTY(Category = "Water")
	float WaterLandVelocityKeptMultiplier = 0.6;

	UPROPERTY(Category = "Water")
	float WaterEnterFromGroundVelocityKeptMultiplier = 0.9;


	// Underwater
	
	UPROPERTY(Category = "Underwater")
	float UnderwaterLandVelocityKeptMultiplier = 0.5;

	UPROPERTY(Category = "Underwater")
	float UnderwaterLandVelocityKeptWhenDivingMultiplier = 0.8;

	UPROPERTY(Category = "Underwater")
	float UnderwaterDiveDepth = -800;

	UPROPERTY(Category = "Underwater")
	float UnderwaterDiveReachBottomStiffness = 30;

	UPROPERTY(Category = "Underwater")
	float UnderwaterDiveReachBottomDamping = .3;


	// Jump

	UPROPERTY(Category = "Underwater|Jump")
	float UnderwaterDiveJumpSpeed = 3000;

	UPROPERTY(Category = "Underwater|Jump")
	float UnderwaterDiveJumpAcceleration = 10000;

	// Follow Spline

	UPROPERTY(Category = "Underwater|Follow Spline")
	float UnderwaterFollowSplineMaxJumpSpeed = 5000;

	UPROPERTY(Category = "Underwater|Follow Spline")
	float UnderwaterFollowSplineMaxJumpHorizontalSpeed = 5000;
};